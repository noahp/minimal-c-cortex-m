import re

import gdb


def get_address_from_linespec_location(location):
    # Set a linespec location to convert to an address
    # location = "main.c:42"

    print("info line {}".format(location))
    output = gdb.execute("info line {}".format(location), to_string=True)
    output = str(output)

    # now find the address
    m = re.search(r"address 0x([0-9a-f]+)", output)
    if m:
        address = int(m.group(1), 16)
        return address
    else:
        raise ValueError("Could not find address in output: {}".format(output))


def get_cycle_counter(void):
    ARM_CM_DWT_CYCCNT = "0xE0001004"

    val = gdb.parse_and_eval("(*(uint32_t *){})".format(ARM_CM_DWT_CYCCNT))
    val = int(val)
    return val


def start_cycle_counter(void):
    ARM_CM_DEMCR = "0xE000EDFC"
    ARM_CM_DWT_CTRL = "0xE0001000"
    gdb.execute("set (*(uint32_t *){}) |= (1 << 24)".format(ARM_CM_DEMCR))
    gdb.execute("set (*(uint32_t *){}) |= (1 << 0)".format(ARM_CM_DWT_CTRL))


class SingleStepSPTrace(gdb.Command):
    """Single step and dump the SP continuously until a breakpoint is hit. SP
    values are written to the file specified in the argument."""

    def __init__(self):
        super(SingleStepSPTrace, self).__init__("sp_trace", gdb.COMMAND_USER)

    def complete(self, text, word):
        # the argument should be a single file name
        return gdb.COMPLETE_FILENAME

    def invoke(self, args, from_tty):
        outfile = args.split()[0]

        print("Dumping SP to %s" % outfile)

        # single-step until a breakpoint is hit
        bp_addresses = []
        for bp in gdb.breakpoints():
            try:
                location = gdb.parse_and_eval(bp.location)
                address = int(location.address)
            except gdb.error:
                print("Location: {}".format(bp.location))
                address = get_address_from_linespec_location(bp.location)
            print("Breakpoint {}:  0x{:08x}".format(bp.number, address))
            bp_addresses.append(address)

        def hit_breakpoint():
            pc = int(gdb.parse_and_eval("$pc"))
            if pc in bp_addresses:
                print("Hit breakpoint at 0x{:08x}".format(pc))
                return True
            else:
                return False

        sp_start = int(gdb.parse_and_eval("$sp"))
        print("Starting SP: 0x{:08x}".format(sp_start))

        sp_min = 0xFFFFFFFF
        while True:
            gdb.execute("si")
            sp = int(gdb.parse_and_eval("$sp"))
            # with open(outfile, "a") as f:
            #     f.write("%s" % sp)
            if sp < sp_min:
                sp_min = sp
            # check if we've reached a breakpoint
            if hit_breakpoint():
                break

        print("Min SP: 0x{:08x}".format(sp_min))
        print("Delta SP: {}".format(sp_start - sp_min))


SingleStepSPTrace()
