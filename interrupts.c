//! This file contains interrupt definitions:
//! - vector table
//! - interrupt service routines
//! - reset handler (system init)
#include <stdint.h>

extern int main(void);

// Following symbols are defined by the linker.
// Start address for the initialization values of the .data section.
extern uint32_t _sidata;
// Start address for the .data section
extern uint32_t _sdata;
// End address for the .data section
extern uint32_t _edata;
// Start address for the .bss section
extern uint32_t _sbss;
// End address for the .bss section
extern uint32_t _ebss;
// End address for stack
extern uint32_t _estack;

// Prevent inlining to avoid persisting any stack allocations
__attribute__((noinline)) static void prv_cinit(void) {
  // Initialize data and bss
  // Copy the data segment initializers from flash to SRAM
  for (uint32_t *dst = &_sdata, *src = &_sidata; dst < &_edata;) {
    *(dst++) = *(src++);
  }

  // Zero fill the bss segment.
  for (uint32_t *dst = &_sbss; dst < &_ebss;) {
    *(dst++) = 0;
  }
}

__attribute__((noreturn)) void ResetHandler(void) {
  prv_cinit();

  // Call the application's entry point.
  (void)main();

  // shouldn't return
  while (1) {
  };
}

// DefaultHandler is used for unpopulated interrupts
static void DefaultHandler(void) {
  __asm__("bkpt");
  // Go into an infinite loop.
  while (1) {
  };
}

static void NMIHandler(void) { DefaultHandler(); }
static void HardFaultHandler(void) { DefaultHandler(); }

// A minimal vector table for a Cortex M. Uncomment/add additional vectors if
// needed.
__attribute__((section(".isr_vector"))) void (*const g_pfnVectors[])(void) = {
    (void *)(&_estack), // initial stack pointer
    ResetHandler, NMIHandler, HardFaultHandler,
    // MemManageHandler,
    // BusFaultHandler,
    // UsageFaultHandler,
    // 0,
    // 0,
    // 0,
    // 0,
    // SVCallHandler,
    // DbgMonHandler,
    // 0,
    // SysTickHandler,
};
