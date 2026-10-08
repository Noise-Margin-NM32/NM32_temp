#include <stdint.h>

/* -------------------------------------------------------------------------- */
/*  Memory Map & Register Definitions                                         */
/* -------------------------------------------------------------------------- */
#define SRAM_BASE        0x30000000
#define FFT_BASE         0x40000000
#define PING_PONG_BASE   0x50000000
#define IFFT_BASE        0x60000000
#define I2S_RX_BASE      0x20000000
#define I2S_TX_BASE      0x20010000
#define SPI_BASE_ADDR    0x20020000
#define GPIO_BASE        0x20030000
#define CLIC_BASE        0x02000000

/* Register Handles */
#define GPIO_OUT         (*((volatile uint32_t*)(GPIO_BASE + 0x04)))

#define SPI_REG_STATUS   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x00)))
#define SPI_REG_CLKDIV   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x04)))
#define SPI_REG_SPICMD   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x08)))
#define SPI_REG_SPIADR   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x0C)))
#define SPI_REG_SPILEN   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x10)))
#define SPI_REG_SPIDUM   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x14)))
#define SPI_REG_RXFIFO   (*((volatile uint32_t*)(SPI_BASE_ADDR + 0x20)))

#define I2S_RX_DATA      (*((volatile uint32_t*)(I2S_RX_BASE + 0x00)))
#define I2S_RX_PR        (*((volatile uint32_t*)(I2S_RX_BASE + 0x04)))
#define I2S_RX_CTRL      (*((volatile uint32_t*)(I2S_RX_BASE + 0x10)))
#define I2S_RX_CFG       (*((volatile uint32_t*)(I2S_RX_BASE + 0x14)))
#define I2S_RX_LEVEL     (*((volatile uint32_t*)(I2S_RX_BASE + 0xFE00)))
#define I2S_RX_GCLK      (*((volatile uint32_t*)(I2S_RX_BASE + 0xFF10)))

#define PING_PONG_CTRL   (*((volatile uint32_t*)(PING_PONG_BASE + 0x1000)))

/* CLIC Registers */
#define CLIC_INT_IE(n)   (*((volatile uint8_t*)(CLIC_BASE + 0x1000 + 0x04*(n))))
#define CLIC_INT_IP(n)   (*((volatile uint8_t*)(CLIC_BASE + 0x1000 + 0x04*(n) + 1)))
#define CLIC_INT_CTL(n)  (*((volatile uint8_t*)(CLIC_BASE + 0x1000 + 0x04*(n) + 2)))

#define N_FFT            512
#define HOP              256
#define I2S_IRQ_NUM      16   /* Vector slot for I2S RX */

/* Linker Symbols */
extern uint32_t _text_flash_start;
extern uint32_t _text_ram_start;
extern uint32_t _text_ram_end;
extern uint32_t _data_flash_start;
extern uint32_t _data_ram_start;
extern uint32_t _data_ram_end;

/* Global state variables */
volatile uint8_t g_i2s_irq_flag = 0;
static int16_t   input_buffer[N_FFT];
static int       input_write_ptr = 0;

/* -------------------------------------------------------------------------- */
/*  SPI Flash Bootloader Routine                                              */
/* -------------------------------------------------------------------------- */
static uint32_t read_spi_flash_word(uint32_t flash_byte_offset) {
    SPI_REG_SPILEN = (8 & 0x3F) | ((24 & 0x3F) << 8) | ((32 & 0xFFFF) << 16);
    SPI_REG_SPIDUM = 0;
    SPI_REG_SPICMD = 0x03 << 24;
    SPI_REG_SPIADR = flash_byte_offset << 8;
    SPI_REG_STATUS = (1 << 0) | (0x1 << 8);

    while (((SPI_REG_STATUS >> 16) & 0x1F) == 0);
    return SPI_REG_RXFIFO;
}

static void do_spi_flash_transfer(void) {
    SPI_REG_CLKDIV = 4;

    /* Copy .text section */
    uint32_t *src_flash = (uint32_t*)&_text_flash_start;
    uint32_t *dest_ram  = (uint32_t*)&_text_ram_start;
    uint32_t flash_offset = (uint32_t)src_flash;

    while (dest_ram < &_text_ram_end) {
        uint32_t val = read_spi_flash_word(flash_offset);
        *dest_ram = ((val >> 24) & 0x000000FF) |
                    ((val >> 8)  & 0x0000FF00) |
                    ((val << 8)  & 0x00FF0000) |
                    ((val << 24) & 0xFF000000);
        dest_ram++;
        flash_offset += 4;
    }

    /* Copy .data section */
    src_flash = (uint32_t*)&_data_flash_start;
    dest_ram  = (uint32_t*)&_data_ram_start;
    flash_offset = (uint32_t)src_flash;

    while (dest_ram < &_data_ram_end) {
        uint32_t val = read_spi_flash_word(flash_offset);
        *dest_ram = ((val >> 24) & 0x000000FF) |
                    ((val >> 8)  & 0x0000FF00) |
                    ((val << 8)  & 0x00FF0000) |
                    ((val << 24) & 0xFF000000);
        dest_ram++;
        flash_offset += 4;
    }
}

/* -------------------------------------------------------------------------- */
/*  Interrupt Service Routine (ISR)                                           */
/* -------------------------------------------------------------------------- */
void c_irq_handler(void) __attribute__((interrupt("machine")));
void c_irq_handler(void) {
    /* INDICATION 2: Interrupt Acknowledged */
    GPIO_OUT = 0xAA;

    /* Clear pending interrupt flag in CLIC */
    CLIC_INT_IP(I2S_IRQ_NUM) = 0;

    /* Mark flag for main process thread */
    g_i2s_irq_flag = 1;
}

/* Helper bit reversal for 9-bit FFT */
static inline uint32_t bit_reverse9(uint32_t v) {
    uint32_t r = 0;
    for (int j = 0; j < 9; j++) { r = (r << 1) | (v & 1); v >>= 1; }
    return r;
}

/* Transfer audio frame from circular buffer into active hardware Ping-Pong Bank */
static void transfer_i2s_to_fft_bank(volatile uint32_t *bank) {
    int start = input_write_ptr;
    for (int i = 0; i < N_FFT; i++) {
        int src_idx = (start + i) % N_FFT;
        int16_t s   = input_buffer[src_idx];
        uint32_t rev = bit_reverse9(i);
        bank[rev] = ((uint32_t)(uint16_t)s);  /* Real sample; Imag = 0 */
    }

    /* INDICATION 3: Transfer to Bank Completed */
    GPIO_OUT = 0xBB;
}

/* -------------------------------------------------------------------------- */
/*  Main Function                                                             */
/* -------------------------------------------------------------------------- */
int main(void) {
    /* 1. Execute SPI Flash payload copy to RAM */
    do_spi_flash_transfer();

    /* 2. Indicate main app execution started */
    GPIO_OUT = 0x01;

    /* Initialize I2S Hardware */
    I2S_RX_GCLK = 1;
    I2S_RX_PR   = 2;
    I2S_RX_CFG  = 0x20B;
    I2S_RX_CTRL = 3;

    /* Configure CLIC for I2S Interrupt */
    CLIC_INT_CTL(I2S_IRQ_NUM) = 0xC0; /* Priority */
    CLIC_INT_IE(I2S_IRQ_NUM)  = 1;    /* Enable IRQ in CLIC */

    /* Enable Global Interrupts in RISC-V mstatus CSR */
    asm volatile ("csrs mstatus, %0" :: "r"(0x8));

    /* Unmask PicoRV32 internal IRQ mask register (0 = all unmasked) */
/* Correct byte encoding for PicoRV32 maskirq custom instruction */
    asm volatile (".word 0x0607870b" ::: "memory");

    volatile uint32_t *bank_a = (volatile uint32_t*)(PING_PONG_BASE);
    
    /* Wait for I2S Interrupt Trigger */
    while (!g_i2s_irq_flag) {
        /* Poll I2S hardware level in software to fill circular buffer */
        if (I2S_RX_LEVEL > 0) {
            int16_t sample = (int16_t)(I2S_RX_DATA << 1);
            (void)I2S_RX_DATA; // Read second channel byte
            input_buffer[input_write_ptr] = sample;
            input_write_ptr = (input_write_ptr + 1) % N_FFT;
        }
    }

    /* 3. Execute Transfer from I2S Buffer to FFT Bank */
    transfer_i2s_to_fft_bank(bank_a);

    /* 4. Complete Test - Mark All Verification Checkpoints Passed */
    GPIO_OUT = 0xFF;

    while (1);
    return 0;
}
