ROM_ORIGIN = 0x00000000
ROM_LENGTH = 0x00004000
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 0x00001000

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \

ARCHFLAGS += \
  -mcpu=cortex-m0plus \
  -include $(_THIS_DIR)/samd11c14a.h \
