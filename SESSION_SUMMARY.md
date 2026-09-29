# Session Summary — Ibex Bring-Up Debug (branch `ibex`)

_Last updated: 2026-09-17_

## 1. Where this started

The branch `ibex` is integrating an Ibex RISC-V core into the NM32 SoC over a
shared AHB bus, on top of a previously-working "zero-copy" audio pipeline
(I2S → Ping-Pong RAM → FFT → CPU filtration → IFFT → I2S) that had **no
interrupts, no DMA, and CPU-polled I2S FIFOs**. This branch is actively
adding DMA and the Ibex CPU itself — it is mid-bugfix, not a clean/stopped
state. All work below happened in one continuous debugging session against a
Vivado xsim simulation of the full SoC + testbench (`tb.sv`).

The starting symptom (from an external planning doc,
`implementation_plan.md`, not in this repo): the simulation crashed at
**8.675 ms** with Ibex assertion failures (`IbexBranchDecisionValidKnownEnable`,
`IbexIdInstrKnownKnownEnable`) — the CPU was fetching/decoding unknown (`X`)
data.

## 2. Root cause #1 — DMA blasting an empty I2S FIFO (fixed)

**Diagnosis:** The DMA controller had no flow control. Given a "copy 512
samples" command, it blasted all 512 AHB reads back-to-back in ~15µs,
completely ignoring the 44.1kHz I2S sample rate. Since the I2S RX FIFO
couldn't fill that fast, the DMA read garbage (`X`/uninitialized) out of an
empty FIFO and wrote it into SRAM. The CPU later read that garbage, branched
on it, and Ibex's internal "known-value" assertions fired.

Additionally, the DMA held `HBUSREQ` high for the *entire* 512-word transfer,
which — if the I2S peripheral ever stalled the bus — could freeze the whole
SoC for milliseconds.

**Fix implemented — standard DMA Request (DREQ) handshaking:**

| File | Change |
|---|---|
| `DMA_Module/dma_controller.v` | Added a `DREQ` input pin and a new `WAIT_DREQ` FSM state. The DMA now transfers **one word at a time**: after `IDLE` (and after each `WRITE_DATA` beat), it enters `WAIT_DREQ`, drops `HBUSREQ`, and only re-requests the bus once `DREQ` pulses high. |
| `I2S/EF_I2S_APB.v` | Exposed the internal `fifo_empty`/`fifo_full` signals as new outputs `rx_fifo_empty` / `rx_fifo_full`. |
| `I2S/EF_I2S_TX_APB.v` | Exposed `tx_fifo_full_o` / `tx_fifo_empty_o` as new outputs. |
| `NM32_top_temp/.../NM32_top.sv` | Wired `dma_rx_inst.DREQ = ~i2s_rx_fifo_empty` and `dma_tx_inst.DREQ = ~i2s_tx_fifo_full`, so each DMA channel only takes the bus when its peripheral genuinely has data ready / room available. |

**Result:** this pushed the crash from 8.675 ms to (what first looked like)
20.5 ms — but closer inspection of the actual log showed the *first*
assertion now fires at **6.911355 ms**, and — critically — the simulation
**never stops**: the same ~10 assertion messages repeat every 10 ns forever
after that point, with no further testbench progress (no further
`[BENCHMARK]` or `[TESTBENCH]` output). So DREQ fixed the original failure
mode but exposed a second, different bug.

## 3. Root cause #2 — CPU bus starvation from concurrent DMA channels (fixed)

**Diagnosis:**
- Firmware (`firmware/main.c`, `pack_and_start_dma()` ~line 297-311) starts
  **both** `DMA_TX` (`ctrl=0x3`) and `DMA_RX` (`ctrl=0x5`) back-to-back every
  audio hop.
- After the DREQ fix, both DMA channels' `HBUSREQ` toggle on/off *very*
  frequently, because the I2S FIFOs are rarely fully empty/full while
  actively streaming — so both channels are requesting the bus almost
  continuously.
- `ahb_decoder_and_arbiter/ahb_arbiter.v` is a **sticky, non-fair
  round-robin arbiter**: 4 masters (`NUM_ARB_MSTS=4`) — master 0 = Ibex
  instruction fetch, master 1 = Ibex data, master 2 = `dma_rx_inst`, master 3
  = `dma_tx_inst`. It keeps re-granting whichever master currently owns the
  bus for as long as that master's own `HBUSREQ` stays asserted, and only
  rotates `turn` past a master when *that master's own request* drops. With
  DMA_RX and DMA_TX churning their requests against each other far more
  often than the CPU's fetch cadence interleaves, the round-robin could keep
  landing back on one DMA channel or the other indefinitely — **starving the
  CPU even though it was continuously requesting** — until Ibex's
  instruction-fetch interface stalled long enough to trip the X-propagation
  assertions.
- Confirmed safe to preempt: `dma_controller.v` does strictly single-beat
  NONSEQ transfers, dropping `HBUSREQ` every beat during `WAIT_DREQ` — so no
  in-flight AHB burst is ever cut off mid-stream by a preemption.

**Fix implemented — bounded anti-starvation override in the arbiter,**
contained entirely in `ahb_decoder_and_arbiter/ahb_arbiter.v` (no port/param
changes elsewhere):

1. Added `starve_cnt` (8-bit counter) + `STARVE_LIMIT = 64` cycles, and a
   `starved_others` flag (OR of every other master's `HBUSREQ`).
2. Widened the sticky-grant condition so it only holds while
   `!(starve_cnt >= STARVE_LIMIT && starved_others)` — once a master has
   held the bus for 64 cycles against a genuinely competing request, the
   existing round-robin fallback branch takes over (no new branch needed).
3. `starve_cnt` increments each cycle the same master keeps winning against
   a competing request, and resets to 0 whenever the grant actually
   rotates or nobody else is contending.
4. `turn` now also advances when a forced override switches the grant away
   from a master whose `HBUSREQ` is still high, so the preempted master
   doesn't immediately re-win the very next cycle.

This was syntax-checked standalone with `xvlog` (clean compile, no errors).

## 4. Simulation workflow fix — X-propagation watchdog (added)

**Problem noticed while re-testing fix #2:** re-running the sim to verify
the arbiter change is slow and hard to read. Investigation found:

- Boot is **already bypassed** for simulation speed —
  `NM32_top_temp/.../tb.sv:290-299` (commit `7f0bb78`) force-loads the
  compiled firmware straight into SRAM via `$readmemh` and patches boot ROM
  word 2 to a NOP, skipping the slow bit-banged SPI bootloader loop. Boot is
  not the bottleneck.
- The testbench has a **fixed, unconditional 800 ms (80,000,000-cycle)
  safety timeout** (`tb.sv:381`), sized to cover 4 full audio frames.
  Nothing previously detected that the sim had already gone wrong and
  stopped early.
- When the assertion storm hits, xsim doesn't stop — it re-prints the same
  ~10 error lines every 10 ns for the *rest* of the 800 ms window. This is
  why a broken run still took ~6 minutes of wall-clock time even though it
  had clearly already failed within the first few milliseconds: xsim was
  burning real I/O time on an unbounded stream of repeated error text.
- Waveform dumping was already mostly disabled from an earlier "Disabled for
  Speed" pass (`tb.sv` lines ~392-499, commented out) — not the bottleneck.
- `run_sim_tcl.tcl` / `test_sim.tcl` already run Vivado in scripted/batch
  mode, which is faster than the GUI's "Run Simulation" (which also opens a
  live waveform viewer) — but both scripts always ran the full 800 ms
  regardless of outcome.

**Fix implemented:** added an X-propagation watchdog directly in `tb.sv`
(new block right after the existing safety-timeout `initial` block, ~line
390-407). It watches the exact signals feeding Ibex's fetch/load interface
at the top level (`dut.instr_rvalid`/`dut.instr_rdata`,
`dut.data_rvalid`/`dut.data_rdata`) and calls `$finish` the instant either
goes unknown (`$isunknown`) while valid is asserted, printing one clear
diagnostic line (timestamp + whether it was a fetch or a data-load
corruption) instead of letting the sim grind through the rest of the 800 ms
window re-printing the same errors.

**Net effect:** a failing run should now end in well under a second of
wall-clock time with a single actionable line, instead of minutes of noisy
repeated output.

## 5. Housekeeping done along the way

- Deleted ~975 MB of stale Vivado log/journal clutter from the repo root
  (`vivado*.log`, `vivado_*.backup.log`, `.jou` files) — these were already
  covered by `.gitignore` and never at risk of being committed, just disk
  clutter from repeated Vivado GUI launches since Sep 10.

## 6. Current repo state (uncommitted)

Modified, not yet committed:
```
DMA_Module/dma_controller.v                              (DREQ + WAIT_DREQ)
I2S/EF_I2S_APB.v                                          (rx_fifo_empty/full outputs)
I2S/EF_I2S_TX_APB.v                                       (tx_fifo_full_o/empty_o outputs)
ahb_decoder_and_arbiter/ahb_arbiter.v                     (anti-starvation fix)
NM32_top_temp/.../sources_1/new/NM32_top.sv               (DREQ wiring)
NM32_top_temp/.../sim_1/new/tb.sv                         (X-propagation watchdog)
```
Also modified but **not touched by this session** (pre-existing local
changes, likely from earlier firmware/FFT work — worth checking before
committing):
```
firmware/bootloader.c, main.c, firmware.asm, and their build artifacts
(.o/.elf/.bin/.hex)
NM32_top_temp/NM32_top_temp.xpr
run_sim_tcl.tcl
```
Untracked: `test_sim.tcl`, `sim_output.txt`, `vivado_run.out`, and unrelated
resume files (`R_SARANG_RESUME.pdf`, `resume.*`).

Last simulation run (before the watchdog was added) reached 6.911355 ms and
then free-ran in an assertion storm for the remainder of the log we
captured — the arbiter fix and watchdog have **not yet been verified against
a fresh simulation run.**

## 7. How I think we should proceed

**Step 1 — Run the simulation and read the watchdog's verdict.**
This is the immediate next action and should be fast now. Three outcomes:

- **No watchdog message, sim reaches `"[TESTBENCH] Simulation successful!"`**
  → both fixes worked. Move to Step 2.
- **Watchdog fires, but much later than 6.9 ms** → progress; the starvation
  fix helped but something else (or a residual arbiter edge case) still
  stalls the CPU eventually. Worth checking `STARVE_LIMIT` isn't being
  masked by a different starvation path (e.g. a master outside the 4
  arbitrated ones, or a slave that never asserts `HREADY`).
- **Watchdog fires at roughly the same point (~6.9 ms)** → the arbiter fix
  didn't address the actual mechanism; re-open the hypothesis (possible
  candidates: `ibex_to_ahb.sv`'s retry-on-no-grant behavior interacting
  badly with the new preemption, or a slave — SRAM/AHB-APB bridge — that
  itself stalls `HREADY` long enough to matter independent of arbitration).

**Step 2 — Once one full pass-through succeeds, tighten verification.**
A single passing run isn't strong confidence for concurrent hardware
behavior. Recommend:
  - Re-run a couple of times (simulation is deterministic here since there's
    no randomization seed in play, so re-running mainly guards against
    having fixed only a symptom); more valuable is checking a **second
    scenario** — e.g. a shorter/longer `HOP` size or a burst of non-silent
    audio input — to make sure the fix isn't tuned to this exact timing.
  - Optionally probe `starve_cnt`/`master_sel` in the waveform during a
    healthy run to confirm CPU grants happen at bounded intervals under
    sustained dual-DMA load, as originally suggested in the arbiter fix
    plan — this is good evidence to keep even if not strictly required.

**Step 3 — Clean up and commit in logical chunks**, rather than one giant
commit, so the history stays useful:
  1. DMA/I2S DREQ handshaking (`dma_controller.v`, `EF_I2S_APB.v`,
     `EF_I2S_TX_APB.v`, the DREQ wiring in `NM32_top.sv`).
  2. AHB arbiter anti-starvation fix (`ahb_arbiter.v`).
  3. Testbench watchdog (`tb.sv`).
  - Separately: figure out what the pre-existing uncommitted
    firmware/`.xpr`/`run_sim_tcl.tcl` changes are (not from this session) —
    confirm whether they're finished work to commit alongside, or unrelated
    in-progress edits that should be reviewed on their own before deciding
    whether to bundle them in.

**Step 4 — Re-visit the "Pending" items from `STATUS.md`** now that DMA +
Ibex bring-up is closer to working: interrupts (CLIC/PLIC wiring — `clic.v`
exists but per the earlier survey isn't fully exercised yet), and SPI-flash
boot for a non-simulation (real hardware) boot path, since simulation
currently bypasses it entirely.

**Longer term / optional hardening**, not urgent:
  - The `STARVE_LIMIT = 64` constant is a reasonable first guess but
    untuned — if real audio timing margins are tight, it's worth sanity
    checking that 64 cycles of possible CPU delay per starvation event
    doesn't itself threaten I2S real-time deadlines under worst-case
    contention.
  - Consider whether `ibex_to_ahb.sv`'s retry-on-no-grant pattern (drops
    back to `ST_IDLE` and re-requests) could be simplified now that the
    arbiter guarantees bounded latency — not necessary, just a possible
    future simplification.
