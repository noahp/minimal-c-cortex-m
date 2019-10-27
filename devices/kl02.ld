OUTPUT_FORMAT ("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
SEARCH_DIR(.)

MEMORY
{
  /* cortex-m0+ supports up to 32 external interrupts plus 16 built in; see:
   * https://developer.arm.com/ip-products/processors/cortex-m
   * this could be sized down if there's fewer ISR's used by the app */
  INTERRUPTS (rx)  : ORIGIN = 0x0,          LENGTH = (16 + 32) * 4
  /* FLASHCONFIG section is 16 bytes. contains OTP flags, watch out! */
  FLASHCONFIG(rx)  : ORIGIN = 0x400,        LENGTH = 16
  FLASH       (rx) : ORIGIN = 0x410,        LENGTH = 32K - ORIGIN(FLASH)
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
