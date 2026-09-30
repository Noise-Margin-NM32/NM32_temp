//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : boot_rom_ahb
// Purpose : 4 KB read-only boot memory, AHB slave 2 @ 0x0000_0000. Holds
//           start.S + bootloader.c (the .boot section of firmware.elf).
//           Ibex (boot_addr 0) resets to 0x80 inside this ROM.
// Clocks  : HCLK (system clk)
// Notes   : - Contents come from firmware/bootrom.hex via $readmemh. The
//             relative path is resolved from the XSim run directory
//             (NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim/).
//           - Zero wait states, always OKAY. Writes are ignored.
//           - The latched address only updates on a ROM access, so HRDATA
//             stays stable however long the master takes to sample it.
//==========================================================================
`timescale 1ns / 1ps

module boot_rom_ahb (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire        HREADY,
    
    output wire        HREADYOUT,
    output wire  [31:0] HRDATA,
    output wire [1:0]  HRESP
);

    // 4KB Memory Array (1024 words x 32 bits)
    reg [31:0] memory [0:1023];

    // Firmware image (build with `make -C firmware`). Words past the end of
    // the image read as 0 rather than X: Ibex prefetches beyond the last
    // instruction, and X there trips its known-value assertions.
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) memory[i] = 32'h0;
        $readmemh("./../../../../../firmware/bootrom.hex", memory);
    end

    // ---- Address latch ----
    reg [31:0] latched_addr;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            latched_addr <= 32'b0;
        end else if (HREADY && HSEL) begin
            // Only update the address when the CPU specifically talks to the ROM
            latched_addr <= HADDR;
        end
    end

    // ---- Read data (word addressed) ----
    assign HRDATA = memory[latched_addr[11:2]];

    // ROM is always instantly ready and always returns OKAY (00)
    assign HREADYOUT = 1'b1; 
    assign HRESP     = 2'b00;

endmodule
