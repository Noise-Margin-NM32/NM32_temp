`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2026 09:13:35 AM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb();
    reg clk = 0;
    reg pclk = 0;
    reg rstn = 0;

    wire [0:0] ws;
    wire [0:0] sck;
    reg [0:0] sdi = 0;
    wire [0:0] sdo;
    
    always #5 clk = ~clk;
    always #10 pclk = ~pclk;

    nm32_top dut (
        .clk(clk),
        .rstn(rstn),
        .pclk(pclk),
        .ws(ws),
        .sck(sck),
        .sdi(sdi),
        .sdo(sdo)
    );

    initial begin
        // Tell the simulator to record every single wire's voltage changes
        $dumpfile("soc_waveform.vcd");
        $dumpvars(0, tb);

        $display("--- Powering on NM32 SoC ---");
        
        // Hold reset low for a few clock cycles to stabilize the silicon
        #20;
        rstn = 1;
        $display("--- Reset released. CPU is fetching from ROM... ---");

        // Let the simulation run for 50,000 nanoseconds
        #50000;
        
        $display("--- Simulation complete ---");
        $finish;
    end
endmodule
