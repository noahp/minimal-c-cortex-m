MEMORY
{
  rom (rx) : ORIGIN = 0x00000000, LENGTH = 0x100000
  ram (rwx) :  ORIGIN = 0x20000000, LENGTH = 0x40000
}

/* this should work but it doesn't :( */
SEARCH_DIR(.)
INCLUDE devices/cortex-m-generic.ld
