`timescale 1ns / 1ps

module ahb_arbiter #(
    parameter NUM_ARB      = 0,   
    parameter NUM_ARB_MSTS = 1,   // number of masters
    parameter DEF_ARB_MST  = 0,   // default master index
    parameter NUM_SLVS     = 3,   // number of slaves
    parameter ALG_NUMBER   = 1,   // Kept for port-compatibility, but ignored (Always RR)

    // Slave address ranges 
    parameter [32*16-1:0] ADDR_LOW_FLAT  = 0,
    parameter [32*16-1:0] ADDR_HIGH_FLAT = 0
)(
    input  wire        hresetn,
    input  wire        hclk,
    input  wire        remap, // Ignored in this simple version

    // Master inputs 
    input  wire [14:0] mst_hbusreq,   
    input  wire [14:0] mst_hlock,
    input  wire [29:0] mst_htrans,    
    input  wire [31:0] mst_haddr   [0:14],
    input  wire [14:0] mst_hwrite,
    input  wire [2:0]  mst_hsize   [0:14],
    input  wire [2:0]  mst_hburst  [0:14],
    input  wire [3:0]  mst_hprot   [0:14],
    input  wire [31:0] mst_hwdata  [0:14],

    // Master outputs 
    output wire [14:0] mst_hgrant,
    output wire        mst_hready_out,   
    output wire [1:0]  mst_hresp_out,    
    output wire [31:0] mst_hrdata_out,   

    // Slave inputs 
    output wire [NUM_SLVS-1:0] slv_hsel,
    output wire [31:0]         slv_haddr_out,
    output wire                slv_hwrite_out,
    output wire [1:0]          slv_htrans_out,
    output wire [2:0]          slv_hsize_out,
    output wire [2:0]          slv_hburst_out,
    output wire [3:0]          slv_hprot_out,
    output wire [31:0]         slv_hwdata_out,
    output wire [3:0]          slv_hmaster_out,
    output wire                slv_hmastlock_out,
    output wire                slv_hready_in,  

    // Slave outputs 
    input  wire [NUM_SLVS-1:0] slv_hready_in_v,
    input  wire [1:0]          slv_hresp_v   [0:14],
    input  wire [31:0]         slv_hrdata_v  [0:14],
    input  wire [15:0]         slv_hsplit_v  [0:14]
);

    // =========================================================================
    // 1. FLAT ARRAY EXTRACTION
    // =========================================================================
    wire [31:0] addr_low  [0:15];
    wire [31:0] addr_high [0:15];
    genvar g;
    generate
        for(g = 0; g < 16; g = g + 1) begin : gen_addr
            assign addr_low[g]  = ADDR_LOW_FLAT[32*g +: 32];
            assign addr_high[g] = ADDR_HIGH_FLAT[32*g +: 32];
        end
    endgenerate

    // =========================================================================
    // 2. ROUND ROBIN ARBITRATION
    // =========================================================================
    reg [3:0] active_master;      // Owns the Address Phase
    reg [3:0] data_phase_master;  // Owns the Data Phase (Delayed by 1 clock)
    reg [3:0] next_master;
    
    wire shared_hready; // The muxed HREADY from the active slave

    always @(*) begin
        next_master = active_master;
        
        // Only evaluate a master switch when the current transaction completes
        if (shared_hready) begin 
            // Simple Round Robin: Check current_master + 1, + 2, etc.
            reg found;
            found = 1'b0;
            for (integer i = 1; i <= 15; i = i + 1) begin
                if (i <= NUM_ARB_MSTS && !found) begin
                    integer check_idx;
                    check_idx = active_master + i;
                    if (check_idx >= NUM_ARB_MSTS) begin
                        check_idx = check_idx - NUM_ARB_MSTS;
                    end
                    
                    if (mst_hbusreq[check_idx]) begin
                        next_master = check_idx[3:0];
                        found = 1'b1;
                    end
                end
            end
        end
    end

    // Update Master State
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            active_master     <= DEF_ARB_MST[3:0];
            data_phase_master <= DEF_ARB_MST[3:0];
        end else if (shared_hready) begin
            active_master     <= next_master;
            data_phase_master <= active_master; // Pipeline the master for HWDATA routing
        end
    end

    // Grant Output Assignment
    generate
        for (g = 0; g < 15; g = g + 1) begin : gen_grant
            assign mst_hgrant[g] = (active_master == g[3:0]);
        end
    endgenerate

    // =========================================================================
    // 3. ADDRESS DECODING (ADDRESS PHASE)
    // =========================================================================
    wire [31:0] sel_haddr  = mst_haddr[active_master];
    wire        sel_hwrite = mst_hwrite[active_master];
    wire [2:0]  sel_hsize  = mst_hsize[active_master];
    wire [2:0]  sel_hburst = mst_hburst[active_master];
    wire [3:0]  sel_hprot  = mst_hprot[active_master];
    wire [1:0]  sel_htrans = mst_htrans[(active_master * 2) +: 2];

    reg [NUM_SLVS-1:0] slv_sel_addr_phase;
    reg                default_slave_addr_phase;

    always @(*) begin
        slv_sel_addr_phase = 0;
        default_slave_addr_phase = 1'b1;

        // Check if the Address Phase is actually active (NONSEQ or SEQ)
        if (sel_htrans == 2'b10 || sel_htrans == 2'b11) begin
            for (integer i = 0; i < NUM_SLVS; i = i + 1) begin
                // Compare only the upper bits [31:10] as per original design
                if (sel_haddr[31:10] >= addr_low[i][31:10] && sel_haddr[31:10] <= addr_high[i][31:10]) begin
                    slv_sel_addr_phase[i] = 1'b1;
                    default_slave_addr_phase = 1'b0;
                end
            end
        end
    end

    // =========================================================================
    // 4. PIPELINING TO DATA PHASE
    // =========================================================================
    reg [NUM_SLVS-1:0] slv_sel_data_phase;
    reg                default_slave_data_phase;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            slv_sel_data_phase       <= 0;
            default_slave_data_phase <= 1'b1;
        end else if (shared_hready) begin
            // Shift the Address Phase selections into the Data Phase
            slv_sel_data_phase       <= slv_sel_addr_phase;
            default_slave_data_phase <= default_slave_addr_phase;
        end
    end

    // HWDATA is a Data Phase signal, so it must use the pipelined master
    wire [31:0] sel_hwdata = mst_hwdata[data_phase_master];

    // =========================================================================
    // 5. MUXING SLAVE RESPONSES (DATA PHASE)
    // =========================================================================
    reg [31:0] mux_hrdata;
    reg [1:0]  mux_hresp;
    reg        mux_hready;

    always @(*) begin
        // Default safe values
        mux_hrdata = 32'b0;
        mux_hresp  = 2'b00; // OKAY
        mux_hready = 1'b1;  

        if (default_slave_data_phase) begin
            // If accessing invalid memory, return OKAY and ready to prevent lockup
            mux_hready = 1'b1;
            mux_hresp  = 2'b00; 
        end else begin
            for (integer i = 0; i < NUM_SLVS; i = i + 1) begin
                if (slv_sel_data_phase[i]) begin
                    mux_hrdata = slv_hrdata_v[i];
                    mux_hresp  = slv_hresp_v[i];
                    mux_hready = slv_hready_in_v[i];
                end
            end
        end
    end

    assign shared_hready = mux_hready;

    // =========================================================================
    // 6. FINAL SIGNAL ASSIGNMENTS
    // =========================================================================
    
    // To Masters
    assign mst_hready_out    = shared_hready;
    assign mst_hresp_out     = mux_hresp;
    assign mst_hrdata_out    = mux_hrdata;

    // To Slaves
    assign slv_hsel          = slv_sel_addr_phase;
    assign slv_haddr_out     = sel_haddr;
    assign slv_hwrite_out    = sel_hwrite;
    assign slv_htrans_out    = sel_htrans;
    assign slv_hsize_out     = sel_hsize;
    assign slv_hburst_out    = sel_hburst;
    assign slv_hprot_out     = sel_hprot;
    assign slv_hwdata_out    = sel_hwdata;
    assign slv_hmaster_out   = active_master;
    assign slv_hmastlock_out = mst_hlock[active_master];
    assign slv_hready_in     = shared_hready; 

endmodule