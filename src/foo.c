
struct foo_variable {
  int value;
} foo_variable = {
    .1234,
};

// define a small foo function too
void foo(void) { foo_variable.value++; }
