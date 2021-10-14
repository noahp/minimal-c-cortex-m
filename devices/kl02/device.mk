
# Select a manual linker script, this part is complex enough
_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
LINKER_SCRIPT := $(_THIS_DIR)/kl02.ld

LDSCRIPT = devices/kl02.ld
ARCHFLAGS += -mcpu=cortex-m0plus
FLASH_CMD = @ echo $(DEVICE) flashing/debug not currently supported
GDB_RELOAD_CMD = jlink-reload
