# Add memfault sources etc

MEMFAULT_PORT_ROOT := src
MEMFAULT_SDK_ROOT := third-party/memfault-firmware-sdk

MEMFAULT_COMPONENTS := core util panics
ifeq ($(ENABLE_MEMFAULT_METRICS),1)
MEMFAULT_COMPONENTS += metrics
endif
ifeq ($(ENABLE_MEMFAULT_DEMO),1)
MEMFAULT_COMPONENTS += demo
endif
include $(MEMFAULT_SDK_ROOT)/makefiles/MemfaultWorker.mk

SRCS += \
  $(MEMFAULT_COMPONENTS_SRCS) \
  $(MEMFAULT_PORT_ROOT)/memfault_platform_port.c \
  $(MEMFAULT_SDK_ROOT)/ports/panics/src/memfault_platform_ram_backed_coredump.c \

INCLUDES += \
  $(MEMFAULT_COMPONENTS_INC_FOLDERS) \
  $(MEMFAULT_SDK_ROOT)/ports/include \
  $(MEMFAULT_PORT_ROOT)
