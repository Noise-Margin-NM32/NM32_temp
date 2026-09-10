// *******************************************************************
// AHB system generator - Lock-on-Request Fair Round-Robin Arbiter
// *******************************************************************

`include "ahb_package.vh" // Includes system-wide macro definitions (like IDLE, NONSEQ, SEQ, OK_RESP)

module ahb_arbiter #(
    parameter NUM_ARB_MSTS = 4,   // Defines the total number of active hardware masters (e.g., 0:CPU, 1: DMA)
    parameter DEF_ARB_MST  = 0    // Specifies the index of the fallback master when the bus is completely idle
)(
    input  wire        hresetn,   // System-wide asynchronous active-low reset signal
    input  wire        hclk,      // Main system clock source driving all synchronous pipeline stages

// Master outputs - arrayed signals driven from masters into the arbiter

    input  wire [14:0]      mst_hbusreq,     // Vector of individual request lines from up to 15 masters; bit [i] = master i hbusreq
    input  wire [29:0]      mst_htrans,      // Flattened transfer types from masters; bits [2i+1:2i] encode master i's transfer status
                // 00 (IDLE): Master owns the bus but has no active read/write transfer to perform
                // 10 (NONSEQ): First transfer beat of a new address or a standalone single transfer
                // 11 (SEQ): Sequential subsequent beats of a burst transfer (address increments linearly)
    input  wire [15*32-1:0] mst_haddr_flat,  // Flattened 32-bit addresses; bits [32*(i+1)-1:32*i] contain master i's target address
    input  wire [14:0]      mst_hwrite,      // Flattened write control lines; bit [i] indicates master i transaction type (1=Write, 0=Read)
    input  wire [15*32-1:0] mst_hwdata_flat, // Flattened 32-bit write data buses; bits [32*(i+1)-1:32*i] hold master i's output write payload
    input  wire [15*3-1:0]  mst_hsize_flat,  // Flattened 3-bit size codes; bits [3*(i+1)-1:3*i] dictate master i's data width width (byte/halfword/word)

// Feedback from Decoder/Slaves to control arbitration pipeline

    input  wire        hready,      // Global ready signal from active slave; stalls the entire pipeline when pulled low (0)

// Master inputs - signals sent back to masters from the arbiter

    // FIX 2: Registered grant lines to prevent combinatorial glitching upstream
    output reg  [14:0] mst_hgrant,        // 15-bit one-hot encoded vector indicating which master currently won bus ownership

// Multiplexed Master Status Output (Routes directly downstream to Decoder/Slaves)

    output reg  [3:0]  master_sel,        // 4-bit pointer tracking which master is currently driving the Address Phase
    output reg  [3:0]  r_master_sel,      // 4-bit registered pointer tracking which master is currently in the Data Phase
    
    output reg  [31:0] sel_haddr,        // Muxed 32-bit address passed downstream to the decoder and all slaves
    output reg  [31:0] sel_hwdata,       // Muxed 32-bit write data bus passed straight downstream to all slaves
    output reg         sel_hwrite,       // Muxed 1-bit read/write control line sent down to all slaves
    output reg  [2:0]  sel_hsize,        // Muxed 3-bit size encoder sent down to all slaves
    output reg  [1:0]  sel_htrans        // Muxed 2-bit transfer type sent down to the decoder and all slaves
);

// Internal signals

    // FIX 4: Segmented loop variables to guarantee complete isolation across concurrent execution processes
    integer arb_k;   // Loop iterator bound strictly to the combinatorial round-robin priority picker block
    integer mux_i;   // Loop iterator bound strictly to the master signal multiplexing block
    integer grant_i; // Loop iterator bound strictly to the synchronous master grant register block

    // arbitration
    reg  [3:0]  grant_master;   // Combinatorial index pointing to the immediate winner of the current arbitration check
    reg  [3:0]  turn;           // Round-robin tracking register storing the starting priority position for the next sweep cycle
    wire        req_ored;       // Single bit flag evaluating whether any valid master request is currently active

    // Round-robin temporaries (hoisted from always block for Verilog-2001 compatibility)
    reg         rr_found;       // Flags if the round-robin loop successfully located an unmasked master request
    reg  [3:0]  rr_idx;         // Temporary pointer storing the current rotated index value under evaluation

    // Direct reduction OR across valid master requests 
    // Shifts 1 left by total masters, subtracts 1 to form a perfect bitmask, masks out unconfigured request tracks, and performs bit reduction
    assign req_ored = |(mst_hbusreq & ((1 << NUM_ARB_MSTS) - 1));

    // -----------------------------------------------------------------------
    // HARDCODED FAIR ROUND-ROBIN ARBITRATION UPDATE
    // -----------------------------------------------------------------------
    always @(*) begin
        grant_master = master_sel; // Hold the current address phase master selection as a base default fallback

        if (hready) begin // Only allow arbitration recalculations if the current slave transaction is not stalled
            if (master_sel < NUM_ARB_MSTS[3:0] && mst_hbusreq[master_sel]) begin
                grant_master = master_sel;  // Sticky rule: Keep the active master locked onto the bus if its request line is still asserted
            end 
            // If the current master drops its request, evaluate other pending requests via round-robin
            else if (req_ored) begin // Check if any other unmasked master requests are active in the system
                rr_found = 1'b0; // Reset search status flag to low before initiating the round-robin ring evaluation
                for (arb_k = 0; arb_k < NUM_ARB_MSTS; arb_k = arb_k + 1) begin // Step sequentially through the configured master count
                    rr_idx = (turn + arb_k) % NUM_ARB_MSTS; // Calculate rotating priority index offset relative to the current 'turn' position
                    if (!rr_found && mst_hbusreq[rr_idx]) begin // If no winner has been declared yet and the scanned master is requesting...
                        grant_master = rr_idx[3:0]; // Assign this master index as the immediate combinatorial winner
                        rr_found     = 1'b1;        // Terminate active checking loops by toggling the search status flag high
                    end // End condition check
                end // End round-robin search sweep loop
            end 
            // No master wants the bus? Go to default master
            else begin
                grant_master = DEF_ARB_MST[3:0]; // Snap the bus back to the designated default master index
            end // End priority checks
        end // End stall condition barrier
    end // End always block

    // -----------------------------------------------------------------------
    // Pipeline Registers
    // master_sel / r_master_sel pipeline
    // -----------------------------------------------------------------------
    always @(posedge hclk or negedge hresetn) begin // Synchronous edge block triggered by clock or negative asynchronous reset
        if (!hresetn) begin                      // Check if system reset has been asserted
            master_sel    <= DEF_ARB_MST[3:0];   // Force the address phase pointer to reset back to the default master index
            r_master_sel  <= DEF_ARB_MST[3:0];   // Force the data phase pointer to reset back to the default master index
            turn          <= 4'd0;                // Return the priority tracking loop to base position 0
        end else if (hready) begin          // If slave data paths are ready, advance pipeline layers synchronously
            master_sel    <= grant_master;     // Move the immediate arbitration winner into the active Address Phase position
            r_master_sel  <= master_sel;       // Shift the current address phase master down into the Data Phase layer
            
            // FIX 3: Shift the starting point of the next round-robin loop step only when the active owner releases the bus
            if (!mst_hbusreq[master_sel] && req_ored) begin // If owner dropped request and other masters are active...
                turn <= (grant_master + 1) % NUM_ARB_MSTS; // Move priority turn directly ahead of the winning master to guarantee fair access
            end // End turn increment check
        end // End active clock execution path
    end // End clock block

    // -----------------------------------------------------------------------
    // Master MUX
    // Master MUX - select bus signals from winning master
    // -----------------------------------------------------------------------
    always @(*) begin
        // Set up base fallback initialization lines mapped onto the default master index parameter
        sel_haddr  = mst_haddr_flat [32*DEF_ARB_MST+:32]; // Drive address line fallback
        sel_hwrite = mst_hwrite[DEF_ARB_MST];            // Drive write control fallback
        sel_hsize  = mst_hsize_flat [3*DEF_ARB_MST+:3];   // Drive data sizing fallback
        sel_htrans = mst_htrans[2*DEF_ARB_MST+:2];        // Drive transfer type fallback
        
        // Changed base initialization vector index lookup to safely fall back to pipelined r_master_sel mapping
        sel_hwdata = mst_hwdata_flat[32*r_master_sel+:32]; // Wire data phase fallback straight from the pipelined data master ID
        
        for (mux_i = 0; mux_i < NUM_ARB_MSTS; mux_i = mux_i + 1) begin // Run through available master sets to map structural multiplexers
            if (master_sel == mux_i[3:0]) begin // If loop index matches the current address-phase master...
                sel_haddr  = mst_haddr_flat [32*mux_i+:32]; // Slice out and pass the 32-bit target address downstream
                sel_hwrite = mst_hwrite[mux_i];            // Extract and pass the corresponding transaction read/write type
                sel_hsize  = mst_hsize_flat [3*mux_i+:3];   // Extract and pass the data width formatting code
                sel_htrans = mst_htrans[2*mux_i+:2];        // Extract and pass the command operation type (IDLE/NONSEQ/SEQ)
            end // End address phase check
            if (r_master_sel == mux_i[3:0]) begin // If loop index matches the delayed data-phase master...
                sel_hwdata = mst_hwdata_flat[32*mux_i+:32]; // Extract and drive its write data channel down onto the shared slave tracks
            end // End data phase check
        end // End multiplexer search loop
    end // End always block

    // -----------------------------------------------------------------------
    // FIX 2: Registered grant lines
    // Replaces the combinatorial generate block. mst_hgrant updates on the rising
    // edge, gated by hready to stay in sync with the master_sel pipeline.
    // On reset, the default master is pre-granted.
    // -----------------------------------------------------------------------
    always @(posedge hclk or negedge hresetn) begin // Synchronous block governing master flag grant feedback
        if (!hresetn) begin // Check if system reset has been dropped
            mst_hgrant <= 15'b1 << DEF_ARB_MST; // Perform one-hot shift to assert a pre-grant code to the default master index
        end else if (hready) begin // If the system is not stalled by a wait-state...
            for (grant_i = 0; grant_i < 15; grant_i = grant_i + 1) begin // Run through all 15 hardware master slots
                mst_hgrant[grant_i] <= (grant_master == grant_i[3:0]); // Evaluate and capture a stable, registered one-hot grant flag bit
            end // End grant bit generation loop
        end // End register clock edge update check
    end // End sequential block

endmodule // End of ahb_arbiter module structure
