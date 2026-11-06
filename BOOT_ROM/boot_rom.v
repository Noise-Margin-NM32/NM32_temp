//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : boot_rom_ahb
// Purpose : 4 KB read-only boot memory @ 0x0000_0000, dual-ported:
//             I_* - AHB-Lite slave on the Instruction AHB bus (I-bus,
//                   slave 0): CPU instruction fetches.
//             H*  - AHB slave on the Data AHB bus (D-bus, slave 2): data
//                   reads of constants (.rodata) placed in the ROM.
//           Holds start.S + bootloader.c (the .boot section of firmware.elf).
//           Ibex (boot_addr 0) resets to 0x80 inside this ROM.
// Clocks  : HCLK (system clk)
// Notes   : - Contents come from firmware/bootrom.hex via $readmemh. The
//             relative path is resolved from the XSim run directory
//             (NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim/).
//           - Words past the end of the image read as NOP (0x00000013):
//             the CPU prefetches beyond the last instruction.
//           - Zero wait states, always OKAY. Writes are ignored.
//           - Each port latches its address only on an active transfer
//             (HSEL && HREADY && HTRANS[1]); a data phase with no active
//             transfer returns NOP.
//==========================================================================
`timescale 1ns / 1ps

module boot_rom_ahb (
    input  wire        HCLK,
    input  wire        HRESETn,

    // D-bus port (read-only)
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire        HREADY,
    output wire        HREADYOUT,
    output wire [31:0] HRDATA,
    output wire [1:0]  HRESP,

    // I-bus port (AHB-Lite, read-only)
    input  wire        I_HSEL,
    input  wire [31:0] I_HADDR,
    input  wire [1:0]  I_HTRANS,
    input  wire        I_HWRITE,
    input  wire        I_HREADY,
    output wire        I_HREADYOUT,
    output wire [31:0] I_HRDATA,
    output wire [1:0]  I_HRESP
);

    localparam [31:0] NOP = 32'h00000013;

    // 4KB Memory Array (1024 words x 32 bits)
    reg [31:0] memory [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) memory[i] = NOP;
        $readmemh("./../../../../../firmware/bootrom.hex", memory);
    end

    // ---- D-bus port ----
    reg [31:0] d_addr;
    reg        d_active;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            d_addr   <= 32'b0;
            d_active <= 1'b0;
        end else if (HREADY) begin
            d_active <= HSEL && HTRANS[1] && !HWRITE;
            if (HSEL && HTRANS[1]) d_addr <= HADDR;
        end
    end

    assign HRDATA    = d_active ? memory[d_addr[11:2]] : NOP;
    assign HREADYOUT = 1'b1;
    assign HRESP     = 2'b00;

    // ---- I-bus port ----
    reg [31:0] i_addr;
    reg        i_active;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            i_addr   <= 32'b0;
            i_active <= 1'b0;
        end else if (I_HREADY) begin
            i_active <= I_HSEL && I_HTRANS[1] && !I_HWRITE;
            if (I_HSEL && I_HTRANS[1]) i_addr <= I_HADDR;
        end
    end

    assign I_HRDATA    = i_active ? memory[i_addr[11:2]] : NOP;
    assign I_HREADYOUT = 1'b1;
    assign I_HRESP     = 2'b00;

endmodule
