`timescale 1ns / 1ps
// Bridge_Top — Engine Container
// Wires the AHB slave interface and APB FSM Controller together.
// Exposes a scalar PREADY/PRDATA interface; the top-level wrapper
// handles the packed-array fan-in/fan-out through the decoder.

module Bridge_Top (
    input  logic        Hclk,
    input  logic        Hresetn,
    input  logic        Hwrite,
    input  logic        Hreadyin,
    input  logic [1:0]  Htrans,
    input  logic [31:0] Hwdata,
    input  logic [31:0] Haddr,
    
    input  logic 	Hsel,    //Added because the bridge is a slave

    input  logic [31:0] Prdata,   // muxed read data from decoder
    input  logic        PREADY,   // muxed PREADY from decoder

    output logic        Penable,
    output logic        Pwrite,
    output logic [3:0]  Pselx,
    output logic [31:0] Paddr,
    output logic [31:0] Pwdata,
    output logic        Hreadyout,
    output logic [1:0]  Hresp,
    output logic [31:0] Hrdata
);

    // Internal fabric signals
    logic        valid;
    logic [31:0] Haddr1, Haddr2;
    logic        Hwritereg;
    logic [3:0]  tempselx;

    // Pipelined AHB slave monitor
    AHB_slave_interface AHBSlave (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .Hwrite    (Hwrite),
        .Hreadyin  (Hreadyin),
        .Htrans    (Htrans),
        .Haddr     (Haddr),
        .Hwdata    (Hwdata),
        .Prdata    (Prdata),
        .valid     (valid),
        .Haddr1    (Haddr1),
        .Haddr2    (Haddr2),
        .Hrdata    (Hrdata),
        .Hwritereg (Hwritereg),
        .tempselx  (tempselx),
        .Hresp     (Hresp)
    );

    // 5-state APB sequencer
    APB_FSM_Controller APBControl (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .valid     (valid),
        .Haddr1    (Haddr1),
        .Haddr2    (Haddr2),
        .Hwdata    (Hwdata),
        .Prdata    (Prdata),
        .Hwrite    (Hwrite),
        .Haddr     (Haddr),
        .Hwritereg (Hwritereg),
        .tempselx  (tempselx),
        .PREADY    (PREADY),
        .Pwrite    (Pwrite),
        .Penable   (Penable),
        .Pselx     (Pselx),
        .Paddr     (Paddr),
        .Pwdata    (Pwdata),
        .Hreadyout (Hreadyout)
    );

endmodule
