
BUILDDIR ?= build
TARGET = $(BUILDDIR)/main.elf

BOARD ?= stm32f4discovery

ENABLE_SEMIHOSTING ?= 1

ifeq (stm32f4discovery,$(BOARD))
LDSCRIPT ?= ld-scripts/stm32f407.ld
ARCHFLAGS ?= -mcpu=cortex-m4
OPENOCD_CFG ?= stm32f4.openocd.cfg
endif

ifeq (kl02,$(BOARD))
# not really a thing, pass
$(error $(BOARD) not currently supported)
LDSCRIPT ?= ld-scripts/kl02.ld
ARCHFLAGS ?= -mcpu=cortex-m0plus
OPENOCD_CFG ?=
endif

CFLAGS += $(ARCHFLAGS)

CFLAGS += -ffunction-sections -fdata-sections

CFLAGS += -g3

CFLAGS += -Wall -Werror

CFLAGS += -mlittle-endian -mthumb -mthumb-interwork

ifeq (1,$(ENABLE_SEMIHOSTING))
LDFLAGS += --specs=rdimon.specs -lc -lrdimon
CFLAGS += -DENABLE_SEMIHOSTING=1
else
LDFLAGS += --specs=nano.specs
CFLAGS += -DENABLE_SEMIHOSTING=0
endif

LDFLAGS += -T$(LDSCRIPT)
LDFLAGS += -Wl,--gc-sections,-Map,$(TARGET).map

CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
SIZE = arm-none-eabi-size
RM = rm -rf

SRCS = \
    main.c \
    startup.c \

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

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
	$(SIZE) $(TARGET)

openocd: build
	openocd -f $(OPENOCD_CFG)

gdb: $(TARGET)
	arm-none-eabi-gdb-py $(TARGET) -ex "source gdb-startup"

.PHONY: all clean openocd gdb
