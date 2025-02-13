#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
int
pikafish_init();

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
int
pikafish_main();

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
ssize_t
pikafish_stdin_write(char *data);

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
char *
pikafish_stdout_read();
