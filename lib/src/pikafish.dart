import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'pikafish_state.dart';
import 'engine/engine_interface.dart';
import 'engine/ffi_engine.dart';
import 'engine/process_engine.dart';

/// A wrapper for C++ engine.
class Pikafish {
  final Completer<Pikafish>? completer;
  final PikafishEngine _engine;
  final _state = _PikafishState();

  Pikafish._({this.completer}) : _engine = Platform.isIOS ? FFIPikafishEngine() : ProcessPikafishEngine() {
    _initEngine();
  }

  static Pikafish? _instance;

  factory Pikafish() {
    if (_instance != null) {
      throw StateError('Multiple instances are not supported, yet.');
    }

    _instance = Pikafish._();
    return _instance!;
  }

  /// The current state of the underlying C++ engine.
  ValueListenable<PikafishState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _engine.output;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != PikafishState.ready) {
      throw StateError('Pikafish is not ready ($stateValue)');
    }
    _engine.writeCommand(line);
  }

  /// Stops the C++ engine.
  void dispose() {
    _engine.dispose();
    _state._setValue(PikafishState.disposed);
    _instance = null;
  }

  Future<void> _initEngine() async {
    try {
      await _engine.init();
      _state._setValue(PikafishState.ready);
      completer?.complete(this);
    } catch (error) {
      _state._setValue(PikafishState.error);
      completer?.completeError(error);
    }
  }
}

/// Creates a C++ engine asynchronously.
///
/// This method is different from the factory method [Pikafish.new] that
/// it will wait for the engine to be ready before returning the instance.
Future<Pikafish> pikafishAsync() {
  if (Pikafish._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<Pikafish>();
  Pikafish._instance = Pikafish._(completer: completer);
  return completer.future;
}

class _PikafishState extends ChangeNotifier implements ValueListenable<PikafishState> {
  PikafishState _value = PikafishState.starting;

  @override
  PikafishState get value => _value;

  _setValue(PikafishState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}
