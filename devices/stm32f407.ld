MEMORY
{
  rom (rx) : ORIGIN = 0x08000000, LENGTH = 128K
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 112K
}

/* has to be relative to where ld is running */
INCLUDE devices/cortex-m-generic.ld
