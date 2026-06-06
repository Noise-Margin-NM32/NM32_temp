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

    // The Physical Wire Loopback: 
    // TX drives the wires, RX listens to them.
    assign rx_ws  = tx_ws;
    assign rx_sck = tx_sck;
    assign sdi    = sdo;

    // ---------------------------------------------------------
    // 3. Device Under Test (DUT) Instantiation
    // ---------------------------------------------------------
    nm32_top dut (
        .clk(clk),
        .pclk(clk), // Assuming peripheral clock is the same as system clock
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
        #500000; // 500us (50,000 cycles at 100MHz)
        
        $display("--------------------------------------------------");
        $display(" Simulation reached timeout and finished safely.");
        $display(" Check your waveforms!");
        $display("--------------------------------------------------");
        $finish;
    end

    // ---------------------------------------------------------
    // 6. CPU Instruction & Memory Tracer (Commented out for clean simulation logs)
    // ---------------------------------------------------------
    /*
    always @(posedge clk) begin
        if (dut.cpu_mem_valid && dut.cpu_mem_ready) begin
            if (dut.cpu_mem_wstrb != 4'b0000) begin
                $display("Time=%0t: [CPU WRITE] Addr=0x%08h, Data=0x%08h, Wstrb=%b", $time, dut.cpu_mem_addr, dut.cpu_mem_wdata, dut.cpu_mem_wstrb);
            end else begin
                $display("Time=%0t: [CPU READ ] Addr=0x%08h, Data=0x%08h", $time, dut.cpu_mem_addr, dut.cpu_mem_rdata);
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
        if (dut.bridge.p_selx || dut.bridge.p_enable || dut.bridge.current_state != 0) begin
            $display("Time=%0t: [BRIDGE] state=%d sel=%b en=%b addr=0x%08h wdata=0x%08h rdata=0x%08h write=%b h_ready_out=%b h_rdata=0x%08h rx_fifo_rdata=0x%08h rx_empty=%b rx_fifo_rd=%b",
                $time,
                dut.bridge.current_state,
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
    */

    // ---------------------------------------------------------
    // 7. Auto-Verification and Finish Logic
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (dut.sram0.SRAM_0.EN && ~dut.sram0.SRAM_0.R_WB) begin
            if (dut.sram0.SRAM_0.AD == 10'd65 && dut.sram0.SRAM_0.DI == 32'h55555555) begin
                $display("--------------------------------------------------");
                $display(" >>> SUCCESS: SRAM test and I2S loopback PASSED! <<<");
                $display("--------------------------------------------------");
                $finish;
            end
            if (dut.sram0.SRAM_0.AD == 10'd65 && dut.sram0.SRAM_0.DI == 32'hFA11FA11) begin
                $display("--------------------------------------------------");
                $display(" >>> FAILURE: I2S loopback FAILED! <<<");
                $display("--------------------------------------------------");
                $finish;
            end
        end
    end

endmodule