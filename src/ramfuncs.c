//! random functions to execute from ram

#include "ramfuncs.h"

#include "memfault/components.h"

int ramfunc_run(int a, int b) {
  MEMFAULT_ASSERT(a < b);

  return a - b;
}
