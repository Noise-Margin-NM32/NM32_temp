//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : ping_pong_ram
// Purpose : Zero-copy shared frame memory, AHB slave 4 @ 0x5000_0000.
//           Two 512x32 banks: at any time one bank belongs to the FFT/IFFT
//           accelerators (dedicated dual-port link, no AHB traffic) while
//           the CPU fills/drains the other bank over AHB.
// Clocks  : clk (system clk)
//
// AHB register map (offsets from 0x5000_0000):
//   0x0000-0x07FC  Bank 0 data (512 words)
//   0x0800-0x0FFC  Bank 1 data (512 words)
//   0x1000         PING_PONG_CTRL  bit0 = accel_bank_sel
//                    0: accelerators own Bank 0, 1: accelerators own Bank 1
//
// Notes   : - Data word format: {real[31:16], imag[15:0]}, Q15.
//           - AHB reads take 1 wait state (synchronous BRAM read latency);
//             writes are zero-wait. Removing the wait state makes the CPU
//             sample X data (see README "Wait-State Timing Fix").
//           - An AHB access to a bank takes port A of that bank, overriding
//             the accelerator. The CPU may read/write the accelerator-owned
//             bank only while no FFT/IFFT is running (main.c does exactly
//             that between CTRL start/done).
//           - The FFT and IFFT share the accelerator ports; NM32_top.sv muxes
//             them on fft_busy, so they must never run at the same time.
//==========================================================================
`timescale 1ns / 1ps

module ping_pong_ram (
    input wire clk,
    input wire rstn,
    
    // AHB Slave Interface (CPU Access)
    input  wire        hsel,
    input  wire [31:0] haddr,
    input  wire        hwrite,
    input  wire [1:0]  htrans,
    input  wire [2:0]  hsize,
    input  wire [31:0] hwdata,
    input  wire        hready_in,
    output wire        hready_out,
    output wire [31:0] hrdata,
    
    // Accelerator Interface (FFT/IFFT Shared)
    input  wire        accel_we_a,
    input  wire [8:0]  accel_addr_a,
    input  wire [31:0] accel_din_a,
    output wire [31:0] accel_dout_a,
    
    input  wire        accel_we_b,
    input  wire [8:0]  accel_addr_b,
    input  wire [31:0] accel_din_b,
    output wire [31:0] accel_dout_b
);

    // ---------------------------------------------------------------------
    // 1. Storage: two 512x32 true dual-port RAMs (inferred BRAM)
    // ---------------------------------------------------------------------
    reg [31:0] bank0 [0:511];
    reg [31:0] bank1 [0:511];
    
    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            bank0[i] = 0;
            bank1[i] = 0;
        end
    end
    
    // ---------------------------------------------------------------------
    // 2. PING_PONG_CTRL and AHB address-phase latch
    // ---------------------------------------------------------------------
    reg accel_bank_sel;        // bank owned by the accelerators (0/1)

    reg [12:0] r_haddr;
    reg       r_hwrite;
    reg       r_active;
    reg       r_wait;          // high for the 1 read wait-state cycle
    
    wire ahb_active = hsel && hready_in && (htrans == 2'b10 || htrans == 2'b11);
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_haddr <= 0;
            r_hwrite <= 0;
            r_active <= 0;
            r_wait <= 0;
            accel_bank_sel <= 0;
        end else begin
            if (hready_in) begin
                r_haddr <= haddr[12:0];
                r_hwrite <= hwrite;
                r_active <= ahb_active;
            end
            
            // Insert 1 wait state for reads
            if (ahb_active && !hwrite) begin
                r_wait <= 1;
            end else begin
                r_wait <= 0;
            end
            
            // Write to Control Register at offset 0x1000
            if (r_active && r_hwrite && (r_haddr[12:0] == 13'h1000) && hready_in) begin
                accel_bank_sel <= hwdata[0];
            end
        end
    end
    
    assign hready_out = r_wait ? 1'b0 : 1'b1;   // 1 wait state on reads only
    
    wire is_bank0 = (r_haddr[12:11] == 2'b00); // 0x000 - 0x7FC
    wire is_bank1 = (r_haddr[12:11] == 2'b01); // 0x800 - 0xFFC
    wire is_ctrl  = (r_haddr[12:0] == 13'h1000); // 0x1000
    
    wire [8:0] word_addr = r_haddr[10:2];

    // ---------------------------------------------------------------------
    // 3. Port routing
    //    Port A: AHB (when it targets this bank) else accelerator port A.
    //    Port B: accelerator port B only.
    //    Accelerator writes are gated by accel_bank_sel.
    // ---------------------------------------------------------------------
    // Bank 0
    wire b0_we_a = (r_active && r_hwrite && is_bank0) ? 1'b1 : (accel_bank_sel == 0 ? accel_we_a : 1'b0);
    wire [8:0] b0_addr_a = (r_active && is_bank0) ? word_addr : accel_addr_a;
    wire [31:0] b0_din_a = (r_active && r_hwrite && is_bank0) ? hwdata : accel_din_a;
    reg [31:0] b0_dout_a;
    
    wire b0_we_b = (accel_bank_sel == 0 ? accel_we_b : 1'b0);
    wire [8:0] b0_addr_b = accel_addr_b;
    wire [31:0] b0_din_b = accel_din_b;
    reg [31:0] b0_dout_b;
    
    // Bank 1
    wire b1_we_a = (r_active && r_hwrite && is_bank1) ? 1'b1 : (accel_bank_sel == 1 ? accel_we_a : 1'b0);
    wire [8:0] b1_addr_a = (r_active && is_bank1) ? word_addr : accel_addr_a;
    wire [31:0] b1_din_a = (r_active && r_hwrite && is_bank1) ? hwdata : accel_din_a;
    reg [31:0] b1_dout_a;
    
    wire b1_we_b = (accel_bank_sel == 1 ? accel_we_b : 1'b0);
    wire [8:0] b1_addr_b = accel_addr_b;
    wire [31:0] b1_din_b = accel_din_b;
    reg [31:0] b1_dout_b;
    
    // ---------------------------------------------------------------------
    // 4. RAM arrays (write-first ports, 1-cycle read latency)
    // ---------------------------------------------------------------------
    always @(posedge clk) begin
        if (b0_we_a) bank0[b0_addr_a] <= b0_din_a;
        b0_dout_a <= bank0[b0_addr_a];
        
        if (b0_we_b) bank0[b0_addr_b] <= b0_din_b;
        b0_dout_b <= bank0[b0_addr_b];
        
        if (b1_we_a) bank1[b1_addr_a] <= b1_din_a;
        b1_dout_a <= bank1[b1_addr_a];
        
        if (b1_we_b) bank1[b1_addr_b] <= b1_din_b;
        b1_dout_b <= bank1[b1_addr_b];
    end
    
    // ---------------------------------------------------------------------
    // 5. Read data
    // ---------------------------------------------------------------------
    // AHB side
    wire [31:0] data_rdata = is_bank0 ? b0_dout_a : (is_bank1 ? b1_dout_a : 32'h0);
    assign hrdata = is_ctrl ? {31'b0, accel_bank_sel} : data_rdata;
    
    // Accelerator side: always the bank selected by accel_bank_sel
    assign accel_dout_a = (accel_bank_sel == 0) ? b0_dout_a : b1_dout_a;
    assign accel_dout_b = (accel_bank_sel == 0) ? b0_dout_b : b1_dout_b;

endmodule
