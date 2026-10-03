#!/usr/bin/env python3
"""
check_fft.py - check the NM32 FFT/IFFT accelerators, frame by frame, against
NumPy, using the bank dumps tb.sv writes to the XSim run directory:

    fft_in.txt   / fft_out.txt    bank as each FFT starts / when it is DONE
    ifft_in.txt  / ifft_out.txt   same for the IFFT
    audio_out.txt                 every word written to the I2S TX FIFO

Bank word format: bits [15:0] real, [31:16] imag, both int16 (Q15).
Both accelerators read their input in bit-reversed order and write natural
order. Each of the 9 butterfly stages halves. Measured against NumPy the
twiddle signs are swapped relative to NumPy's convention:

    FFT_hw(x)  = (1/512) sum x e^{+j..} = ifft(x)
    IFFT_hw(Y) = (1/512) sum Y e^{-j..} = fft(Y) / 512

For real input FFT_hw gives conj(fft(x))/512: same magnitudes, so the
magnitude mask is unaffected, and the round trip is x/512 (the firmware's
IFFT_GAIN_SHIFT restores unity gain).

Pass criterion per frame: error RMS <= TOL_LSB (fixed-point rounding over
9 stages is a few LSB) and the output is not all zero when the input isn't.

Usage: tools/check_fft.py [xsim_run_dir]
"""
import sys
from pathlib import Path

import numpy as np

N = 512
TOL_LSB = 8.0


def load_frames(path):
    words = [int(l, 16) for l in Path(path).read_text().split()]
    if len(words) % N:
        sys.exit(f"{path}: {len(words)} words is not a whole number of frames")
    w = np.array(words, dtype=np.uint32).reshape(-1, N)
    re = (w & 0xFFFF).astype(np.uint16).view(np.int16).astype(float)
    im = (w >> 16).astype(np.uint16).view(np.int16).astype(float)
    return re + 1j * im


def bitrev(n_bits=9):
    return np.array([int(f"{i:0{n_bits}b}"[::-1], 2) for i in range(N)])


def check(name, x_in, y_out, model):
    rev = bitrev()
    ok = True
    for f, (xi, yo) in enumerate(zip(x_in, y_out)):
        x = xi[rev]                       # undo the bit-reversed input layout
        ref = model(x)
        err = np.sqrt(np.mean(np.abs(yo - ref) ** 2))
        sig = np.sqrt(np.mean(np.abs(ref) ** 2))
        silent = not np.any(yo) and np.any(xi)
        good = err <= TOL_LSB and not silent
        ok &= good
        print(f"{name} frame {f}: in rms {np.sqrt(np.mean(np.abs(x)**2)):8.1f}"
              f"  ref rms {sig:8.1f}  err rms {err:6.2f} LSB  "
              f"{'OK' if good else 'FAIL' + (' (all-zero output)' if silent else '')}")
    return ok


def main():
    run = Path(sys.argv[1] if len(sys.argv) > 1 else
               "NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim")
    ok = check("FFT ", load_frames(run / "fft_in.txt"), load_frames(run / "fft_out.txt"),
               lambda x: np.fft.ifft(x))
    ok &= check("IFFT", load_frames(run / "ifft_in.txt"), load_frames(run / "ifft_out.txt"),
                lambda y: np.fft.fft(y) / N)

    audio = np.array([int(l, 16) for l in (run / "audio_out.txt").read_text().split()],
                     dtype=np.uint32)
    left = (audio[0::2] & 0xFFFF).astype(np.uint16).view(np.int16).astype(float)
    nz = np.count_nonzero(left)
    print(f"audio_out: {len(left)} left samples, {nz} nonzero, "
          f"rms {np.sqrt(np.mean(left**2)):.1f}, peak {np.max(np.abs(left)):.0f}")
    ok &= nz > 0

    print("PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
