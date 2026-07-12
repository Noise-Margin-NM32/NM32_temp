#include <stdint.h>

// Exported memory symbols from sections.ld
extern uint32_t _text_flash_start;
extern uint32_t _text_ram_start;
extern uint32_t _text_ram_end;

extern uint32_t _data_flash_start;
extern uint32_t _data_ram_start;
extern uint32_t _data_ram_end;

// APB SPI Controller Register Map Offsets derived from PADDR[5:2]
#define SPI_BASE_ADDR        0x20020000
#define SPI_REG_STATUS       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x00)) // CS selection & Trigger
#define SPI_REG_CLKDIV       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x04)) // Clock divider
#define SPI_REG_SPICMD       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x08)) // SPI Command Reg
#define SPI_REG_SPIADR       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x0C)) // SPI Address Reg
#define SPI_REG_SPILEN       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x10)) // Length configurations
#define SPI_REG_SPIDUM       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x14)) // Dummy cycles
#define SPI_REG_TXFIFO       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x18)) // Tx data
#define SPI_REG_RXFIFO       (*(volatile uint32_t*)(SPI_BASE_ADDR + 0x20)) // Rx data

// Reads a 32-bit word from your off-chip SPI memory using the native IP register layout
uint32_t read_spi_flash_word(uint32_t flash_byte_offset) {
    // 1. Setup the SPI payload bit lengths: 8-bit command, 24-bit address, 32-bit data read
    // Pack fields according to: PWDATA[5:0] = cmd_len, PWDATA[13:8] = addr_len, PWDATA[31:16] = data_len
    SPI_REG_SPILEN = (8 & 0x3F) | ((24 & 0x3F) << 8) | ((32 & 0xFFFF) << 16);

    // 2. Clear out any dummy cycles for standard read (0x03)
    SPI_REG_SPIDUM = 0;

    // 3. Load the standard SPI flash read command (0x03) and target address
    // Shift command by 24 bits and address by 8 bits to align to MSB-first tx
    SPI_REG_SPICMD = 0x03 << 24;
    SPI_REG_SPIADR = flash_byte_offset << 8;

    // 4. Trigger the transaction: Assert Chip Select 0 and pulse the read enable bit
    // PWDATA[0] = spi_rd, PWDATA[11:8] = spi_csreg (Select CS0 -> 4'b0001)
    SPI_REG_STATUS = (1 << 0) | (0x1 << 8);

    // 5. Poll the status register until the RX FIFO elements indicator becomes non-zero
    // Elements_rx is mapped past the 9-bit status spacing + 7-bit controller status field
    while (((SPI_REG_STATUS >> 16) & 0x1F) == 0);

    // 6. Read out the captured 32-bit word directly from the FIFO
    uint32_t data_word = SPI_REG_RXFIFO;

    return data_word;
}

// Global execution control sequence
void hardware_spi_bootloader(void) {
    // Set clock division factor (e.g., divide internal bus clock by 4)
    SPI_REG_CLKDIV = 4;

    // 1. Stream out the application instructions into ITCM RAM space
    uint32_t *src_flash = (uint32_t*)&_text_flash_start;
    uint32_t *dest_ram  = (uint32_t*)&_text_ram_start;
    uint32_t flash_offset = (uint32_t)src_flash - 0x80000000;

    while (dest_ram < &_text_ram_end) {
        uint32_t val = read_spi_flash_word(flash_offset);
        *dest_ram = ((val >> 24) & 0x000000FF) |
                    ((val >> 8)  & 0x0000FF00) |
                    ((val << 8)  & 0x00FF0000) |
                    ((val << 24) & 0xFF000000);
        dest_ram++;
        flash_offset += 4;
    }

    // 2. Stream out the initialized global variables into Data RAM space
    src_flash = (uint32_t*)&_data_flash_start;
    dest_ram  = (uint32_t*)&_data_ram_start;
    flash_offset = (uint32_t)src_flash - 0x80000000;

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