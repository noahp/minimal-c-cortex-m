# minimal-c-cortex-m

A minimal Arm Cortex-M example, including semihosting, for my own reference.
*not really recommended for anything beyond toy usage*

```bash
# necessary tools
❯ sudo apt install openocd gcc-arm-none-eabi

# start openocd in one terminal
❯ make openocd

# build default config (stm32f4discovery) and start gdb in another terminal
❯ make gdb

# 'continue' in gdb, you should see 'Hello there!' in openocd
```

For RTT, run this in another terminal:

```bash
# keep retrying until connection is made. also reopen on aborted connection
# on normal exit (eg ctrl+] then ctrl+d), will terminate the loop
❯ until telnet localhost 9090; do sleep 0.5; done
```

## stm32f407 discovery

For pyocd (TODO why does this not really erase/write flash successfully?)

```bash
# install st-link stuff
❯ sudo apt install stlink-tools

# install pyocd
❯ pip install pyocd

# plug in board and

❯ pyocd list
  #   Probe                           Unique ID
----------------------------------------------------------------
  0   NUCLEO-L073RZ [stm32l073rztx]   blahblah
```
