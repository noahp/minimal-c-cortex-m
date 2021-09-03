//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See License.txt for details
//!
//! Glue layer between the Memfault SDK and the underlying platform
//!
//! TODO: Fill in FIXMEs below for your platform

#include "memfault/components.h"
#include "memfault/ports/reboot_reason.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "third-party/stm32f407xx.h"

static char device_serial[96 / 8 * 2 + sizeof("-noahp")] = {0};

static void prv_init_device_serial(void) {
  uint8_t uid[96 / 8] = {0};
  memcpy(&uid, (uint8_t *)UID_BASE, sizeof(uid));

  char uid_str[sizeof(uid) * 2 + 1];
  for (size_t i = 0; i < sizeof(uid); i++) {
    snprintf(uid_str + 2 * i, 3, "%02x", uid[i]);
  }

  snprintf(device_serial, sizeof(device_serial), "%s-noahp", uid_str);
}

void memfault_platform_get_device_info(sMemfaultDeviceInfo *info) {
  // IMPORTANT: All strings returned in info must be constant
  // or static as they will be used _after_ the function returns

  // See https://mflt.io/version-nomenclature for more context
  *info = (sMemfaultDeviceInfo){
      // An ID that uniquely identifies the device in your fleet
      // (i.e serial number, mac addr, chip id, etc)
      // Regular expression defining valid device serials: ^[-a-zA-Z0-9_]+$
      .device_serial = device_serial,
      // A name to represent the firmware running on the MCU.
      // (i.e "ble-fw", "main-fw", or a codename for your project)
      .software_type = "app-fw",
      // The version of the "software_type" currently running.
      // "software_type" + "software_version" must uniquely represent
      // a single binary
      .software_version = "1.0.0",
      // The revision of hardware for the device. This value must remain
      // the same for a unique device.
      // (i.e evt, dvt, pvt, or rev1, rev2, etc)
      // Regular expression defining valid hardware versions:
      // ^[-a-zA-Z0-9_\.\+]+$
      .hardware_version = "dvt1",
  };
}

//! Last function called after a coredump is saved. Should perform
//! any final cleanup and then reset the device
void memfault_platform_reboot(void) {
  // !FIXME: Perform any final system cleanup here

  __asm__("bkpt 99");
  NVIC_SystemReset();
  while (1) {
  } // unreachable
}

bool memfault_platform_time_get_current(sMemfaultCurrentTime *time) {
  // !FIXME: If the device tracks real time, update 'unix_timestamp_secs' with
  // seconds since epoch This will cause events logged by the SDK to be
  // timestamped on the device rather than when they arrive on the server
  *time = (sMemfaultCurrentTime){
      .type = kMemfaultCurrentTimeType_UnixEpochTimeSec,
      .info = {.unix_timestamp_secs = 0},
  };

  // !FIXME: If device does not track time, return false, else return true if
  // time is valid
  return false;
}

extern uint32_t _data;
extern uint32_t _ebss;
extern uint32_t _stack;


size_t memfault_platform_sanitize_address_range(void *start_addr,
                                                size_t desired_size) {
  struct {
    uint32_t start_addr;
    size_t length;
  } s_mcu_mem_regions[] = {
      // !FIXME: Update with list of valid memory banks to collect in a coredump
      // {.start_addr = (uint32_t)&_data,
      //  .length = (uint32_t)&_stack - (uint32_t)&_data},
      {.start_addr = 0x00000000, .length = 0xFFFFFFFF},
  };

  for (size_t i = 0; i < MEMFAULT_ARRAY_SIZE(s_mcu_mem_regions); i++) {
    const uint32_t lower_addr = s_mcu_mem_regions[i].start_addr;
    const uint32_t upper_addr = lower_addr + s_mcu_mem_regions[i].length;
    if ((uint32_t)start_addr >= lower_addr &&
        ((uint32_t)start_addr < upper_addr)) {
      return MEMFAULT_MIN(desired_size, upper_addr - (uint32_t)start_addr);
    }
  }

  return 0;
}

const sMfltCoredumpRegion *
memfault_platform_coredump_get_regions(const sCoredumpCrashInfo *crash_info,
                                       size_t *num_regions) {
  static sMfltCoredumpRegion s_coredump_regions[2];
  const size_t stack_size =
      (uintptr_t)&_stack - (uintptr_t)crash_info->stack_address;

  // all of stack
  s_coredump_regions[0] = MEMFAULT_COREDUMP_MEMORY_REGION_INIT(
      crash_info->stack_address, stack_size);

  // all of data
  s_coredump_regions[1] = MEMFAULT_COREDUMP_MEMORY_REGION_INIT(
      &_data, (uint32_t)((uintptr_t)&_ebss - (uintptr_t)&_data));

  *num_regions = MEMFAULT_ARRAY_SIZE(s_coredump_regions);
  return &s_coredump_regions[0];
}

// static RAM storage where logs will be stored. Storage can be any size
// you want but you will want it to be able to hold at least a couple logs.
static uint8_t s_log_buf_storage[512];

//! !FIXME: This function _must_ be called by your main() routine prior
//! to starting an RTOS or baremetal loop.
int memfault_platform_boot(void) {
  // !FIXME: Add init to any platform specific ports here.
  // (This will be done in later steps in the getting started Guide)

  prv_init_device_serial();

  memfault_build_info_dump();
  memfault_platform_reboot_tracking_boot();
  memfault_log_boot(s_log_buf_storage, sizeof(s_log_buf_storage));

  static uint8_t s_event_storage[1024];
  const sMemfaultEventStorageImpl *evt_storage =
      memfault_events_storage_boot(s_event_storage, sizeof(s_event_storage));
  memfault_trace_event_boot(evt_storage);

  memfault_reboot_tracking_collect_reset_info(evt_storage);

  sMemfaultMetricBootInfo boot_info = {
      .unexpected_reboot_count = memfault_reboot_tracking_get_crash_count(),
  };
  memfault_metrics_boot(evt_storage, &boot_info);

  memfault_device_info_dump();
  MEMFAULT_LOG_INFO("Memfault Initialized!");

  return 0;
}

void memfault_platform_log(eMemfaultPlatformLogLevel level, const char *fmt,
                           ...) {
  va_list args;
  va_start(args, fmt);

  char log_buf[128];
  vsnprintf(log_buf, sizeof(log_buf), fmt, args);

  const char *lvl_str;
  switch (level) {
  case kMemfaultPlatformLogLevel_Debug:
    lvl_str = "D";
    break;

  case kMemfaultPlatformLogLevel_Info:
    lvl_str = "I";
    break;

  case kMemfaultPlatformLogLevel_Warning:
    lvl_str = "W";
    break;

  case kMemfaultPlatformLogLevel_Error:
    lvl_str = "E";
    break;

  default:
    return;
    break;
  }

  vsnprintf(log_buf, sizeof(log_buf), fmt, args);

  printf("[%s] MFLT: %s\n", lvl_str, log_buf);

  va_end(args);
}

bool memfault_platform_metrics_timer_boot(
    uint32_t period_sec, MemfaultPlatformTimerCallback callback) {
  (void)period_sec, (void)callback;
  // Schedule a timer to invoke callback() repeatedly after period_sec
  return true;
}

uint64_t memfault_platform_get_time_since_boot_ms(void) {
  // Return time since boot in ms, this is used for relative timings.
  return 0;
}

MEMFAULT_PUT_IN_SECTION(".noinit.mflt_reboot_tracking")
static uint8_t s_reboot_tracking[MEMFAULT_REBOOT_TRACKING_REGION_SIZE];

void memfault_platform_reboot_tracking_boot(void) {
  sResetBootupInfo reset_info = {0};
  memfault_reboot_reason_get(&reset_info);
  memfault_reboot_tracking_boot(s_reboot_tracking, &reset_info);
}

void memfault_reboot_reason_get(sResetBootupInfo *info) {
  const uint32_t reset_cause = 0; // TODO: Populate with MCU reset reason
  eMemfaultRebootReason reset_reason = kMfltRebootReason_Unknown;

  // TODO: Convert MCU specific reboot reason to memfault enum

  *info = (sResetBootupInfo){
      .reset_reason_reg = reset_cause,
      .reset_reason = reset_reason,
  };
}

void user_transport_send_chunk_data(void *chunk_data, size_t chunk_data_len) {
  (void)chunk_data, (void)chunk_data_len;
  // printf("%.*s\n", chunk_data_len, (char *)chunk_data);
}
