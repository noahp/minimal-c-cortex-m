#!/usr/bin/env bash

MFLT_SDK_DIR=third-party/memfault-firmware-sdk

TAGS=$(git -C ${MFLT_SDK_DIR} tag --sort=v:refname | awk '/0.27.1/{flag=1} flag')

echo "" > sizes.txt

for tag in ${TAGS}; do
    git -C ${MFLT_SDK_DIR} checkout ${tag}
    make clean
    DEVICE=qemu_mps2_an385 ENABLE_STDIO=1 ENABLE_MEMFAULT=1 ENABLE_MEMFAULT_METRICS=1 make -j $(nproc)

    sizes=$(arm-none-eabi-nm --defined --print-size --line-numbers build/main.elf | rg ./third-party/memfault-firmware-sdk | ./sizes.py)

    echo "${tag} ${sizes}" >> sizes.txt
done
