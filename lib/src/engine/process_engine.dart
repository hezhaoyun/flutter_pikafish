import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'engine_interface.dart';

class ProcessPikafishEngine implements PikafishEngine {
  Process? _process;
  final _outputController = StreamController<String>.broadcast();

  @override
  Future<void> init() async {
    final engineFile = await _prepareEngineFile();
    if (engineFile == null) return;

    _process = await Process.start(
      engineFile.path,
      [],
      mode: ProcessStartMode.normal,
    );

    _process!.stdout
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen(_outputController.add);

    _process!.stderr
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen(_outputController.add);
  }

  Future<File?> _prepareEngineFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final engineFileName = _getPlatformEngineFileName();
    if (engineFileName == null) return null;

    final engineFile = File('${appDir.path}/$engineFileName');
    if (!await engineFile.exists()) {
      final bytes = await rootBundle.load('packages/pikafish/assets/pikafish/$engineFileName');
      await engineFile.writeAsBytes(bytes.buffer.asUint8List());
      // Make file executable
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', engineFile.path]);
      }
    }
    return engineFile;
  }

  String? _getPlatformEngineFileName() {
    if (Platform.isAndroid) return 'android-armv8';
    if (Platform.isMacOS) return 'macos-apple-silicon';
    if (Platform.isLinux) return 'linux-avx2';
    if (Platform.isWindows) return 'windows-avx2.exe';
    return null;
  }

  @override
  void writeCommand(String command) {
    _process?.stdin.writeln(command);
  }

  @override
  void dispose() {
    writeCommand('quit');
    _process?.kill();
    _outputController.close();
  }

  @override
  Stream<String> get output => _outputController.stream;
}
