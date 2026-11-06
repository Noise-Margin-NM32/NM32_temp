`timescale 1ns/1ps
`default_nettype wire

module program_counter #(
    parameter [31:0] RESET_PC = 32'h00000000   // reset vector
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire        en,       // Clock enable (pc_enable from stall unit)
    input  wire        jump,     // Branch taken or jump
    input  wire [31:0] d_in,     // Target address
    input  wire        halt,     // External halt/freeze
    output reg  [31:0] pc
);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc <= RESET_PC;
        end else if (jump && !halt) begin
            pc <= d_in;
        end else if (en && !halt) begin
            pc <= pc + 4;
        end
    end

endmodule