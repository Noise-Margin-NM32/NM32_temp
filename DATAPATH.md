# NM32 SoC: Control and Data Path Flow

This document details the exact hardware and software flow of the NM32 SoC, detailing how the control and data paths operate from boot to steady-state audio processing, including explicit AHB bus addresses and data movements.

## Phase 1: Boot Sequence
1. **Instruction Fetch (AHB Read):**
   * **Address:** `0x0000_0000` to `0x0000_0FFF` (Slave 0: Boot ROM)
   * **Data Flow:** The CPU reads the compiled C program instructions and begins executing.
2. **I2S Peripheral Setup (AHB Writes):**
   * **Address:** `0x2000_0008` (Slave 1: I2S RX Control Register)
   * **Address:** `0x7000_0008` (Slave 6: I2S TX Control Register)
   * **Data Flow:** The CPU writes configuration bits (`0x3`) to enable the FIFOs and turn the microphones/speakers on.
3. **Loading Twiddle Factors (AHB Read -> AHB Write):**
   * The CPU enters a loop of 256 iterations.
   * **AHB Read Address:** `0x0000_xxxx` (Slave 0: Boot ROM `.rodata`) -> Fetches the 32-bit sine/cosine constant.
   * **AHB Write Address:** `0x4000_0800` up to `0x4000_0BFC` (Slave 3: FFT Accelerator Twiddle RAM) -> Stores the constant.
   * **AHB Write Address:** `0x6000_0800` up to `0x6000_0BFC` (Slave 5: IFFT Accelerator Twiddle RAM) -> Stores the conjugated constant.
4. **Priming the First Audio Frame (AHB Read -> AHB Write):**
   * The CPU loops 512 times to grab the first chunk of audio.
   * **AHB Read Address:** `0x2000_0000` (Slave 1: I2S RX FIFO) -> Pulls one 32-bit audio sample.
   * **AHB Write Address:** `0x5000_0000` up to `0x5000_07FC` (Slave 4: Ping-Pong RAM **Bank 0**) -> Stores the sample in sequence.

---

## Phase 2: Steady-State Audio Loop
*(Assuming we are processing the frame that is sitting in **Bank 0**, while receiving new audio into **Bank 1**)*

1. **Assigning the Ping-Pong Roles (AHB Write):**
   * **Address:** `0x5000_1000` (Slave 4: Ping-Pong Control Register)
   * **Data Flow:** CPU writes `0x0000_0000`. This locks the AHB Bus out of Bank 0, handing it over to the hardware accelerators. It unlocks Bank 1 for the CPU.
2. **Triggering the FFT (AHB Write):**
   * **Address:** `0x4000_0C00` (Slave 3: FFT Control Register)
   * **Data Flow:** CPU writes `0x0000_0001` (Start Bit).
3. **FFT Hardware Processing (*Zero-Copy, Bypasses AHB Bus*):**
   * The FFT hardware directly reads and writes to the physical SRAM cells of **Bank 0** via its dedicated internal wires. **Zero data travels across the AHB bus** during this massive mathematical operation.
4. **Polling for FFT Completion (AHB Read):**
   * **Address:** `0x4000_0C00` (Slave 3: FFT Control Register)
   * **Data Flow:** The CPU continuously reads this address over the bus until bit 1 (Done Bit) becomes `1`.
5. **Bit-Reversal (AHB Read -> AHB Write):**
   * **Address:** `0x5000_0000` to `0x5000_07FC` (Slave 4: Ping-Pong RAM **Bank 0**)
   * **Data Flow:** The CPU reads two processed frequency samples, swaps them, and writes them back to Bank 0 to re-order the indices.
6. **Triggering the IFFT (AHB Write):**
   * **Address:** `0x6000_0C00` (Slave 5: IFFT Control Register)
   * **Data Flow:** CPU writes `0x0000_0001` (Start Bit). The IFFT directly crunches Bank 0 without using the bus.
7. **Polling for IFFT Completion (AHB Read):**
   * **Address:** `0x6000_0C00` (Slave 5: IFFT Control Register)
   * **Data Flow:** The CPU continuously reads this until bit 1 becomes `1`.
8. **Simultaneous Audio Output & Input Streaming:**
   * The CPU loops 512 times to play the finished audio and ingest the next frame:
   * **Output Flow (AHB Read -> AHB Write):**
     * **Read Address:** `0x5000_0000` to `0x5000_07FC` (Slave 4: Ping-Pong **Bank 0**) -> Reads the finished audio sample.
     * **Write Address:** `0x7000_0000` (Slave 6: I2S TX FIFO) -> Pushes the audio to the speaker.
   * **Input Flow (AHB Read -> AHB Write):**
     * **Read Address:** `0x2000_0000` (Slave 1: I2S RX FIFO) -> Pulls the next fresh audio sample from the microphone.
     * **Write Address:** `0x5000_0800` up to `0x5000_0FFC` (Slave 4: Ping-Pong RAM **Bank 1**) -> Stores the new sample in the other bank.
9. **Loop Restarts (AHB Write):**
   * **Address:** `0x5000_1000` (Slave 4: Ping-Pong Control Register)
   * **Data Flow:** CPU writes `0x0000_0001`. This locks Bank 1 to the hardware, unlocks Bank 0 for the CPU, and the cycle repeats instantly.
