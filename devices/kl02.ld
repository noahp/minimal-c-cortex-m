OUTPUT_FORMAT ("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
SEARCH_DIR(.)

MEMORY
{
  INTERRUPTS (rx)  : ORIGIN = 0x0,          LENGTH = 192        /* 192 */
  FLASHCONFIG(rx)  : ORIGIN = 0x400,        LENGTH = 16         /* 16 bytes */
  TEXT       (rx)  : ORIGIN = 0x410,        LENGTH = 32K - 0x410
  RAM        (rwx) : ORIGIN = 0x1FFFFC00,   LENGTH = 1K
  RAM2       (rwx) : ORIGIN = 0x20000000,   LENGTH = 3K
}

STACK_SIZE = 0x100;

/* Section Definitions */
SECTIONS
{
    .interrupts :
    {
        KEEP(*(.isr_vector .isr_vector.*))
    } > INTERRUPTS

    .flashconfig :
    {
        KEEP(*(.flashconfig .flashconfig.*))
    } > FLASHCONFIG

    .text :
    {
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
    } > TEXT

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > TEXT

    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > TEXT

    . = ALIGN(4);
    _etext = .;
    _sidata = .;

    .data : AT (_etext)
    {
        _sdata = .;
        *(.data .data.*)
        . = ALIGN(4);
        _edata = . ;
    } > RAM2

    /* .bss section which is used for uninitialized data */
    .bss (NOLOAD) :
    {
        _sbss = . ;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
    } > RAM

    .heap (COPY):
    {
        __end__ = .;
        end = __end__;
        *(.heap*)
        __HeapLimit = .;
    } > RAM

    /* stack section */
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        _sstack = .;
        . = . + STACK_SIZE;
        . = ALIGN(8);
        _estack = .;
    } > RAM2

    . = ALIGN(4);
    _end = . ;
}
