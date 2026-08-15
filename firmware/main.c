/*
 * main.c - NM32 SoC firmware, PURE Q15 selective noise cancellation
 *
 * Design choices for this version:
 *   - No float anywhere. All math is int16 / int32 / int64.
 *   - Hardware FFT/IFFT accelerators do the heavy transform work in Q15.
 *   - Mask stage: spectral subtraction + Wiener-style, projected onto known
 *     siren templates, all in Q15.
 *   - Integer sqrt via binary (digit-by-digit) method - no lookup table.
 *   - 50% overlap-add with Hamming window for click-free reconstruction.
 *   - OLA normalization is precomputed once (constant per position at 50%
 *     overlap with a fixed window) so runtime has zero divisions in OLA.
 *
 * Numeric ranges (planned carefully, since Q15 wraps silently on overflow):
 *   - Input samples right-shifted by 5 bits before FFT to guarantee headroom
 *     (sqrt(512) ~= 22.6, so 5 bits of shift covers worst-case butterfly gain)
 *   - Mask values in Q15: range [0, 32767] representing [0.0, ~1.0]
 *   - Suppression strength in Q15: same range
 *   - mag_sq and sir_sq in int32 (up to Q30 after squaring)
 *   - Dot-product accumulator in int64 (257 terms of Q30 each)
 *
 * PicoRV32 note: assumes eventual M-extension for hardware multiply/divide.
 * Without M, integer divides in the mask stage will be slow (still faster
 * than float emulation though).
 */

#include <stdint.h>

/* -------------------------------------------------------------------------- */
/*  Base addresses (unchanged from original)                                  */
/* -------------------------------------------------------------------------- */

#define SRAM_BASE       0x30000000
#define FFT_BASE        0x40000000
#define PING_PONG_BASE  0x50000000
#define IFFT_BASE       0x60000000
#define I2S_RX_BASE     0x20000000
#define I2S_TX_BASE     0x20010000

#define I2S_RX_DATA   (*((volatile uint32_t*)(I2S_RX_BASE + 0x00)))
#define I2S_RX_PR     (*((volatile uint32_t*)(I2S_RX_BASE + 0x04)))
#define I2S_RX_CTRL   (*((volatile uint32_t*)(I2S_RX_BASE + 0x10)))
#define I2S_RX_CFG    (*((volatile uint32_t*)(I2S_RX_BASE + 0x14)))
#define I2S_RX_LEVEL  (*((volatile uint32_t*)(I2S_RX_BASE + 0xFE00)))
#define I2S_RX_GCLK   (*((volatile uint32_t*)(I2S_RX_BASE + 0xFF10)))

#define I2S_TX_DATA   (*((volatile uint32_t*)(I2S_TX_BASE + 0x00)))
#define I2S_TX_PR     (*((volatile uint32_t*)(I2S_TX_BASE + 0x04)))
#define I2S_TX_CTRL   (*((volatile uint32_t*)(I2S_TX_BASE + 0x10)))
#define I2S_TX_CFG    (*((volatile uint32_t*)(I2S_TX_BASE + 0x14)))
#define I2S_TX_LEVEL  (*((volatile uint32_t*)(I2S_TX_BASE + 0xFE00)))
#define I2S_TX_GCLK   (*((volatile uint32_t*)(I2S_TX_BASE + 0xFF10)))

#define FFT_CTRL         (*((volatile uint32_t*)(FFT_BASE + 0x0C00)))
#define IFFT_CTRL        (*((volatile uint32_t*)(IFFT_BASE + 0x0C00)))
#define PING_PONG_CTRL   (*((volatile uint32_t*)(PING_PONG_BASE + 0x1000)))

/* -------------------------------------------------------------------------- */
/*  Algorithm constants (all Q15-friendly)                                    */
/* -------------------------------------------------------------------------- */

#define N_FFT              512
#define HOP                256
#define HALF               257           /* N_FFT/2 + 1 unique bins */
#define N_DIRECTIONS       1

#define Q15_ONE            32767         /* max positive Q15 */
#define Q15_HALF           16384         /* 0.5 in Q15 */

/* Tuning constants in Q15 */
#define TRIGGER_THRESHOLD_Q15   3277     /* 0.1 * 32767 */
#define SMOOTH_ALPHA_Q15        13107    /* 0.4 * 32767 */
#define SMOOTH_ONE_MINUS_A_Q15  19661    /* 0.6 * 32767 */
#define TRIGGER_MULT_Q15        1        /* multiplier for projection strength, keep at 1 initially */

#define INPUT_SHIFT_FFT    5             /* shift input right by this many bits to guarantee no FFT overflow */
#define NUM_FRAMES         8             /* number of hops to process before halting (sim-friendly) */

extern const uint32_t fft_twiddles[256];
extern const int16_t  trigger_vecs_q15[N_DIRECTIONS][HALF];

/* -------------------------------------------------------------------------- */
/*  Buffers (all integer)                                                     */
/* -------------------------------------------------------------------------- */

/* Hamming window in Q15, computed at boot */
static int16_t hamming_q15[N_FFT];

/* Circular mic input buffer, int16 audio */
static int16_t input_buffer[N_FFT];
static int     input_write_ptr = 0;

/* OLA output accumulator in int32 (accumulates Q15 samples, may need range) */
static int32_t ola_buffer[N_FFT];

/* Working arrays for the mask stage - hold FFT output in Q15 real/imag */
static int16_t real_q15[N_FFT];
static int16_t imag_q15[N_FFT];

/* Squared magnitudes and squared projection - int32 for headroom */
static int32_t mag_sq[HALF];
static int32_t sir_sq[HALF];

/* Q15 magnitudes for projection dot products */
static int16_t mag_q15_arr[HALF];

/* Q15 projection vector */
static int16_t proj_q15[HALF];

/* Q15 mask + smoothing state */
static int16_t mask_q15[HALF];
static int16_t prev_mask_q15[HALF];
static int     first_frame = 1;

/* Precomputed OLA normalization inverse (Q15) - constant since window + hop are fixed */
static int32_t ola_norm_inv_q15[HOP];

/* -------------------------------------------------------------------------- */
/*  Integer sqrt - binary (digit-by-digit) method                             */
/*  Takes uint32_t input, returns uint16_t sqrt.  No memory, no divides.      */
/*  ~16 iterations, each just shifts and compares.                            */
/* -------------------------------------------------------------------------- */

static uint16_t isqrt_bin(uint32_t x) {
    uint32_t bit    = 1u << 30;
    uint32_t result = 0;

    /* Skip bits above the input's magnitude for faster convergence */
    while (bit > x) bit >>= 2;

    while (bit != 0) {
        if (x >= result + bit) {
            x     -= result + bit;
            result = (result >> 1) + bit;
        } else {
            result >>= 1;
        }
        bit >>= 2;
    }
    return (uint16_t)result;
}

/* Q15 sqrt: input is Q15 in range [0, 32767], output is Q15 in same range */
static int16_t sqrt_q15(int32_t x_q15) {
    if (x_q15 <= 0) return 0;
    /* sqrt(x_Q15) where x_Q15 = actual * 32768:
     *   sqrt(actual * 32768) = sqrt(actual) * sqrt(32768) = sqrt(actual) * 181.02
     * We want result in Q15: result_Q15 = sqrt(actual) * 32768
     * So: result_Q15 = isqrt(x_Q15) * sqrt(32768) = isqrt(x_Q15 << 15)
     * i.e. shift input up by 15 bits first, then take integer sqrt. */
    uint32_t scaled = (uint32_t)x_q15 << 15;
    uint16_t r = isqrt_bin(scaled);
    if (r > 32767) r = 32767;
    return (int16_t)r;
}

/* -------------------------------------------------------------------------- */
/*  pow(x, 2.5) in Q15 = x^2 * sqrt(x), reuses isqrt_bin                      */
/* -------------------------------------------------------------------------- */

static int16_t pow25_q15(int16_t x_q15) {
    if (x_q15 <= 0) return 0;
    /* x^2 in Q15: (x * x) >> 15, result also Q15 */
    int32_t x_sq_q15 = ((int32_t)x_q15 * x_q15) >> 15;
    /* sqrt(x) in Q15 (using the helper above) */
    int16_t root     = sqrt_q15(x_q15);
    /* Multiply x^2 * sqrt(x), both Q15, result Q15 */
    return (int16_t)((x_sq_q15 * root) >> 15);
}

/* -------------------------------------------------------------------------- */
/*  Hamming window generation - one-time Taylor cos, then discard             */
/* -------------------------------------------------------------------------- */

/* We compute cos via Taylor series in fixed-point one-time at boot.
 * Result is baked to Q15 and never touched again. */
static int32_t cos_fp_q30(int32_t angle_q16) {
    /* Very rough fixed-point cos, adequate for Hamming window shape.
     * angle_q16 is in Q16 units, representing radians. */
    /* Reduce to [-pi, pi] */
    const int32_t TWO_PI_Q16 = 411774;  /* 2*pi * 65536 */
    const int32_t PI_Q16     = 205887;  /* pi   * 65536 */
    while (angle_q16 >  PI_Q16) angle_q16 -= TWO_PI_Q16;
    while (angle_q16 < -PI_Q16) angle_q16 += TWO_PI_Q16;

    /* Taylor: cos(x) = 1 - x^2/2 + x^4/24 - x^6/720 */
    int64_t x_q30 = ((int64_t)angle_q16 * angle_q16); /* angle^2, in Q32 */
    x_q30 >>= 2;  /* now Q30 */
    int64_t term1 = x_q30 >> 1;              /* x^2/2 */
    int64_t x4    = (x_q30 * x_q30) >> 30;   /* x^4 in Q30 */
    int64_t term2 = x4 / 24;
    int64_t x6    = (x4 * x_q30) >> 30;
    int64_t term3 = x6 / 720;

    int64_t result = ((int64_t)1 << 30) - term1 + term2 - term3;
    return (int32_t)result;
}

static void init_hamming_window(void) {
    /* w[i] = 0.54 - 0.46 * cos(2*pi*i/(N-1))
     * In Q15: w_q15 = 0.54*32768 - 0.46*32768*cos_q30 >> 15  */
    for (int i = 0; i < N_FFT; i++) {
        int32_t angle_q16 = (int32_t)(((int64_t)411774 * i) / (N_FFT - 1)); /* 2*pi*i/(N-1) in Q16 */
        int32_t c_q30     = cos_fp_q30(angle_q16);
        /* 0.54 in Q30 = 579820748, 0.46 in Q30 = 493921050
         * hamming = 0.54 - 0.46*c   (result in Q30 range)
         * then downshift to Q15 */
        int64_t val_q30 = 579820748LL - (((int64_t)493921050 * c_q30) >> 30);
        int32_t val_q15 = (int32_t)(val_q30 >> 15);
        if (val_q15 >  32767) val_q15 =  32767;
        if (val_q15 < -32768) val_q15 = -32768;
        hamming_q15[i] = (int16_t)val_q15;
    }
}

/* -------------------------------------------------------------------------- */
/*  Precompute OLA norm inverse (constant since window and hop are fixed)     */
/*  For a 50% overlapped fixed window, sum of overlapping window^2 at each    */
/*  position within a hop is a fixed value we can precompute and invert once. */
/* -------------------------------------------------------------------------- */

static void init_ola_norm_inv(void) {
    for (int i = 0; i < HOP; i++) {
        /* Sum of window^2 at position i and window^2 at position i+HOP */
        int32_t w1  = hamming_q15[i];
        int32_t w2  = hamming_q15[i + HOP];
        int32_t w1s = (w1 * w1) >> 15;   /* window^2 in Q15 */
        int32_t w2s = (w2 * w2) >> 15;
        int32_t sum = w1s + w2s;
        /* Store the RECIPROCAL as Q15 - so we multiply at runtime instead of divide */
        if (sum > 0) ola_norm_inv_q15[i] = ((int32_t)32768 << 15) / sum;
        else         ola_norm_inv_q15[i] = 0;
    }
}

/* -------------------------------------------------------------------------- */
/*  Twiddle setup for FFT and IFFT hardware (same as original)                */
/* -------------------------------------------------------------------------- */

static void init_twiddles(void) {
    volatile uint32_t* fft_tw  = (volatile uint32_t*)(FFT_BASE  + 0x0800);
    volatile uint32_t* ifft_tw = (volatile uint32_t*)(IFFT_BASE + 0x0800);

    for (int i = 0; i < 256; i++) {
        uint32_t val  = fft_twiddles[i];
        fft_tw[i]     = val;
        int16_t imag  = (int16_t)(val & 0xFFFF);
        ifft_tw[i]    = (val & 0xFFFF0000) | ((uint32_t)(-imag) & 0xFFFF);
    }
}

/* -------------------------------------------------------------------------- */
/*  I2S bring-up (unchanged)                                                  */
/* -------------------------------------------------------------------------- */

static void init_i2s(void) {
    I2S_RX_GCLK = 1;
    I2S_TX_GCLK = 1;
    I2S_RX_PR   = 2;
    I2S_TX_PR   = 2;
    I2S_RX_CFG  = 0x20B;
    I2S_TX_CFG  = 0x20B;
    I2S_RX_CTRL = 2;
    I2S_TX_CTRL = 2;
    for (int i = 0; i < 8; i++) I2S_TX_DATA = 0;
    I2S_RX_CTRL = 3;
    I2S_TX_CTRL = 3;
}

/* -------------------------------------------------------------------------- */
/*  I/O helper - pull HOP samples in / push HOP samples out                   */
/*  Everything is Q15 int16 here; no conversions needed.                      */
/* -------------------------------------------------------------------------- */

static void io_hop(const int16_t *tx_samples, int hop) {
    for (int i = 0; i < hop; i++) {
        int16_t s = tx_samples[i];   /* already clamped */
        while (I2S_TX_LEVEL > 14) ;  I2S_TX_DATA = (uint32_t)(uint16_t)s;
        while (I2S_TX_LEVEL > 14) ;  I2S_TX_DATA = 0;

        while (I2S_RX_LEVEL == 0) ;
        int16_t new_sample = (int16_t)(I2S_RX_DATA << 1);
        while (I2S_RX_LEVEL == 0) ;
        (void)I2S_RX_DATA;

        input_buffer[input_write_ptr] = new_sample;
        input_write_ptr = (input_write_ptr + 1) % N_FFT;
    }
}

/* -------------------------------------------------------------------------- */
/*  Prepare bank: window + shift-down + bit-reverse into hardware bank        */
/* -------------------------------------------------------------------------- */

static inline uint32_t bit_reverse9(uint32_t v) {
    uint32_t r = 0;
    for (int j = 0; j < 9; j++) { r = (r << 1) | (v & 1); v >>= 1; }
    return r;
}

static void prepare_bank(volatile uint32_t *bank) {
    int start = input_write_ptr;
    for (int i = 0; i < N_FFT; i++) {
        int src_idx = (start + i) % N_FFT;
        int32_t s   = input_buffer[src_idx];
        /* Q15 windowing: (sample * window_Q15) >> 15 keeps it Q15 */
        int32_t w = ((int32_t)s * hamming_q15[i]) >> 15;
        /* Then shift down to give FFT hardware headroom */
        w >>= INPUT_SHIFT_FFT;
        if (w >  32767) w =  32767;
        if (w < -32768) w = -32768;
        uint32_t rev = bit_reverse9(i);
        bank[rev] = ((uint32_t)(uint16_t)((int16_t)w));  /* real; imag=0 */
    }
}

/* -------------------------------------------------------------------------- */
/*  Read Q15 spectrum from bank into real_q15/imag_q15 arrays                 */
/* -------------------------------------------------------------------------- */

static void read_bank_spectrum(volatile uint32_t *bank) {
    for (int i = 0; i < N_FFT; i++) {
        uint32_t v  = bank[i];
        real_q15[i] = (int16_t)(v & 0xFFFF);
        imag_q15[i] = (int16_t)((v >> 16) & 0xFFFF);
    }
}

/* -------------------------------------------------------------------------- */
/*  Write masked spectrum back to bank, bit-reversed for IFFT                 */
/* -------------------------------------------------------------------------- */

static void write_bank_spectrum_bitrev(volatile uint32_t *bank) {
    for (int i = 0; i < N_FFT; i++) {
        uint32_t rev = bit_reverse9(i);
        uint32_t packed = ((uint32_t)(uint16_t)real_q15[i])
                        | (((uint32_t)(uint16_t)imag_q15[i]) << 16);
        bank[rev] = packed;
    }
}

/* -------------------------------------------------------------------------- */
/*  Read IFFT output (natural-order Q15) into an int16 output buffer          */
/* -------------------------------------------------------------------------- */

static void read_bank_ifft(volatile uint32_t *bank, int16_t *out) {
    for (int i = 0; i < N_FFT; i++) {
        uint32_t v = bank[i];
        out[i]     = (int16_t)(v & 0xFFFF);
    }
}

/* -------------------------------------------------------------------------- */
/*  The mask stage - pure Q15, no float, no LUT                               */
/* -------------------------------------------------------------------------- */

static void apply_spectral_mask(void) {
    /* Step 1: squared magnitude per bin (mag_sq = re^2 + im^2 in int32) */
    for (int i = 0; i < HALF; i++) {
        int32_t r = real_q15[i];
        int32_t g = imag_q15[i];
        mag_sq[i] = r*r + g*g;  /* max ~32767^2 * 2 fits in int32 */
    }

    /* Step 2: magnitude via integer sqrt, back to Q15
     * mag_sq is Q30 (Q15*Q15), so sqrt gives Q15 directly */
    for (int i = 0; i < HALF; i++) {
        mag_q15_arr[i] = (int16_t)isqrt_bin((uint32_t)mag_sq[i]);
    }

    /* Step 3: projection onto each trigger vector
     * coeff_k = sum(mag[i] * trigger_vecs[k][i]) - Q15*Q15 -> Q30, sum in int64 */
    for (int i = 0; i < HALF; i++) proj_q15[i] = 0;

    for (int k = 0; k < N_DIRECTIONS; k++) {
        int64_t coeff = 0;
        for (int i = 0; i < HALF; i++) {
            coeff += (int64_t)mag_q15_arr[i] * trigger_vecs_q15[k][i];
        }
        /* coeff is Q30 * 257 terms, shift back to Q15 */
        int32_t coeff_q15 = (int32_t)(coeff >> 15);
        /* Optional *1.5 (from reference algo): (coeff * 3) >> 1 */
        coeff_q15 = (coeff_q15 * 3) >> 1;
        /* Clamp to Q15 range */
        if (coeff_q15 >  32767) coeff_q15 =  32767;
        if (coeff_q15 < -32768) coeff_q15 = -32768;
        /* Add coeff * trigger_vec back into proj_q15 */
        for (int i = 0; i < HALF; i++) {
            int32_t v = ((int32_t)coeff_q15 * trigger_vecs_q15[k][i]) >> 15;
            int32_t p = proj_q15[i] + v;
            if (p >  32767) p =  32767;
            if (p < -32768) p = -32768;
            proj_q15[i] = (int16_t)p;
        }
    }

    /* Step 4: sir_sq per bin (proj squared) */
    for (int i = 0; i < HALF; i++) {
        int32_t p = proj_q15[i];
        sir_sq[i] = p * p;
    }

    /* Step 5: total signal and siren power, for trigger ratio decision
     * Use int64 accumulators - 257 * ~2^30 terms */
    int64_t total_sig = 0, total_sir = 0;
    for (int i = 0; i < HALF; i++) {
        total_sig += mag_sq[i];
        total_sir += sir_sq[i];
    }

    /* trigger_ratio > threshold  ==  siren > threshold * signal
     * Replaces division with a multiply. */
    int16_t suppression_q15 = 0;
    int64_t threshold_lhs   = total_sir;
    int64_t threshold_rhs   = (total_sig * TRIGGER_THRESHOLD_Q15) >> 15;
    if (threshold_lhs > threshold_rhs) {
        /* suppression = min(1.0, trigger_ratio * 2)
         * trigger_ratio = total_sir / total_sig, so:
         * suppression = min(Q15_ONE, (total_sir * 2 * Q15_ONE) / total_sig) */
        if (total_sig > 0) {
            int64_t s = ((int64_t)total_sir * 2 * Q15_ONE) / total_sig;
            suppression_q15 = (s > Q15_ONE) ? Q15_ONE : (int16_t)s;
        } else {
            suppression_q15 = Q15_ONE;
        }
    }

    /* Step 6: per-bin Wiener mask, no sqrt per bin division problem
     * mask^2 = (mag_sq - sir_sq) / mag_sq  in Q15
     * mask   = sqrt(mask^2) via integer sqrt above
     * Smoothed with previous frame's mask. */
    for (int i = 0; i < HALF; i++) {
        int32_t mp = mag_sq[i] - sir_sq[i];
        if (mp < 0) mp = 0;

        int32_t mask_sq_q15;
        if (mag_sq[i] > 0) {
            /* (mp << 15) / mag_sq gives result in Q15 range [0, 32767] */
            int64_t num = (int64_t)mp << 15;
            mask_sq_q15 = (int32_t)(num / mag_sq[i]);
            if (mask_sq_q15 > Q15_ONE) mask_sq_q15 = Q15_ONE;
        } else {
            mask_sq_q15 = 0;
        }

        /* mask = sqrt(mask^2) in Q15 */
        int16_t m = sqrt_q15(mask_sq_q15);

        /* Clamp mask to [0.01, 1.0] in Q15: 0.01 * 32767 ~= 328 */
        if (m > Q15_ONE) m = Q15_ONE;
        if (m < 328)     m = 328;

        /* Temporal smoothing: 0.4 * prev + 0.6 * new (in Q15) */
        int32_t smoothed;
        if (first_frame) smoothed = m;
        else             smoothed = ((int32_t)prev_mask_q15[i] * SMOOTH_ALPHA_Q15
                                   + (int32_t)m * SMOOTH_ONE_MINUS_A_Q15) >> 15;
        mask_q15[i]      = (int16_t)smoothed;
        prev_mask_q15[i] = (int16_t)smoothed;
    }
    first_frame = 0;

    /* Step 7: apply mask + rebuild conjugate-symmetric upper half for real output
     * scale = mask * (1 - supp) + mask^2.5 * supp
     * All in Q15. */
    int16_t one_minus_supp = Q15_ONE - suppression_q15;
    for (int i = 0; i < HALF; i++) {
        int16_t m       = mask_q15[i];
        int16_t m_pow25 = pow25_q15(m);
        int32_t scale = ((int32_t)m * one_minus_supp
                       + (int32_t)m_pow25 * suppression_q15) >> 15;
        if (scale > Q15_ONE) scale = Q15_ONE;
        if (scale < 0)       scale = 0;

        /* Multiply real/imag by scale, keeping Q15 */
        int32_t r = ((int32_t)real_q15[i] * scale) >> 15;
        int32_t g = ((int32_t)imag_q15[i] * scale) >> 15;
        if (r >  32767) r =  32767;  if (r < -32768) r = -32768;
        if (g >  32767) g =  32767;  if (g < -32768) g = -32768;
        real_q15[i] = (int16_t)r;
        imag_q15[i] = (int16_t)g;

        /* Mirror to conjugate-symmetric upper half */
        if (i > 0 && i < HALF - 1) {
            real_q15[N_FFT - i] =  real_q15[i];
            imag_q15[N_FFT - i] = -imag_q15[i];
        }
    }
}

/* -------------------------------------------------------------------------- */
/*  Overlap-add and drain: pure Q15, no divisions at runtime                  */
/* -------------------------------------------------------------------------- */

static void overlap_add_and_drain(const int16_t *frame_out, int16_t *tx_out) {
    /* Window this frame's IFFT output again on synthesis, add into OLA buffer */
    for (int i = 0; i < N_FFT; i++) {
        int32_t windowed = ((int32_t)frame_out[i] * hamming_q15[i]) >> 15;
        ola_buffer[i] += windowed;  /* accumulate in int32 for headroom */
    }

    /* Drain first HOP samples: multiply by precomputed inverse of window^2 sum */
    for (int i = 0; i < HOP; i++) {
        int64_t acc  = ola_buffer[i];
        /* Multiply by normalization inverse (Q15) - restores flat amplitude */
        int32_t out  = (int32_t)((acc * ola_norm_inv_q15[i]) >> 15);
        if (out >  32767) out =  32767;
        if (out < -32768) out = -32768;
        tx_out[i] = (int16_t)out;
    }

    /* Shift buffer left by HOP - the second half becomes the new first half */
    for (int i = 0; i < N_FFT - HOP; i++) ola_buffer[i] = ola_buffer[i + HOP];
    for (int i = N_FFT - HOP; i < N_FFT; i++) ola_buffer[i] = 0;
}

/* -------------------------------------------------------------------------- */
/*  Main                                                                      */
/* -------------------------------------------------------------------------- */

int main(void) {
    volatile uint32_t *bank_a = (volatile uint32_t*)(PING_PONG_BASE);
    volatile uint32_t *bank_b = (volatile uint32_t*)(PING_PONG_BASE + 0x0800);
    volatile uint32_t *banks[2] = { bank_a, bank_b };

    /* Boot-time init */
    init_hamming_window();
    init_ola_norm_inv();
    init_twiddles();
    init_i2s();

    for (int i = 0; i < N_FFT; i++) {
        input_buffer[i] = 0;
        ola_buffer[i]   = 0;
    }
    for (int i = 0; i < HALF; i++) prev_mask_q15[i] = 0;

    /* Silence buffer - used both for initial priming and as the "previous
     * frame's output" on iteration 0, since nothing has been computed yet. */
    int16_t silence[N_FFT];
    for (int i = 0; i < N_FFT; i++) silence[i] = 0;

    /* Prime input buffer with a full frame of history before the loop starts */
    io_hop(silence, N_FFT);

    /* Double-buffered per bank parity, since two frames are genuinely
     * in flight at once now: one being computed, one being streamed. */
    int16_t frame_time[2][N_FFT];
    int16_t tx_scratch[2][HOP];

    for (int frame = 0; frame < NUM_FRAMES; frame++) {
        int p = frame % 2;             /* bank parity for this frame */
        int prev_p = 1 - p;            /* parity of the frame just completed */
        volatile uint32_t *bank = banks[p];
        PING_PONG_CTRL = p;

        /* Prepare this frame's input - uses input_buffer as filled by the
         * previous iteration's io_hop (or the priming call, on frame 0). */
        prepare_bank(bank);

        /* Kick off FFT - this runs in hardware, in the background, starting
         * right now. We do NOT wait for it yet. */
        FFT_CTRL = 1;

        /* While FFT hardware is busy, do this frame's I2S work: stream out
         * the PREVIOUS frame's finished audio (or silence, on frame 0) and
         * simultaneously capture the samples the NEXT iteration's
         * prepare_bank will need. This is genuinely concurrent with the
         * FFT computation happening in hardware right now. */
        io_hop(frame == 0 ? silence : tx_scratch[prev_p], HOP);

        /* Now collect the FFT result - if hardware finished during io_hop,
         * this returns immediately with zero extra wait. */
        while ((FFT_CTRL & 2) == 0) ;

        read_bank_spectrum(bank);
        apply_spectral_mask();
        write_bank_spectrum_bitrev(bank);

        /* Kick off IFFT the same way */
        IFFT_CTRL = 1;
        while ((IFFT_CTRL & 2) == 0) ;

        read_bank_ifft(bank, frame_time[p]);
        overlap_add_and_drain(frame_time[p], tx_scratch[p]);

        *((volatile uint32_t*)(SRAM_BASE + 0x7000)) = 0x22220000u | (uint32_t)frame;
    }

    /* Epilogue - stream out the final frame's output, since it never got
     * an overlapped io_hop slot inside the loop. */
    io_hop(tx_scratch[(NUM_FRAMES - 1) % 2], HOP);

    /* Trigger simulation end */
    *((volatile uint32_t*)(SRAM_BASE + 0x7000)) = 0x55555555u;
    while (1) ;
    return 0;
}

/* -------------------------------------------------------------------------- */
/*  Twiddle table - PASTE YOUR 256-entry table from original main.c here     */
/* -------------------------------------------------------------------------- */

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

/* -------------------------------------------------------------------------- */
/*  Placeholder trigger vectors (Q15).                                        */
/*  Simulates a siren-like spectrum: loud between bins 40-70, quiet elsewhere.*/
/*  Bins 40-70 correspond to ~1250-2200 Hz at 16 kHz sample rate.             */
/*                                                                            */
/*  Replace with real siren template data (from SVD of training data or       */
/*  hand-crafted profile). Each row is one direction/template, 257 bins each. */
/* -------------------------------------------------------------------------- */

const int16_t trigger_vecs_q15[N_DIRECTIONS][HALF] = {
    /* Simple placeholder: raised cosine centered around bin 55 */
    /* Values in Q15: 0.7 = 22937, 0.05 = 1638, etc. */
    {
        /* You would fill this with real trained vector data.
         * For now, 0.05 in bins 0-39, ramp up to 0.7 in bins 40-70, back to 0.05 in 71-256.
         * Fill in real values at build time. */
        0
    }
};