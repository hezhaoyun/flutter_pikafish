abstract class PikafishEngine {
  Future<void> init();
  void dispose();
  void writeCommand(String command);
  Stream<String> get output;
}
