// SPDX-FileCopyrightText: 2024 Efabless Corporation and its Licensors, All Rights Reserved
// ========================================================================================
//
//  This software is protected by copyright and other intellectual property
//  rights. Therefore, reproduction, modification, translation, compilation, or
//  representation of this software in any manner other than expressly permitted
//  is strictly prohibited.
//
//  You may access and use this software, solely as provided, solely for the purpose of
//  integrating into semiconductor chip designs that you create as a part of the
//  of Efabless shuttles or Efabless managed production programs (and solely for use and
//  fabrication as a part of Efabless production purposes and for no other purpose.  You
//  may not modify or convey the software for any other purpose.
//
//  Disclaimer: EFABLESS AND ITS LICENSORS MAKE NO WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, WITH REGARD TO THIS MATERIAL, AND EXPRESSLY DISCLAIM
//  ANY AND ALL WARRANTIES OF ANY KIND INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE. Efabless reserves the right to make changes without further
//  notice to the materials described herein. Neither Efabless nor any of its licensors
//  assume any liability arising out of the application or use of any product or
//  circuit described herein. Efabless's products described herein are
//  not authorized for use as components in life-support devices.
//
//  If you have a separate agreement with Efabless pertaining to the use of this software
//  then that agreement shall control.

//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : SRAM_1024x32_ahb_wrapper
// Purpose : 32 KB on-chip SRAM, AHB slave 1 @ 0x3000_0000. Holds the main
//           application (.text copied from SPI flash by the bootloader),
//           .data/.bss and the stack (see firmware/sections.ld).
// Clocks  : HCLK (system clk)
// Notes   : - Behavioural 8192x32 array (not the EF_SRAM macro despite the
//             name, which is kept so the instance/ports stay stable).
//           - Zero wait states: writes land at the end of the data phase,
//             reads are combinational from the registered address.
//           - Byte / halfword / word writes (HSIZE) are supported.
//           - Only HADDR[14:2] is decoded, so the 64 KB AHB window
//             0x3000_0000-0x3000_FFFF aliases the 32 KB array twice.
//           - The testbench watches writes to 0x3000_7000 (firmware
//             handshake words) through this slave's HWDATA.
//==========================================================================
`ifdef USE_POWER_PINS
    `define USE_PG_PIN
`endif

module SRAM_1024x32_ahb_wrapper #(parameter AW = 12) (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    // AHB Slave ports
    input                   HCLK,
    input                   HRESETn,
    
    input wire              HSEL,
    input wire [31:0]       HADDR,
    input wire [1:0]        HTRANS,
    input wire              HWRITE,
    input wire              HREADY,
    input wire [31:0]       HWDATA,
    input wire [2:0]        HSIZE,
    output wire             HREADYOUT,
    output wire [31:0]      HRDATA

);

    // ---------------------------------------------------------------------
    // 1. AHB address-phase latch
    // ---------------------------------------------------------------------
    reg [31:0] r_haddr;
    reg       r_hwrite;
    reg [2:0] r_hsize;
    reg       r_active;
    
    wire ahb_active = HSEL && HREADY && (HTRANS == 2'b10 || HTRANS == 2'b11);
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            r_haddr <= 0;
            r_hwrite <= 0;
            r_hsize <= 0;
            r_active <= 0;
        end else begin
            if (HREADY) begin
                r_haddr <= HADDR;
                r_hwrite <= HWRITE;
                r_hsize <= HSIZE;
                r_active <= ahb_active;
            end
        end
    end
    
    assign HREADYOUT = 1'b1;   // never stalls

    // ---------------------------------------------------------------------
    // 2. Storage: 32 KB (8192 x 32), zero-initialised for simulation
    // ---------------------------------------------------------------------
    reg [31:0] mem [0:8191];
    integer i;
    initial begin
        for (i = 0; i < 8192; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
    end
    wire [12:0] word_addr = r_haddr[14:2];
    
    // ---------------------------------------------------------------------
    // 3. Write (data phase), honouring HSIZE and the byte lane
    // ---------------------------------------------------------------------
    always @(posedge HCLK) begin
        if (r_active && r_hwrite) begin
            if (r_hsize == 3'b000) begin // Byte
                if (r_haddr[1:0] == 2'b00) mem[word_addr][7:0] <= HWDATA[7:0];
                if (r_haddr[1:0] == 2'b01) mem[word_addr][15:8] <= HWDATA[15:8];
                if (r_haddr[1:0] == 2'b10) mem[word_addr][23:16] <= HWDATA[23:16];
                if (r_haddr[1:0] == 2'b11) mem[word_addr][31:24] <= HWDATA[31:24];
            end else if (r_hsize == 3'b001) begin // Halfword
                if (r_haddr[1] == 1'b0) mem[word_addr][15:0] <= HWDATA[15:0];
                if (r_haddr[1] == 1'b1) mem[word_addr][31:16] <= HWDATA[31:16];
            end else begin // Word
                mem[word_addr] <= HWDATA;
            end
`ifdef NM32_TRACE
            if (r_haddr == 32'h30007FFC || r_haddr == 32'h30000FFC)
                $display("Time=%0t: [SRAM WRITE] Addr=0x%08h Data=0x%08h HSIZE=0x%x", $time, r_haddr, HWDATA, r_hsize);
`endif
        end
    end
    
    // ---------------------------------------------------------------------
    // 4. Read: combinational from the registered address (0 wait states)
    // ---------------------------------------------------------------------
    assign HRDATA = (r_active && !r_hwrite) ? mem[word_addr] : 32'h0;

endmodule
