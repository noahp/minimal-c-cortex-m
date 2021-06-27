#include <stdio.h>
#include <unistd.h>
#if ENABLE_RTT
#include "third-party/segger-rtt/RTT/SEGGER_RTT.h"

int _read(int fd, const void *buf, size_t count) {
  (void)fd;

  // always non-blocking
  return SEGGER_RTT_Read(0, (uint8_t *)buf, count);
}

#endif

extern void initialise_monitor_handles(void);

int main(void) {

  // add an sprintf to force including a good portion of clib, including malloc
  // should be snprintf_s but newlib doesn't have it as of 3.3.0
  char yolo[128];
  snprintf(yolo, sizeof(yolo) - 1, "boom %.3f", 123.4f); // NOLINT

#if ENABLE_SEMIHOSTING
  initialise_monitor_handles();
#elif ENABLE_RTT
  SEGGER_RTT_Init();
#endif

#if ENABLE_STDIO
  // line buffering on stdout
  setvbuf(stdout, NULL, _IOLBF, 0);

  printf("🦄 Hello there!\n");
#endif

  while (1) {
#if ENABLE_STDIO
    unsigned read_count = read(0, yolo, sizeof(yolo));
    if (read_count) {
      printf("🦄 Hello there: %.*s\n", read_count, yolo);
    }
#endif
  };

  return 0;
}
