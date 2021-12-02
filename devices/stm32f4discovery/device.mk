ROM_ORIGIN = 0x08000000
ROM_LENGTH = 128K
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 112K

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m4 \
  -mfloat-abi=hard \
  -mfpu=fpv4-sp-d16 \
  -include $(_THIS_DIR)/stm32f407xx.h

# DEBUG_CMD = pyocd gdbserver
# GDB_RELOAD_CMD = pyocd-reload
DEBUG_CMD = openocd -f $(_THIS_DIR)/stm32f4.openocd.cfg
GDB_RELOAD_CMD = openocd-reload
