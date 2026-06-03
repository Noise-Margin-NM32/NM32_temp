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
    // assign rx_ws  = tx_ws;
    // assign rx_sck = tx_sck;
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
        #1000000; 
        
        $display("--------------------------------------------------");
        $display(" Simulation reached 1ms timeout and finished safely.");
        $display(" Check your waveforms!");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule