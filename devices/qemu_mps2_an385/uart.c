//! @file

#include <stdint.h>
#include <sys/types.h>

#include "qemu_mps2_an385.h"

typedef struct UART_t {
  volatile uint32_t DATA;
  volatile uint32_t STATE;
  volatile uint32_t CTRL;
  volatile uint32_t INTSTATUS;
  volatile uint32_t BAUDDIV;
} UART_t;

#define UART0_ADDR ((UART_t *)(0x40004000))
#define UART_DR(baseaddr) (*(unsigned int *)(baseaddr))

#define UART_STATE_TXFULL (1 << 0)
#define UART_CTRL_TX_EN (1 << 0)
#define UART_CTRL_RX_EN (1 << 1)
// snagged the below def from
// https://github.com/ARMmbed/mbed-os/blob/master/targets/TARGET_ARM_FM/TARGET_FVP_MPS2/serial_api.c#L356
#define UART_STATE_RXRDY (1 << 1)
#define UART_STATE_TXNRDY (1 << 0)

// extern unsigned long _heap_bottom;
// extern unsigned long _heap_top;
// extern unsigned long g_ulBase;

// static void * heap_end = 0;

/**
 * @brief initializes the UART emulated hardware
 */
void uart_init(void) {
  UART0_ADDR->BAUDDIV = 16;
  UART0_ADDR->CTRL = UART_CTRL_TX_EN | UART_CTRL_RX_EN;
}

// /**
//  * @brief not used anywhere in the code
//  * @todo  implement if necessary
//  *
//  */
// int _fstat(__attribute__((unused)) int file )
// {
//     return 0;
// }

/**
 * @brief not used anywhere in the code
 * @todo  implement if necessary
 *
 */
int _read(__attribute__((unused)) int file, __attribute__((unused)) char *buf,
          __attribute__((unused)) int len) {
  for (int i = 0; i < len; i++) {
    if (UART0_ADDR->STATE & UART_STATE_RXRDY) {
      buf[i] = UART0_ADDR->DATA;
    } else {
      return i;
    }
  }
  return len;
}

/**
 * @brief  Write bytes to the UART channel to be displayed on the command line
 *         with qemu
 * @param [in] file  ignored
 * @param [in] buf   buffer to send
 * @param [in] len   length of the buffer
 * @returns the number of bytes written
 */
int _write(__attribute__((unused)) int file, __attribute__((unused)) char *buf,
           int len) {
  for (int i = 0; i < len; i++) {
    while (UART0_ADDR->STATE & UART_STATE_TXNRDY) {
    };
    UART_DR(UART0_ADDR) = *buf++;
  }

  return len;
}
