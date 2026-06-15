// *******************************************************************
// AHB system generator - Combined Interconnect (Arbiter + Decoder)
// *******************************************************************

`include "ahb_package.vh"

module ahb_decoder_and_arbiter #(
    parameter NUM_ARB_MSTS = 4,   // Number of active hardware masters
    parameter DEF_ARB_MST  = 0,   // Fallback master index when bus is completely idle
    parameter NUM_SLVS     = 4,   // Number of individual slave modules
    
    // Slave address ranges - flat arrays, index 0..NUM_SLVS-1
    parameter [32*16-1:0] ADDR_LOW_FLAT  = 0,
    parameter [32*16-1:0] ADDR_HIGH_FLAT = 0
)(
    input  wire                 hclk,           // Main system clock source
    input  wire                 hresetn,         // System-wide asynchronous active-low reset

    // -----------------------------------------------------------------------
    // Master Interfaces (Inputs from Masters to Interconnect Matrix)
    // -----------------------------------------------------------------------
    input  wire [14:0]          mst_hbusreq,     // Array of master request lines
    input  wire [29:0]          mst_htrans,      // Flattened master transfer status states
    input  wire [15*32-1:0]     mst_haddr_flat,  // Flattened master target addresses
    input  wire [14:0]          mst_hwrite,      // Flattened master write control bits
    input  wire [15*32-1:0]     mst_hwdata_flat, // Flattened master write payload data buses
    input  wire [15*3-1:0]      mst_hsize_flat,  // Flattened master data width size configurations

    // -----------------------------------------------------------------------
    // Master Feedback (Outputs from Interconnect Matrix back to Masters)
    // -----------------------------------------------------------------------
    output wire [14:0]          mst_hgrant,      // Registered master bus allocation grant lines
    output wire                 slv_hready_mux,  // Multiplexed HREADY returned back to the active master
    output wire [1:0]           slv_hresp_mux,   // Multiplexed HRESP returned back to the active master
    output wire [31:0]          slv_hrdata_mux,  // Multiplexed HRDATA returned back to the active master

    // -----------------------------------------------------------------------
    // Slave Interfaces (Outputs from Interconnect Matrix down to Slaves)
    // -----------------------------------------------------------------------
    output wire [NUM_SLVS-1:0]  slv_hsel,        // Decoded peripheral select lines for each slave
    output wire                 hready,    // Interconnect-wide central pipeline stall signal
    output wire [31:0]          sel_haddr,       // Multiplexed downstream address bus
    output wire [31:0]          sel_hwdata,      // Multiplexed downstream write data bus
    output wire                 sel_hwrite,      // Multiplexed downstream read/write command flag
    output wire [2:0]           sel_hsize,       // Multiplexed downstream beat size control signal
    output wire [1:0]           sel_htrans,      // Multiplexed downstream transaction transfer phase

    // -----------------------------------------------------------------------
    // Slave Feedback (Inputs from individual Slaves back to Interconnect Matrix)
    // -----------------------------------------------------------------------
    input  wire [NUM_SLVS-1:0]  slv_hready_in_v, // Dynamic ready-state array driven from slaves  
    input  wire [NUM_SLVS*2-1:0]  slv_hresp_flat,  // Flat array of responses from individual slaves
    input  wire [NUM_SLVS*32-1:0] slv_hrdata_flat  // Flat read data buses from individual slaves
);

    // -----------------------------------------------------------------------
    // Inter-module Interconnect Interfacing Wires
    // -----------------------------------------------------------------------
    wire [3:0] master_sel_internal;              // Bridges arbiter master mapping decision over to decoder map
    wire [3:0] r_master_sel_unused;              // Registered version outputted from arbiter (kept available for expansion)

    // -----------------------------------------------------------------------
    // Module Instance: AHB Arbiter Block
    // -----------------------------------------------------------------------
    ahb_arbiter #(
        .NUM_ARB_MSTS (NUM_ARB_MSTS),
        .DEF_ARB_MST  (DEF_ARB_MST)
    ) u_ahb_arbiter (
        .hclk             (hclk),
        .hresetn           (hresetn),
        
        // Master input requests
        .mst_hbusreq      (mst_hbusreq),
        .mst_htrans       (mst_htrans),
        .mst_haddr_flat   (mst_haddr_flat),
        .mst_hwrite       (mst_hwrite),
        .mst_hwdata_flat  (mst_hwdata_flat),
        .mst_hsize_flat   (mst_hsize_flat),
        
        // Pipeline Feedback Control
        .hready     (hready),
        
        // Master output grant status flags
        .mst_hgrant       (mst_hgrant),
        
        // Multiplexed routing outputs going down to decoder & slaves
        .master_sel       (master_sel_internal),
        .r_master_sel     (r_master_sel_unused),
        .sel_haddr        (sel_haddr),
        .sel_hwdata       (sel_hwdata),
        .sel_hwrite       (sel_hwrite),
        .sel_hsize        (sel_hsize),
        .sel_htrans       (sel_htrans)
    );

    // -----------------------------------------------------------------------
    // Module Instance: AHB Decoder Block
    // -----------------------------------------------------------------------
    ahb_decoder #(
        .NUM_ARB_MSTS   (NUM_ARB_MSTS),
        .NUM_SLVS        (NUM_SLVS),
        .ADDR_LOW_FLAT   (ADDR_LOW_FLAT),
        .ADDR_HIGH_FLAT  (ADDR_HIGH_FLAT)
    ) u_ahb_decoder (
        .hclk            (hclk),
        .hresetn          (hresetn),
        
        // Internal controls piped direct from arbiter output multiplexers
        .master_sel      (master_sel_internal),
        .sel_haddr       (sel_haddr),
        .sel_htrans      (sel_htrans),
        
        // Downstream slave configurations
        .slv_hsel        (slv_hsel),
        .hready    (hready),
        
        // Feedback components bound for master matrix multiplexers
        .slv_hready_in_v (slv_hready_in_v),
        .slv_hresp_flat  (slv_hresp_flat),
        .slv_hrdata_flat (slv_hrdata_flat),
        
        // Output responses selected for current transaction master
        .slv_hready_mux  (slv_hready_mux),
        .slv_hresp_mux   (slv_hresp_mux),
        .slv_hrdata_mux  (slv_hrdata_mux)
    );

endmodule