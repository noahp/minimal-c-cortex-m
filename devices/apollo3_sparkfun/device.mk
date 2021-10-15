# Sparkfun Artemis Black board for Ambiq Apollo 3
# https://www.sparkfun.com/products/retired/15411

ROM_ORIGIN = 0x0000C000
ROM_LENGTH = 960K
RAM_ORIGIN = 0x10000000
RAM_LENGTH = 384K

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 \
  -include $(_THIS_DIR)/apollo3.h \

FLASH_CMD = \
    JLinkGDBServerCLExe -USB -device ama3b1kk-kcr -endian little -if SWD \
    -speed auto -noir -LocalhostOnly -port 3333
GDB_RELOAD_CMD = jlink-reload
