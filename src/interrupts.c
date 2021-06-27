//! This file contains interrupt definitions:
//! - vector table
//! - interrupt service routines
//! - reset handler (system init)
#include <stdint.h>

#include "third-party/stm32f407xx.h"

extern int main(void);

// Following symbols are defined by the linker.
// Start address for the initialization values of the .data section.
extern uint32_t __etext;
// Start address for the .data section
extern uint32_t __data_start__;
// End address for the .data section
extern uint32_t __data_end__;
// Start address for the .bss section
extern uint32_t __bss_start__;
// End address for the .bss section
extern uint32_t __bss_end__;
// End address for stack
extern uint32_t __stack;

// Prevent inlining to avoid persisting any stack allocations
__attribute__((noinline)) static void prv_cinit(void) {
  // Initialize data and bss
  // Copy the data segment initializers from flash to SRAM
  for (uint32_t *dst = &__data_start__, *src = &__etext; dst < &__data_end__;) {
    *(dst++) = *(src++);
  }

  // Zero fill the bss segment.
  for (uint32_t *dst = &__bss_start__;
       (uintptr_t)dst < (uintptr_t)&__bss_end__;) {
    *(dst++) = 0;
  }
}

__attribute__((noreturn)) void Reset_Handler(void) {
  prv_cinit();

  // Call the application's entry point.
  (void)main();

  // shouldn't return
  while (1) {
  };
}

#pragma GCC optimize("Og")
// Default_Handler is used for unpopulated interrupts
static void Default_Handler(void) {
  __asm__("bkpt 91");
  // Go into an infinite loop.
  while (1) {
  };
}

static void NMI_Handler(void) { Default_Handler(); }
static void HardFault_Handler(void) {
  __asm__("bkpt 92");
  NVIC_SystemReset();
}

// A minimal vector table for a Cortex M. Uncomment/add additional vectors if
// needed.
__attribute__((section(".isr_vector"))) void (*const g_pfnVectors[])(void) = {
    (void *)(&__stack), // initial stack pointer
    Reset_Handler, NMI_Handler, HardFault_Handler,
    // MemManage_Handler,
    // BusFault_Handler,
    // UsageFault_Handler,
    // 0,
    // 0,
    // 0,
    // 0,
    // SVCall_Handler,
    // DbgMon_Handler,
    // 0,
    // SysTick_Handler,
};
