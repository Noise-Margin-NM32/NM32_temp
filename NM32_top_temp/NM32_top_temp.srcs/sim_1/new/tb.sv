//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : tb
// Purpose : Full-chip testbench for nm32_top (Ibex CPU).
//           - I2S: TX clocks are looped back to RX, and a serializer plays
//             firmware/audio_in.txt into the RX data pin (the "microphone").
//           - SPI: behavioural flash model (Flash/flash.v) on CS0 supplies the
//             firmware image the bootloader copies into SRAM.
//           - Checks (each ends the run with a message):
//               [TRAP]     firmware trap_dump (start.S) wrote mcause/mepc/mtval
//               [WATCHDOG] no instruction fetch completed for 20 ms
//               [XCHECK]   X on Ibex instr/data read data
//           - Outputs (written to the simulator run directory, for XSim:
//             NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim/):
//               audio_out.txt  every word written to the I2S TX FIFO
//               fft_out.txt    accelerator bank at each FFT DONE (512 words
//                              per frame, bit-reversed layout, all frames)
//               ifft_out.txt   same at each IFFT DONE (time-domain frame)
//               fft_in.txt / ifft_in.txt  the bank as each FFT / IFFT starts
// Defines : NM32_FAST_BOOT - backdoor-load firmware_flash.hex into SRAM and
//                            NOP the bootloader call at ROM 0x88 (saves ~13 ms)
//           NM32_TRACE     - verbose debug tracing (tb + RTL)
//==========================================================================
`timescale 1ns / 1ps

module tb;
    reg clk;
    reg rstn;

    // ---------------------------------------------------------------------
    // 1. Chip-level wires
    // ---------------------------------------------------------------------
    wire rx_ws, rx_sck, sdi;       // I2S RX (into the SoC)
    wire tx_ws, tx_sck, sdo;       // I2S TX (out of the SoC)

    wire       spi_clk;
    wire [3:0] spi_csn;
    wire [1:0] spi_mode;
    wire [3:0] spi_sdo;
    wire [3:0] spi_sdi;

    wire [7:0] gpio_in = 8'h00;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;

    // I2S TX word-select / bit clock are reused for the RX side.
    assign rx_ws  = tx_ws;
    assign rx_sck = tx_sck;

    // ---------------------------------------------------------------------
    // 2. I2S microphone model
    //    On each falling edge of WS (start of the left slot) load the next
    //    32-bit sample, then shift it out MSB-first after the standard
    //    1-bit I2S delay. The right slot is sent as zeros. The last sample
    //    repeats once the 4096-entry input file is exhausted.
    // ---------------------------------------------------------------------
    reg  [31:0] audio_in_mem [0:4095];
    integer     sample_idx  = 0;
    reg         sdi_reg     = 1'b0;
    reg         last_ws_reg = 1'b1;
    reg  [31:0] shift_reg   = 32'h0;

    assign sdi = sdi_reg;

    initial $readmemh("./../../../../../firmware/audio_in.txt", audio_in_mem);

    always @(negedge rx_sck) begin
        last_ws_reg <= rx_ws;

        if (last_ws_reg == 1'b1 && rx_ws == 1'b0) begin
            shift_reg <= audio_in_mem[sample_idx];
`ifdef NM32_TRACE
            $display("Time=%0t: [SERIALIZER] Loaded sample_idx=%0d, val=0x%08h", $time, sample_idx, audio_in_mem[sample_idx]);
`endif
            if (sample_idx < 4095) sample_idx <= sample_idx + 1;
            sdi_reg <= 1'b0;                          // 1-bit I2S delay
        end else if (rx_ws == 1'b0) begin
            sdi_reg   <= shift_reg[31];               // left slot: data
            shift_reg <= {shift_reg[30:0], 1'b0};
        end else begin
            sdi_reg <= 1'b0;                          // right slot: silence
        end
    end

    // ---------------------------------------------------------------------
    // 3. DUT + external SPI flash
    // ---------------------------------------------------------------------
    nm32_top dut (
        .clk      (clk),
        .rstn     (rstn),
        .rx_ws    (rx_ws),
        .rx_sck   (rx_sck),
        .sdi      (sdi),
        .tx_ws    (tx_ws),
        .tx_sck   (tx_sck),
        .sdo      (sdo),
        .spi_clk  (spi_clk),
        .spi_csn  (spi_csn),
        .spi_mode (spi_mode),
        .spi_sdo  (spi_sdo),
        .spi_sdi  (spi_sdi),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );

    flash flash_inst (
        .sck (spi_clk),
        .csn (spi_csn[0]),     // flash on chip-select 0
        .sdo (spi_sdo[0]),     // SoC MOSI -> flash
        .sdi (spi_sdi[0])      // flash -> SoC MISO
    );

`ifdef NM32_FAST_BOOT
    // Runs after the memories' own time-0 initial blocks.
    initial begin
        #1;
        $readmemh("./../../../../../firmware/firmware_flash.hex", dut.sram0.mem);
        dut.boot_rom.memory[32'h88 >> 2] = 32'h00000013;   // NOP the bootloader call
        $display("Time=%0t: [TESTBENCH] FAST BOOT: firmware backdoor-loaded into SRAM", $time);
    end
`endif

    // ---------------------------------------------------------------------
    // 4. Clock (100 MHz), reset and safety timeout
    // ---------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rstn = 0;
        #100;
        rstn = 1;

        #800000000;            // 800 ms
        $display("Time=%0t: [TESTBENCH] Timeout reached, stopping.", $time);
        $finish;
    end

    // ---------------------------------------------------------------------
    // 5. SRAM mailbox monitor (AHB data phase)
    //    The address phase is registered; HWDATA is sampled when the data
    //    phase completes (HREADY high).
    // ---------------------------------------------------------------------
    reg        mb_pend;
    reg [31:0] mb_addr;
    reg        mb_valid;     // pulses for one clk with a completed SRAM write
    reg [31:0] mb_wr_addr;
    reg [31:0] mb_wr_data;

    always @(posedge clk) begin
        mb_valid <= 1'b0;
        if (!rstn) begin
            mb_pend <= 1'b0;
        end else if (dut.sram_HREADY) begin
            if (mb_pend) begin
                mb_valid   <= 1'b1;
                mb_wr_addr <= mb_addr;
                mb_wr_data <= dut.sram_HWDATA;
            end
            mb_pend <= dut.sram_HSEL && dut.sram_HWRITE && dut.sram_HTRANS[1];
            mb_addr <= dut.sram_HADDR;
        end
    end

    // ---------------------------------------------------------------------
    // 6. Health checks and progress log
    // ---------------------------------------------------------------------
    // Trap dump from start.S: 0x3000_7F20 mcause, 7F24 mepc, 7F28 mtval.
    reg [31:0] trap_mcause, trap_mepc;
    always @(posedge clk) begin
        if (mb_valid && mb_wr_addr == 32'h30007F20) trap_mcause <= mb_wr_data;
        if (mb_valid && mb_wr_addr == 32'h30007F24) trap_mepc   <= mb_wr_data;
        if (mb_valid && mb_wr_addr == 32'h30007F28) begin
            $display("Time=%0t: [TRAP] mcause=0x%08h mepc=0x%08h mtval=0x%08h", $time, trap_mcause, trap_mepc, mb_wr_data);
            $finish;
        end
    end

    // Watchdog: some instruction fetch completes at least every 20 ms
    // (generous: wfi legitimately stops fetching while waiting for an IRQ).
    integer last_insn_time = 0;
    always @(posedge clk) begin
        if (dut.instr_rvalid)
            last_insn_time = $time;
        if ($time - last_insn_time > 20000000) begin      // ns
            $display("Time=%0t: [WATCHDOG] CPU stuck! No instruction fetch for 20ms! Last at %0t, fetch addr 0x%08h.", $time, last_insn_time, dut.instr_addr);
            $finish;
        end
    end

    // X check on the read data Ibex consumes.
    reg data_is_write;       // write flag of the data-port access in flight
    // Granted fetch addresses, oldest first, so an X response is reported
    // against the address it belongs to (Ibex keeps up to 2 in flight).
    reg [31:0] fq [0:3];
    reg [1:0]  fq_wr = 0, fq_rd = 0;
    always @(posedge clk) begin
        if (dut.data_gnt) data_is_write <= dut.data_we;
        if (dut.instr_req && dut.instr_gnt) begin fq[fq_wr] <= dut.instr_addr; fq_wr <= fq_wr + 1; end
        if (dut.instr_rvalid) fq_rd <= fq_rd + 1;
        if (rstn) begin
            if ($isunknown({dut.instr_gnt, dut.instr_rvalid, dut.instr_err,
                            dut.data_gnt, dut.data_rvalid, dut.data_err,
                            dut.clic_irq_valid})) begin
                $display("Time=%0t: [XCHECK] X on Ibex handshake/irq: igt=%b irv=%b ier=%b dgt=%b drv=%b der=%b irq=%b",
                         $time, dut.instr_gnt, dut.instr_rvalid, dut.instr_err,
                         dut.data_gnt, dut.data_rvalid, dut.data_err, dut.clic_irq_valid);
                $finish;
            end
            if (dut.instr_rvalid && $isunknown(dut.instr_rdata)) begin
                $display("Time=%0t: [XCHECK] X on instr_rdata, fetch addr 0x%08h (current request 0x%08h)", $time, fq[fq_rd], dut.instr_addr);
                $finish;
            end
            if (dut.data_rvalid && !data_is_write && $isunknown(dut.data_rdata)) begin
                $display("Time=%0t: [XCHECK] X on data_rdata, data addr 0x%08h", $time, dut.data_addr);
                $finish;
            end
        end
    end

    // X instruction reaching Ibex decode. Stops at the first occurrence (Ibex's
    // own assertions would otherwise flood the log every cycle) and prints the
    // last 8 completed instruction fetches.
    reg [31:0] fetch_addr_q;                 // address of the fetch in flight
    reg [31:0] fh_addr [0:7];
    reg [31:0] fh_data [0:7];
    integer    fh_i;
    always @(posedge clk) begin
        if (dut.instr_gnt) fetch_addr_q <= dut.instr_addr;
        if (dut.instr_rvalid) begin
            for (fh_i = 7; fh_i > 0; fh_i = fh_i - 1) begin
                fh_addr[fh_i] <= fh_addr[fh_i-1];
                fh_data[fh_i] <= fh_data[fh_i-1];
            end
            fh_addr[0] <= fetch_addr_q;
            fh_data[0] <= dut.instr_rdata;
        end
        // First X written into the register file (usual root cause of later
        // "X branch decision" / "X operand" assertions inside Ibex).
        if (rstn && dut.ibex_rf_we_wb && dut.ibex_rf_waddr_wb != 5'd0 &&
            $isunknown(dut.ibex_rf_wdata_wb)) begin
            $display("Time=%0t: [XCHECK] X written to x%0d, pc_id=0x%08h (data port addr=0x%08h)",
                     $time, dut.ibex_rf_waddr_wb, dut.u_ibex_core.id_stage_i.pc_id_i, dut.data_addr);
            for (fh_i = 7; fh_i >= 0; fh_i = fh_i - 1)
                $display("        fetch[-%0d] addr=0x%08h data=0x%08h", fh_i, fh_addr[fh_i], fh_data[fh_i]);
            $finish;
        end
        if (rstn && dut.u_ibex_core.id_stage_i.instr_valid_i &&
            $isunknown(dut.u_ibex_core.id_stage_i.instr_rdata_i)) begin
            $display("Time=%0t: [XCHECK] X instruction in decode, pc_id=0x%08h instr=0x%08h",
                     $time, dut.u_ibex_core.id_stage_i.pc_id_i, dut.u_ibex_core.id_stage_i.instr_rdata_i);
            for (fh_i = 7; fh_i >= 0; fh_i = fh_i - 1)
                $display("        fetch[-%0d] addr=0x%08h data=0x%08h", fh_i, fh_addr[fh_i], fh_data[fh_i]);
            $finish;
        end
    end

    // Accelerator / ping-pong register traffic (0x4000_0000-0x6FFF_FFFF),
    // logged when the data-port access completes. 0x50001000 = PING_PONG_CTRL,
    // 0x40000C00 / 0x60000C00 = FFT / IFFT CTRL.
    reg [31:0] acc_addr, acc_wdata;
    reg [3:0]  acc_be;
    reg        acc_we;
    always @(posedge clk) begin
        if (dut.data_gnt) begin
            acc_addr  <= dut.data_addr;
            acc_we    <= dut.data_we;
            acc_be    <= dut.data_be;
            acc_wdata <= dut.data_wdata;
        end
        if (dut.data_rvalid && acc_addr >= 32'h40000000 && acc_addr < 32'h70000000)
            $display("Time=%0t: [ACCEL ACCESS] Addr=0x%08h Write=%b Data=0x%08h Wstrb=%b",
                     $time, acc_addr, acc_we, acc_we ? acc_wdata : dut.data_rdata, acc_we ? acc_be : 4'b0000);
    end

    // ---------------------------------------------------------------------
    // 7. Output capture
    // ---------------------------------------------------------------------
    integer outfile_fft;
    integer outfile_ifft;
    integer outfile_audio;
    integer f_idx;

    initial begin
        outfile_fft   = $fopen("./fft_out.txt",   "w");
        outfile_ifft  = $fopen("./ifft_out.txt",  "w");
        outfile_audio = $fopen("./audio_out.txt", "w");
    end

    // Speaker output: every sample pushed into the I2S TX FIFO.
    always @(posedge clk) begin
        if (dut.i2s_tx_apb.instance_to_wrap.fifo_wr)
            $fdisplay(outfile_audio, "%08X", dut.i2s_tx_apb.instance_to_wrap.fifo_wdata);
    end

    // Microphone sanity check: the first few samples entering the I2S RX FIFO.
    integer rx_seen = 0;
    always @(posedge clk) begin
        if (dut.i2s_apb.instance_to_wrap.fifo_wr && rx_seen < 6) begin
            $display("Time=%0t: [I2S RX] fifo_wdata=0x%08h", $time, dut.i2s_apb.instance_to_wrap.fifo_wdata);
            rx_seen = rx_seen + 1;
        end
    end

    // Accelerator result dumps (all frames, 512 words each, appended):
    //   fft_out.txt   bank owned by the accelerators when FFT DONE rises
    //                 (raw spectrum, bit-reversed layout as the HW left it)
    //   ifft_out.txt  same, when IFFT DONE rises (time-domain frame)
    task dump_accel_bank(input integer fd);
        for (f_idx = 0; f_idx < 512; f_idx = f_idx + 1)
            $fdisplay(fd, "%08X", dut.scratchpad_sram.accel_bank_sel ?
                                  dut.scratchpad_sram.bank1[f_idx] :
                                  dut.scratchpad_sram.bank0[f_idx]);
    endtask

    // fft_in.txt / ifft_in.txt: the bank as each accelerator starts (its
    // input), so tools/check_fft.py can check every frame against NumPy.
    integer outfile_fft_in, outfile_ifft_in;
    initial begin
        outfile_fft_in  = $fopen("./fft_in.txt",  "w");
        outfile_ifft_in = $fopen("./ifft_in.txt", "w");
    end

    reg fft_irq_q = 1'b0, ifft_irq_q = 1'b0, fft_busy_q = 1'b0, ifft_busy_q = 1'b0;
    always @(posedge clk) begin
        fft_irq_q   <= dut.fft_irq;
        ifft_irq_q  <= dut.ifft_irq;
        fft_busy_q  <= dut.fft_wrapper_inst.fft_busy;
        ifft_busy_q <= dut.ifft_wrapper_inst.ifft_busy;
        if (dut.fft_wrapper_inst.fft_busy   && !fft_busy_q)  dump_accel_bank(outfile_fft_in);
        if (dut.ifft_wrapper_inst.ifft_busy && !ifft_busy_q) dump_accel_bank(outfile_ifft_in);
        if (dut.fft_irq  && !fft_irq_q)  dump_accel_bank(outfile_fft);
        if (dut.ifft_irq && !ifft_irq_q) dump_accel_bank(outfile_ifft);
    end

    // Firmware -> testbench mailbox (main.c), SRAM 0x3000_7F00 (top 256 B,
    // above the stack): 0x2222_00NN after frame NN (logged), 0x5555_5555
    // when all frames are done (ends the run).
    always @(posedge clk) begin
        if (mb_valid && mb_wr_addr == 32'h30007F00) begin
            if (mb_wr_data[31:16] == 16'h2222 && mb_wr_data != 32'h22222222)
                $display("Time=%0t: [TESTBENCH] Frame %0d done", $time, mb_wr_data[15:0]);

            if (mb_wr_data == 32'h55555555) begin
                $display("Time=%0t: [TESTBENCH] Simulation successful!", $time);
                $fclose(outfile_fft);
                $fclose(outfile_ifft);
                $fclose(outfile_fft_in);
                $fclose(outfile_ifft_in);
                $fclose(outfile_audio);
                $finish;
            end
        end
    end

endmodule
