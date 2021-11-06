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
  return 0;
}

static sMemfaultShellImpl memfault_shell_impl = {
    .send_char = send_char,
};
#endif
#endif

#if ENABLE_NOCLI
#include "third-party/nocli/nocli.h"

static void prv_nocli_output(const char *buf, size_t len) {
  fwrite(buf, 1, len, stdout);
}

static void fs(int argc, char **argv) {
  (void)argc, (void)argv;
  printf("function called!\n");
}

struct NocliPrivate nocli_private;
struct NocliCommand commands[] = {{
    .name = "fs",
    .function = fs,
    .help = "fs help",
}};
struct Nocli nocli_ctx = {
    .output_stream = prv_nocli_output,
    .command_table = commands,
    .command_table_length = sizeof(commands) / sizeof(*commands),
    .prefix_string = "console $",
    .echo_on = true,
    .private = &nocli_private,
};
#endif

#if ENABLE_LITTLEFS

#include <string.h>

#include "third-party/littlefs/lfs.h"
#include "third-party/littlefs/lfs_util.h"

// variables used by the filesystem
lfs_t lfs;
lfs_file_t file;

#include "libopencm3/stm32/flash.h"

static uint32_t prv_flash_address_for_littlefs(const struct lfs_config *c,
                                               lfs_block_t block,
                                               lfs_off_t off) {
  return (uint32_t)block * c->block_size + (uint32_t)off +
         0x08020000;  // base address of 128k sectors
}

static int prv_lfs_read(const struct lfs_config *c, lfs_block_t block,
                        lfs_off_t off, void *buffer, lfs_size_t size) {
  LFS_TRACE("read %lu %lu %lu\n", block, off, size);

  // flash is memory-mapped, so fetch the appropriate address
  const uint32_t address = prv_flash_address_for_littlefs(c, block, off);
  memcpy(buffer, (void *)address, size);

  return LFS_ERR_OK;
}

static int prv_lfs_prog(const struct lfs_config *c, lfs_block_t block,
                        lfs_off_t off, const void *buffer, lfs_size_t size) {
  LFS_TRACE("prog %lu %lu %lu\n", block, off, size);

  const uint32_t address = prv_flash_address_for_littlefs(c, block, off);

  {
    flash_unlock();
    for (size_t i = 0; i < size / 2; i++) {
      const uint16_t *src = (uint16_t *)buffer + i;
      uint16_t *dest = (uint16_t *)address + i;
      flash_program_half_word((uint32_t)dest, *src);
    }
    flash_lock();
  }

  return LFS_ERR_OK;
}

// May return LFS_ERR_CORRUPT if the block should be considered bad.
static int prv_lfs_erase(const struct lfs_config *c, lfs_block_t block) {
  (void)c;

  // 128k sectors start at block 5
  block += 5;

  LFS_TRACE("erase block %lu\n", block);

  {
    flash_unlock();
    flash_erase_sector(block, 1);  // 16-bit program size
    flash_lock();
  }

  return LFS_ERR_OK;
}

static int prv_lfs_sync(const struct lfs_config *c) {
  (void)c;
  return LFS_ERR_OK;
}

// configuration of the filesystem is provided by this struct
const struct lfs_config cfg = {
    // block device operations
    .read = prv_lfs_read,
    .prog = prv_lfs_prog,
    .erase = prv_lfs_erase,
    .sync = prv_lfs_sync,

    // block device configuration
    .read_size = 1,
    .prog_size = 2,
    .block_size = 131072,
    .block_count = 7,
    .cache_size = 16,
    .lookahead_size = 16,
    .block_cycles = 500,
};

static void prv_lfs_init(void) {
  // note: if using non-default cpu frequency on the stm32f4 discovery (which is
  // 16MHz High Speed Internal oscillator, HSI), may need to update wait states
  // flash_set_ws(0);

  // mount the filesystem
  int err = lfs_mount(&lfs, &cfg);

  // reformat if we can't mount the filesystem
  // this should only happen on the first boot
  if (err) {
    lfs_format(&lfs, &cfg);
    lfs_mount(&lfs, &cfg);
  }

  // read current count
  uint32_t boot_count = 0;
  lfs_file_open(&lfs, &file, "boot_count", LFS_O_RDWR | LFS_O_CREAT);
  lfs_file_read(&lfs, &file, &boot_count, sizeof(boot_count));

  // update boot count
  boot_count += 1;
  lfs_file_rewind(&lfs, &file);
  lfs_file_write(&lfs, &file, &boot_count, sizeof(boot_count));

  // remember the storage is not updated until the file is closed successfully
  lfs_file_close(&lfs, &file);

  // release any resources we were using
  lfs_unmount(&lfs);

  // print the boot count
  printf("boot_count: %" PRIu32 "\n", boot_count);
}

#endif

int main(void) {
#if ENABLE_SEMIHOSTING
  initialise_monitor_handles();
#elif ENABLE_RTT
  SEGGER_RTT_Init();
#endif

#if ENABLE_NOCLI
  Nocli_Init(&nocli_ctx);

#endif

#if ENABLE_STDIO
  // line buffering on stdout
  setvbuf(stdout, NULL, _IOLBF, 0);

  printf("🦄 Hello there!\n");
#endif

#if ENABLE_LITTLEFS
  prv_lfs_init();
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
      memfault_demo_shell_receive_char(c);
    }
#elif ENABLE_NOCLI
    char c;

    if (read(0, &c, sizeof(c))) {
      Nocli_Feed(&nocli_ctx, &c, sizeof(c));
    }
#endif
  };

  return 0;
}
