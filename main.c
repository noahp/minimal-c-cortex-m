#include <stdio.h>

extern void initialise_monitor_handles(void);

int main(void) {
  char yolo[128];

  // should be snprintf_s but newlib doesn't have it as of 3.3.0
  snprintf(yolo, sizeof(yolo) - 1, "boom %.3f", 123.4f); // NOLINT

#if ENABLE_SEMIHOSTING
  initialise_monitor_handles();

  // don't buffer on stdout
  setbuf(stdout, NULL);

  printf("🦄 Hello there!\n");
#endif

  while (1) {
  };

  return 0;
}
