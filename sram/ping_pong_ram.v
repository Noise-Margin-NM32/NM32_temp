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

    // Two 512x32 True Dual-Port RAMs
    reg [31:0] bank0 [0:511];
    reg [31:0] bank1 [0:511];
    
    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            bank0[i] = 0;
            bank1[i] = 0;
        end
    end
    
    // Control Registers
    reg accel_bank_sel; // 0 = Bank0, 1 = Bank1
    
    // AHB Protocol Latch
    reg [12:0] r_haddr;
    reg       r_hwrite;
    reg       r_active;
    reg       r_wait;
    
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
    
    assign hready_out = r_wait ? 1'b0 : 1'b1; // Zero wait state
    
    wire is_bank0 = (r_haddr[12:11] == 2'b00); // 0x000 - 0x7FC
    wire is_bank1 = (r_haddr[12:11] == 2'b01); // 0x800 - 0xFFC
    wire is_ctrl  = (r_haddr[12:0] == 13'h1000); // 0x1000
    
    wire [8:0] word_addr = r_haddr[10:2];
    
    // Bank 0 Routing
    wire b0_we_a = (r_active && r_hwrite && is_bank0) ? 1'b1 : (accel_bank_sel == 0 ? accel_we_a : 1'b0);
    wire [8:0] b0_addr_a = (r_active && is_bank0) ? word_addr : accel_addr_a;
    wire [31:0] b0_din_a = (r_active && r_hwrite && is_bank0) ? hwdata : accel_din_a;
    reg [31:0] b0_dout_a;
    
    wire b0_we_b = (accel_bank_sel == 0 ? accel_we_b : 1'b0);
    wire [8:0] b0_addr_b = accel_addr_b;
    wire [31:0] b0_din_b = accel_din_b;
    reg [31:0] b0_dout_b;
    
    // Bank 1 Routing
    wire b1_we_a = (r_active && r_hwrite && is_bank1) ? 1'b1 : (accel_bank_sel == 1 ? accel_we_a : 1'b0);
    wire [8:0] b1_addr_a = (r_active && is_bank1) ? word_addr : accel_addr_a;
    wire [31:0] b1_din_a = (r_active && r_hwrite && is_bank1) ? hwdata : accel_din_a;
    reg [31:0] b1_dout_a;
    
    wire b1_we_b = (accel_bank_sel == 1 ? accel_we_b : 1'b0);
    wire [8:0] b1_addr_b = accel_addr_b;
    wire [31:0] b1_din_b = accel_din_b;
    reg [31:0] b1_dout_b;
    
    // RAM Instantiations (Inferred)
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
    
    // AHB Read Data
    wire [31:0] data_rdata = is_bank0 ? b0_dout_a : (is_bank1 ? b1_dout_a : 32'h0);
    assign hrdata = is_ctrl ? {31'b0, accel_bank_sel} : data_rdata;
    
    // Accelerator Read Data
    assign accel_dout_a = (accel_bank_sel == 0) ? b0_dout_a : b1_dout_a;
    assign accel_dout_b = (accel_bank_sel == 0) ? b0_dout_b : b1_dout_b;

endmodule
