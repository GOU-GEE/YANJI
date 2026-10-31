#include <dlfcn.h>
#include <stdio.h>
int main(void) {
  void* lib=dlopen("/data/local/tmp/yanji_go_probe.so", RTLD_NOW);
  if (!lib) { fprintf(stderr,"DLOPEN_FAILED: %s\n",dlerror()); return 2; }
  int (*probe)(void)=dlsym(lib,"YanjiProbeABI");
  if (!probe) { fprintf(stderr,"SYMBOL_FAILED: %s\n",dlerror()); return 3; }
  printf("YANJI_GO_ABI_PROBE=%d\n", probe());
  return 0;
}
