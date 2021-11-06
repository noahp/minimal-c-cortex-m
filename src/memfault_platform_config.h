#pragma once

//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See License.txt for details
//!
//! Platform overrides for the default configuration settings in the
//! memfault-firmware-sdk. Default configuration settings can be found in
//! "memfault/config.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MEMFAULT_USE_GNU_BUILD_ID 1

#define MEMFAULT_ASSERT_HALT_IF_DEBUGGING_ENABLED 1

#define MEMFAULT_EVENT_INCLUDE_DEVICE_SERIAL 1

// #define MEMFAULT_PLATFORM_COREDUMP_STORAGE_REGIONS_CUSTOM 1
#define MEMFAULT_PLATFORM_COREDUMP_STORAGE_RAM_SIZE 8000
#define MEMFAULT_COREDUMP_COLLECT_HEAP_STATS 1
#define MEMFAULT_COREDUMP_COLLECT_LOG_REGIONS 1

// #define MEMFAULT_COMPACT_LOG_ENABLE 1

#ifdef __cplusplus
}
#endif
