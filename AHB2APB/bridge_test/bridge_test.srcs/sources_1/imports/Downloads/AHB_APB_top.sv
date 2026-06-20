`timescale 1ns / 1ps
// AHB_APB_top — Master Wrapper
// Exposes packed-array peripheral ports to the testbench/SoC.
// Instantiates Bridge_Top and APB_Decoder, wiring the scalar
// internal bus to the vectorized peripheral interfaces.
//
// Peripheral map
//   PSEL[0] / PRDATA[0] / PREADY[0]  —  I2S RX  (0x8000_0000–0x8000_0FFF)
//   PSEL[1] / PRDATA[1] / PREADY[1]  —  I2S TX  (0x8000_1000–0x8000_1FFF)
//   PSEL[2] / PRDATA[2] / PREADY[2]  —  GPIO    (0x8000_2000–0x8000_2FFF)
//   PSEL[3] / PRDATA[3] / PREADY[3]  —  WDT     (0x8800_0000–0x8BFF_FFFF)

module AHB_APB_top (
    // AHB master (CPU) side
    input  logic        Hclk,
    input  logic        Hresetn,
    input  logic        Hwrite,
    input  logic        Hreadyin,
    input  logic [1:0]  Htrans,
    input  logic [31:0] Hwdata,
    input  logic [31:0] Haddr,

    output logic        Hreadyout,
    output logic [1:0]  Hresp,
    output logic [31:0] Hrdata,

    // APB peripheral side
    output logic        Penable,
    output logic        Pwrite,
    output logic [31:0] Paddr,
    output logic [31:0] Pwdata,
    output logic [3:0]  PSEL,

    input  logic [3:0][31:0] PRDATA,
    input  logic [3:0]       PREADY
);

    // Internal scalar bus between bridge and decoder
    logic [31:0] Prdata_int;
    logic        Pready_int;
    logic [3:0]  Pselx_int;

    Bridge_Top BridgeInst (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .Hwrite    (Hwrite),
        .Hreadyin  (Hreadyin),
        .Htrans    (Htrans),
        .Hwdata    (Hwdata),
        .Haddr     (Haddr),
        .Prdata    (Prdata_int),
        .PREADY    (Pready_int),
        .Penable   (Penable),
        .Pwrite    (Pwrite),
        .Pselx     (Pselx_int),
        .Paddr     (Paddr),
        .Pwdata    (Pwdata),
        .Hreadyout (Hreadyout),
        .Hresp     (Hresp),
        .Hrdata    (Hrdata)
    );

    APB_Decoder DecoderInst (
        .Pselx_from_bridge (Pselx_int),
        .Paddr_from_bridge (Paddr),
        .PSEL              (PSEL),
        .Prdata_to_bridge  (Prdata_int),
        .Pready_to_bridge  (Pready_int),
        .PRDATA            (PRDATA),
        .PREADY            (PREADY)
    );

endmodule
