#!/usr/bin/env python3

"""

Takes data in this form:

00003e18 0000000c T g_memfault_build_id	./third-party/memfault-firmware-sdk/components/core/src/memfault_build_id.c:22
00003f94 0000000c V g_memfault_cdr_source	./third-party/memfault-firmware-sdk/components/core/src/memfault_data_packetizer.c:63
00004348 0000000c T g_memfault_coredump_data_source	./third-party/memfault-firmware-sdk/components/panics/src/memfault_coredump.c:563
00003fa0 0000000c T g_memfault_data_rle_source	./third-party/memfault-firmware-sdk/components/core/src/memfault_data_source_rle.c:290
00003fbc 0000000c T g_memfault_event_data_source	./third-party/memfault-firmware-sdk/components/core/src/memfault_event_storage.c:439
00003fd0 0000000c T g_memfault_log_data_source	./third-party/memfault-firmware-sdk/components/core/src/memfault_log_data_source.c:263

And sums the second column, bucketized by the third column (i.e. code vs data vs
bss, so very similar to what binutils size does).
"""

import sys

def main():
    sizes = {}
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        _, size, objtype, path = line.split(None, 3)
        # normalize case, we don't discriminate between t/T
        objtype = objtype.lower()
        size = int(size, 16)
        path = path.split(":")[0]
        sizes[objtype] = sizes.get(objtype, 0) + size

    # for objtype, size in sorted(sizes.items(), key=lambda x: x[1], reverse=True):
    #     print(f"{size:10} {objtype}")

    # code size is the sum of all t, d, w, and v symbols
    code_size = sum(sizes.get(x, 0) for x in "tdwv")

    # ram size is the sum of all b, d, and v symbols
    ram_size = sum(sizes.get(x, 0) for x in "bdv")

    print(code_size, ram_size)

if __name__ == "__main__":
    main()
