# Example memfault port

The memfault port files were copied from the templates in the SDK:

> https://github.com/memfault/memfault-firmware-sdk/tree/master/ports/templates .

This port dumps the following sections on crash:

- current contents of stack (stack pointer to top of stack)
- all of `.data` and `.bss` (heap is excluded)

Using the memfault demo cli, the `export` command can be used to dump
base64-encoded chunks to be manually uploaded:

```plaintext
mflt> export
[I] MFLT: MC:CAKoAgIDAQd4HjJmMDAyYjAwMTU0NzM5MzMzODM0MzUzNy1ub2FocApmYXBwLWZ3CWUxLjAuMAZkZHZ0MQtGfQKbZvUPBKIBAAUAbnw=:
```

To export binary chunk data over a different interface (eg http or mqtt), see
this example for how to export chunk data from the sdk:

> https://docs.memfault.com/docs/mcu/data-from-firmware-to-the-cloud#basic-operation-mode
