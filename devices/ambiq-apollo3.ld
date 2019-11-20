/*
 * Taken from AmbiqSuite SDK Version 2.30 downloaded from here:
 * https://ambiqmicro.com/mcu/
 *
 * Based on the boards/apollo3_evb/examples/while/gcc/while.ld example.
 */


/******************************************************************************
 *
 * while.ld - Linker script for applications using startup_gnu.c
 *
 *****************************************************************************/

/* cortex-m4 supports up to 240 external interrupts plus 16 built in; see:
 * https://developer.arm.com/ip-products/processors/cortex-m
 * this could be sized down if there's fewer ISR's used by the app */
interrupt_region_size = (16 + 240) * 4;
flash_origin = 0x0000C000;

MEMORY
{
  /* cortex-m4 supports up to 240 external interrupts plus 16 built in; see:
   * https://developer.arm.com/ip-products/processors/cortex-m
   * this could be sized down if there's fewer ISR's used by the app */
  INTERRUPTS (rx) : ORIGIN = flash_origin, LENGTH = interrupt_region_size
  FLASH (rx)      :
      ORIGIN = flash_origin + interrupt_region_size,
      LENGTH = 960K - interrupt_region_size
  RAM (xrw)       : ORIGIN = 0x10000000, LENGTH = 384K
}

STACK_SIZE = 0x100;

SECTIONS
{
    .interrupts :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector .isr_vector.*))
        . = ALIGN(4);
    } > INTERRUPTS

    .text :
    {
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
    } > FLASH

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > FLASH

    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > FLASH

    . = ALIGN(4);
    _etext = .;
    _sidata = .;

    .data : AT (_etext)
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        . = ALIGN(4);
        _edata = . ;
    } > RAM

    /* .bss section which is used for uninitialized data */
    .bss (NOLOAD) :
    {
        _sbss = . ;
        __bss_start__ = _sbss;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
        __bss_end__ = _ebss;
    } > RAM

    .heap (NOLOAD):
    {
        . = ALIGN(4);
        PROVIDE ( end = . );
        PROVIDE ( _end = . );
        PROVIDE ( __end__ = . );

        *(.heap*)
        __HeapLimit = .;
        . = ALIGN(4);
    } > RAM

    /* stack section */
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        _sstack = .;
        . = . + STACK_SIZE;
        . = ALIGN(8);
        _estack = .;
    } > RAM

    . = ALIGN(4);
    _end = . ;
}
