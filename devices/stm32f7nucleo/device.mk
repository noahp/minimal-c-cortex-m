ROM_ORIGIN = 0x08000000
ROM_LENGTH = 2048K
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 512K

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m7 \
  -mfloat-abi=hard \
  -mfpu=fpv5-d16 \
  -include $(_THIS_DIR)/stm32f756xx.h \
  -I$(_THIS_DIR)/HAL \
  -I$(_THIS_DIR) \
  -DSTM32F756xx=1 \

ifeq ($(ENABLE_MEMFAULT),1)
# TODO define this path elsewhere eg MEMFAULT_SDK_ROOT
SRCS += \
  third-party/memfault-firmware-sdk/ports/stm32cube/f7/rcc_reboot_tracking.c

endif

# DEBUG_CMD = pyocd gdbserver
# GDB_RELOAD_CMD = pyocd-reload
DEBUG_CMD = openocd -f $(_THIS_DIR)/stm32f7.openocd.cfg
GDB_RELOAD_CMD = openocd-reload
