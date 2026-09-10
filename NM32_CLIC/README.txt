Here is the updated step-by-step transaction flow, adjusted for the optimized **16-channel architecture** and incorporating the exact new memory-mapped register addresses.

---

### Step 1: The Peripheral Fires (Direct Wire)

* **Action:** An audio peripheral (e.g., your I2S DMA buffer fills up with microphone data) pulls its dedicated interrupt line **High**.
* **CLIC State:** Inside the CLIC, the wire goes straight to the input array `intr_src_i[0]`. On the next clock cycle (`posedge hclk`), the combinational logic latches this electrical high signal into bit `0` of the **`ip_reg`** (Interrupt Pending Register).
* **Result:** The pending flag is now set (`ip_reg[0] = 1`), meaning the CLIC remembers the event even if the peripheral line drops later.

---

### Step 2: Hardware Arbitration & Threshold Evaluation (CLIC Internal Logic)

* **Mask Check:** The CLIC performs a bitwise `AND` between `ip_reg` and `ie_reg` (Interrupt Enable). Assuming the CPU software previously unmasked this channel (`ie_reg[0] = 1`), the interrupt moves to the encoder.
* **Priority Matching:** The combinational loop looks up the value inside `prio_reg[0]`. Because it has the highest priority value out of all active requests (e.g., programmed to max urgency `3'b111` or level 7), it wins the internal 16-channel arbitration.
* **Threshold Gate:** The CLIC evaluates the winner: Is the winning priority (`7`) strictly greater than the current **`threshold_reg`**?
* **Preemption Floor:** If the CPU is currently running low-priority background code (threshold is `0`), the check passes ($7 > 0$).
* **Signal Core:** The CLIC pulls the handshake wire **`irq_valid_o` High** and exposes the 4-bit binary ID (`irq_id_o = 4'd0`) and level (`irq_level_o = 3'd7`) directly to the CPU core ports.

---

### Step 3: The CPU Takes the Trap (Hardware Handshake)

* **Core Action:** The CPU finishes its executing instruction, sees `irq_valid_o` is high, and accepts the trap.
* **Vectored Jump:** The CPU reads `irq_id_o` (`0`), multiplies it by 4 bytes, adds it to its internal vector base pointer register, and forces that target address directly into its Program Counter (PC).
* **Result:** The CPU automatically context-switches, instantly jumping directly into your specific `i2s_rx_isr` function code.

---

### Step 4: The CPU Acknowledges and Clears the Source (AHB Bus Cycle)

Once the CPU executes your interrupt handling code, it must clear the pending status so the loop doesn't trigger infinitely. This is where your 32-bit **AHB-Lite bus interface** activates.

#### Phase A: Address Phase (`hclk` Cycle 1)

* The CPU instruction pipeline issues a store/write command targeting the CLIC's pending register address (**Base Offset `0x80**`).
* On the bus fabric:
* `hsel_i` goes **High** (selecting this CLIC module).
* `htrans_i` goes to `2'b10` (NONSEQ, indicating a valid transaction start).
* `hwrite_i` goes **High** (indicating a write operation).
* `haddr_i` points to the `ip_reg` memory offset (`BASE_ADDR + 32'h0000_0080`).


* **CLIC Action:** At the rising edge of the clock, the CLIC decodes the address. `haddr_i[8:2]` yields `7'h20`. The CLIC latches `hwrite_i` into `reg_write_phase` and stores `7'h20` in `reg_addr_latched`. It asserts `hready_o = 1` to indicate it requires zero wait-states.

#### Phase B: Data Phase (`hclk` Cycle 2)

* The CPU puts the clearing bitmask data onto the **`hwdata_i`** bus. To clear channel 0, it writes a `0` to bit 0.
* **CLIC Action:** Because `reg_write_phase` is active and `reg_addr_latched` matches the scaled `ip_reg` offset (`7'h20`), the internal flip-flop logic updates:
```systemverilog
ip_reg <= hwdata_i[15:0]; // Bit 0 becomes 0

```


* **Result:** The pending status is officially cleared in hardware.

---

### Step 5: System Resets to Normal

* Because `ip_reg[0]` is now `0`, the priority encoder drops its winning request.
* The CLIC drops `irq_valid_o` back to **Low**.
* The CPU completes the function, executes an `mret` (Machine Return) command, and returns seamlessly to processing your main audio filtration mathematics block until the next buffer fills up and the cycle repeats.

---

### Summary of Register Mapping Addresses for Software Reference

When you write software to control or clear this controller via the AHB bus, configure your pointers using these exact word-aligned offsets:

| Register Name | Offset Address | Function |
| --- | --- | --- |
| `prio_reg[0]` | `Base + 0x00` | Priority Configuration for Channel 0 |
| `prio_reg[1]` | `Base + 0x04` | Priority Configuration for Channel 1 |
| ... | ... | ... |
| `prio_reg[15]` | `Base + 0x3C` | Priority Configuration for Channel 15 |
| `ip_reg` | **`Base + 0x80`** | Interrupt Pending Status Mask (Read/Clear) |
| `ie_reg` | **`Base + 0x84`** | Interrupt Enable Control Mask (Read/Write) |
| `threshold_reg` | **`Base + 0x88`** | Active Preemption Threshold Floor (Read/Write) |

