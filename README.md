# NM32 SoC (KAVACH), `ibex` branch

NM32 is a RISC-V System-on-Chip for real-time selective audio noise suppression. A microphone stream comes in over
I2S. The CPU runs it through 512-point FFT/IFFT hardware accelerators, applies a spectral mask that removes the
selected "trigger" sounds, and streams the result back out over I2S.

On this branch the CPU is **Ibex** (lowRISC, RV32IMC), which replaces PicoRV32. The full audio pipeline runs
end-to-end in Vivado XSim.

## Status (2026-10-03)

| Item | State |
|---|---|
| Ibex boot (Boot ROM, then SPI flash, then SRAM) | Working |
| FFT, mask and IFFT pipeline, I2S RX and TX, DMA | Working. The sim ends with `Simulation successful` (~61.5 ms) |
| CLIC interrupt controller, GPIO, watchdog (EF_WDT32) | Integrated in RTL. Firmware still polls instead of using interrupts |
| Fresh-clone simulation in Vivado 2025.2 | Verified: no errors, traps or watchdog stops |
| **Known bug** | Frames 0-6 receive identical FFT input (input buffer not advancing). See `STATUS.md` |

## Architecture

**AHB masters**, which share one arbiter and one decoder:

| Master | Source |
|---|---|
| 0 | Ibex instruction port, via `ibex_to_ahb` |
| 1 | Ibex data port, via `ibex_to_ahb` |
| 2 | DMA |

**AHB slaves:**

| Slave | Address |
|---|---|
| APB bridge | `0x2000_0000` |
| SRAM (32 KB: code and data) | `0x3000_0000` |
| Boot ROM | `0x0000_0000` |
| FFT | `0x4000_0000` |
| Ping-pong scratchpad | `0x5000_0000` |
| IFFT | `0x6000_0000` |
| CLIC | `0x7000_0000` |

**APB peripherals:** I2S RX, I2S TX, SPI master (boot flash), DMA, GPIO and the watchdog. The exact addresses are
the `#define`s in `firmware/main.c`, and they must match `NM32_top.sv`.

### Key design points

- **Zero-copy ping-pong.** The FFT and IFFT have no internal data RAM. They compute in place on
  `sram/ping_pong_ram.v` through a dedicated port. `PING_PONG_CTRL` (`0x5000_1000`) decides which bank the hardware
  owns and which bank the CPU owns, so the CPU fills one bank while the accelerators work on the other.
- **Twiddle factors in firmware.** The twiddle factors are a `const` table in `main.c`. The CPU loads them into the
  accelerators at boot, so no twiddle ROM IP is needed.
- **One clock for all APB peripherals.** Every APB peripheral runs on `clk`. The bridge holds `PENABLE` for only one
  `clk` cycle, so a peripheral clocked on `pclk` drops writes and causes polling hangs.

### Boot flow

1. Ibex starts in the Boot ROM, which is loaded from `firmware/bootrom.hex`.
2. The bootloader copies the program from the SPI flash model (`firmware/firmware_flash.hex`) into SRAM.
3. It then jumps to `main()`.
4. `main()` loads the twiddle factors and runs the per-frame loop: I2S RX, FFT, mask, IFFT, I2S TX.

## How to run the simulation

```bash
git clone -b ibex git@github.com:Noise-Margin-NM32/NM32_temp.git
cd NM32_temp/NM32_top_temp
vivado -mode batch -source sim.tcl      # runs until $finish
```

- **GUI alternative:** open `NM32_top_temp/NM32_top_temp.xpr` and click **Run Simulation**, then **Run All**.
- **Input:** `firmware/audio_in.txt` (tracked in git) is fed in as the microphone signal.
- **Outputs:** written to `NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim/`:
  - `fft_in.txt` / `fft_out.txt`
  - `ifft_in.txt` / `ifft_out.txt`
  - `audio_out.txt`
- **Check the accelerators against NumPy:** run `python3 tools/check_fft.py` from the xsim directory.
- **Listen to the output:** `python3 NM32_top_temp/hex2wav.py audio_out.txt out.wav`.
- **Verbose debug traces:** add `-d NM32_TRACE` to the xvlog options.

### Rebuilding the firmware

```bash
cd firmware && make     # needs riscv64-unknown-elf-gcc
```

The build regenerates `bootrom.hex` and `firmware_flash.hex`, which the simulation loads. Rebuild after every
change to the firmware.

## Repository layout

| Path | Contents |
|---|---|
| `NM32_top_temp/` | Vivado project, top level `NM32_top.sv`, testbench `tb.sv` |
| `Ibex/` | Ibex core sources |
| `ahb_decoder_and_arbiter/`, `AHB2APB/` | Bus fabric |
| `FFT_Accelerator/`, `IFFT_Accelerator/` | FFT and IFFT accelerators |
| `sram/` | SRAM and ping-pong RAM |
| `I2S/`, `GPIO/`, `apb_spi_master-master/`, `DMA_Module/`, `wdt/`, `clic.v` | Peripherals |
| `BOOT_ROM/`, `Flash/` | Boot ROM and flash model |
| `firmware/` | Boot loader, `main.c`, linker script |
| `tools/` | Checking scripts |
| `legacy/` | Retired code, kept for reference |

More detail: `STATUS.md` (open issues), `DATAPATH.md` (per-frame flow) and `NM32_SoC_Spec_2.0.md` (spec).
