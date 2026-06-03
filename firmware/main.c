#include <stdint.h>

// 1. Hardware Base Addresses (From your ahb_arbiter parameters)
#define I2S_RX_BASE 0x20000000
#define I2S_TX_BASE 0x20010000
#define SRAM_BASE   0x30000000

// 2. Memory-Mapped Pointers
// We pick an arbitrary offset in SRAM (0x0100) to store our test word
#define SRAM_TEST_ADDR (*((volatile uint32_t*)(SRAM_BASE + 0x0100)))

// Standard Efabless IP register offsets (Data = 0x00, Control = 0x04)
#define I2S_RX_DATA    (*((volatile uint32_t*)(I2S_RX_BASE + 0x00)))
#define I2S_RX_CTRL    (*((volatile uint32_t*)(I2S_RX_BASE + 0x01)))

#define I2S_TX_DATA    (*((volatile uint32_t*)(I2S_TX_BASE + 0x00)))
#define I2S_TX_CTRL    (*((volatile uint32_t*)(I2S_TX_BASE + 0x01)))

int main() {
    uint32_t test_word = 0xDEADBEEF;
    uint32_t received_word = 0;

    // Turn on the I2S IP cores
    I2S_RX_CTRL = 1;
    I2S_TX_CTRL = 1;

    // ---------------------------------------------------------
    // PHASE 1: SRAM TEST
    // ---------------------------------------------------------
    
    // Write the word into the SRAM via AHB
    SRAM_TEST_ADDR = test_word;

    // Burn a few CPU cycles just to put empty space in the Vivado 
    // waveforms so the transactions are easy to see visually.
    for (volatile int i = 0; i < 5; i++);

    // ---------------------------------------------------------
    // PHASE 2: I2S TRANSMISSION
    // ---------------------------------------------------------

    // Read the word out of SRAM and instantly shove it into the TX module
    I2S_TX_DATA = SRAM_TEST_ADDR;

    // ---------------------------------------------------------
    // PHASE 3: THE HARDWARE DELAY
    // ---------------------------------------------------------
    
    // The C code must wait while the hardware shifts the 32 bits 
    // across the loopback wire. I2S clocks are usually much slower 
    // than CPU clocks, so we wait a few hundred cycles.
    for (volatile int i = 0; i < 500; i++);

    // ---------------------------------------------------------
    // PHASE 4: THE READBACK & VERIFICATION
    // ---------------------------------------------------------

    // Read the fully assembled word out of the RX module
    received_word = I2S_RX_DATA;

    // Trap the CPU to verify success
    if (received_word == 0xDEADBEEF) {
        // SUCCESS: The chip works perfectly!
        while(1); 
    } else {
        // FAIL: Something went wrong in the transfer.
        while(1);
    }

    return 0;
}