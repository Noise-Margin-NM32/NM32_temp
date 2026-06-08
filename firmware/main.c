#include <stdint.h>
#include "audio_in.h"

#define SRAM_BASE      0x30000000
#define FFT_BASE       0x40000000
#define IFFT_BASE      0x60000000

#define I2S_RX_BASE    0x20000000
#define I2S_TX_BASE    0x20010000

#define I2S_RX_DATA    (*((volatile uint32_t*)(I2S_RX_BASE + 0x00)))
#define I2S_RX_PR      (*((volatile uint32_t*)(I2S_RX_BASE + 0x04)))
#define I2S_RX_CTRL    (*((volatile uint32_t*)(I2S_RX_BASE + 0x10)))
#define I2S_RX_CFG     (*((volatile uint32_t*)(I2S_RX_BASE + 0x14)))
#define I2S_RX_LEVEL   (*((volatile uint32_t*)(I2S_RX_BASE + 0xFE00)))
#define I2S_RX_GCLK    (*((volatile uint32_t*)(I2S_RX_BASE + 0xFF10)))

#define I2S_TX_DATA    (*((volatile uint32_t*)(I2S_TX_BASE + 0x00)))
#define I2S_TX_PR      (*((volatile uint32_t*)(I2S_TX_BASE + 0x04)))
#define I2S_TX_CTRL    (*((volatile uint32_t*)(I2S_TX_BASE + 0x10)))
#define I2S_TX_CFG     (*((volatile uint32_t*)(I2S_TX_BASE + 0x14)))
#define I2S_TX_LEVEL   (*((volatile uint32_t*)(I2S_TX_BASE + 0xFE00)))
#define I2S_TX_GCLK    (*((volatile uint32_t*)(I2S_TX_BASE + 0xFF10)))

#define FFT_CTRL       (*((volatile uint32_t*)(FFT_BASE + 0x0C00)))
#define IFFT_CTRL      (*((volatile uint32_t*)(IFFT_BASE + 0x0C00)))

// 512-point twiddle factors (Q15 format: Real in upper 16 bits, Imag in lower 16 bits)
const uint32_t fft_twiddles[256] = {
    0x7FFF0000, 0x7FFDFE6E, 0x7FF5FCDC, 0x7FE9FB4A, 0x7FD8F9B8, 0x7FC1F827, 0x7FA6F696, 0x7F86F505,
    0x7F61F374, 0x7F37F1E4, 0x7F09F055, 0x7ED5EEC6, 0x7E9CED38, 0x7E5FEBAB, 0x7E1DEA1E, 0x7DD5E892,
    0x7D89E707, 0x7D39E57E, 0x7CE3E3F5, 0x7C88E26D, 0x7C29E0E6, 0x7BC5DF61, 0x7B5CDDDD, 0x7AEEDC5A,
    0x7A7CDAD8, 0x7A05D958, 0x7989D7DA, 0x7909D65D, 0x7884D4E1, 0x77FAD367, 0x776BD1EF, 0x76D8D079,
    0x7641CF05, 0x75A5CD92, 0x7504CC21, 0x745FCAB3, 0x73B5C946, 0x7307C7DC, 0x7254C674, 0x719DC50E,
    0x70E2C3AA, 0x7022C248, 0x6F5EC0E9, 0x6E96BF8D, 0x6DC9BE32, 0x6CF8BCDB, 0x6C23BB86, 0x6B4ABA33,
    0x6A6DB8E4, 0x698BB797, 0x68A6B64C, 0x67BCB505, 0x66CFB3C1, 0x65DDB27F, 0x64E8B141, 0x63EEB005,
    0x62F1AECD, 0x61F0AD98, 0x60EBAC65, 0x5FE3AB37, 0x5ED7AA0B, 0x5DC7A8E3, 0x5CB3A7BE, 0x5B9CA69C,
    0x5A82A57E, 0x5964A464, 0x5842A34D, 0x571DA239, 0x55F5A129, 0x54C9A01D, 0x539B9F15, 0x52689E10,
    0x51339D0F, 0x4FFB9C12, 0x4EBF9B18, 0x4D819A23, 0x4C3F9931, 0x4AFB9844, 0x49B4975A, 0x48699675,
    0x471C9593, 0x45CD94B6, 0x447A93DD, 0x43259308, 0x41CE9237, 0x4073916A, 0x3F1790A2, 0x3DB88FDE,
    0x3C568F1E, 0x3AF28E63, 0x398C8DAC, 0x38248CF9, 0x36BA8C4B, 0x354D8BA1, 0x33DF8AFC, 0x326E8A5B,
    0x30FB89BF, 0x2F878928, 0x2E118895, 0x2C998806, 0x2B1F877C, 0x29A386F7, 0x28268677, 0x26A885FB,
    0x25288584, 0x23A68512, 0x222384A4, 0x209F843B, 0x1F1A83D7, 0x1D938378, 0x1C0B831D, 0x1A8282C7,
    0x18F98277, 0x176E822B, 0x15E281E3, 0x145581A1, 0x12C88164, 0x113A812B, 0x0FAB80F7, 0x0E1C80C9,
    0x0C8C809F, 0x0AFB807A, 0x096A805A, 0x07D9803F, 0x06488028, 0x04B68017, 0x0324800B, 0x01928003,
    0x00008001, 0xFE6E8003, 0xFCDC800B, 0xFB4A8017, 0xF9B88028, 0xF827803F, 0xF696805A, 0xF505807A,
    0xF374809F, 0xF1E480C9, 0xF05580F7, 0xEEC6812B, 0xED388164, 0xEBAB81A1, 0xEA1E81E3, 0xE892822B,
    0xE7078277, 0xE57E82C7, 0xE3F5831D, 0xE26D8378, 0xE0E683D7, 0xDF61843B, 0xDDDD84A4, 0xDC5A8512,
    0xDAD88584, 0xD95885FB, 0xD7DA8677, 0xD65D86F7, 0xD4E1877C, 0xD3678806, 0xD1EF8895, 0xD0798928,
    0xCF0589BF, 0xCD928A5B, 0xCC218AFC, 0xCAB38BA1, 0xC9468C4B, 0xC7DC8CF9, 0xC6748DAC, 0xC50E8E63,
    0xC3AA8F1E, 0xC2488FDE, 0xC0E990A2, 0xBF8D916A, 0xBE329237, 0xBCDB9308, 0xBB8693DD, 0xBA3394B6,
    0xB8E49593, 0xB7979675, 0xB64C975A, 0xB5059844, 0xB3C19931, 0xB27F9A23, 0xB1419B18, 0xB0059C12,
    0xAECD9D0F, 0xAD989E10, 0xAC659F15, 0xAB37A01D, 0xAA0BA129, 0xA8E3A239, 0xA7BEA34D, 0xA69CA464,
    0xA57EA57E, 0xA464A69C, 0xA34DA7BE, 0xA239A8E3, 0xA129AA0B, 0xA01DAB37, 0x9F15AC65, 0x9E10AD98,
    0x9D0FAECD, 0x9C12B005, 0x9B18B141, 0x9A23B27F, 0x9931B3C1, 0x9844B505, 0x975AB64C, 0x9675B797,
    0x9593B8E4, 0x94B6BA33, 0x93DDBB86, 0x9308BCDB, 0x9237BE32, 0x916ABF8D, 0x90A2C0E9, 0x8FDEC248,
    0x8F1EC3AA, 0x8E63C50E, 0x8DACC674, 0x8CF9C7DC, 0x8C4BC946, 0x8BA1CAB3, 0x8AFCCC21, 0x8A5BCD92,
    0x89BFCF05, 0x8928D079, 0x8895D1EF, 0x8806D367, 0x877CD4E1, 0x86F7D65D, 0x8677D7DA, 0x85FBD958,
    0x8584DAD8, 0x8512DC5A, 0x84A4DDDD, 0x843BDF61, 0x83D7E0E6, 0x8378E26D, 0x831DE3F5, 0x82C7E57E,
    0x8277E707, 0x822BE892, 0x81E3EA1E, 0x81A1EBAB, 0x8164ED38, 0x812BEEC6, 0x80F7F055, 0x80C9F1E4,
    0x809FF374, 0x807AF505, 0x805AF696, 0x803FF827, 0x8028F9B8, 0x8017FB4A, 0x800BFCDC, 0x8003FE6E,
};

int main() {
    volatile uint32_t* fft_data = (volatile uint32_t*)FFT_BASE;
    volatile uint32_t* fft_twiddle = (volatile uint32_t*)(FFT_BASE + 0x0800);
    
    volatile uint32_t* ifft_data = (volatile uint32_t*)IFFT_BASE;
    volatile uint32_t* ifft_twiddle = (volatile uint32_t*)(IFFT_BASE + 0x0800);
    
    volatile uint32_t* sram_out = (volatile uint32_t*)SRAM_BASE;

    // 1. Initialize Twiddle Factors for FFT and IFFT first (CPU intensive)
    for (int i = 0; i < 256; i++) {
        uint32_t val = fft_twiddles[i];
        
        // FFT Twiddles loaded directly
        fft_twiddle[i] = val;
        
        // IFFT Twiddles are complex conjugates: negate the imaginary part (lower 16 bits)
        int16_t real = (int16_t)(val >> 16);
        int16_t imag = (int16_t)(val & 0xFFFF);
        int16_t negated_imag = -imag;
        
        ifft_twiddle[i] = ((uint32_t)real << 16) | ((uint32_t)negated_imag & 0xFFFF);
    }

    // 2. Initialize Peripheral Clocks, Formats, and Enable I2S
    I2S_RX_GCLK = 1;
    I2S_TX_GCLK = 1;
    // 2. Configure I2S RX and TX for 32-bit, stereo, left-justified
    I2S_RX_PR = 2;
    I2S_TX_PR = 2;
    I2S_RX_CFG = 0x20B; 
    I2S_TX_CFG = 0x20B; 
    
    // Enable FIFOs but keep engines disabled
    I2S_RX_CTRL = 2; // fifo_en=1, en=0
    I2S_TX_CTRL = 2; // fifo_en=1, en=0

    // Prime TX FIFO with 8 dummy words (4 stereo frames) to keep it ahead of RX
    for (int i = 0; i < 8; i++) {
        I2S_TX_DATA = 0;
    }

    // Enable engines
    I2S_RX_CTRL = 3; // fifo_en=1, en=1
    I2S_TX_CTRL = 3; // fifo_en=1, en=1

    // 3. Process 4 frames continuously
    
    // Prime the very first frame: send dummy TX data to generate I2S clocks, and receive Frame 0
    for (int i = 0; i < 512; i++) {
        while (I2S_TX_LEVEL > 14); 
        I2S_TX_DATA = 0;           // Dummy data (Left)
        while (I2S_TX_LEVEL > 14); 
        I2S_TX_DATA = 0;           // Dummy data (Right)
        
        while (I2S_RX_LEVEL == 0); 
        sram_out[i] = I2S_RX_DATA << 1; // Read Left, shift left by 1 to restore
        while (I2S_RX_LEVEL == 0); 
        uint32_t dummy = I2S_RX_DATA; // Read Right and discard
    }

    // Pause I2S clocks to prevent RX/TX from running during FFT processing
    // I2S_TX_GCLK = 0;
    // I2S_RX_GCLK = 0;

    uint32_t* next_sram_out = (uint32_t*)(SRAM_BASE + 0x0800); // Temporary buffer for next frame

    for (int frame = 0; frame < 4; frame++) {
        
        // Copy input samples to FFT Data RAM in bit-reversed order (512 points = 9 bits)
        for (int i = 0; i < 512; i++) {
            uint32_t rev_idx = 0;
            uint32_t temp = i;
            for (int j = 0; j < 9; j++) {
                rev_idx = (rev_idx << 1) | (temp & 1);
                temp >>= 1;
            }
            fft_data[rev_idx] = sram_out[i];
        }

        // Start FFT
        FFT_CTRL = 1;
        
        // Wait for FFT engine completion
        while ((FFT_CTRL & 2) == 0);

        // Copy FFT outputs directly from FFT Data RAM to IFFT Data RAM in bit-reversed order
        // The twiddles are already conjugated for the IFFT, so we pass the natural X[k] directly.
        for (int i = 0; i < 512; i++) {
            uint32_t rev_idx = 0;
            uint32_t temp = i;
            for (int j = 0; j < 9; j++) {
                rev_idx = (rev_idx << 1) | (temp & 1);
                temp >>= 1;
            }
            ifft_data[rev_idx] = fft_data[i];
        }

        // Start IFFT
        IFFT_CTRL = 1;

        // Wait for IFFT engine completion
        while ((IFFT_CTRL & 2) == 0);

        // Resume I2S clocks
        // I2S_RX_GCLK = 1; // MUST wake up RX first
        // I2S_TX_GCLK = 1; // Then start TX which generates the clocks

        // Read back computed reconstructed time-domain samples from IFFT to SRAM (offset 0-511)
        // and simultaneously output them to I2S TX, while receiving the NEXT frame
        for (int i = 0; i < 512; i++) {
            uint32_t out_val = ifft_data[i];
            sram_out[i] = out_val;
            
            while (I2S_TX_LEVEL > 14); 
            I2S_TX_DATA = out_val;     // Output Left
            while (I2S_TX_LEVEL > 14); 
            I2S_TX_DATA = 0;           // Output Right
            
            while (I2S_RX_LEVEL == 0); 
            next_sram_out[i] = I2S_RX_DATA << 1; // Read Left, shift left by 1 to restore
            while (I2S_RX_LEVEL == 0); 
            uint32_t dummy = I2S_RX_DATA; // Read Right and discard
        }

        // Toggle handshake flag to notify testbench that the current frame is complete
        uint32_t handshake = 0x55555555;
        if (frame == 0) handshake = 0x11111111;
        else if (frame == 1) handshake = 0x22222222;
        else if (frame == 2) handshake = 0x33333333;
        
        *((volatile uint32_t*)(SRAM_BASE + 0x0104)) = handshake;

        // Pause I2S clocks again before next FFT
        // I2S_TX_GCLK = 0; // Stop TX clocks first
        // I2S_RX_GCLK = 0; // Then sleep RX

        // Copy next frame's data into sram_out for processing in the next iteration
        for (int i = 0; i < 512; i++) {
            sram_out[i] = next_sram_out[i];
        }
    }

    while(1);
    return 0;
}