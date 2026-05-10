`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2026 04:50:54 PM
// Design Name: 
// Module Name: NM32_top
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


module nm32_top(
    input clk,
    input rst
);

// Pico signals
wire        mem_valid;
wire        mem_ready;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;
wire [31:0] mem_rdata;

// Instantiate Pico
picorv32 cpu (
    .clk(clk),
    .resetn(~rst),

    .mem_valid(mem_valid),
    .mem_ready(mem_ready),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata)
);

// SIMPLE MEMORY (TEMP)
reg [31:0] memory [0:1023];

always @(posedge clk) begin
    mem_ready <= 0;

    if (mem_valid) begin
        mem_ready <= 1;

        if (mem_wstrb)
            memory[mem_addr[11:2]] <= mem_wdata;

        mem_rdata <= memory[mem_addr[11:2]];
    end
end

endmodule
