//! This file contains interrupt definitions:
//! - vector table
//! - interrupt service routines
//! - reset handler (system init)
#include <stdint.h>

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
  prv_cinit();

  // Call the application's entry point.
  (void)main();

  // shouldn't return
  while (1) {
  };
}

// Default_Handler is used for unpopulated interrupts
static void Default_Handler(void) {
  __asm__("bkpt");
  // Go into an infinite loop.
  while (1) {
  };
}

static void NMI_Handler(void) { Default_Handler(); }
static void HardFault_Handler(void) { Default_Handler(); }

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
    // SysTick_Handler,
};
