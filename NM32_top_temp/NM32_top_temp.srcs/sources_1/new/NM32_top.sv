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
    input wire [1-1:0] ws,
    input wire [1-1:0] sck,
    input wire [1-1:0] sdi,
    output wire [1-1:0] sdo
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////           Wires and Parameters           ////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam NUM_SLVS = 3;
localparam TRAN_WIDTH = 3;
localparam DATA_WIDTH = 32;

localparam i2s_AW = 4;
localparam i2s_DW = 32;

wire remap;

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
wire cpu_hlock;
wire [2:0] cpu_hburst;
wire [3:0] cpu_hprot;

assign cpu_hbusreq = 1; // CPU always requests the bus?
assign cpu_hlock = 0;   // No locked transfers for now
assign remap = 0;  // No remapping for now
assign cpu_hburst = 3'b000; // No bursts for now
assign cpu_hprot = 4'b0011; // Default protection


// Pico native signals
wire        cpu_mem_valid;
wire        cpu_mem_ready; 
wire [31:0] cpu_mem_addr;
wire [31:0] cpu_mem_wdata;
wire [3:0]  cpu_mem_wstrb;
wire [31:0] cpu_mem_rdata;


// Arbiter wires

wire [14:0] mst_hbusreq;   // [i] = master i hbusreq
wire [14:0] mst_hlock;
wire [29:0] mst_htrans;    // [2i+1:2i] = master i htrans
wire [31:0] mst_haddr   [0:14];
wire [14:0] mst_hwrite;
wire [2:0]  mst_hsize   [0:14];
wire [2:0]  mst_hburst  [0:14];
wire [3:0]  mst_hprot   [0:14];
wire [31:0] mst_hwdata  [0:14];

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
wire [2:0]          slv_hburst_out;
wire [3:0]          slv_hprot_out;
wire [31:0]         slv_hwdata_out;
wire [3:0]          slv_hmaster_out;
wire                slv_hmastlock_out;
wire                slv_hready_in;  // hready fed into slaves

// Slave outputs (what each slave drives back)
wire [NUM_SLVS-1:0] slv_hready_in_v;
wire [1:0]          slv_hresp_v   [0:14];
wire [31:0]         slv_hrdata_v  [0:14];
wire [15:0]         slv_hsplit_v  [0:14];


//AHB to APB bridge wires
wire                       bridge_h_write      ;
wire                       bridge_h_sel_apb    ; 
wire                       bridge_h_ready_in   ;
wire [TRAN_WIDTH - 1 : 0]  bridge_h_trans      ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_wdata      ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_addr       ;
wire [DATA_WIDTH - 1 : 0]  bridge_p_rdata      ;

wire                       bridge_h_resp       ;
wire                       bridge_h_ready_out  ;
wire                       bridge_p_enable     ;
wire                       bridge_p_write      ;
wire                       bridge_p_selx       ;
wire [DATA_WIDTH - 1 : 0]  bridge_p_wdata      ;
wire [DATA_WIDTH - 1 : 0]  bridge_p_addr       ;
wire [DATA_WIDTH - 1 : 0]  bridge_h_rdata      ;



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



// CPU is master 0 on the AHB bus
// assign mst_hbusreq = {14'b0, cpu_hbusreq};        //CPU sending to the arbiter
// assign mst_hlock = {14'b0, cpu_hlock};
// assign mst_htrans = {28'b0, cpu_htrans};
// assign mst_haddr = {14'b0, cpu_haddr};
// assign mst_hwrite = {14'b0, cpu_hwrite};
// assign mst_hsize = {14'b0, cpu_hsize};
// assign mst_hburst = {14'b0, cpu_hburst};
// assign mst_hprot = {14'b0, cpu_hprot};
// assign mst_hwdata = {14'b0, cpu_hwdata};

assign mst_hbusreq[0] = cpu_hbusreq;        //CPU sending to the arbiter
assign mst_hlock[0] = cpu_hlock;
assign mst_htrans[1:0] = cpu_htrans;
assign mst_haddr[0] = cpu_haddr;
assign mst_hwrite[0] = cpu_hwrite;
assign mst_hsize[0] = cpu_hsize;
assign mst_hburst[0] = cpu_hburst;
assign mst_hprot[0] = cpu_hprot;
assign mst_hwdata[0] = cpu_hwdata;

generate
    genvar i;
    for(i = 1; i<15; i = i+1) begin
        assign mst_hbusreq[i] = 0;
        assign mst_hlock[i] = 0;
        assign mst_htrans[2*i+1:2*i] = 0;
        assign mst_haddr[i] = 0;
        assign mst_hwrite[i] = 0;
        assign mst_hsize[i] = 0;
        assign mst_hburst[i] = 0;
        assign mst_hprot[i] = 0;
        assign mst_hwdata[i] = 0;
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


assign i2s_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_PADDR = bridge_p_addr[3:0];   // From bridge to APB slave
assign i2s_PENABLE = bridge_p_enable; // From bridge to APB slave

assign i2s_tx_PWRITE = bridge_p_write; // From bridge to APB slave
assign i2s_tx_PWDATA = bridge_p_wdata; // From bridge to APB slave
assign i2s_tx_PADDR = bridge_p_addr[3:0];   // From bridge to APB slave
assign i2s_tx_PENABLE = bridge_p_enable; // From bridge to APB slave


//APB DECODER LOGIC:
//for psel
assign i2s_PSEL = (bridge_p_addr[31:16] == 16'h2000) ? bridge_p_selx : 1'b0;    // From bridge to APB slave
assign i2s_tx_PSEL = (bridge_p_addr[31:16] == 16'h2001) ? bridge_p_selx : 1'b0;    // From bridge to APB slave
//for prdtata:
assign bridge_p_rdata = (i2s_PSEL) ? i2s_PRDATA: 32'b0; // From APB slave to bridge
assign bridge_p_rdata = (i2s_tx_PSEL) ? i2s_tx_PRDATA: 32'b0; // From APB slave to bridge

//Temporary tie off to make i2s always ready, it must be changed after we  make a better bridge.
//nvm we just left it alone,
//also pls look into how to connect irq for i2s and stuff @meera



// assign slv_hrdata_v = {(NUM_SLVS-2){32'b0}, sram_HRDATA, bridge_h_rdata}; // To arbiter (only from slave 0)
// assign slv_hresp_v = {(NUM_SLVS-1){2'b00}, bridge_h_resp}; // To arbiter (only from slave 0)
// assign slv_hready_in_v = {(NUM_SLVS-2){1'b0},sram_HREADYOUT, bridge_h_ready_out}; // To arbiter (only from slave 0)
// assign slv_hsplit_v = {(NUM_SLVS){16'b0}}; // No splits for now


assign slv_hrdata_v[0] = bridge_h_rdata; // To arbiter (only from slave 0)
assign slv_hresp_v[0] = {1'b0, bridge_h_resp}; // To arbiter (only from slave 0)
assign slv_hready_in_v[0] = bridge_h_ready_out; // To arbiter (only from slave 0)
assign slv_hsplit_v[0] = 0; // No splits for now

assign slv_hrdata_v[1] = sram_HRDATA; // To arbiter (only from slave 1)
assign slv_hresp_v[1] = 2'b00; // OKAY response
assign slv_hready_in_v[1] = sram_HREADYOUT; // Ready from SRAM
assign slv_hsplit_v[1] = 0; // No splits for now

assign slv_hrdata_v[2] = boot_rom_HRDATA; // To arbiter (only from slave 2)
assign slv_hresp_v[2] = boot_rom_HRESP; // From boot ROM
assign slv_hready_in_v[2] = boot_rom_HREADYOUT; // From boot ROM
assign slv_hsplit_v[2] = 0; // No splits for

generate
    genvar i;
    for(i = 3; i<15; i = i+1) begin
        assign slv_hrdata_v[i] = 0;
        assign slv_hresp_v[i] = 0;
        assign slv_hready_in_v[i] = 0;
        assign slv_hsplit_v[i] = 0;
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
    .mem_rdata(cpu_mem_rdata)
);

picorv32_ahb wrapper( .clk(clk), .resetn(rstn), 
    .mem_valid(cpu_mem_valid), .mem_ready(cpu_mem_ready), .mem_addr(cpu_mem_addr), 
    .mem_wdata(cpu_mem_wdata), .mem_wstrb(cpu_mem_wstrb), .mem_rdata(cpu_mem_rdata),

    .HADDR(cpu_haddr), .HTRANS(cpu_htrans), .HSIZE(cpu_hsize), .HWRITE(cpu_hwrite), .HWDATA(cpu_hwdata),
    .HREADY(cpu_hready), .HRDATA(cpu_hrdata), .HRESP(cpu_hresp)
     );


// Other masters (if any) would be assigned here

ahb_arbiter #(
    .NUM_ARB(0),
    .NUM_ARB_MSTS(1),
    .DEF_ARB_MST(0),
    .NUM_SLVS(NUM_SLVS),
    .ALG_NUMBER(1),            //Round Robin
    .ADDR_LOW_FLAT({416'b0, 32'h00000000, 32'h3000_0000, 32'h2000_0000}), // Base address of slave 1, 0
    .ADDR_HIGH_FLAT({416'b0, 32'h0000FFFF,32'h3000_FFFF, 32'h200F_FFFF})
) 
arbiter  
(
    .hclk(clk),
    .hresetn(rstn),
    .remap(remap),

    // Master interface
    .mst_hbusreq(mst_hbusreq),
    .mst_hlock(mst_hlock),
    .mst_haddr(mst_haddr),
    .mst_hsize(mst_hsize),
    .mst_htrans(mst_htrans),
    .mst_hwrite(mst_hwrite),
    .mst_hburst(mst_hburst),
    .mst_hprot(mst_hprot),
    .mst_hwdata(mst_hwdata),

    // Slave interface
    .slv_hsel(slv_hsel),
    .slv_haddr_out(slv_haddr_out),
    .slv_hwrite_out(slv_hwrite_out),
    .slv_htrans_out(slv_htrans_out),
    .slv_hsize_out(slv_hsize_out),
    .slv_hburst_out(slv_hburst_out),
    .slv_hprot_out(slv_hprot_out),
    .slv_hwdata_out(slv_hwdata_out),
    .slv_hmaster_out(slv_hmaster_out),
    .slv_hmastlock_out(slv_hmastlock_out),
    .slv_hready_in(slv_hready_in),

// Feedback from slaves to arbiter
    .slv_hready_in_v(slv_hready_in_v),
    .slv_hresp_v(slv_hresp_v),
    .slv_hrdata_v(slv_hrdata_v),
    .slv_hsplit_v(slv_hsplit_v),

    // Outputs to masters
    .mst_hgrant(mst_hgrant),
    .mst_hready_out(mst_hready_out),
    .mst_hresp_out(mst_hresp_out),
    .mst_hrdata_out(mst_hrdata_out)
);

AHB_to_APB_Bridge #(
              .DATA_WIDTH(32),
              .ADDR_WIDTH(32),
              .TRAN_WIDTH(2)

)
bridge (
    //inputs
    .h_clk(clk),
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
    .h_rdata(bridge_h_rdata)   // To arbiter (not used in this simple bridge)

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
    .ws(ws),
    .sck(sck),
    .sdi(sdi)
);

EF_I2S_TX_APB #(.AW(i2s_AW), .DW(i2s_DW)) i2s_tx_apb (
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
    .ws(ws),
    .sck(sck)
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
