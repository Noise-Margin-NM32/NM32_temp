`timescale 1ns / 1ps

module tb;

    // ---------------------------------------------------------
    // 1. Core Signals
    // ---------------------------------------------------------
    reg clk;
    reg rstn;

    // ---------------------------------------------------------
    // 2. Loopback Wires
    // ---------------------------------------------------------
    wire [1-1:0] rx_ws;
    wire [1-1:0] rx_sck;
    wire [1-1:0] sdi;
    
    wire [1-1:0] tx_ws;
    wire [1-1:0] tx_sck;
    wire [1-1:0] sdo;

    assign rx_ws  = tx_ws;
    assign rx_sck = tx_sck;

    reg [31:0] audio_in_mem [0:2047];
    integer sample_idx = 0;
    integer bit_idx = 31;
    reg sdi_reg = 0;
    assign sdi = sdi_reg;

    initial begin
        $readmemh("/home/r_sarang/NM32_SoC/audio_in.txt", audio_in_mem);
    end

    // Robust Synchronous I2S Serializer
    reg last_ws_reg = 1'b1;
    reg [31:0] shift_reg = 32'h0;
    
    always @(negedge rx_sck) begin
        last_ws_reg <= rx_ws;
        
        if (last_ws_reg == 1'b1 && rx_ws == 1'b0) begin
            // Detect falling edge of ws -> load new sample
            shift_reg <= audio_in_mem[sample_idx];
            $display("Time=%0t: [SERIALIZER] Loaded sample_idx=%d, val=0x%08h", $time, sample_idx, audio_in_mem[sample_idx]);
            if (sample_idx < 2047) begin
                sample_idx <= sample_idx + 1;
            end
            sdi_reg <= 1'b0; // 1-cycle standard delay
        end else if (rx_ws == 1'b0) begin
            // Shift out MSB
            sdi_reg <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
        end else begin
            sdi_reg <= 1'b0;
        end
    end

    // ---------------------------------------------------------
    // 3. Device Under Test (DUT) Instantiation
    // ---------------------------------------------------------
    nm32_top dut (
        .clk(clk),
        .rstn(rstn),
        
        // I2S RX Ports (Listening)
        .rx_ws(rx_ws),
        .rx_sck(rx_sck),
        .sdi(sdi),
        
        // I2S TX Ports (Driving)
        .tx_ws(tx_ws),
        .tx_sck(tx_sck),
        .sdo(sdo)
    );

    // ---------------------------------------------------------
    // 4. Clock Generation (100MHz)
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        // The #5 delay prevents the SIGSEGV crash! (10ns period = 100MHz)
        forever #5 clk = ~clk; 
    end

    // ---------------------------------------------------------
    // 5. Reset Sequence and Safety Timeout
    // ---------------------------------------------------------
    initial begin
        // Hold reset low to clear all registers
        rstn = 0;
        
        // Wait 100ns, then release reset
        #100;
        rstn = 1;

        // --- SAFETY TIMEOUT ---
        // Because your C code ends in an infinite while(1) loop, 
        // the simulation will run forever if you click "Run All".
        // This command forces Vivado to stop after 1 millisecond.
        // (1 ms is plenty of time for a 100MHz CPU to run the test)
        // --- SAFETY TIMEOUT ---
        #48000000; // 48.0ms (4,800,000 cycles at 100MHz)
        
        $display("--------------------------------------------------");
        $display(" Simulation reached timeout and finished safely.");
        $display(" Check your waveforms!");
        $display("--------------------------------------------------");
        $finish;
    end


    // ---------------------------------------------------------
    // 6. CPU Instruction & Memory Tracer
    // ---------------------------------------------------------
    // ---------------------------------------------------------
    // 6. CPU Instruction & Memory Tracer
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (dut.cpu_mem_valid && dut.cpu_mem_ready) begin
            if (dut.cpu_mem_wstrb != 4'b0000) begin
                if (dut.cpu_mem_addr[31:28] == 4'h2 || dut.cpu_mem_addr[31:28] == 4'h3 || dut.cpu_mem_addr[31:28] == 4'h4 || dut.cpu_mem_addr[31:28] == 4'h6) begin
                    if (dut.cpu_mem_addr == 32'h20000000 && dut.cpu_mem_wstrb == 4'b0000) $display("Time=%0t: [CPU READ] I2S_RX_DATA = 0x%08h", $time, dut.cpu_mem_rdata);
                    $display("Time=%0t: [CPU WRITE] Addr=0x%08h, Data=0x%08h, Wstrb=%b", $time, dut.cpu_mem_addr, dut.cpu_mem_wdata, dut.cpu_mem_wstrb);
                end
            end else begin
                if (dut.cpu_mem_addr[31:28] == 4'h2 || dut.cpu_mem_addr[31:28] == 4'h3 || dut.cpu_mem_addr[31:28] == 4'h4 || dut.cpu_mem_addr[31:28] == 4'h6) begin
                    if (dut.cpu_mem_addr == 32'h20000000 && dut.cpu_mem_wstrb == 4'b0000) $display("Time=%0t: [CPU READ] I2S_RX_DATA = 0x%08h", $time, dut.cpu_mem_rdata);
                    $display("Time=%0t: [CPU READ ] Addr=0x%08h, Data=0x%08h", $time, dut.cpu_mem_addr, dut.cpu_mem_rdata);
                end
            end
        end
    end
    // I2S Tracer
    always @(posedge clk) begin
        if (dut.i2s_tx_apb.instance_to_wrap.fifo_wr) begin
            $display("Time=%0t: [I2S TX FIFO WRITE] Data=0x%08h", $time, dut.i2s_tx_apb.instance_to_wrap.fifo_wdata);
        end
        if (dut.i2s_tx_apb.instance_to_wrap.fifo_rd_int) begin
            $display("Time=%0t: [I2S TX FIFO READ] Data=0x%08h", $time, dut.i2s_tx_apb.instance_to_wrap.fifo_rdata);
        end
        if (dut.i2s_apb.instance_to_wrap.fifo_wr) begin
            $display("Time=%0t: [I2S RX FIFO WRITE] Data=0x%08h", $time, dut.i2s_apb.instance_to_wrap.fifo_wdata);
        end
    end

    // Track WS and SCK toggles to verify clock generation
    always @(edge rx_sck) begin
        $display("Time=%0t: [I2S SCK EDGE] sck=%b, ws=%b, sdo=%b, sdi=%b", $time, rx_sck, rx_ws, sdo, sdi);
    end
    always @(edge rx_ws) begin
        $display("Time=%0t: [I2S WS EDGE] sck=%b, ws=%b, sdo=%b, sdi=%b", $time, rx_sck, rx_ws, sdo, sdi);
    end

    // Monitor APB bridge transactions
    always @(posedge clk) begin
        if (dut.bridge.p_selx || dut.bridge.p_enable || dut.bridge.state != 0) begin
            $display("Time=%0t: [BRIDGE] state=%d sel=%b en=%b addr=0x%08h wdata=0x%08h rdata=0x%08h write=%b h_ready_out=%b h_rdata=0x%08h rx_fifo_rdata=0x%08h rx_empty=%b rx_fifo_rd=%b",
                $time,
                dut.bridge.state,
                dut.bridge.p_selx,
                dut.bridge.p_enable,
                dut.bridge.p_addr,
                dut.bridge.p_wdata,
                dut.bridge.p_rdata,
                dut.bridge.p_write,
                dut.bridge.h_ready_out,
                dut.bridge.h_rdata,
                dut.i2s_apb.instance_to_wrap.fifo_rdata,
                dut.i2s_apb.instance_to_wrap.fifo_empty,
                dut.i2s_apb.instance_to_wrap.fifo_rd
            );
        end
    end

    // ---------------------------------------------------------
    // 6b. Cycle-by-Cycle CPU-AHB Debug Tracer
    // ---------------------------------------------------------
    integer cycle_count = 0;
    always @(posedge clk) begin
        if (dut.cpu_mem_addr[31:16] == 16'h2000 || dut.cpu_mem_addr[31:16] == 16'h2001) begin
            $display("Time=%0t | rstn=%b | wrapper_state=%b valid=%b ready=%b addr=0x%h | htrans=%b haddr=0x%h hready_out=%b | rom_sel=%b rom_ready=%b rom_laddr=0x%h rom_rdata=0x%h",
                $time, rstn,
                dut.wrapper.state, dut.cpu_mem_valid, dut.cpu_mem_ready, dut.cpu_mem_addr,
                dut.cpu_htrans, dut.cpu_haddr, dut.cpu_hready,
                dut.boot_rom_HSEL, dut.boot_rom.HREADY, dut.boot_rom.latched_addr, dut.boot_rom.HRDATA);
            cycle_count = cycle_count + 1;
        end
    end

    // ---------------------------------------------------------
    // 7. Auto-Verification and Frame Dumping Logic
    // ---------------------------------------------------------
    integer outfile_fft;
    integer outfile_ifft;
    integer f_idx;
    initial begin
        outfile_fft = $fopen("/home/r_sarang/NM32_SoC/fft_out.txt", "w");
        outfile_ifft = $fopen("/home/r_sarang/NM32_SoC/ifft_out.txt", "w");
    end

    always @(posedge clk) begin
        if (dut.sram0.SRAM_0.EN && ~dut.sram0.SRAM_0.R_WB) begin
            if (dut.sram0.SRAM_0.AD == 10'd65) begin
                if (dut.sram0.SRAM_0.DI == 32'h11111111 || 
                    dut.sram0.SRAM_0.DI == 32'h22222222 || 
                    dut.sram0.SRAM_0.DI == 32'h33333333 || 
                    dut.sram0.SRAM_0.DI == 32'h55555555) begin
                    
                    $display("Time=%0t: [TESTBENCH] Handshake 0x%08h detected. Dumping current FFT frame to fft_out.txt and IFFT frame to ifft_out.txt...", $time, dut.sram0.SRAM_0.DI);
                    
                    for (f_idx = 0; f_idx < 512; f_idx = f_idx + 1) begin
                        // Dump FFT outputs directly from the FFT engine's internal data RAM
                        $fdisplay(outfile_fft, "%08X", dut.fft_wrapper_inst.fft_engine.data_ram.ram[f_idx]);
                        // Dump IFFT outputs (stored at SRAM offset 0-511)
                        $fdisplay(outfile_ifft, "%08X", dut.sram0.SRAM_0.mem[f_idx]);
                    end
                    
                    if (dut.sram0.SRAM_0.DI == 32'h55555555) begin
                        $display("Time=%0t: [TESTBENCH] Frame 4 completed. Verification simulation successful!", $time);
                        $fclose(outfile_fft);
                        $fclose(outfile_ifft);
                        $finish;
                    end
                end
            end
        end
    end

endmodule