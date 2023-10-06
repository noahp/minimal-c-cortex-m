ROM_ORIGIN = 0x00000000
ROM_LENGTH = 4M
RAM_ORIGIN = 0x20000000
RAM_LENGTH = 4M

_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ARCHFLAGS += \
  -mcpu=cortex-m3 \
  -mfloat-abi=soft \
  -include $(_THIS_DIR)/qemu_mps2_an385.h \
  -DSYSTEM_INIT_HANDLER=uart_init

SRCS += \
  $(_THIS_DIR)/uart.c

        # -serial stdio
DEBUG_CMD = \
    qemu-system-arm -machine mps2-an385 -monitor null -semihosting \
        --semihosting-config enable=on,target=native \
        -chardev stdio,id=con,mux=on -serial chardev:con -mon chardev=con,mode=readline \
        -nographic -gdb tcp::3333 -S \
        -kernel "$<"
GDB_RELOAD_CMD = 'print "no reload"'
