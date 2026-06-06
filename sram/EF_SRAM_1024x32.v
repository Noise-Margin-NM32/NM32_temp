`timescale 1 ns / 1 ps

`ifdef USE_POWER_PINS
    `define USE_PG_PIN
`endif

module EF_SRAM_1024x32 (DO, ScanOutCC, AD, BEN, CLKin, DI, EN, R_WB, ScanInCC, ScanInDL, ScanInDR, SM, TM, WLBI, WLOFF,
`ifdef USE_PG_PIN
vgnd, vnb, vpb, vpwra,
`endif
vpwrac,
`ifdef USE_PG_PIN
vpwrm,
vpwrp,
`endif
vpwrpc
);
    parameter NB = 32;  // Number of Data Bits
    parameter NA = 10;  // Number of Address Bits
    parameter NW = 1024;  // Number of WORDS
    parameter SEED = 0 ;    // User can define SEED at memory instantiation by .SEED(<Some_Seed_value>)

    output reg [(NB - 1) : 0] DO;
    output wire ScanOutCC;

    input wire [(NB - 1) : 0] DI;
    input wire [(NB - 1) : 0] BEN;
    input wire [(NA - 1) : 0] AD;
    input wire EN;
    input wire R_WB;
    input wire CLKin;
    input wire WLBI;
    input wire WLOFF;
    input wire TM;
    input wire SM;
    input wire ScanInCC;
    input wire ScanInDL;
    input wire ScanInDR;
    input wire vpwrac;
    input wire vpwrpc;

`ifdef USE_PG_PIN
    input wire vgnd;
    input wire vpwrm;

`ifdef EF_SRAM_PA_SIM
  inout wire vpwra;
`else
  input wire vpwra;
`endif

`ifdef EF_SRAM_PA_SIM
  inout wire vpwrp;
`else
  input wire vpwrp;
`endif

    input wire vnb;
    input wire vpb;
`else
    supply0 vgnd;
    supply0 vnb;
    supply1 vpwra;
    supply1 vpwrm;
    supply1 vpwrp;
    supply1 vpb;
`endif

    // 1024 x 32-bit Native Memory Array
    reg [31:0] mem [0:1023];
    
    integer i;
    initial begin
        for(i=0; i<1024; i=i+1) begin
            mem[i] = 32'h0000_0000;
        end
    end

    // Tie off the unused ASIC scan chain output
    assign ScanOutCC = 1'b0;

    // Standard FPGA BRAM Inference Logic
    always @(posedge CLKin) begin
        if (EN) begin
            // R_WB == 0 means WRITE operation
            if (~R_WB) begin 
                // BEN is a 32-bit mask driven by the AHB controller. 
                // We check the lowest bit of each byte lane to write cleanly.
                if (BEN[0])  mem[AD][7:0]   <= DI[7:0];
                if (BEN[8])  mem[AD][15:8]  <= DI[15:8];
                if (BEN[16]) mem[AD][23:16] <= DI[23:16];
                if (BEN[24]) mem[AD][31:24] <= DI[31:24];
            end
            
            // Synchronous Read output
            DO <= mem[AD];
        end
    end

endmodule