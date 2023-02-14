#include <stdio.h>
#include <unistd.h>

#if ENABLE_MEMFAULT
#include "memfault/components.h"
#endif

#if ENABLE_RTT
#include "third-party/segger-rtt/RTT/SEGGER_RTT.h"

int _read(int fd, const void *buf, size_t count) {
  (void)fd;

  // always non-blocking
  return SEGGER_RTT_Read(0, (uint8_t *)buf, count);
}
#endif

extern void initialise_monitor_handles(void);

#if ENABLE_MEMFAULT
extern void __real_free(void *ptr);
extern void *__real_malloc(size_t size);
void __wrap_free(void *ptr) {
  MEMFAULT_HEAP_STATS_FREE(ptr);
  __real_free(ptr);
}

void *__wrap_malloc(size_t size) {
  void *ptr = __real_malloc(size);
  MEMFAULT_HEAP_STATS_MALLOC(ptr, size);
  return ptr;
}
#if ENABLE_MEMFAULT_DEMO
static int send_char(char c) {
  putchar(c);
  fflush(stdout);
  return 0;
}

static sMemfaultShellImpl memfault_shell_impl = {
    .send_char = send_char,
};
#endif
#endif

int main(void) {
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

#if ENABLE_MEMFAULT
#if ENABLE_MEMFAULT_DEMO
  memfault_demo_shell_boot(&memfault_shell_impl);
#endif
  memfault_platform_boot();
#endif

  while (1) {
#if ENABLE_MEMFAULT_DEMO
    char c;

    if (read(0, &c, sizeof(c))) {
#if defined(BOARD_qemu_mps2_an385)
      // hack workaround, the qemu console sends \r instead of \n
      if (c == '\r') {
        c = '\n';
      }
#endif
      memfault_demo_shell_receive_char(c);
    }
#endif
  };

  return 0;
}
