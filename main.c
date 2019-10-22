#include <stdio.h>

extern void initialise_monitor_handles(void);

int main(void) {
#if ENABLE_SEMIHOSTING
  initialise_monitor_handles();

  // don't buffer on stdout
  setbuf(stdout, NULL);

  printf("Hello there!\n");
#endif

  while (1) {
  };

  return 0;
}
