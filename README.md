# minimal-c-cortex-m

A minimal Arm Cortex-M example, including semihosting, for my own reference.
*not really recommended for anything beyond toy usage*

```bash
# necessary tools
sudo apt install openocd gcc-arm-none-eabi

# start openocd in one terminal
make openocd

# build default config (stm32f4discovery) and start gdb in another terminal
make gdb

# 'continue' in gdb, you should see 'Hello there!' in openocd
```
