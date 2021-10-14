#pragma once

//! Fan out to the correct cmsis header based on built-in compilation flags

#include "CMSIS_5/CMSIS/Core/Include/cmsis_compiler.h"


/* -------------------------  Interrupt Number Definition  ------------------------ */

typedef enum IRQn
{
/* -------------------  Processor Exceptions Numbers  ----------------------------- */
  NonMaskableInt_IRQn           = -14,     /*  2 Non Maskable Interrupt */
  HardFault_IRQn                = -13,     /*  3 HardFault Interrupt */
  MemoryManagement_IRQn         = -12,     /*  4 Memory Management Interrupt */
  BusFault_IRQn                 = -11,     /*  5 Bus Fault Interrupt */
  UsageFault_IRQn               = -10,     /*  6 Usage Fault Interrupt */
  SecureFault_IRQn              =  -9,     /*  7 Secure Fault Interrupt */
  SVCall_IRQn                   =  -5,     /* 11 SV Call Interrupt */
  DebugMonitor_IRQn             =  -4,     /* 12 Debug Monitor Interrupt */
  PendSV_IRQn                   =  -2,     /* 14 Pend SV Interrupt */
  SysTick_IRQn                  =  -1,     /* 15 System Tick Interrupt */

/* -------------------  Processor Interrupt Numbers  ------------------------------ */
  Interrupt0_IRQn               =   0,
  Interrupt1_IRQn               =   1,
  Interrupt2_IRQn               =   2,
  Interrupt3_IRQn               =   3,
  Interrupt4_IRQn               =   4,
  Interrupt5_IRQn               =   5,
  Interrupt6_IRQn               =   6,
  Interrupt7_IRQn               =   7,
  Interrupt8_IRQn               =   8,
  Interrupt9_IRQn               =   9
  /* Interrupts 10 .. 480 are left out */
} IRQn_Type;

#define __CHECK_DEVICE_DEFINES 1

#if (__ARM_ARCH == 6)
// Can't distinguish M0/M0+, pick least variant
#include "CMSIS_5/CMSIS/Core/Include/core_cm0.h"
// #include "CMSIS_5/CMSIS/Core/Include/core_cm0plus.h"

#elif defined(__ARM_ARCH_7M__)
#include "CMSIS_5/CMSIS/Core/Include/core_cm3.h"

#elif defined(__ARM_ARCH_7EM__)
#include "CMSIS_5/CMSIS/Core/Include/core_cm4.h"

// Alas, no compiler flags to distinguish M4 from M7
// #elif xx
// #include "CMSIS_5/CMSIS/Core/Include/core_cm7.h"

#elif defined(__ARM_ARCH_8M_BASE__)
#include "CMSIS_5/CMSIS/Core/Include/core_cm23.h"

#elif defined(__ARM_ARCH_ISA_THUMB)
#include "CMSIS_5/CMSIS/Core/Include/core_cm33.h"

// Alas, no compiler flags to distinguish M33 from M35p
// #elif xx
// #include "CMSIS_5/CMSIS/Core/Include/core_cm35p.h"

// Bit of a hack to rely on this...
#elif defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_1)
#include "CMSIS_5/CMSIS/Core/Include/core_cm55.h"

#else
#error "Unknown Cortex-M variant!"
#endif
