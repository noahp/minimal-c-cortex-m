
# .gdb-startup assumes the elf is here
BUILDDIR = build
TARGET = $(BUILDDIR)/main.elf

BOARD ?= stm32f4discovery

ENABLE_SEMIHOSTING ?= 1

# TODO cleaner board mux

ifeq (apollo3_sparkfun,$(BOARD))
# Sparkfun Artemis Black board for Ambiq Apollo 3
# https://www.sparkfun.com/products/retired/15411
LDSCRIPT = devices/ambiq-apollo3.ld
ARCHFLAGS += -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
FLASH_CMD = \
    JLinkGDBServerCLExe -USB -device ama3b1kk-kcr -endian little -if SWD \
    -speed auto -noir -LocalhostOnly -port 3333
GDB_RELOAD_CMD = jlink-reload
endif

ifeq (stm32f4discovery,$(BOARD))
LDSCRIPT = devices/stm32f407.ld
ARCHFLAGS += -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
FLASH_CMD = openocd -f devices/stm32f4.openocd.cfg
GDB_RELOAD_CMD = openocd-reload
endif

ifeq (kl02,$(BOARD))
LDSCRIPT = devices/kl02.ld
ARCHFLAGS += -mcpu=cortex-m0plus
FLASH_CMD = @ echo $(BOARD) flashing/debug not currently supported
GDB_RELOAD_CMD = jlink-reload
endif

ifeq (samd11,$(BOARD))
LDSCRIPT = devices/samd11d14am_flash.ld
ARCHFLAGS += -mcpu=cortex-m0plus
endif

CFLAGS += $(ARCHFLAGS)

CFLAGS += -ffunction-sections -fdata-sections

CFLAGS += -ggdb3

CFLAGS += -Wall -Werror

CFLAGS += -mlittle-endian -mthumb -mthumb-interwork

LDFLAGS += -T$(LDSCRIPT)

ifeq (1,$(ENABLE_SEMIHOSTING))
LDFLAGS += --specs=rdimon.specs -lc -lrdimon
CFLAGS += -DENABLE_SEMIHOSTING=1
else
LDFLAGS += --specs=nano.specs
CFLAGS += -DENABLE_SEMIHOSTING=0
endif

LDFLAGS += -Wl,--gc-sections,-Map,$(TARGET).map,--print-memory-usage

CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
SIZE = arm-none-eabi-size
RM = rm -rf

SRCS = \
    main.c \
    interrupts.c \

OBJS = $(patsubst %.c, %.o, $(SRCS))
OBJS := $(addprefix $(BUILDDIR)/,$(OBJS))

# VPATH = ./

all: $(TARGET)

$(BUILDDIR):
	mkdir -p $@

clean:
	$(RM) $(BUILDDIR)

$(BUILDDIR)/%.o: %.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $^ -o $@

$(TARGET): $(OBJS) $(LDSCRIPT)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
	$(SIZE) $(TARGET)

flash: $(TARGET)
	$(FLASH_CMD)

gdb: $(TARGET)
	arm-none-eabi-gdb-py $(TARGET) -ex "source .gdb-startup" -ex $(GDB_RELOAD_CMD)

.PHONY: all clean flash gdb
