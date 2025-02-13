#import "PikafishPlugin.h"
#import "ffi.h"

@implementation PikafishPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (registrar == NULL) {
    // avoid dead code stripping
    pikafish_init();
    pikafish_main();
    pikafish_stdin_write(NULL);
    pikafish_stdout_read();
  }
}

@end
