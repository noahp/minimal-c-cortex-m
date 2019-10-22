OUTPUT_FORMAT ("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
SEARCH_DIR(.)

/*************************************************************************************
 * Memory layout for STM32 linking
 *
 * Defines where to access the flash and sram for linking purposes. Here's the overall
 * layout (from https://github.com/trebisky/stm32f103/blob/master/blink1/blink.lds).
 *
 * 0x00000000 - 0x07ffffff - aliased to flash or sys memory depending on BOOT jumpers.
 * 0x08000000 - 0x0800ffff - Flash.
 * 0x1ffff000 - 0x1ffff7ff - Boot firmware in system memory.
 * 0x1ffff800 - 0x1fffffff - Option bytes.
 * 0x20000000 - 0x20004fff - SRAM.
 * 0x40000000 - 0x40023400 - Peripherals
 */

MEMORY
{
  FLASH (rx)      : ORIGIN = 0x08000000, LENGTH = 1024K
  RAM (xrw)       : ORIGIN = 0x20000000, LENGTH = 192K
}

STACK_SIZE = 0x100;

_estack = 0x20020000;    /* end of 128K RAM on AHB bus*/

/* Section Definitions */
SECTIONS
{
    .interrupts :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector .isr_vector.*))
        . = ALIGN(4);
    } > FLASH

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

    .heap (COPY):
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
