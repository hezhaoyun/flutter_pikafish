import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../ffi.dart';
import 'engine_interface.dart';

final _logger = Logger('FFIPikafishEngine');

class FFIPikafishEngine implements PikafishEngine {
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  @override
  Future<void> init() async {
    _mainSubscription = _mainPort.listen(_onMainMessage);
    _stdoutSubscription = _stdoutPort.listen(_onStdoutMessage);

    nativeInit();
    final success = await compute(
        _spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort]);

    if (!success) {
      throw StateError('Failed to initialize engine');
    }
  }

  void _onMainMessage(dynamic message) {
    final exitCode = message is int ? message : 1;
    _cleanUp(exitCode);
  }

  void _onStdoutMessage(dynamic message) {
    if (message is String) {
      _logger.finest('The stdout isolate sent $message');
      _stdoutController.sink.add(message);
    } else {
      _logger.fine('The stdout isolate sent $message');
    }
  }

  @override
  void writeCommand(String command) {
    final pointer = '$command\n'.toNativeUtf8();
    nativeStdinWrite(pointer);
    calloc.free(pointer);
  }

  @override
  void dispose() {
    writeCommand('quit');
    _cleanUp(0);
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();
    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
  }

  @override
  Stream<String> get output => _stdoutController.stream;
}

// Isolate entry point for the main engine thread
Future<bool> _spawnIsolates(List<SendPort> ports) async {
  final mainPort = ports[0];
  final stdoutPort = ports[1];

  // Start the main isolate
  await Isolate.spawn(
    _mainIsolateFunction,
    [mainPort, stdoutPort],
    debugName: 'pikafish-main',
  );

  // Start the stdout isolate
  await Isolate.spawn(
    _stdoutIsolateFunction,
    stdoutPort,
    debugName: 'pikafish-stdout',
  );

  return true;
}

// Main isolate function that runs the engine
void _mainIsolateFunction(List<SendPort> ports) {
  final mainPort = ports[0];

  try {
    final exitCode = nativeMain();
    mainPort.send(exitCode);
  } catch (e) {
    _logger.severe('Main isolate encountered an error: $e');
    mainPort.send(1);
  }
}

// Stdout isolate function that reads engine output
void _stdoutIsolateFunction(SendPort stdoutPort) {
  while (true) {
    final pointer = nativeStdoutRead();
    if (pointer == nullptr) {
      break;
    }

    final output = pointer.toDartString();
    stdoutPort.send(output);
  }

  stdoutPort.send(null);
}
