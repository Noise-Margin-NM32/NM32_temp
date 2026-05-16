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
    input clk,
    input rst
);


localparam NUM_SLVS = 1;

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
wire cpu_hburst;
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
wire        remap;

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


// CPU is master 0 on the AHB bus
assign mst_hbusreq[0] = cpu_hbusreq;        //CPU sending to the arbiter
assign mst_hlock[0] = cpu_hlock;
assign mst_htrans[1:0] = cpu_htrans;
assign mst_haddr[0] = cpu_haddr;
assign mst_hwrite[0] = cpu_hwrite;
assign mst_hsize[0] = cpu_hsize;
assign mst_hburst[0] = cpu_hburst;
assign mst_hprot[0] = cpu_hprot;
assign mst_hwdata[0] = cpu_hwdata;

assign cpu_hgrant = mst_hgrant[0];  // CPU gets from arbiter
assign cpu_hready = mst_hready_out;
assign cpu_hrdata = mst_hrdata_out;
assign cpu_hresp = mst_hresp_out;

// Instantiate Pico
picorv32 cpu (
    .clk(clk),
    .resetn(~rst),

    .mem_valid(cpu_mem_valid),
    .mem_ready(cpu_mem_ready),
    .mem_addr(cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_wstrb(cpu_mem_wstrb),
    .mem_rdata(cpu_mem_rdata)
);

picorv32_ahb wrapper( .clk(clk), .rst(rst), 
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
    .ADDR_LOW_FLAT({480'b0, 32'h2000_0000}), // Base address of slave 0
    .ADDR_HIGH_FLAT({480'b0, 32'h2000_FFFF})
) 
arbiter  
(
    .hclk(clk),
    .hresetn(~rst),
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
    .slv_haddr(slv_haddr_out),
    .slv_hwrite(slv_hwrite_out),
    .slv_htrans(slv_htrans_out),
    .slv_hsize(slv_hsize_out),
    .slv_hburst(slv_hburst_out),
    .slv_hprot(slv_hprot_out),
    .slv_hwdata(slv_hwdata_out),
    .slv_hmaster(slv_hmaster_out),
    .slv_hmastlock(slv_hmastlock_out),
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





// SIMPLE MEMORY (TEMP)
// reg [31:0] memory [0:1023];

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
