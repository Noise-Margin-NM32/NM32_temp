# NM32 SoC: Project Status and Architecture Comparison

This document provides a high-level comparison between the originally intended architecture (which relied heavily on DMA and external components) and the current, highly optimized Zero-Copy implementation. It also tracks the completion percentage and outlines pending tasks.

## Overall Completion Estimate: ~50% to 60%
The most mathematically complex and computationally intensive custom IPs (FFT, IFFT, I2S, Ping-Pong Memory, AHB Matrix) are fully functional, integrated, and verified. The remaining work focuses entirely on microcontroller-level orchestration (Interrupts, DMA, SPI Flash) and the high-level C filtration algorithm.

---

## 1. Boot Phase Comparison

| Intended Flow | Current Implementation | Status / Pending |
| :--- | :--- | :--- |
| Reset controller resets everything | Simple active-low reset wire | **Pending:** Dedicated Reset Controller |
| CPU runs from Boot ROM | CPU executes from internal Boot ROM | **Done** |
| CPU pulls code/twiddles from external SPI Flash | Code and twiddles are currently compiled directly into the internal Boot ROM | **Pending:** SPI Peripheral, External Flash integration, and ITCM/DTCM separation |
| Configure Watchdog, GPIO, Debug, PLIC | None of these are currently initialized in the C firmware | **Pending:** Write drivers/initialization for these modules |
| DMA Channels Configured | DMA is not integrated. CPU handles all data movement manually | **Pending:** Integrate DMA module and map channels |

---

## 2. Real-Time Dataflow Comparison (The Architectural Shift)

There is a massive architectural difference here. The original intended flow relied on **heavy DMA usage** to constantly shuttle data back and forth between SRAM, DTCM, and the FFT/IFFT scratchpads. 

**Our current Zero-Copy Ping-Pong architecture is vastly superior** because it eliminates 80% of those DMA transfers!

* **Original Intended Flow:** I2S -> (DMA 0) -> SRAM -> (DMA 1) -> FFT Scratchpad -> (CPU) -> DTCM -> (CPU) -> IFFT Scratchpad -> (DMA 3) -> SRAM -> (DMA 4) -> I2S.
* **Current Optimized Flow:** I2S -> (CPU/DMA) -> Ping-Pong RAM -> (CPU) -> I2S.

Because the Ping-Pong RAM physically acts as the FFT scratchpad, the IFFT scratchpad, *and* the DTCM all simultaneously, the data never has to move across the bus for processing! Once the audio is in the Ping-Pong RAM, the FFT computes on it in-place. The CPU can then run the filtration algorithm on it in-place. Finally, the IFFT computes on it in-place. No DMA transfers are required between these stages!

| Intended Real-Time Flow | Current Implementation | Status / Pending |
| :--- | :--- | :--- |
| I2S FIFO fills to 512, fires Interrupt | I2S FIFO is small (16 words). CPU polls it continuously | **Pending:** Increase I2S FIFO size, enable Interrupts |
| DMA moves I2S data to memory | CPU manually polls and moves data to Ping-Pong RAM | **Pending:** Have DMA Ch0 handle I2S -> Ping-Pong RAM |
| FFT/IFFT fire Interrupts when done | CPU constantly polls the `Done` bits in a `while` loop | **Pending:** Route FFT/IFFT done signals to the PLIC (Interrupt Controller) and write ISRs |
| CPU transfers data to DTCM for filtration | CPU does simple bit-reversal right inside the Ping-Pong RAM | **Pending:** Implement the actual Audio Filtration Algorithm in C |
| DMA moves data back to I2S TX | CPU manually pushes data to I2S TX | **Pending:** Have DMA Ch4 handle Ping-Pong RAM -> I2S TX |

---

## 3. Pending Tasks (Roadmap)
To achieve the 100% intended dataflow, we need to implement the following:

1. **Interrupts (PLIC):** Hook up the `fft_done`, `ifft_done`, and I2S FIFO flags to the PLIC (Platform-Level Interrupt Controller) and write the C Interrupt Service Routines (ISRs) so the CPU doesn't have to poll.
2. **DMA Controller:** Drop the DMA IP into `NM32_top.sv`, connect it to the AHB bus, and configure channels 0 and 4 to handle the I2S streaming in the background. *(Channels 1 and 3 are no longer needed thanks to our zero-copy architecture!)*
3. **SPI & External Flash:** Add an SPI controller to the bus so the SoC can boot from an external Flash chip and load instructions into an ITCM.
4. **General Peripherals (GPIO, Watchdog):** Integrate these existing IPs into the AHB/APB bus and map their registers.
5. **Filtration Algorithm:** Write the actual C code for the audio filtration process that sits between the FFT and IFFT phases.

## Resolved (2026-10-05)
- **Dual-port SRAM.** The SRAM has a second, read-only port wired straight to the Ibex instruction interface through `ibex_imem_router` (`NM32_top_temp.srcs/sources_1/new/ibex_imem_router.sv`). Fetches from `0x3000_xxxx` take one cycle and never use AHB. Boot ROM fetches still go through `ibex_to_ahb` (master 0). The router grants an SRAM fetch only when no AHB fetch is outstanding, so responses stay in order. The full run now ends at ~53.2 ms (was ~61.5 ms).
- **Full-scale peaks and distortion.** These came from the Hamming window: `cos_fp_q30` computed x^4 in int64 and overflowed for angles above ~1.7 rad, which corrupted the middle of the window. The window is now built from `fft_twiddles` (exact, periodic Hamming). Tone-only hops went from ~2000 RMS error to 285-590 RMS, and the output peak dropped from 32768 to 18148.

## Resolved (2026-10-03)
- "Frames 0-6 identical": not an RTL bug. The old `audio_in.txt` repeated every 32 samples, so every 256-hop window was identical. Replaced by a 4096-sample non-periodic stimulus from `tools/gen_audio_in.py` (tone at bin 20.3 + siren sweep bins 50-60 from sample 1536); `tb.sv` input memory enlarged to 4096. All 8 frames now differ.
- The stray `0x0000` RX sample was a genuine zero crossing of the old sine input.
- Spectral mask never suppressed anything: `trigger_vecs_q15` was an all-zero placeholder. Now a unit-norm Hann template over bins 40-70. Result: background tone passes unchanged, siren bins attenuated ~20 dB (frames 5-7). `check_fft.py` PASS.
- Golden outputs for this stimulus saved outside the repo in `~/NM32_golden/ibex/`.

## Open
- Firmware still polls; CLIC interrupt handlers, watchdog kick and GPIO driver are not written yet.
- Siren suppression is weaker than the per-bin estimate above. Fitting the tone out of the output leaves 4000-5400 RMS in the last two hops, against an 8100 RMS siren input (about 4-6 dB). It needs mask tuning and a longer run, ideally with a trained template.
