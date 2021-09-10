MEMORY
{
  rom (rx) : ORIGIN = 0x08000000, LENGTH = 128K
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 112K
}

SEARCH_DIR(.)
INCLUDE cortex-m-generic.ld
