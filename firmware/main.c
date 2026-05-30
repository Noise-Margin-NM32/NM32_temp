#include <stdint.h>

// =======================================================================
// 1. BASE ADDRESS MAPPING
// =======================================================================
#define I2S_RX_BASE 0x20000000
#define I2S_TX_BASE 0x20010000
#define SRAM_BASE   0x30000000

// =======================================================================
// 2. REGISTER POINTERS
// =======================================================================
#define RX_DATA (*((volatile uint32_t*)(I2S_RX_BASE + 0x0000))) 
#define RX_PR   (*((volatile uint32_t*)(I2S_RX_BASE + 0x0004))) 
#define RX_CTRL (*((volatile uint32_t*)(I2S_RX_BASE + 0x0010))) 
#define RX_CFG  (*((volatile uint32_t*)(I2S_RX_BASE + 0x0014))) 
#define RX_GCLK (*((volatile uint32_t*)(I2S_RX_BASE + 0xFF10))) 

#define TX_DATA (*((volatile uint32_t*)(I2S_TX_BASE + 0x0000))) 
#define TX_PR   (*((volatile uint32_t*)(I2S_TX_BASE + 0x0004))) 
#define TX_CTRL (*((volatile uint32_t*)(I2S_TX_BASE + 0x0010))) 
#define TX_CFG  (*((volatile uint32_t*)(I2S_TX_BASE + 0x0014))) 
#define TX_GCLK (*((volatile uint32_t*)(I2S_TX_BASE + 0xFF10))) 

#define SRAM    ((volatile uint32_t*)SRAM_BASE)

int main() {
    // --- PHASE A: ENABLE CLOCK GATES ---
    RX_GCLK = 1;
    TX_GCLK = 1;

    // --- PHASE B: CONFIGURE AUDIO FORMAT ---
    
    RX_CFG = (32 << 4) | (1 << 2) | 2;;
    TX_CFG = (32 << 4) | (0 << 2) | 2;;

    // --- PHASE C: SET CLOCK PRESCALERS (16 kHz Target) ---
    // 50 MHz PCLK / (2 * 1.024 MHz SCK) = ~24
    RX_PR = 24;
    TX_PR = 24;

    // --- PHASE D: ENABLE MODULES AND FIFOS ---
    RX_CTRL = 0x3;
    TX_CTRL = 0x3;

    // --- PHASE E: BLOCK-BASED DSP LOOP ---
    while(1) {
        
        // Step 1: Collect a block of 512 samples into SRAM
        // The CPU will stay in this loop. Because of the APB PREADY stall,
        // it will naturally pace itself to the 16 kHz microphone speed.
        for (uint32_t i = 0; i < 512; i++) {
            SRAM[i] = RX_DATA;
        }

        // ---------------------------------------------------------
        // [ YOUR FFT AND AUDIO FILTERING MATH WOULD GO HERE ]
        // ---------------------------------------------------------

        // Step 2: Play the processed block of 512 samples out to the speaker
        for (uint32_t i = 0; i < 512; i++) {
            TX_DATA = SRAM[i];
        }
    }

    return 0;
}