
ARM_CC ?= arm-none-eabi-gcc
# if cc isn't set by the user, set it to ARM_CC
ifeq ($(origin CC),default)
CC = $(ARM_CC)
endif
SIZE = arm-none-eabi-size
RM = rm -rf

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

ARCHFLAGS += -mlittle-endian -mthumb

# this should be before libraries it depends on, eg libgcc and libnosys
# manually specify libgcc_nano, only gcc has the magic .specs aliasing logic
LDFLAGS += -lc_nano

# clang support
CC_VERSION_INFO := $(shell $(CC) --version)

ifneq '' '$(findstring clang,$(CC_VERSION_INFO))'
USING_CLANG = yes

ARM_CORTEXM_SYSROOT := \
  $(shell $(ARM_CC) $(ARCHFLAGS) -print-sysroot 2>&1)

# The directory where Newlib's libc.a & libm.a reside
# for the specific target architecture
ARM_CORTEXM_MULTI_DIR := \
  $(shell $(ARM_CC) $(ARCHFLAGS) -print-multi-directory 2>&1)

CFLAGS += \
  --sysroot=$(ARM_CORTEXM_SYSROOT) \
  --target=arm-none-eabi

LDFLAGS += \
  -L$(ARM_CORTEXM_SYSROOT)/lib/$(ARM_CORTEXM_MULTI_DIR)
endif

CFLAGS += $(ARCHFLAGS)

CFLAGS += -ggdb3

CFLAGS += -Wall -Werror

CFLAGS += -fdebug-prefix-map=$(abspath .)=.
LDFLAGS += -nostdlib

# Set this c define to 1 if ENABLE_SEMIHOSTING=1 or 0 otherwise
CFLAGS += -DENABLE_SEMIHOSTING=$(or $(findstring 1,$(ENABLE_SEMIHOSTING)),0)

ifeq (1,$(ENABLE_SEMIHOSTING))
# add rdimon specs, and include stdlib when linking
ifeq ($(USING_CLANG),)
LDFLAGS += \
  --specs=rdimon.specs
endif
LDFLAGS += -lrdimon_nano
else
# omit stdlib, but add libnosys and libgcc manually instead of providing a local
# port, so stdlib functions are available. this makes it easy to use clang too.
ifeq ($(USING_CLANG),)
LDFLAGS += \
  --specs=nano.specs --specs=nosys.specs
endif
endif

LDFLAGS += \
  -lg_nano -lnosys \
  $(shell $(ARM_CC) $(ARCHFLAGS) -print-libgcc-file-name 2>&1)

# LDFLAGS += -Wl,-T$(LDSCRIPT)
LDFLAGS += -Wl,--gc-sections,-Map,$(TARGET).map

# print memory usage if linking with gnu ld
ifeq ($(USING_CLANG),)
LDFLAGS += -Wl,--print-memory-usage
endif

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

$(TARGET): $(LDSCRIPT) $(OBJS)
	$(CC) $(CFLAGS) -T$^ $(LDFLAGS) -o $@
	$(SIZE) $(TARGET)

flash: $(TARGET)
	$(FLASH_CMD)

gdb: $(TARGET)
	arm-none-eabi-gdb-py $(TARGET) -ex "source .gdb-startup" -ex $(GDB_RELOAD_CMD)

.PHONY: all clean flash gdb
