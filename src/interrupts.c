//! This file contains interrupt definitions:
//! - vector table
//! - interrupt service routines
//! - reset handler (system init)
#include <stdint.h>

#if ENABLE_MEMFAULT
#include "memfault/components.h"
#endif

extern int main(void);

// Following symbols are defined by the linker.
// Start address for the initialization values of the .data section.
extern uint32_t _data_loadaddr;
// Start address for the .data section
extern uint32_t _data;
// End address for the .data section
extern uint32_t _edata;
// Start address for the .bss section
extern uint32_t _bss;
// End address for the .bss section
extern uint32_t _ebss;
// End address for stack
extern uint32_t _stack;

// Prevent inlining to avoid persisting any stack allocations
__attribute__((noinline)) static void prv_cinit(void) {
  // Initialize data and bss
  // Copy the data segment initializers from flash to SRAM
  for (uint32_t *dst = &_data, *src = &_data_loadaddr; dst < &_edata;) {
    *(dst++) = *(src++);
  }

  // Zero fill the bss segment.
  for (uint32_t *dst = &_bss; (uintptr_t)dst < (uintptr_t)&_ebss;) {
    *(dst++) = 0;
  }
}

__attribute__((noreturn)) void Reset_Handler(void) {
  // __ARM_FP is defined by the compiler if -mfloat-abi=hard is set
#if defined(__ARM_FP)
  // enable floating-point access; some instructions emitted at -O3 will make
  // use of the FP co-processor, eg vldr.64
#define CPACR (*(volatile uint32_t *)0xE000ED88)
  CPACR |= ((3UL << 10 * 2) | /* set CP10 Full Access */
            (3UL << 11 * 2)); /* set CP11 Full Access */
#endif

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

__attribute__((weak)) void NMI_Handler(void) { Default_Handler(); }
__attribute__((weak)) void HardFault_Handler(void) {
  __asm__("bkpt 92");
  NVIC_SystemReset();
}

// A minimal vector table for a Cortex M. Uncomment/add additional vectors if
// needed.
__attribute__((section(".vectors"))) void (*const vector_table[])(void) = {
    (void *)(&_stack), // initial stack pointer
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
    // PendSV_Handler,
    // SysTick_Handler,
};
