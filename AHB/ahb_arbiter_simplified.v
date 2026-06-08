// *******************************************************************
// AHB system generator - Lock-on-Request Fair Round-Robin Arbiter
// *******************************************************************

`include "ahb_package.vh"

module ahb_arbiter #(
    parameter NUM_ARB_MSTS = 4,   // number of masters
    parameter DEF_ARB_MST  = 0    // default master index
)(
    input  wire        hresetn,
    input  wire        hclk,

// Master outputs - arrayed signals driven from masters into the arbiter

    input  wire [14:0]      mst_hbusreq,     // Bus request lines from up to 15 masters; [i] = master i hbusreq
    input  wire [29:0]      mst_htrans,      // Transfer type from masters; [2i+1:2i] = master i htrans
                //00 (IDLE): master has bus but nothing to read/write
                //10 (NONSEQ): address unrelated to previous address (fresh transfer)
                //11 (SEQ): address consecutive from previous address
    input  wire [15*32-1:0] mst_haddr_flat,  // 32-bit transfer addresses from each master; [32*(i+1)-1:32*i] = master i haddr
    input  wire [14:0]      mst_hwrite,      // Write control line from each master (1=Write, 0=Read)
    input  wire [15*32-1:0] mst_hwdata_flat, // carries write data which master is sending; [32*(i+1)-1:32*i] = master i hwdata
    input  wire [15*3-1:0]  mst_hsize_flat,  // 2-bit code for transfer size (e.g., byte, halfword, word) from each master; [3*(i+1)-1:3*i] = master i hsize

// Feedback from Decoder/Slaves to control arbitration pipeline

    input  wire        s_dec_hready,      // Readiness of current slave

// Master inputs - signals sent back to masters from the arbiter

    // FIX 2: Changed from wire to reg - grant lines are now registered to prevent
    //        combinatorial glitching. Masters sample a stable, glitch-free value on
    //        the rising edge. The generate block has been replaced with a clocked
    //        always block below.
    output reg  [14:0] mst_hgrant,        // Bus grant lines to each master; [i]=1 means master i won the bus

// Multiplexed Master Status Output (Routes directly downstream to Decoder/Slaves)

    output reg  [3:0]  master_sel,        // Current master index selected for the Address Phase
    output reg  [3:0]  r_master_sel,      // Current master index selected for the Data Phase
    
    output reg  [31:0] sel_haddr,        // Multiplexed address from winning master
    output reg  [31:0] sel_hwdata,       // Multiplexed write data from winning master
    output reg         sel_hwrite,       // Multiplexed write control from winning master
    output reg  [2:0]  sel_hsize,        // Multiplexed size indicator from winning master
    output reg  [1:0]  sel_htrans        // Multiplexed transfer status type from winning master
);

// Internal signals

    // FIX 4: Renamed shared loop iterators to block-specific names to eliminate any
    //        simulator scheduling ambiguity between concurrent always @(*) blocks.
    integer arb_k;   // used exclusively in the arbitration always block
    integer mux_i;   // used exclusively in the master mux always block
    integer grant_i; // used exclusively in the grant registration always block

    //arbitration
    reg  [3:0]  grant_master;   // index of master who won arbitration
    reg  [3:0]  turn; // round robin pointer: tracks highest priority for turn if multiple masters request the bus at the same moment
    wire        req_ored;      // Logical OR reduction of all valid, unmasked bus requests

    // Round-robin temporaries (hoisted from always block for Verilog-2001 compatibility)
    reg         rr_found;
    reg  [3:0]  rr_idx;

    // Direct reduction OR across valid master requests 
    assign req_ored = |(mst_hbusreq & ((1 << NUM_ARB_MSTS) - 1));

    // -----------------------------------------------------------------------
    // HARDCODED FAIR ROUND-ROBIN ARBITRATION UPDATE
    // -----------------------------------------------------------------------
    always @(*) begin
        grant_master = master_sel;

        if (s_dec_hready) begin
            if (master_sel < NUM_ARB_MSTS[3:0] && mst_hbusreq[master_sel]) begin
                grant_master = master_sel;  // sticky: keep current master while it still requests
            end 
            // If the current master drops its request, evaluate other pending requests via round-robin
            else if (req_ored) begin
                rr_found = 1'b0;
                for (arb_k = 0; arb_k < NUM_ARB_MSTS; arb_k = arb_k + 1) begin
                    rr_idx = (turn + arb_k) % NUM_ARB_MSTS;
                    if (!rr_found && mst_hbusreq[rr_idx]) begin
                        grant_master = rr_idx[3:0];
                        rr_found     = 1'b1;
                    end
                end
            end 
            // No master wants the bus? Go to default master
            else begin
                grant_master = DEF_ARB_MST[3:0];
            end
        end
    end

    // -----------------------------------------------------------------------
    // Pipeline Registers
    // master_sel / r_master_sel pipeline
    // -----------------------------------------------------------------------
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin                      // on reset, go to default master, idle state
            master_sel    <= DEF_ARB_MST[3:0];
            r_master_sel  <= DEF_ARB_MST[3:0];
            turn          <= 4'd0;
        end else if (s_dec_hready) begin
            master_sel    <= grant_master;     // advances address phase tracking pointer
            r_master_sel  <= master_sel;       // advances data phase tracking pointer
            
            // FIX 3: Removed the sel_htrans != IDLE dependency. Since our masters hold
            //        hbusreq high for the entire duration of their transfer, dropping the
            //        request reliably signals the master is truly done. The req_ored gate
            //        prevents turn from advancing spuriously while the bus is idle (e.g.
            //        default master holding the bus with no real requestors pending).
            if (!mst_hbusreq[master_sel] && req_ored) begin
                turn <= (grant_master + 1) % NUM_ARB_MSTS;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Master MUX
    // Master MUX - select bus signals from winning master
    // -----------------------------------------------------------------------
    always @(*) begin
        sel_haddr  = mst_haddr_flat [32*DEF_ARB_MST+:32];
        sel_hwrite = mst_hwrite[DEF_ARB_MST];
        sel_hsize  = mst_hsize_flat [3*DEF_ARB_MST+:3];
        sel_htrans = mst_htrans[2*DEF_ARB_MST+:2];
        
        // Changed base initialization vector index lookup to safely fall back to pipelined r_master_sel mapping
        sel_hwdata = mst_hwdata_flat[32*r_master_sel+:32];
        
        for (mux_i = 0; mux_i < NUM_ARB_MSTS; mux_i = mux_i + 1) begin
            if (master_sel == mux_i[3:0]) begin
                sel_haddr  = mst_haddr_flat [32*mux_i+:32];
                sel_hwrite = mst_hwrite[mux_i];
                sel_hsize  = mst_hsize_flat [3*mux_i+:3];
                sel_htrans = mst_htrans[2*mux_i+:2];
            end
            if (r_master_sel == mux_i[3:0]) begin
                sel_hwdata = mst_hwdata_flat[32*mux_i+:32];
            end
        end
    end

    // -----------------------------------------------------------------------
    // FIX 2: Registered grant lines
    // Replaces the combinatorial generate block. mst_hgrant updates on the rising
    // edge, gated by s_dec_hready to stay in sync with the master_sel pipeline.
    // On reset, the default master is pre-granted.
    // -----------------------------------------------------------------------
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            mst_hgrant <= 15'b1 << DEF_ARB_MST;
        end else if (s_dec_hready) begin
            for (grant_i = 0; grant_i < 15; grant_i = grant_i + 1) begin
                mst_hgrant[grant_i] <= (grant_master == grant_i[3:0]);
            end
        end
    end

endmodule