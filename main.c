#include <stdio.h>

#include <ctype.h>
#include <getopt.h>

extern void initialise_monitor_handles(void);


void _sbrk(void) {}
void _write(void) {}
void _close(void) {}
void _fstat(void) {}
void _isatty(void) {}
void _lseek(void) {}
void _read(void) {}

int cmdline(int argc, char **argv) {
  int aflag = 0;
  int bflag = 0;
  char *cvalue = NULL;
  int index;
  int c;

  opterr = 0;

  while ((c = getopt (argc, argv, "abc:")) != -1)
    switch (c)
      {
      case 'a':
        aflag = 1;
        break;
      case 'b':
        bflag = 1;
        break;
      case 'c':
        cvalue = optarg;
        break;
      case '?':
        // if (optopt == 'c')
        //   fprintf (stderr, "Option -%c requires an argument.\n", optopt);
        // else if (isprint (optopt))
        //   fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        // else
        //   fprintf (stderr,
        //            "Unknown option character `\\x%x'.\n",
        //            optopt);
        return 1;
      default:
        return -1;
      }

  printf ("aflag = %d, bflag = %d, cvalue = %s\n",
          aflag, bflag, cvalue);

  for (index = optind; index < argc; index++)
    printf ("Non-option argument %s\n", argv[index]);
  return 0;
}

int main(void) {
#if ENABLE_SEMIHOSTING
  initialise_monitor_handles();

  // don't buffer on stdout
  setbuf(stdout, NULL);


#endif
  printf("🦄 Hello there!\n");


  char *argv[] = {
    "cmdline",
    "-a",
  };
  (void)cmdline(2, argv);
  while (1) {
  };

  return 0;
}
