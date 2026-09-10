# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

NM32 (codename "KAVACH") is a System-on-Chip (Verilog/SystemVerilog RTL) for real-time selective audio noise
suppression: a CPU-driven pipeline mixes an Ibex RV32I core, an AHB/APB bus matrix, custom FFT/IFFT accelerators,
and I2S audio I/O to filter out user-specified "trigger" sounds from a live microphone feed and play the filtered
audio back out. See `NM32_SoC_Spec_2.0.md` for the full functional spec, `DATAPATH.md` for the exact boot and
steady-state AHB address/data flow, and `STATUS.md` for what's implemented vs. pending.

This is a hardware project developed against Xilinx Vivado; there is no software package manager, linter, or test
runner in the conventional sense. Correctness is validated through RTL simulation.

## Architecture

### Bus topology
- **AHB** is the primary system bus (`ahb_decoder_and_arbiter/`, `AHB2APB/AHB_APB_Bridge.sv`) connecting the CPU,
  Boot ROM, FFT/IFFT accelerators, the Ping-Pong SRAM, and an AHB-to-APB bridge for lower-speed peripherals
  (GPIO, I2S, SPI, DMA config) reachable at `0x2000_0000+`.
- Top-level integration lives in `NM32_top_temp/NM32_top_temp.srcs/sources_1/new/NM32_top.sv` (module `nm32_top`),
  which instantiates the arbiter, all AHB slaves (Boot ROM, SRAM, FFT, IFFT, Ping-Pong scratchpad, CLIC), and the
  APB peripheral set, and wires the Ibex core in via `ibex_to_ahb.sv`.
- Fixed AHB slave address map (see `ADDR_LOW_FLAT`/`ADDR_HIGH_FLAT` in `NM32_top.sv` and `DATAPATH.md`): Boot ROM
  `0x0000_0000`, APB bridge `0x2000_0000`, SRAM `0x3000_0000`, FFT `0x4000_0000`, Ping-Pong scratchpad
  `0x5000_0000`, IFFT `0x6000_0000`, CLIC `0x7000_0000`.

### Zero-copy ping-pong architecture (the key design decision — read `STATUS.md` before changing dataflow)
The FFT/IFFT accelerators do **not** have internal data RAMs and do **not** move data over the AHB bus during
computation. They have a dedicated direct hardware link into a shared **Ping-Pong SRAM** (`sram/ping_pong_ram.v`),
split into Bank 0 / Bank 1 and toggled by a `PING_PONG_CTRL` register. While hardware computes in-place on one
bank, the CPU streams new I2S audio into the other bank — this is what makes the pipeline double-buffered and
avoids the bus-bottlenecked DMA-heavy design that was originally planned. When touching FFT/IFFT/SRAM code, keep
this zero-copy invariant intact rather than reintroducing AHB-mediated scratchpad copies.

Twiddle factors are **not** synthesized as a ROM; they are computed/stored as firmware constants and loaded into a
small internal twiddle RAM inside each accelerator over AHB during boot (see `firmware/`, `DATAPATH.md` Phase 1
step 3). Don't resurrect `twiddle_rom_512.v` as the source of truth for twiddle data — it's legacy.

### CPU core
- `Ibex/` is a vendored copy of lowRISC's Ibex RV32I(M) core (large upstream tree — treat it as a dependency, not
  something to refactor). Only `Ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv` currently carries local
  modifications for this project.
- `pico/` contains an alternative PicoRV32 core (`picorv32_ahb.v`) — legacy/experimental, not the active CPU in
  `NM32_top.sv`.

### Major functional blocks
- `FFT_Accelerator/`, `IFFT_Accelerator/` — 256-point FFT/IFFT hardware, folded-butterfly implementation, with an
  AHB wrapper (`nm32_fft_ahb_wrapper.v` / `nm32_ifft_ahb_wrapper.v`) exposing control/status registers and the
  twiddle RAM.
- `I2S/` — I2S RX/TX peripherals (mic in, speaker out), APB-attached.
- `DMA/`, `DMA_Module/` — DMA controller work; per `STATUS.md`, DMA integration into `NM32_top.sv` is still
  pending (channels for I2S↔Ping-Pong streaming), don't assume it's wired in yet.
- `ahb_decoder_and_arbiter/`, `AHB2APB/` — bus fabric.
- `GPIO/`, `wdt/`, `rv_plic/`, `Flash/`, `apb_spi_master-master/` — peripherals in varying states of integration;
  per `STATUS.md`, PLIC interrupt wiring, watchdog, GPIO, and SPI/external-flash boot are mostly not yet
  integrated into `NM32_top.sv` (CPU currently polls FFT/IFFT/I2S status registers rather than using interrupts).
- `sram/` — Boot ROM (`BOOT_ROM/boot_rom.v`) and the Ping-Pong SRAM.
- `firmware/` — the C/asm firmware image (bootloader + main + twiddle constants) that gets embedded into the Boot
  ROM / flash image consumed by simulation.

## Firmware build

```bash
cd firmware
make            # builds firmware.elf, then bootrom.hex / firmware_flash.hex / firmware.asm
make clean
```

Requires a `riscv64-unknown-elf-gcc` toolchain (RV32IM, `ilp32` ABI) on `PATH`. `bootrom.hex` and
`firmware_flash.hex` are the Verilog-readable hex images the RTL testbenches/Boot ROM load — regenerate them after
any firmware source change before re-running simulation.

## Running simulation

Primary simulation flow is Vivado XSim, driven from the `NM32_top_temp` Vivado project:

```bash
# From repo root, batch-mode simulation via Vivado's Tcl interpreter:
vivado -mode batch -source run_sim_tcl.tcl
```

`run_sim_tcl.tcl` opens `NM32_top_temp/NM32_top_temp.xpr`, launches simulation, and runs for 40ms. The testbench
is `NM32_top_temp/NM32_top_temp.srcs/sim_1/new/tb.sv` (plus `tb_monitor.sv`). Simulation reads `audio_in.txt`
(generate synthetic input audio with `python3 -c "import verify_fft; verify_fft.generate_audio_signal()"` if
missing) and writes `fft_out.txt` / `ifft_out.txt` to the repo root; verify results with `python3 verify_fft.py`
(requires matplotlib).

Alternatively, open `NM32_top_temp/NM32_top_temp.xpr` in the Vivado GUI and use Run Simulation.

There's also a Verilator-based coverage flow in `verilator_tb/`:

```bash
cd verilator_tb
./run_verilator.sh
```

This scrapes the file list straight out of the `.xpr` project file (excluding `tb.sv`/`old_tb.sv`), compiles
`verilator_tb.sv` as the top testbench, and produces a coverage report under `obj_dir/logs/`.

## Working conventions

- RTL is a mix of Verilog (`.v`) and SystemVerilog (`.sv`); vendored/third-party IP (`Ibex/`, `rv_plic/`,
  `apb_spi_master-master/`, `GPIO/` EF_GPIO8, `wdt/`) should be treated as upstream and left unmodified unless a
  local integration fix is specifically needed.
  - `.xpr`, `.jou`, `.log`, `.cache`, `.hw`, `.ip_user_files`, `.sim`, `.runs`, `.Xil/` are all Vivado-managed
  project state/artifacts, not hand-edited sources.
- When changing the AHB/APB address map, update it consistently in `NM32_top.sv` (`ADDR_LOW_FLAT`/`ADDR_HIGH_FLAT`,
  `SLAVE_ADDR_START`/`SLAVE_ADDR_END`) *and* `DATAPATH.md`/`NM32_SoC_Spec_2.0.md`, since firmware and testbenches
  hardcode these addresses.
