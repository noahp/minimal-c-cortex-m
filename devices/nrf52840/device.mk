ROM_ORIGIN = 0x00000000
ROM_LENGTH = 0x100000
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 0x40000

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m4 \
  -mfloat-abi=hard \
  -mfpu=fpv4-sp-d16 \
  -include $(_THIS_DIR)/nrf52840.h

FLASH_CMD = \
    JLinkGDBServerCLExe -USB -device nRF52840_xxAA -endian little -if SWD \
    -speed auto -noir -LocalhostOnly -port 3333
GDB_RELOAD_CMD = jlink-reload
