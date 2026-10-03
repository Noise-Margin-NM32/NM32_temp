#!/usr/bin/env python3
"""
gen_audio_in.py - write firmware/audio_in.txt, the mic stimulus tb.sv serializes.

4096 samples, one 32-bit I2S left-slot word per line (sample in bits [31:16]).
The signal is deliberately NOT periodic in the 256-sample hop, so every
frame's FFT input differs:
  - background: tone at 20.3 bins (should pass the mask)
  - "siren":    sweep from bin 50 to 60 (the placeholder trigger vector is
                centred on bin 55), switched on from sample 1536 onwards
Usage (repo root):  python3 tools/gen_audio_in.py
"""
import math
import os

N, NFFT, SIREN_ON = 4096, 512, 1536
out = os.path.join(os.path.dirname(__file__), "..", "firmware", "audio_in.txt")

phase = 0.0
with open(out, "w") as f:
    for n in range(N):
        s = 0.30 * math.sin(2 * math.pi * 20.3 * n / NFFT)
        if n >= SIREN_ON:
            k = 50 + 10 * (n - SIREN_ON) / (N - SIREN_ON)   # bins, linear sweep
            phase += 2 * math.pi * k / NFFT
            s += 0.35 * math.sin(phase)
        v = max(-32768, min(32767, int(round(s * 32767))))
        f.write("%08X\n" % ((v & 0xFFFF) << 16))
print("wrote", N, "samples to", os.path.normpath(out))
