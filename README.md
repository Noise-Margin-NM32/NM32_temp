# NM32 SoC Architecture Updates

This repository contains the latest architectural improvements to the NM32 SoC for high-performance audio processing, specifically related to the integration of the FFT and IFFT accelerators with the system bus and memory.

## Key Architectural Changes

### 1. Zero-Copy Architecture (Direct Connection)
Previously, the FFT and IFFT accelerators relied on their own internal "Data RAMs". Processing an audio frame meant the CPU had to copy data from the main scratchpad into the accelerator's internal memory via the AHB bus, wait for completion, and copy it back out.
**The Change:** We removed the internal RAMs. The accelerators now feature a dedicated, direct hardware connection to the newly implemented Ping-Pong SRAM.
**How it helps:** Bypassing the AHB bus completely eliminates the severe bottleneck of copying data back and forth. The CPU merely writes incoming audio to the shared memory and signals the accelerators to start. The accelerators compute directly on that memory, saving thousands of clock cycles per frame.

### 2. Ping-Pong Buffer Strategy
**The Change:** The shared SRAM was divided into two distinct banks (Bank 0 and Bank 1) governed by a hardware `PING_PONG_CTRL` switch.
**How it helps:** This enables real-time "double-buffering". While the FFT/IFFT hardware is crunching numbers on Bank 0, the CPU can simultaneously write the newly arriving audio samples to Bank 1. They operate entirely in parallel without memory collisions, ensuring zero dropped audio samples and maximum throughput.

### 3. Software Twiddle Factors (ROM Removal)
**The Change:** The massive Vivado hardware IP block (`twiddle_rom_512.v`) was removed. Twiddle factors (sine/cosine coefficients) are now embedded as a software `const` array in the firmware `.rodata`. During the boot process, the CPU loads these factors into a tiny internal RAM inside the accelerators over the AHB bus.
**How it helps:** We save massive amounts of FPGA logic and routing resources. Additionally, it gives us ultimate software flexibility—modifying the FFT size or tweaking coefficients no longer requires re-synthesizing massive hardware blocks.

### 4. Wait-State Timing Fix for SRAM Reads
**The Change:** Block RAMs on FPGAs are synchronous and possess a 1-clock-cycle read latency. The initial custom AHB interface incorrectly asserted zero wait states (`hready_out = 1`). We modified the interface to inject exactly 1 wait state (`hready_out = 0`) upon a read request.
**How it helps:** It prevents the CPU from sampling the bus before the memory outputs the data. This completely resolved an issue where undefined `XXXXXXXX` garbage data was propagating through the FFT math engine, ensuring absolute data integrity at high CPU frequencies.
