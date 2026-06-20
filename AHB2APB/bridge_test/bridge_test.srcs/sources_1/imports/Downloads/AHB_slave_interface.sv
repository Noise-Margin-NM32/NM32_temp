`timescale 1ns / 1ps
// Parameterized AHB Slave Interface — 4-Peripheral Configuration
// Peripherals: I2S_RX[0], I2S_TX[1], GPIO[2], WDT[3]

module AHB_slave_interface #(
    parameter logic [31:0] APB_BASE_ADDR = 32'h8000_0000,
    parameter logic [31:0] APB_HIGH_ADDR = 32'h8C00_0000,

    parameter logic [31:0] BASE_I2S_RX   = 32'h8000_0000,
    parameter logic [31:0] HIGH_I2S_RX   = 32'h8000_1000,

    parameter logic [31:0] BASE_I2S_TX   = 32'h8000_1000,
    parameter logic [31:0] HIGH_I2S_TX   = 32'h8000_2000,

    parameter logic [31:0] BASE_GPIO     = 32'h8000_2000,
    parameter logic [31:0] HIGH_GPIO     = 32'h8000_3000,

    parameter logic [31:0] BASE_WDT      = 32'h8800_0000,
    parameter logic [31:0] HIGH_WDT      = 32'h8C00_0000
) (
    input  logic        Hclk,
    input  logic        Hresetn,
    input  logic        Hwrite,
    input  logic        Hreadyin,
    input  logic [1:0]  Htrans,
    input  logic [31:0] Haddr,
    input  logic [31:0] Hwdata,
    input  logic [31:0] Prdata,

    output logic        valid,
    output logic [31:0] Haddr1,
    output logic [31:0] Haddr2,
    output logic [31:0] Hrdata,
    output logic        Hwritereg,
    output logic [3:0]  tempselx,   // one-hot: bit0=RX, bit1=TX, bit2=GPIO, bit3=WDT
    output logic [1:0]  Hresp
);

    // ----------------------------------------------------------------
    // Pipeline shift registers: align pipelined address with data phase
    // ----------------------------------------------------------------
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) begin
            Haddr1 <= 32'h0;
            Haddr2 <= 32'h0;
        end else begin
            Haddr1 <= Haddr;
            Haddr2 <= Haddr1;
        end
    end

    // Delay write-direction flag by one cycle to align with data phase
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) Hwritereg <= 1'b0;
        else          Hwritereg <= Hwrite;
    end

    // ----------------------------------------------------------------
    // Valid: asserted when a real AHB transaction is on the bus
    // ----------------------------------------------------------------
    always_comb begin
        valid = 1'b0;
        if (Hresetn && Hreadyin &&
            (Haddr >= APB_BASE_ADDR && Haddr < APB_HIGH_ADDR) &&
            (Htrans == 2'b10 || Htrans == 2'b11))
            valid = 1'b1;
    end

    // ----------------------------------------------------------------
    // Look-ahead decode: maps current Haddr to one-hot peripheral slot
    // ----------------------------------------------------------------
    always_comb begin
        tempselx = 4'b0000;
        if (Hresetn) begin
            if      (Haddr >= BASE_I2S_RX && Haddr < HIGH_I2S_RX) tempselx = 4'b0001;
            else if (Haddr >= BASE_I2S_TX && Haddr < HIGH_I2S_TX) tempselx = 4'b0010;
            else if (Haddr >= BASE_GPIO   && Haddr < HIGH_GPIO)   tempselx = 4'b0100;
            else if (Haddr >= BASE_WDT    && Haddr < HIGH_WDT)    tempselx = 4'b1000;
        end
    end

    assign Hrdata = Prdata;   // read data passes straight through
    assign Hresp  = 2'b00;    // always OKAY response
endmodule
