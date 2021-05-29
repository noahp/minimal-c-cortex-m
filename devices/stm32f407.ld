ENTRY(ResetHandler)

OUTPUT_FORMAT ("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
SEARCH_DIR(.)

/* STM32F407 memory regions as follows:

0x2001 C000 - 0x2001 FFFF SRAM2 (16 KB)
0x2000 0000 - 0x2001 BFFF SRAM1 (112 KB)
0x1FFF 0000 - 0x1FFF 77FF System memory System memory System memory System memory
0x0810 0000 - 0x0FFF FFFF Reserved Reserved Reserved Reserved
0x0800 0000 - 0x080F FFFF Flash memory Flash memory Flash memory Flash memory
*/

/* cortex-m4 supports up to 240 external interrupts plus 16 built in; see:
 * https://developer.arm.com/ip-products/processors/cortex-m
 * this could be sized down if there's fewer ISR's used by the app */
interrupt_region_size = (16 + 240) * 4;
flash_origin = 0x08000000;

MEMORY
{
  /* Note that we'd normally use ORIGIN(INTERRUPTS) and LENGTH(INTERRUPTS),
    but this bug prevents it on some compiler releases (ex 8-2019-q3-update):
    https://sourceware.org/bugzilla/show_bug.cgi?id=24289

    So use a variable instead */

  INTERRUPTS (rx) : ORIGIN = 0x08000000 /*flash_origin*/, LENGTH = (16 + 240) * 4 /*interrupt_region_size*/
  FLASH (rx)      :
      ORIGIN = ORIGIN(INTERRUPTS) + LENGTH(INTERRUPTS),
      LENGTH = 1024K - LENGTH(INTERRUPTS)
  RAM (xrw)       : ORIGIN = 0x20000000, LENGTH = 112K
}

STACK_SIZE = 0x100;

_estack = ORIGIN(RAM) + LENGTH(RAM);

/* Section Definitions */
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
