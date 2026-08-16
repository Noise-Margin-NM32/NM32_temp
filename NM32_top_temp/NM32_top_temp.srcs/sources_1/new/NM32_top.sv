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
    input wire rstn,
    input wire [1-1:0] rx_ws,
    input wire [1-1:0] rx_sck,
    output wire [1-1:0] tx_ws,
    output wire [1-1:0] tx_sck,
    input wire [1-1:0] sdi,
    output wire [1-1:0] sdo,
    // SPI Master Ports
    output wire spi_clk,
    output wire [3:0] spi_csn,
    output wire [1:0] spi_mode,
    output wire [3:0] spi_sdo,
    input wire [3:0] spi_sdi,
    
    // GPIO Ports
    input  wire [7:0] gpio_in,
    output wire [7:0] gpio_out,
    output wire [7:0] gpio_oe
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////           Wires and Parameters           ////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam NUM_ARB_MSTS = 4; // Number of AHB masters in the system
localparam DEF_ARB_MST  = 0; // Default AHB master to be granted bus access when no other masters are requesting
localparam NUM_SLVS = 7;

localparam APB_NUM_SLVS = 2;

localparam TRAN_WIDTH = 2;
localparam DATA_WIDTH = 32;

localparam SPI_BUF_DEPTH = 10;


localparam [32*16-1:0] ADDR_LOW_FLAT  = {288'b0, 32'h7000_0000, 32'h6000_0000, 32'h5000_0000, 32'h4000_0000, 32'h0000_0000, 32'h3000_0000, 32'h2000_0000}; //clic, ifft, scratchpad, fft, bootrom, sram, apbbridge
localparam [32*16-1:0] ADDR_HIGH_FLAT = {288'b0, 32'h7000_0FFF, 32'h6000_0FFF, 32'h5000_3FFF, 32'h4000_0FFF, 32'h0000_FFFF, 32'h3000_FFFF, 32'h200F_FFFF};

localparam i2s_AW = 4;
localparam i2s_DW = 32;



// localparam SPI_BUF_DEPTH = 10;

localparam NUM_APB_SLAVES = 6; // GPIO, I2S, I2S_TX, SPI, DMA_RX, DMA_TX
localparam [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_START = {32'h2005_0000, 32'h2004_0000, 32'h2003_0000, 32'h2002_0000, 32'h2001_0000, 32'h2000_0000};
localparam [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_END   = {32'h2005_FFFF, 32'h2004_FFFF, 32'h2003_FFFF, 32'h2002_FFFF, 32'h2001_FFFF, 32'h2000_FFFF};

// wire remap;

// wire pclk; // For APB peripherals
reg pclk_reg;

// Ibex Instruction Memory - AHB bus wires
wire [31:0] ibex_imem_haddr;
wire [1:0]  ibex_imem_htrans;
wire [2:0]  ibex_imem_hsize;
wire        ibex_imem_hwrite;
wire [31:0] ibex_imem_hwdata;
wire        ibex_imem_hready;
wire [31:0] ibex_imem_hrdata;
wire [1:0]  ibex_imem_hresp;
wire        ibex_imem_hgrant;
wire        ibex_imem_hbusreq;

// Ibex Data Memory - AHB bus wires
wire [31:0] ibex_dmem_haddr;
wire [1:0]  ibex_dmem_htrans;
wire [2:0]  ibex_dmem_hsize;
wire        ibex_dmem_hwrite;
wire [31:0] ibex_dmem_hwdata;
wire        ibex_dmem_hready;
wire [31:0] ibex_dmem_hrdata;
wire [1:0]  ibex_dmem_hresp;
wire        ibex_dmem_hgrant;
wire        ibex_dmem_hbusreq;
// wire cpu_hlock; //changed by agy
// wire [2:0] cpu_hburst; //changed by agy
// wire [3:0] cpu_hprot; //changed by agy

// assign cpu_hbusreq; // CPU always requests the bus?
// assign cpu_hlock;   // No locked transfers for now
// assign remap = 1'b0;  // No remapping for now
// assign cpu_hburst; // No bursts for now
// assign cpu_hprot; // Default protection


// Ibex native signals handled directly inside wrappers


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

wire                       bridge_h_write      ;
wire                       bridge_h_sel_apb    ; 
wire                       bridge_h_ready_in   ;
wire [TRAN_WIDTH - 1 : 0]  bridge_h_trans      ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_wdata      ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_addr       ;
wire [NUM_APB_SLAVES-1:0][DATA_WIDTH - 1 : 0]  bridge_p_rdata      ;

wire                       bridge_h_resp       ;
wire                       bridge_h_ready_out  ;
wire                       bridge_p_enable     ;
wire                       bridge_p_write      ;
wire [NUM_APB_SLAVES-1:0]  bridge_p_selx       ;
wire [DATA_WIDTH - 1 : 0]  bridge_p_wdata      ;
wire [DATA_WIDTH - 1 : 0]  bridge_p_addr       ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_rdata      ;

wire [NUM_APB_SLAVES-1:0]       bridge_pready; // From APB slaves to bridge

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



 wire [31:0] spi_PADDR;
 wire [31:0] spi_PWDATA;
 wire        spi_PWRITE;
 wire         spi_PSEL;
 wire         spi_PENABLE;
 wire [ 31:0] spi_PRDATA;
 wire         spi_PREADY;
 wire         spi_PSLVERR;//???? What to tie off to
 wire [ 1:0]  spi_events;//????? WHat to tie off to 


//  wire [1-1:0] sdo;



// DMA RX Wires
wire        dma_rx_irq;
wire        dma_rx_check;
wire [31:0] dma_rx_PADDR;
wire [31:0] dma_rx_PWDATA;
wire        dma_rx_PWRITE;
wire        dma_rx_PSEL;
wire        dma_rx_PENABLE;
wire [31:0] dma_rx_PRDATA;
wire        dma_rx_PREADY;

///////////////////////////////////////////////////////////////////////////TIE OFFS////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        pclk_reg <= 1'b0;
    end else begin
        pclk_reg <= ~pclk_reg; // Divide clk by 2 for APB peripherals
    end
end

assign pclk = pclk_reg;


assign mst_hbusreq[0] = ibex_imem_hbusreq;
assign mst_htrans[0] = ibex_imem_htrans;
assign mst_haddr[0] = ibex_imem_haddr;
assign mst_hwrite[0] = ibex_imem_hwrite;
assign mst_hsize[0] = ibex_imem_hsize;
assign mst_hwdata[0] = ibex_imem_hwdata;
assign ibex_imem_hgrant = mst_hgrant[0];
assign ibex_imem_hready = mst_hready_out;
assign ibex_imem_hrdata = mst_hrdata_out;
assign ibex_imem_hresp = mst_hresp_out;

assign mst_hbusreq[1] = ibex_dmem_hbusreq;
assign mst_htrans[1] = ibex_dmem_htrans;
assign mst_haddr[1] = ibex_dmem_haddr;
assign mst_hwrite[1] = ibex_dmem_hwrite;
assign mst_hsize[1] = ibex_dmem_hsize;
assign mst_hwdata[1] = ibex_dmem_hwdata;
assign ibex_dmem_hgrant = mst_hgrant[1];
assign ibex_dmem_hready = mst_hready_out;
assign ibex_dmem_hrdata = mst_hrdata_out;
assign ibex_dmem_hresp = mst_hresp_out;

generate
    genvar i;
    for(i = 2; i<15; i = i+1) begin
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

// Slave 6: CLIC Wrapper connections
wire        clic_HSEL;
wire [31:0] clic_HADDR;
wire [1:0]  clic_HTRANS;
wire        clic_HWRITE;
wire [2:0]  clic_HSIZE;
wire [31:0] clic_HWDATA;
wire        clic_HREADY;
wire        clic_HREADYOUT;
wire [1:0]  clic_HRESP;
wire [31:0] clic_HRDATA;

assign clic_HSEL      = slv_hsel[6];
assign clic_HADDR     = slv_haddr_out;
assign clic_HTRANS    = slv_htrans_out;
assign clic_HWRITE    = slv_hwrite_out;
assign clic_HSIZE     = slv_hsize_out;
assign clic_HWDATA    = slv_hwdata_out;
assign clic_HREADY    = slv_hready_in;

assign i2s_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_PADDR = bridge_p_addr;   // From bridge to APB slave
assign i2s_PENABLE = bridge_p_enable; // From bridge to APB slave
assign i2s_PSEL = bridge_p_selx[0]; // From bridge to APB slave
assign bridge_pready[0] = i2s_PREADY; // From APB slave to bridge
assign bridge_p_rdata[0] = i2s_PRDATA; // From APB slave to bridge

assign i2s_tx_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_tx_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_tx_PADDR = bridge_p_addr;   // From bridge to APB slave
assign i2s_tx_PENABLE = bridge_p_enable; // From bridge to APB slave
assign i2s_tx_PSEL = bridge_p_selx[1]; // From bridge to APB slave
assign bridge_pready[1] = i2s_tx_PREADY; // From APB slave to bridge
assign bridge_p_rdata[1] = i2s_tx_PRDATA; // From APB slave to bridge

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

assign slv_hrdata_v[6] = clic_HRDATA; // To arbiter (only from slave 6)
assign slv_hresp_v[6] = {1'b0, clic_HRESP};
assign slv_hready_in_v[6] = clic_HREADYOUT;

generate
   genvar j;
    for(j = 7; j<NUM_SLVS; j = j+1) begin
//        assign slv_hrdata_v[j] = 0;
//        assign slv_hresp_v[j] = 0;
         assign slv_hready_in_v[j] = 0;
//      assign slv_hsplit_v[j] = 0; //changed by agy
    end

endgenerate


assign spi_PADDR = bridge_p_addr; // From bridge to APB slave
assign spi_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign spi_PWRITE = bridge_p_write; // From bridge to APB slave
assign spi_PSEL = bridge_p_selx[2]; // From bridge to APB slave
assign spi_PENABLE = bridge_p_enable; // From bridge to APB slave
assign bridge_pready[2] = spi_PREADY; // From APB slave to bridge
assign bridge_p_rdata[2] = spi_PRDATA; // From APB slave to

assign dma_rx_PADDR = bridge_p_addr;
assign dma_rx_PWDATA = bridge_p_wdata;
assign dma_rx_PWRITE = bridge_p_write;
assign dma_rx_PSEL = bridge_p_selx[3];
assign dma_rx_PENABLE = bridge_p_enable;
assign bridge_pready[3] = dma_rx_PREADY;
assign bridge_p_rdata[3] = dma_rx_PRDATA;

wire        dma_tx_irq;
wire        dma_tx_check;
wire [31:0] dma_tx_PADDR;
wire [31:0] dma_tx_PWDATA;
wire        dma_tx_PWRITE;
wire        dma_tx_PSEL;
wire        dma_tx_PENABLE;
wire [31:0] dma_tx_PRDATA;
wire        dma_tx_PREADY;

assign dma_tx_PADDR = bridge_p_addr;
assign dma_tx_PWDATA = bridge_p_wdata;
assign dma_tx_PWRITE = bridge_p_write;
assign dma_tx_PSEL = bridge_p_selx[5];
assign dma_tx_PENABLE = bridge_p_enable;
assign bridge_pready[5] = dma_tx_PREADY;
assign bridge_p_rdata[5] = dma_tx_PRDATA;

// GPIO Wires and Connections
wire [31:0] gpio_PADDR;
wire [31:0] gpio_PWDATA;
wire        gpio_PWRITE;
wire        gpio_PSEL;
wire        gpio_PENABLE;
wire [31:0] gpio_PRDATA;
wire        gpio_PREADY;
wire        gpio_IRQ;

assign gpio_PADDR = bridge_p_addr;
assign gpio_PWDATA = bridge_p_wdata;
assign gpio_PWRITE = bridge_p_write;
assign gpio_PSEL = bridge_p_selx[4];
assign gpio_PENABLE = bridge_p_enable;
assign bridge_pready[4] = gpio_PREADY;
assign bridge_p_rdata[4] = gpio_PRDATA;

dma_controller dma_rx_inst (
    .PCLK(pclk),
    .HCLK(clk),
    .PRESETN(rstn),
    .HRESETN(rstn),
    
    // APB Slave Interface
    .PSEL(dma_rx_PSEL),
    .PENABLE(dma_rx_PENABLE),
    .PWRITE(dma_rx_PWRITE),
    .PADDR(dma_rx_PADDR),
    .PWDATA(dma_rx_PWDATA),
    .PRDATA(dma_rx_PRDATA),
    .PREADY(dma_rx_PREADY),
    
    // AHB Master Interface
    .HGRANT(mst_hgrant[2]),
    .HBUSREQ(mst_hbusreq[2]),
    .HADDR(mst_haddr[2]),
    .HTRANS(mst_htrans[2]),
    .HWRITE(mst_hwrite[2]),
    .HREADY(mst_hready_out),
    .irq(dma_rx_irq),
    .HRDATA(mst_hrdata_out),
    .HWDATA(mst_hwdata[2]),
    .check(dma_rx_check)
);
assign mst_hsize[2] = 3'b010; // 32-bit transfers

dma_controller dma_tx_inst (
    .PCLK(pclk),
    .HCLK(clk),
    .PRESETN(rstn),
    .HRESETN(rstn),
    
    // APB Slave Interface
    .PSEL(dma_tx_PSEL),
    .PENABLE(dma_tx_PENABLE),
    .PWRITE(dma_tx_PWRITE),
    .PADDR(dma_tx_PADDR),
    .PWDATA(dma_tx_PWDATA),
    .PRDATA(dma_tx_PRDATA),
    .PREADY(dma_tx_PREADY),
    
    // AHB Master Interface
    .HGRANT(mst_hgrant[3]),
    .HBUSREQ(mst_hbusreq[3]),
    .HADDR(mst_haddr[3]),
    .HTRANS(mst_htrans[3]),
    .HWRITE(mst_hwrite[3]),
    .HREADY(mst_hready_out),
    .irq(dma_tx_irq),
    .HRDATA(mst_hrdata_out),
    .HWDATA(mst_hwdata[3]),
    .check(dma_tx_check)
);
assign mst_hsize[3] = 3'b010; // 32-bit transfers

//////////////////////////////////////////////////////////////////////////////// INSTANTIATIONS ////////////////////////////////////////////////////////////////////////
// CLIC Output processing
wire        clic_irq_valid;
wire [3:0]  clic_irq_id;
wire [2:0]  clic_irq_level;
wire [31:0] cpu_irq;

// Instantiate Ibex
wire        instr_req;
wire        instr_gnt;
wire        instr_rvalid;
wire [31:0] instr_addr;
wire [31:0] instr_rdata;
wire        instr_err;

wire        data_req;
wire        data_gnt;
wire        data_rvalid;
wire        data_we;
wire [3:0]  data_be;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire        data_err;

ibex_core #(
    .RV32M(ibex_pkg::RV32MFast),
    .BranchPredictor(1),
    .WritebackStage(1)
) u_ibex_core (
    .clk_i(clk),
    .rst_ni(rstn),

    .hart_id_i(32'h0),
    .boot_addr_i(32'h0000_0000),

    .instr_req_o(instr_req),
    .instr_gnt_i(instr_gnt),
    .instr_rvalid_i(instr_rvalid),
    .instr_addr_o(instr_addr),
    .instr_rdata_i(instr_rdata),
    .instr_err_i(instr_err),

    .data_req_o(data_req),
    .data_gnt_i(data_gnt),
    .data_rvalid_i(data_rvalid),
    .data_we_o(data_we),
    .data_be_o(data_be),
    .data_addr_o(data_addr),
    .data_wdata_o(data_wdata),
    .data_rdata_i(data_rdata),
    .data_err_i(data_err),

    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(clic_irq_valid),
    .irq_fast_i(15'b0),
    .irq_nm_i(1'b0),
    .irq_pending_o(),
    .crash_dump_o(),
    .double_fault_seen_o(),
    
    .debug_req_i(1'b0),
    .fetch_enable_i(ibex_pkg::IbexMuBiOn),
    .mcounteren_writable_i(ibex_pkg::IbexMuBiOn),
    .alert_minor_o(),
    .alert_major_internal_o(),
    .alert_major_bus_o(),
    .core_busy_o()
);

// Instruction Memory Wrapper
ibex_to_ahb imem_wrapper (
    .clk_i(clk),
    .rst_ni(rstn),
    .req_i(instr_req),
    .gnt_o(instr_gnt),
    .addr_i(instr_addr),
    .we_i(1'b0),
    .be_i(4'b1111),
    .wdata_i(32'b0),
    .rvalid_o(instr_rvalid),
    .rdata_o(instr_rdata),
    .err_o(instr_err),
    
    .HADDR(ibex_imem_haddr),
    .HTRANS(ibex_imem_htrans),
    .HSIZE(ibex_imem_hsize),
    .HWRITE(ibex_imem_hwrite),
    .HWDATA(ibex_imem_hwdata),
    .HRDATA(ibex_imem_hrdata),
    .HREADY(ibex_imem_hready),
    .HRESP(ibex_imem_hresp),
    .HBUSREQ(ibex_imem_hbusreq),
    .HGRANT(ibex_imem_hgrant)
);

// Data Memory Wrapper
ibex_to_ahb dmem_wrapper (
    .clk_i(clk),
    .rst_ni(rstn),
    .req_i(data_req),
    .gnt_o(data_gnt),
    .addr_i(data_addr),
    .we_i(data_we),
    .be_i(data_be),
    .wdata_i(data_wdata),
    .rvalid_o(data_rvalid),
    .rdata_o(data_rdata),
    .err_o(data_err),
    
    .HADDR(ibex_dmem_haddr),
    .HTRANS(ibex_dmem_htrans),
    .HSIZE(ibex_dmem_hsize),
    .HWRITE(ibex_dmem_hwrite),
    .HWDATA(ibex_dmem_hwdata),
    .HRDATA(ibex_dmem_hrdata),
    .HREADY(ibex_dmem_hready),
    .HRESP(ibex_dmem_hresp),
    .HBUSREQ(ibex_dmem_hbusreq),
    .HGRANT(ibex_dmem_hgrant)
);

// Convert CLIC's vectored output into a standard 32-bit irq vector for picorv32
assign cpu_irq = clic_irq_valid ? (32'b1 << clic_irq_id) : 32'b0;

// Bundle peripheral interrupts for the CLIC
wire [15:0] clic_intr_src;
assign clic_intr_src[0] = i2s_IRQ;
assign clic_intr_src[1] = i2s_tx_IRQ;
assign clic_intr_src[2] = fft_irq;
assign clic_intr_src[3] = ifft_irq;
assign clic_intr_src[4] = dma_rx_irq;
assign clic_intr_src[5] = dma_tx_irq;
assign clic_intr_src[6] = gpio_IRQ;
assign clic_intr_src[15:7] = 9'b0;

clic_ahb clic_inst (
    .hclk(clk),
    .hresetn(rstn),
    
    .hsel_i(clic_HSEL),
    .haddr_i(clic_HADDR),
    .htrans_i(clic_HTRANS),
    .hwrite_i(clic_HWRITE),
    .hsize_i(clic_HSIZE),
    .hwdata_i(clic_HWDATA),
    .hready_o(clic_HREADYOUT),
    .hrdata_o(clic_HRDATA),
    .hresp_o(clic_HRESP[0]),
    
    .intr_src_i(clic_intr_src),
    
    .irq_valid_o(clic_irq_valid),
    .irq_id_o(clic_irq_id),
    .irq_level_o(clic_irq_level)
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
AHB_to_APB_Bridge #(
              .DATA_WIDTH(32),
              .ADDR_WIDTH(32),
              .TRAN_WIDTH(2),
              .NUM_APB_SLAVES(NUM_APB_SLAVES),
              .SLAVE_ADDR_START(SLAVE_ADDR_START),
              .SLAVE_ADDR_END(SLAVE_ADDR_END)

)
bridge (
    //inputs
    .h_clk(clk),
    .pclk(pclk), // ADDED PCLK
    .h_reset_n(rstn),
    .h_write(bridge_h_write), // From arbiter to bridge
    .h_sel_apb(bridge_h_sel_apb), // Assuming slave 0 is the APB bridge
    .h_ready_in(bridge_h_ready_in), // Ready from slave 0
    .h_trans(bridge_h_trans), // From arbiter to bridge
    .h_wdata(bridge_h_wdata), // From arbiter to bridge
    .h_addr(bridge_h_addr),   // From arbiter to bridge
    .p_rdata(bridge_p_rdata), // From APB slave to bridge
    //outputs
    .h_resp(bridge_h_resp), // to arbiter
    .h_ready_out(bridge_h_ready_out), // To slave 0
    .p_enable(bridge_p_enable), // To APB slave (not used in this simple bridge)
    .p_write(bridge_p_write),  // To APB slave (not used in this simple bridge)
    .p_selx(bridge_p_selx),   // To APB slave (not used in this simple bridge)
    .p_wdata(bridge_p_wdata),  // To APB slave (not used in this simple bridge)
    .p_addr(bridge_p_addr),    // To APB slave (not used in this simple bridge)
    .h_rdata(bridge_h_rdata),   // To arbiter (not used in this simple bridge)
    .pready(bridge_pready)

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

EF_GPIO8_APB gpio_apb_inst (
    .PCLK(pclk),
    .PRESETn(rstn),
    .PWRITE(gpio_PWRITE),
    .PWDATA(gpio_PWDATA),
    .PADDR(gpio_PADDR),
    .PENABLE(gpio_PENABLE),
    .PSEL(gpio_PSEL),
    .PREADY(gpio_PREADY),
    .PRDATA(gpio_PRDATA),
    .IRQ(gpio_IRQ),
    .io_in(gpio_in),
    .io_out(gpio_out),
    .io_oe(gpio_oe)
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



    apb_spi_master #(
        .BUFFER_DEPTH(SPI_BUF_DEPTH),
        .APB_ADDR_WIDTH(12)
    ) spi_inst (
    .HCLK   (pclk),
    .HRESETn(rstn),
    .PADDR  (spi_PADDR[11:0]),
    .PWDATA (spi_PWDATA),
    .PWRITE (spi_PWRITE),
    .PSEL   (spi_PSEL),
    .PENABLE(spi_PENABLE),
    .PRDATA (spi_PRDATA),
    .PREADY (spi_PREADY),
    .PSLVERR(spi_PSLVERR),

    .events_o(spi_events),

    .spi_clk (spi_clk),
    .spi_csn0(spi_csn[0]),
    .spi_csn1(spi_csn[1]),
    .spi_csn2(spi_csn[2]),
    .spi_csn3(spi_csn[3]),
    .spi_mode(spi_mode),
    .spi_sdo0(spi_sdo[0]),
    .spi_sdo1(spi_sdo[1]),
    .spi_sdo2(spi_sdo[2]),
    .spi_sdo3(spi_sdo[3]),
    .spi_sdi0(spi_sdi[0]),
    .spi_sdi1(spi_sdi[1]),
    .spi_sdi2(spi_sdi[2]),
    .spi_sdi3(spi_sdi[3])
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
