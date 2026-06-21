`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NOISE MARGIN
// Engineers: Omkar, Vijay, Meera, Satyam, Sarang, Avichal, Shriya, Adi
//  
// 
// Create Date: 04/13/2026 04:50:54 PM
// Design Name: NM32_KAVACH 
// Module Name: NM32_top
// Project Name: 1-TOPS
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module nm32_top(
    input wire clk,
    input wire pclk, // For APB peripherals
    input wire rstn,
    input wire [1-1:0] rx_ws,
    input wire [1-1:0] rx_sck,
    output wire [1-1:0] tx_ws,
    output wire [1-1:0] tx_sck,
    input wire [1-1:0] sdi,
    output wire [1-1:0] sdo
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////           Wires and Parameters           ////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam NUM_ARB_MSTS = 1; // Number of AHB masters in the system
localparam DEF_ARB_MST  = 0; // Default AHB master to be granted bus access when no other masters are requesting
localparam NUM_SLVS = 6;

localparam APB_NUM_SLVS = 2;

localparam [32*16-1:0] ADDR_LOW_FLAT  = {320'b0, 32'h6000_0000, 32'h5000_0000, 32'h4000_0000, 32'h0000_0000, 32'h3000_0000, 32'h2000_0000}; //ifft, scratchpad, fft, bootrom, sram, apbbridge
localparam [32*16-1:0] ADDR_HIGH_FLAT = {320'b0, 32'h6000_0FFF, 32'h5000_3FFF, 32'h4000_0FFF, 32'h0000_FFFF, 32'h3000_FFFF, 32'h200F_FFFF};

localparam i2s_AW = 4;
localparam i2s_DW = 32;

localparam [31:0] I2S_RX_BASE = 32'h2000_0000;
localparam [31:0] I2S_RX_SIZE = 32'h0000_FFFF;
localparam [31:0] I2S_TX_BASE = 32'h2001_0000;
localparam [31:0] I2S_TX_SIZE = 32'h0000_FFFF;
localparam [31:0] GPIO_BASE   = 32'h0000_0000;
localparam [31:0] GPIO_SIZE   = 32'h0000_0000;
localparam [31:0] WDT_BASE    = 32'h0000_0000;
localparam [31:0] WDT_SIZE    = 32'h0000_0000;

// wire remap;

//cpu - AHB bus wires
wire [31:0] cpu_haddr;
wire [1:0]  cpu_htrans;
wire [2:0]  cpu_hsize;
wire        cpu_hwrite;
wire [31:0] cpu_hwdata;
wire        cpu_hready;
wire [31:0] cpu_hrdata;
wire [1:0]  cpu_hresp;

wire cpu_hgrant;
wire cpu_hbusreq;
// wire cpu_hlock; //changed by agy
// wire [2:0] cpu_hburst; //changed by agy
// wire [3:0] cpu_hprot; //changed by agy

// assign cpu_hbusreq; // CPU always requests the bus?
// assign cpu_hlock;   // No locked transfers for now
// assign remap = 1'b0;  // No remapping for now
// assign cpu_hburst; // No bursts for now
// assign cpu_hprot; // Default protection


// Pico native signals
wire        cpu_mem_valid;
wire        cpu_mem_ready; 
wire [31:0] cpu_mem_addr;
wire [31:0] cpu_mem_wdata;
wire [3:0]  cpu_mem_wstrb;
wire [31:0] cpu_mem_rdata;
wire        cpu_mem_instr;


// Arbiter wires

wire [14:0] mst_hbusreq;   // [i] = master i hbusreq
// wire [14:0] mst_hlock; //changed by agy
wire [14:0][1:0]  mst_htrans;    //changed by agy
wire [14:0][31:0] mst_haddr;     //changed by agy
wire [14:0] mst_hwrite;
wire [14:0][2:0]  mst_hsize;     //changed by agy
// wire [14:0][2:0]  mst_hburst;    //changed by agy
// wire [14:0][3:0]  mst_hprot;     //changed by agy
wire [14:0][31:0] mst_hwdata;    //changed by agy

// Master inputs (what arbiter feeds back to each master)
wire [14:0] mst_hgrant;
wire        mst_hready_out;  // shared hready to all masters
wire [1:0]  mst_hresp_out;    // shared hresp to all masters
wire [31:0] mst_hrdata_out;   // shared hrdata to all masters

// Slave inputs (what arbiter drives to slaves) – per slave
wire [NUM_SLVS-1:0] slv_hsel;
wire [31:0]         slv_haddr_out;
wire                slv_hwrite_out;
wire [1:0]          slv_htrans_out;
wire [2:0]          slv_hsize_out;
// wire [2:0]          slv_hburst_out; //changed by agy
// wire [3:0]          slv_hprot_out; //changed by agy
wire [31:0]         slv_hwdata_out;
// wire [3:0]          slv_hmaster_out; //changed by agy
// wire                slv_hmastlock_out; //changed by agy
wire                slv_hready_in;  // hready fed into slaves

// Slave outputs (what each slave drives back)
wire [NUM_SLVS-1:0]               slv_hready_in_v;
wire [NUM_SLVS-1:0][1:0]          slv_hresp_v;  //changed by agy
wire [NUM_SLVS-1:0][31:0]         slv_hrdata_v; //changed by agy
// wire [14:0][15:0]         slv_hsplit_v; //changed by agy


//AHB to APB bridge wires
wire                       bridge_h_sel_apb    ; 
wire                       bridge_h_write      ;
wire                       bridge_h_ready_in   ;
wire [1 : 0]  bridge_h_trans      ;
wire [31 : 0]              bridge_h_addr       ;
wire [31 : 0]              bridge_h_wdata      ;

wire [31 : 0]  bridge_h_rdata      ;
wire [1:0]                 bridge_h_resp       ;
wire                       bridge_h_ready_out  ;

wire [3:0][31 : 0]         bridge_p_rdata      ;
wire [3:0]                 bridge_p_ready      ;

wire                       bridge_p_enable     ;
wire                       bridge_p_write      ;
wire [31 : 0]  bridge_p_addr       ;
wire [31 : 0]  bridge_p_wdata      ;
wire [3:0]    bridge_p_selx       ;



//SRAM wrapper WIRES 
 wire             sram_HSEL;
 wire [31:0]      sram_HADDR;
 wire [1:0]       sram_HTRANS;
 wire             sram_HWRITE;
 wire             sram_HREADY;
 wire [31:0]      sram_HWDATA;
 wire [2:0]       sram_HSIZE;
 wire             sram_HREADYOUT;
 wire [31:0]      sram_HRDATA;

//BOOT ROM wires
wire        boot_rom_HSEL;
wire [31:0] boot_rom_HADDR;
wire [1:0]  boot_rom_HTRANS;
wire        boot_rom_HWRITE;
wire        boot_rom_HREADY;
wire        boot_rom_HREADYOUT;
wire [31:0] boot_rom_HRDATA;
wire [1:0]  boot_rom_HRESP;


 //I2S
 wire         i2s_PWRITE;
 wire [ 31:0] i2s_PWDATA;
 wire [ 31:0] i2s_PADDR;
 wire         i2s_PENABLE;
 wire         i2s_PSEL;
 wire         i2s_PREADY;
 wire [ 31:0] i2s_PRDATA;
 wire         i2s_IRQ;
//  wire [1-1:0] ws;
//  wire [1-1:0] sck;
//  wire [1-1:0] sdi;

 wire         i2s_tx_PWRITE;
 wire [ 31:0] i2s_tx_PWDATA;
 wire [ 31:0] i2s_tx_PADDR;
 wire         i2s_tx_PENABLE;
 wire         i2s_tx_PSEL;
 wire         i2s_tx_PREADY;
 wire [ 31:0] i2s_tx_PRDATA;
 wire         i2s_tx_IRQ;

//  wire [1-1:0] sdo;



///////////////////////////////////////////////////////////////////////////TIE OFFS////////////////////////////////////////////////////////////////////////

assign mst_hbusreq[0] = cpu_hbusreq;        //CPU sending to the arbiter
// assign mst_hlock[0] = cpu_hlock; //changed by agy
assign mst_htrans[0] = cpu_htrans; //changed by agy
assign mst_haddr[0] = cpu_haddr;
assign mst_hwrite[0] = cpu_hwrite;
assign mst_hsize[0] = cpu_hsize;
// assign mst_hburst[0] = cpu_hburst; //changed by agy
// assign mst_hprot[0] = cpu_hprot; //changed by agy
assign mst_hwdata[0] = cpu_hwdata;

generate
    genvar i;
    for(i = 1; i<15; i = i+1) begin
        assign mst_hbusreq[i] = 1'b0;
//         assign mst_hlock[i] = 1'b0; //changed by agy
        assign mst_htrans[i] = 2'b00; //changed by agy
        assign mst_haddr[i] = 1'b0;
        assign mst_hwrite[i] = 1'b0;
        assign mst_hsize[i] = 1'b0;
//         assign mst_hburst[i] = 1'b0; //changed by agy
//         assign mst_hprot[i] = 1'b0; //changed by agy
        assign mst_hwdata[i] = 1'b0;
    end
endgenerate


assign cpu_hgrant = mst_hgrant[0];  // CPU gets from arbiter
assign cpu_hready = mst_hready_out;
assign cpu_hrdata = mst_hrdata_out;
assign cpu_hresp = mst_hresp_out;


//bridge connections (assuming slave 0 is the APB bridge)
assign bridge_h_write = slv_hwrite_out; // From arbiter to bridge
assign bridge_h_sel_apb = slv_hsel[0]; // Assuming slave 0
assign bridge_h_ready_in = slv_hready_in; // Ready from slave
assign bridge_h_trans = slv_htrans_out; // From arbiter to bridge
assign bridge_h_wdata = slv_hwdata_out; // From arbiter to bridge
assign bridge_h_addr = slv_haddr_out;   // From arbiter to bridge

assign sram_HSEL = slv_hsel[1]; // Assuming slave 1 is SRAM
assign sram_HADDR = slv_haddr_out;
assign sram_HTRANS = slv_htrans_out;
assign sram_HWRITE = slv_hwrite_out;
assign sram_HREADY = slv_hready_in; // Assuming shared hready for all
assign sram_HWDATA = slv_hwdata_out;
assign sram_HSIZE = slv_hsize_out;

assign boot_rom_HSEL = slv_hsel[2]; // Assuming slave 2 is boot ROM
assign boot_rom_HADDR = slv_haddr_out;
assign boot_rom_HTRANS = slv_htrans_out;
assign boot_rom_HWRITE = slv_hwrite_out;
assign boot_rom_HREADY = slv_hready_in; // Assuming shared hready for all

// Slave 3: FFT Wrapper connections
wire        fft_HSEL;
wire [31:0] fft_HADDR;
wire [1:0]  fft_HTRANS;
wire        fft_HWRITE;
wire [2:0]  fft_HSIZE;
// wire [2:0]  fft_HBURST; //changed by agy
wire [31:0] fft_HWDATA;
// wire [3:0]  fft_HPROT; //changed by agy
wire        fft_HREADY;
// wire [3:0]  fft_HMASTER; //changed by agy
// wire        fft_HMASTLOCK; //changed by agy
wire        fft_HREADYOUT;
wire [1:0]  fft_HRESP;
wire [31:0] fft_HRDATA;
// wire [15:0] fft_HSPLIT; //changed by agy
wire        fft_irq;

assign fft_HSEL      = slv_hsel[3];
assign fft_HADDR     = slv_haddr_out;
assign fft_HTRANS    = slv_htrans_out;
assign fft_HWRITE    = slv_hwrite_out;
assign fft_HSIZE     = slv_hsize_out;
// assign fft_HBURST    = slv_hburst_out; //changed by agy
assign fft_HWDATA    = slv_hwdata_out;
// assign fft_HPROT     = slv_hprot_out; //changed by agy
assign fft_HREADY    = slv_hready_in;
// assign fft_HMASTER   = slv_hmaster_out; //changed by agy
// assign fft_HMASTLOCK = slv_hmastlock_out; //changed by agy

// Slave 4: Scratchpad RAM connections
wire        scratch_HSEL;
wire [31:0] scratch_HADDR;
wire [1:0]  scratch_HTRANS;
wire        scratch_HWRITE;
wire [2:0]  scratch_HSIZE;
// wire [2:0]  scratch_HBURST; //changed by agy
wire [31:0] scratch_HWDATA;
// wire [3:0]  scratch_HPROT; //changed by agy
wire        scratch_HREADY;
wire        scratch_HREADYOUT;
wire [1:0]  scratch_HRESP;
wire [31:0] scratch_HRDATA;

assign scratch_HSEL   = slv_hsel[4];
assign scratch_HADDR  = slv_haddr_out;
assign scratch_HTRANS = slv_htrans_out;
assign scratch_HWRITE = slv_hwrite_out;
assign scratch_HSIZE  = slv_hsize_out;
// assign scratch_HBURST = slv_hburst_out; //changed by agy
assign scratch_HWDATA = slv_hwdata_out;
// assign scratch_HPROT  = slv_hprot_out; //changed by agy
assign scratch_HREADY = slv_hready_in;

// Slave 5: IFFT Wrapper connections
wire        ifft_HSEL;
wire [31:0] ifft_HADDR;
wire [1:0]  ifft_HTRANS;
wire        ifft_HWRITE;
wire [2:0]  ifft_HSIZE;
// wire [2:0]  ifft_HBURST; //changed by agy
wire [31:0] ifft_HWDATA;
// wire [3:0]  ifft_HPROT; //changed by agy
wire        ifft_HREADY;
// wire [3:0]  ifft_HMASTER; //changed by agy
// wire        ifft_HMASTLOCK; //changed by agy
wire        ifft_HREADYOUT;
wire [1:0]  ifft_HRESP;
wire [31:0] ifft_HRDATA;
// wire [15:0] ifft_HSPLIT; //changed by agy
wire        ifft_irq;

assign ifft_HSEL      = slv_hsel[5];
assign ifft_HADDR     = slv_haddr_out;
assign ifft_HTRANS    = slv_htrans_out;
assign ifft_HWRITE    = slv_hwrite_out;
assign ifft_HSIZE     = slv_hsize_out;
// assign ifft_HBURST    = slv_hburst_out; //changed by agy
assign ifft_HWDATA    = slv_hwdata_out;
// assign ifft_HPROT     = slv_hprot_out; //changed by agy
assign ifft_HREADY    = slv_hready_in;
// assign ifft_HMASTER   = slv_hmaster_out; //changed by agy
// assign ifft_HMASTLOCK = slv_hmastlock_out; //changed by agy




assign i2s_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_PADDR = bridge_p_addr;   // From bridge to APB slave
assign i2s_PENABLE = bridge_p_enable; // From bridge to APB slave
assign i2s_PSEL = bridge_p_selx[0]; // Assuming I2S is APB slave 0
assign bridge_p_ready[0] = i2s_PREADY; // From bridge to APB slave
assign bridge_p_rdata[0] = i2s_PRDATA; // From bridge to APB slave




assign i2s_tx_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_tx_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_tx_PADDR = bridge_p_addr;   // From bridge to APB slave
assign i2s_tx_PENABLE = bridge_p_enable; // From bridge to APB slave
assign i2s_tx_PSEL = bridge_p_selx[1]; // Assuming I2S TX is APB slave 1
assign bridge_p_ready[1] = i2s_tx_PREADY; // From bridge to APB slave
assign bridge_p_rdata[1] = i2s_tx_PRDATA; // From bridge to APB slave

generate
    genvar idx;
    for(idx = 2; idx < 4; idx = idx + 1) begin
        assign bridge_p_selx[idx] = 32'b0; // No more APB slaves for now
        assign bridge_p_ready[idx] = 1'b0; // Tie ready high for non-existent slaves
        assign bridge_p_rdata[idx] = 32'b0; // Tie data to 0 for non-existent slaves
    end
endgenerate

// assign slv_hrdata_v = {(NUM_SLVS-2){32'b0}, sram_HRDATA, bridge_h_rdata}; // To arbiter (only from slave 0)
// assign slv_hresp_v = {(NUM_SLVS-1){2'b00}, bridge_h_resp}; // To arbiter (only from slave 0)
// assign slv_hready_in_v = {(NUM_SLVS-2){1'b0},sram_HREADYOUT, bridge_h_ready_out}; // To arbiter (only from slave 0)
// assign slv_hsplit_v = {(NUM_SLVS){16'b0}}; // No splits for now


assign slv_hrdata_v[0] = bridge_h_rdata; // To arbiter (only from slave 0) 
assign slv_hresp_v[0] = {1'b0, bridge_h_resp}; // To arbiter (only from slave 0)
assign slv_hready_in_v[0] = bridge_h_ready_out; // To arbiter (only from slave 0)
// assign slv_hsplit_v[0] = 0; // No splits for now //changed by agy

assign slv_hrdata_v[1] = sram_HRDATA; // To arbiter (only from slave 1)
assign slv_hresp_v[1] = 2'b00; // OKAY response
assign slv_hready_in_v[1] = sram_HREADYOUT; // Ready from SRAM
// assign slv_hsplit_v[1] = 0; // No splits for now //changed by agy

assign slv_hrdata_v[2] = boot_rom_HRDATA; // To arbiter (only from slave 2)
assign slv_hresp_v[2] = boot_rom_HRESP; // From boot ROM
assign slv_hready_in_v[2] = boot_rom_HREADYOUT; // From boot ROM
// assign slv_hsplit_v[2] = 0; // No splits for //changed by agy

assign slv_hrdata_v[3] = fft_HRDATA; // To arbiter (only from slave 3)
assign slv_hresp_v[3] = fft_HRESP;
assign slv_hready_in_v[3] = fft_HREADYOUT;
// assign slv_hsplit_v[3] = fft_HSPLIT; //changed by agy

assign slv_hrdata_v[4] = scratch_HRDATA; // To arbiter (only from slave 4)
assign slv_hresp_v[4] = scratch_HRESP;
assign slv_hready_in_v[4] = scratch_HREADYOUT;
// assign slv_hsplit_v[4] = 16'b0; //changed by agy

assign slv_hrdata_v[5] = ifft_HRDATA; // To arbiter (only from slave 5)
assign slv_hresp_v[5] = ifft_HRESP;
assign slv_hready_in_v[5] = ifft_HREADYOUT;
// assign slv_hsplit_v[5] = ifft_HSPLIT; //changed by agy

generate
   genvar j;
    for(j = 6; j<15; j = j+1) begin
        assign slv_hrdata_v[j] = 0;
        assign slv_hresp_v[j] = 0;
        // assign slv_hready_in_v[j] = 0;
//      assign slv_hsplit_v[j] = 0; //changed by agy
    end

endgenerate


//////////////////////////////////////////////////////////////////////////////// INSTANTIATIONS ////////////////////////////////////////////////////////////////////////

// Instantiate Pico
picorv32 cpu (
    .clk(clk),
    .resetn(rstn),

    .mem_valid(cpu_mem_valid),
    .mem_ready(cpu_mem_ready),
    .mem_addr(cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_wstrb(cpu_mem_wstrb),
    .mem_rdata(cpu_mem_rdata),
    .mem_instr(cpu_mem_instr)
);

pico_to_ahb wrapper( .clk(clk), .resetn(rstn), 
    .mem_valid(cpu_mem_valid), .mem_ready(cpu_mem_ready), .mem_addr(cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata), .mem_wstrb(cpu_mem_wstrb), .mem_rdata(cpu_mem_rdata),
    .mem_instr(cpu_mem_instr),

    .mst_haddr(cpu_haddr), 
    .mst_htrans(cpu_htrans), 
    .mst_hsize(cpu_hsize), 
    .mst_hwrite(cpu_hwrite), 
    .mst_hwdata(cpu_hwdata),
    .mst_hready_out(cpu_hready), 
    .mst_hrdata_out(cpu_hrdata), 
    .mst_hresp_out(cpu_hresp), 
    .mst_hbusreq(cpu_hbusreq),
    .mst_hgrant(cpu_hgrant)
//     .mst_hlock(cpu_hlock), .mst_hburst(cpu_hburst), .mst_hprot(cpu_hprot),  //changed by agy

     );


// Other masters (if any) would be assigned here

ahb_decoder_and_arbiter #(
    .NUM_ARB_MSTS(NUM_ARB_MSTS),
    .DEF_ARB_MST(DEF_ARB_MST),
    .NUM_SLVS(NUM_SLVS),

    .ADDR_LOW_FLAT(ADDR_LOW_FLAT),
    .ADDR_HIGH_FLAT(ADDR_HIGH_FLAT)
) 
arbiter  
(
    .hclk(clk),
    .hresetn(rstn),

    // Master interface
    .mst_hbusreq(mst_hbusreq),
    .mst_htrans(mst_htrans),
    .mst_haddr(mst_haddr),
    .mst_hwrite(mst_hwrite),
    .mst_hwdata(mst_hwdata),
    .mst_hsize(mst_hsize),

    // Slave interface
    .slv_hsel(slv_hsel),
    .hready(slv_hready_in),
    .sel_haddr(slv_haddr_out),
    .sel_hwdata(slv_hwdata_out),
    .sel_hwrite(slv_hwrite_out),
    .sel_hsize(slv_hsize_out),
    .sel_htrans(slv_htrans_out),

// Feedback from slaves to arbiter
    .slv_hready_in_v(slv_hready_in_v),
    .slv_hresp(slv_hresp_v),
    .slv_hrdata(slv_hrdata_v),

    // Outputs to masters
    .mst_hgrant(mst_hgrant),
    .slv_hready_mux(mst_hready_out),
    .slv_hresp_mux(mst_hresp_out),
    .slv_hrdata_mux(mst_hrdata_out)
);

//changed by agy
ahb_apb_bridge #(
    .I2S_RX_BASE(I2S_RX_BASE),
    .I2S_RX_SIZE(I2S_RX_SIZE),
    .I2S_TX_BASE(I2S_TX_BASE),
    .I2S_TX_SIZE(I2S_TX_SIZE),
    .GPIO_BASE(GPIO_BASE),
    .GPIO_SIZE(GPIO_SIZE),
    .WDT_BASE(WDT_BASE),
    .WDT_SIZE(WDT_SIZE)
    )
    bridge (
    .Hclk      (clk),
    .Pclk      (pclk),
    .Hresetn   (rstn),
    .HSEL      (bridge_h_sel_apb),
    .Hwrite    (bridge_h_write),
    .Hreadyin  (bridge_h_ready_in),
    .Htrans    (bridge_h_trans),
    .Haddr     (bridge_h_addr),
    .Hwdata    (bridge_h_wdata),

    .Hreadyout (bridge_h_ready_out),
    .Hresp     (bridge_h_resp),
    .Hrdata    (bridge_h_rdata),

    .Penable   (bridge_p_enable),
    .Pwrite    (bridge_p_write),
    .Paddr     (bridge_p_addr),
    .Pwdata    (bridge_p_wdata),
    .PSEL      (bridge_p_selx),
    
    .PRDATA    (bridge_p_rdata), // {i2s_tx_PRDATA, i2s_PRDATA}
    .PREADY    (bridge_p_ready)
);



SRAM_1024x32_ahb_wrapper sram0 (
    .HCLK(clk),
    .HRESETn(rstn),
    .HSEL(sram_HSEL),
    .HADDR(sram_HADDR),
    .HTRANS(sram_HTRANS),
    .HWRITE(sram_HWRITE),
    .HREADY(sram_HREADY),
    .HWDATA(sram_HWDATA),
    .HSIZE(sram_HSIZE),
    .HREADYOUT(sram_HREADYOUT),
    .HRDATA(sram_HRDATA)
);

EF_I2S_APB #(.AW(i2s_AW), .DW(i2s_DW)) i2s_apb (
    .PCLK(pclk),
    .PRESETn(rstn),
    .PWRITE(i2s_PWRITE),
    .PWDATA(i2s_PWDATA),
    .PADDR(i2s_PADDR),
    .PENABLE(i2s_PENABLE),
    .PSEL(i2s_PSEL),
    .PREADY(i2s_PREADY),
    .PRDATA(i2s_PRDATA),
    .IRQ(i2s_IRQ),
    .ws(rx_ws),
    .sck(rx_sck),
    .sdi(sdi)
);

EF_I2S_TX_APB #(.AW(i2s_AW), .DW(i2s_DW)) i2s_tx_apb (
    .sc_testmode(1'b0),
    .PCLK(pclk),
    .PRESETn(rstn),
    .PWRITE(i2s_tx_PWRITE),
    .PWDATA(i2s_tx_PWDATA),
    .PADDR(i2s_tx_PADDR),
    .PENABLE(i2s_tx_PENABLE),
    .PSEL(i2s_tx_PSEL),
    .PREADY(i2s_tx_PREADY),
    .PRDATA(i2s_tx_PRDATA),
    .IRQ(i2s_tx_IRQ),
    .sdo(sdo),
    .ws(tx_ws),
    .sck(tx_sck)
);

boot_rom_ahb boot_rom (
    .HCLK(clk),
    .HRESETn(rstn),
    .HSEL(boot_rom_HSEL),
    .HADDR(boot_rom_HADDR),
    .HTRANS(boot_rom_HTRANS),
    .HWRITE(boot_rom_HWRITE),
    .HREADY(boot_rom_HREADY),
    .HREADYOUT(boot_rom_HREADYOUT),
    .HRDATA(boot_rom_HRDATA),
    .HRESP(boot_rom_HRESP)
);

    // Shared RAM wires for FFT
    wire        fft_ram_we_a;
    wire [8:0]  fft_ram_addr_a;
    wire [31:0] fft_ram_din_a;
    wire [31:0] fft_ram_dout_a;
    wire        fft_ram_we_b;
    wire [8:0]  fft_ram_addr_b;
    wire [31:0] fft_ram_din_b;
    wire [31:0] fft_ram_dout_b;
    wire        fft_busy;
    
    // Slave 3: FFT Accelerator Wrapper
    nm32_fft_ahb_wrapper #(
        .BASE_ADDR(32'h4000_0000),
        .ADDR_MASK(32'h0000_0FFF)
    ) fft_wrapper_inst (
        .hclk(clk),
        .hresetn(rstn),
        
        .slv_hsel(fft_HSEL),
        .slv_haddr(fft_HADDR),
        .slv_hwrite(fft_HWRITE),
        .slv_htrans(fft_HTRANS),
        .slv_hsize(fft_HSIZE),
//         .slv_hburst(fft_HBURST), //changed by agy
        .slv_hwdata(fft_HWDATA),
//         .slv_hprot(fft_HPROT), //changed by agy
        .slv_hready(fft_HREADY),
//         .slv_hmaster(fft_HMASTER), //changed by agy
//         .slv_hmastlock(fft_HMASTLOCK), //changed by agy
        
        .slv_hready_out(fft_HREADYOUT),
        .slv_hresp(fft_HRESP),
        .slv_hrdata(fft_HRDATA),
//         .slv_hsplit(fft_HSPLIT), //changed by agy
        .slv_err(),
        
        .fft_irq(fft_irq),
        
        .ram_we_a(fft_ram_we_a),
        .ram_addr_a(fft_ram_addr_a),
        .ram_din_a(fft_ram_din_a),
        .ram_dout_a(fft_ram_dout_a),
        .ram_we_b(fft_ram_we_b),
        .ram_addr_b(fft_ram_addr_b),
        .ram_din_b(fft_ram_din_b),
        .ram_dout_b(fft_ram_dout_b),
        .fft_busy(fft_busy)
    );

    // Shared RAM wires for IFFT
    wire        ifft_ram_we_a;
    wire [8:0]  ifft_ram_addr_a;
    wire [31:0] ifft_ram_din_a;
    wire [31:0] ifft_ram_dout_a;
    wire        ifft_ram_we_b;
    wire [8:0]  ifft_ram_addr_b;
    wire [31:0] ifft_ram_din_b;
    wire [31:0] ifft_ram_dout_b;
    wire        ifft_busy;
    
    // Accelerator Port MUXing (FFT vs IFFT) based on busy signals
    // Assuming they don't run at the same exact cycle
    wire        accel_we_a   = fft_busy ? fft_ram_we_a   : ifft_ram_we_a;
    wire [8:0]  accel_addr_a = fft_busy ? fft_ram_addr_a : ifft_ram_addr_a;
    wire [31:0] accel_din_a  = fft_busy ? fft_ram_din_a  : ifft_ram_din_a;
    
    wire        accel_we_b   = fft_busy ? fft_ram_we_b   : ifft_ram_we_b;
    wire [8:0]  accel_addr_b = fft_busy ? fft_ram_addr_b : ifft_ram_addr_b;
    wire [31:0] accel_din_b  = fft_busy ? fft_ram_din_b  : ifft_ram_din_b;
    
    wire [31:0] accel_dout_a;
    wire [31:0] accel_dout_b;
    
    assign fft_ram_dout_a = accel_dout_a;
    assign fft_ram_dout_b = accel_dout_b;
    
    assign ifft_ram_dout_a = accel_dout_a;
    assign ifft_ram_dout_b = accel_dout_b;

    // Slave 4: Ping-Pong Shared RAM (Replaces Scratchpad)
    ping_pong_ram scratchpad_sram (
        .clk(clk),
        .rstn(rstn),
        
        // AHB Slave Interface
        .hsel(scratch_HSEL),
        .haddr(scratch_HADDR),
        .hwrite(scratch_HWRITE),
        .htrans(scratch_HTRANS),
        .hsize(scratch_HSIZE),
        .hwdata(scratch_HWDATA),
        .hready_in(scratch_HREADY),
        .hready_out(scratch_HREADYOUT),
        .hrdata(scratch_HRDATA),
        
        // Shared Accelerator Ports
        .accel_we_a(accel_we_a),
        .accel_addr_a(accel_addr_a),
        .accel_din_a(accel_din_a),
        .accel_dout_a(accel_dout_a),
        
        .accel_we_b(accel_we_b),
        .accel_addr_b(accel_addr_b),
        .accel_din_b(accel_din_b),
        .accel_dout_b(accel_dout_b)
    );

    // Slave 5: IFFT Accelerator Wrapper
    nm32_ifft_ahb_wrapper #(
        .BASE_ADDR(32'h6000_0000),
        .ADDR_MASK(32'h0000_0FFF)
    ) ifft_wrapper_inst (
        .hclk(clk),
        .hresetn(rstn),
        
        .slv_hsel(ifft_HSEL),
        .slv_haddr(ifft_HADDR),
        .slv_hwrite(ifft_HWRITE),
        .slv_htrans(ifft_HTRANS),
        .slv_hsize(ifft_HSIZE),
//         .slv_hburst(ifft_HBURST), //changed by agy
        .slv_hwdata(ifft_HWDATA),
//         .slv_hprot(ifft_HPROT), //changed by agy
        .slv_hready(ifft_HREADY),
//         .slv_hmaster(ifft_HMASTER), //changed by agy
//         .slv_hmastlock(ifft_HMASTLOCK), //changed by agy
        
        .slv_hready_out(ifft_HREADYOUT),
        .slv_hresp(ifft_HRESP),
        .slv_hrdata(ifft_HRDATA),
//         .slv_hsplit(ifft_HSPLIT), //changed by agy
        .slv_err(),
        
        .ifft_irq(ifft_irq),
        
        .ram_we_a(ifft_ram_we_a),
        .ram_addr_a(ifft_ram_addr_a),
        .ram_din_a(ifft_ram_din_a),
        .ram_dout_a(ifft_ram_dout_a),
        .ram_we_b(ifft_ram_we_b),
        .ram_addr_b(ifft_ram_addr_b),
        .ram_din_b(ifft_ram_din_b),
        .ram_dout_b(ifft_ram_dout_b),
        .ifft_busy(ifft_busy)
    );



// SIMPLE MEMORY (TEMP)
// reg [31:0] memory [0:1023];+

// always @(posedge clk) begin
//     mem_ready <= 0;

//     if (mem_valid) begin
//         mem_ready <= 1;

//         if (mem_wstrb)
//             memory[mem_addr[11:2]] <= mem_wdata;

//         mem_rdata <= memory[mem_addr[11:2]];
//     end
// end

endmodule
