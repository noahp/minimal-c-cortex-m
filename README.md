# minimal-c-cortex-m

A minimal Arm Cortex-M example, including semihosting, for my own reference.
_not really recommended for anything beyond toy usage_

```bash
# necessary tools
❯ sudo apt install openocd gcc-arm-none-eabi

# start openocd in one terminal
❯ make debug

# in another terminal, run this command to build with semihosting for default
# board (stm32f4discovery), and start gdb
❯ ENABLE_STDIO=1 ENABLE_SEMIHOSTING=1 make gdb

# 'continue' in gdb, you should see 'Hello there!' in openocd
```

For RTT, run this in another terminal (and set the ENABLE_RTT=1 variable at
build):

```bash
# keep retrying until connection is made. also reopen on aborted connection
# on normal exit (eg ctrl+] then ctrl+d), will terminate the loop
❯ until telnet localhost 9090; do sleep 0.5; done
```

## QEMU for stm32f407 discovery

You can run the application in QEMU, here's what I did:

1. download this forked version of QEMU and unpack:

   ```bash
   ❯ wget https://github.com/xpack-dev-tools/qemu-arm-xpack/releases/download/v2.8.0-12/xpack-qemu-arm-2.8.0-12-linux-x64.tar.gz
   ```

2. build the application with semihosting enabled:

   ```bash
   ❯ ENABLE_STDIO=1 ENABLE_SEMIHOSTING=1 make
   ```

3. start qemu in one window:

   ```bash
   # the -S halts the cpu at the first instruction
   ❯ ~/Downloads/xpack-qemu-arm-2.8.0-12/bin/qemu-system-gnuarmeclipse \
     -cpu cortex-m4 \
     -machine STM32F4-Discovery \
     -gdb tcp::3333 \
     -nographic \
     -S \
     -semihosting-config enable=on,target=gdb \
     -kernel build/main.elf
   ```

4. start gdb in another window:

   ```bash
   ❯ gdb-multiarch -q build/main.elf -ex 'target remote :3333'
   ```

5. continuing, you should see the startup print in the gdb window
