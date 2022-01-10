ROM_ORIGIN = 0x08000000
ROM_LENGTH = 2048K
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 512K

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m7 \
  -mfloat-abi=hard \
  -mfpu=fpv5-d16 \
  -include $(_THIS_DIR)/stm32f756xx.h

# DEBUG_CMD = pyocd gdbserver
# GDB_RELOAD_CMD = pyocd-reload
DEBUG_CMD = openocd -f $(_THIS_DIR)/stm32f7.openocd.cfg
GDB_RELOAD_CMD = openocd-reload
