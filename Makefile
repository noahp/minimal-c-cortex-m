# disable echoing rule commands, run make with --trace to see them
.SILENT:

ARM_CC ?= arm-none-eabi-gcc
# if cc isn't set by the user, set it to ARM_CC
ifeq ($(origin CC),default)
CC := $(ARM_CC)
endif

# use ccache if available
CCACHE := $(shell command -v ccache 2> /dev/null)
ifdef CCACHE
CC := ccache $(CC)
endif

SIZE = arm-none-eabi-size
RM = rm -rf

# .gdb-startup assumes the elf is here
BUILDDIR = build
TARGET = $(BUILDDIR)/main.elf

DEVICE ?= stm32f4discovery
CFLAGS += \
  -DBOARD_$(DEVICE) \
  -DBOARD_NAME=\"$(DEVICE)\"

# set C preprocessor tokens of 0 or 1 for each flag
FLAGS = \
  ENABLE_STDIO \
  ENABLE_SEMIHOSTING \
  ENABLE_RTT \
  ENABLE_MEMFAULT \
  ENABLE_MEMFAULT_METRICS \
  ENABLE_MEMFAULT_DEMO

CFLAGS += $(foreach flag,$(FLAGS),-D$(flag)=$(or $(findstring 1,$($(flag))),0))

# Bring in any device-specific settings
include devices/$(DEVICE)/device.mk

DEFAULT_LINKER_SCRIPT = devices/cortex-m-generic.ld
LINKER_SCRIPT ?= $(DEFAULT_LINKER_SCRIPT)

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

# this is pretty fragile
ARCHFLAGS_ := $(patsubst -mcpu=cortex-%,-mcpu=cortex_%,$(ARCHFLAGS))

CFLAGS += \
  --sysroot=$(ARM_CORTEXM_SYSROOT) \
  -I$(ARM_CORTEXM_SYSROOT)/include \


  # --target=arm-none-eabi

LDFLAGS += \
  -L$(ARM_CORTEXM_SYSROOT)/lib/$(ARM_CORTEXM_MULTI_DIR)
endif

CFLAGS += \
  $(ARCHFLAGS_) \
  -Os -ggdb3 -std=gnu11 \
  -fdebug-prefix-map=$(abspath .)=. \
  -I. \
  -ffunction-sections -fdata-sections \

CFLAGS += \
  -Werror \
  -Wall \
  -Wextra \
  -Wno-error=undef \
  -Wno-error=unused-command-line-argument \

CFLAGS += $(CFLAGS_WARNINGS)

ifeq ($(ENABLE_MEMFAULT),1)
include Makefile-memfault.mk

# LDFLAGS += -Wl,--wrap=malloc,--wrap=free

endif

INCLUDES += \
  third-party/CMSIS_5/CMSIS/Core/Include \

CFLAGS += $(addprefix -I,$(INCLUDES))

LDFLAGS += -nostdlib

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

# Specifiy --buil-id=sha1 - the default when using lld is 'fast', which is not
# compatible with the default ld uses, 'sha1', so explicitly set it!
# LDFLAGS += -Wl,--gc-sections,-Map,$(TARGET).map,--build-id=sha1
LDFLAGS += -Wl,--gc-sections,--build-id=sha1

ifeq ($(USING_CLANG),)
# print memory usage if linking with gnu ld
LDFLAGS += -Wl,--print-memory-usage
# additional gcc-specific flags, used for computing stack usage
CFLAGS += -fstack-usage

# these can be used with the program below to compute call stack usage
# https://github.com/sharkfox/stack-usage
# ccache doesn't support them, so disabled
# CFLAGS += -fdump-rtl-dfinish -fdump-ipa-cgraph
endif

SRCS += \
    src/main.c \
    src/interrupts.c \

ifneq (,$(ENABLE_RTT))
# disable asm for simplicity
CFLAGS += \
  -DRTT_USE_ASM=0 \
  -DSEGGER_RTT_MODE_DEFAULT=SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL \
  -I third-party/segger-rtt/RTT

SRCS += \
  third-party/segger-rtt/RTT/SEGGER_RTT_printf.c \
  third-party/segger-rtt/RTT/SEGGER_RTT.c \
  third-party/segger-rtt/Syscalls/SEGGER_RTT_Syscalls_GCC.c \

endif

all: $(TARGET)

OBJS = $(patsubst %.c, %.o, $(SRCS))
OBJS := $(addprefix $(BUILDDIR)/,$(OBJS))

# depfiles for tracking include changes
DEPFILES = $(OBJS:%.o=%.o.d)
DEPFLAGS = -MT $@ -MMD -MP -MF $@.d
-include $(DEPFILES)

$(BUILDDIR):
	mkdir -p $@

clean:
	$(RM) $(BUILDDIR)

# If CFLAGS differ from last build, rebuild all files
RAW_CFLAGS := $(CFLAGS) $(LDFLAGS)
CFLAGS_STALE = \
  $(shell \
    if ! (echo "$(RAW_CFLAGS)" | diff -q $(BUILDDIR)/cflags - > /dev/null 2>&1); then \
      echo CFLAGS_STALE; \
    fi \
   )
.PHONY: CFLAGS_STALE
$(BUILDDIR)/cflags: $(CFLAGS_STALE)
	mkdir -p $(dir $@)
	echo "$(RAW_CFLAGS)" > $@

$(BUILDDIR)/%.o: %.c $(BUILDDIR)/cflags
	mkdir -p $(dir $@)
	$(info Compiling $<)
	$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

LINKER_SCRIPT := $(DEFAULT_LINKER_SCRIPT)

ifeq ($(LINKER_SCRIPT),$(DEFAULT_LINKER_SCRIPT))
# Populate ROM + RAM region values as linker args from device.mk
LD_TEMPLATE_VARS := ROM_ORIGIN ROM_LENGTH RAM_ORIGIN RAM_LENGTH
# LD_TEMPLATE_LDFLAGS = \
#   $(foreach t_,$(LD_TEMPLATE_VARS),-Wl,--defsym=$(t_)=$($(t_)))
# LDFLAGS += $(LD_TEMPLATE_LDFLAGS)

LD_TEMPLATE_CFLAGS = \
   $(foreach t_,$(LD_TEMPLATE_VARS),-D$(t_)=$($(t_)))

endif

$(BUILDDIR)/link.ld: devices/cortex-m-generic.ld.template
	$(info Generating linker script $@)
	mkdir -p $(dir $@)
	gcc $(LD_TEMPLATE_CFLAGS) -E -nostdinc -P -C -x c -o $@ $<

$(TARGET): $(LINKER_SCRIPT) $(OBJS)
	$(info Linking $@)
	$(CC) $(CFLAGS) -T$^ $(LDFLAGS) -o $@
	$(SIZE) $(TARGET)

debug: $(TARGET)
	$(DEBUG_CMD)

gdb: $(TARGET)
	arm-none-eabi-gdb-py $(TARGET) -ex "source .gdb-startup" -ex $(GDB_RELOAD_CMD)

.PHONY: all clean debug gdb
