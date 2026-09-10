`timescale 1ns/1ps
`include "ahb_package.vh"

module ahb_arbiter_tb;

    parameter NUM_ARB_MSTS = 4;
    parameter DEF_ARB_MST  = 0;
    parameter CLK_PERIOD   = 10;

    reg         hclk;
    reg         hresetn;

    // Master Signals (Flat Packed Arrays)
    reg  [14:0]      mst_hbusreq;
    reg  [29:0]      mst_htrans;
    reg  [15*32-1:0] mst_haddr_flat;
    reg  [14:0]      mst_hwrite;
    reg  [15*32-1:0] mst_hwdata_flat;
    reg  [15*3-1:0]  mst_hsize_flat;

    // Decoder Feedback
    reg         hready;

    // DUT Outputs
    wire [14:0] mst_hgrant;
    wire [3:0]  master_sel;
    wire [3:0]  r_master_sel;
    wire [31:0] sel_haddr;
    wire [31:0] sel_hwdata;
    wire        sel_hwrite;
    wire [2:0]  sel_hsize;
    wire [1:0]  sel_htrans;

    // DUT Instance
    ahb_arbiter #(
        .NUM_ARB_MSTS(NUM_ARB_MSTS),
        .DEF_ARB_MST(DEF_ARB_MST)
    ) dut (
        .hclk(hclk),
        .hresetn(hresetn),
        .mst_hbusreq(mst_hbusreq),
        .mst_htrans(mst_htrans),
        .mst_haddr_flat(mst_haddr_flat),
        .mst_hwrite(mst_hwrite),
        .mst_hwdata_flat(mst_hwdata_flat),
        .mst_hsize_flat(mst_hsize_flat),
        .hready(hready),
        .mst_hgrant(mst_hgrant),
        .master_sel(master_sel),
        .r_master_sel(r_master_sel),
        .sel_haddr(sel_haddr),
        .sel_hwdata(sel_hwdata),
        .sel_hwrite(sel_hwrite),
        .sel_hsize(sel_hsize),
        .sel_htrans(sel_htrans)
    );

    // Clock Generator
    initial hclk = 0;
    always #(CLK_PERIOD/2) hclk = ~hclk;

    // Global reset/signal initialization
    initial begin
        mst_hbusreq     = 15'b0;
        mst_htrans      = 30'b0;
        mst_haddr_flat  = {15*32{1'b0}};
        mst_hwrite      = 15'b0;
        mst_hwdata_flat = {15*32{1'b0}};
        mst_hsize_flat  = {15*3{1'b0}};
        hready    = 1'b1;
    end

    // -----------------------------------------------------------------------
    // REACTIVE AHB MASTER SIMULATION TASK
    // This safely mimics a real hardware master block that waits for hgrant.
    // -----------------------------------------------------------------------
    task automatic execute_ahb_transfer;
        input integer master_id;
        input [31:0]  start_addr;
        input [31:0]  base_wdata;
        input integer burst_beats; // 1 for single access, >1 for bursts
        integer beat;
        begin
            // Step 1: Assert Bus Request
            mst_hbusreq[master_id] = 1'b1;
            
            // Step 2: Maintain request and wait reactively until granted by the arbiter
            while (!mst_hgrant[master_id]) begin
                @(posedge hclk);
            end
            
            // Step 3: Drive the Address Phase
            #1; // Offset slightly past clock edge to mimic setup routing delays
            mst_htrans[2*master_id +: 2]       = 2'b10; // NONSEQ (Start transfer)
            mst_haddr_flat[32*master_id +: 32] = start_addr;
            mst_hwrite[master_id]              = 1'b1;  // Write operation
            
            // Handle sequential burst beats if requested
            for (beat = 1; beat < burst_beats; beat = beat + 1) begin
                @(posedge hclk);
                #1;
                mst_htrans[2*master_id +: 2]       = 2'b11; // SEQ
                mst_haddr_flat[32*master_id +: 32] = start_addr + (beat * 4);
                mst_hwdata_flat[32*master_id +: 32] = base_wdata + ((beat - 1) * 32'h10); // Prev beat data
            end
            
            // Step 4: Complete final address cycle & release request line
            //@(posedge hclk);
            while(!hready) @(posedge hclk); // block if slave stalls
            @(posedge hclk);
            #1;
            mst_hbusreq[master_id]             = 1'b0;  // Drop request (Sticky lock release)
            mst_htrans[2*master_id +: 2]       = 2'b00; // IDLE
            mst_haddr_flat[32*master_id +: 32] = 32'h0;
            mst_hwdata_flat[32*master_id +: 32] = base_wdata + ((burst_beats - 1) * 32'h10); // Final data phase beat
            
            // Step 5: Final data phase termination clock edge
            @(posedge hclk);
            #1;
            mst_hwdata_flat[32*master_id +: 32] = 32'h0;
        end
    endtask

    // -----------------------------------------------------------------------
    // Dynamic Cycle Monitor
    // -----------------------------------------------------------------------
    always @(posedge hclk) begin
        if (hresetn) begin
            $display("[CYCLE %3d] HREADY=%b | REQs=%4b | Internal Turn Pointer=%0d", 
                      $time/CLK_PERIOD, hready, mst_hbusreq[3:0], dut.turn);
            $display("            -> Pipeline Status: Current Winner=%0d | Address Phase (master_sel)=%0d | Data Phase (r_master_sel)=%0d", 
                      dut.grant_master, master_sel, r_master_sel);
            $display("            -> Bus Mux: HADDR=32'h%h | HTRANS=%b | HWDATA=32'h%h | GRANTS=%4b", 
                      sel_haddr, sel_htrans, sel_hwdata, mst_hgrant[3:0]);
            $display("------------------------------------------------------------------------------------------");
        end
    end

    // -----------------------------------------------------------------------
    // Main Test Sequence
    // -----------------------------------------------------------------------
    initial begin
        $display("==========================================================================================");
        $display("STARTING REACTIVE AHB ARBITER SYSTEM VERIFICATION");
        $display("==========================================================================================");
        
        // TEST CASE 1: Reset Behavior
        hresetn = 0;
        #(CLK_PERIOD * 2);
        hresetn = 1;
        @(posedge hclk);
        #1;
        $display("\n[TEST CASE 1] Verification of Reset Master Allocation Complete.");
        
        #(CLK_PERIOD * 2);

        // TEST CASE 2: Single Isolated Master Request (Master 2)
        $display("\n[TEST CASE 2] Starting Isolated Master 2 Reactive Request...");
        execute_ahb_transfer(2, 32'hAAAA_2222, 32'hDDDD_2000, 1);
        
        #(CLK_PERIOD * 2);

        // TEST CASE 3: Simultaneous Contention & Round-Robin Fairness Order Loop
        $display("\n[TEST CASE 3] Launching Parallel Contention Bus Flood (All 4 Masters compete)...");
        fork
            execute_ahb_transfer(0, 32'h0000_0000, 32'hD000_0000, 1);
            execute_ahb_transfer(1, 32'h1111_1111, 32'hD111_0000, 1);
            execute_ahb_transfer(2, 32'h2222_2222, 32'hD222_0000, 1);
            execute_ahb_transfer(3, 32'h3333_3333, 32'hD333_0000, 1);
        join
        
        #(CLK_PERIOD * 2);

        // TEST CASE 4: Sticky Burst Lock Verification vs High Contention Interrupts
        $display("\n[TEST CASE 4] Testing Sticky Lock-On-Request Behavior (Master 1 Bursts, Master 3 Contends)...");
        fork
            execute_ahb_transfer(1, 32'h1000_0000, 32'hBCDE_0000, 4); // Master 1 issues a 4-beat burst transfer
            begin
                #(CLK_PERIOD); // Delay master 3 slightly so Master 1 grabs bus first
                execute_ahb_transfer(3, 32'h3333_3333, 32'hFFFF_3333, 1);
            end
        join

        #(CLK_PERIOD * 2);

        // TEST CASE 5: Slave Wait-State Backpressure Stalling
        $display("\n[TEST CASE 5] Stalling Active Pipeline via Slave Wait States (hready = 0)...");
        fork
            execute_ahb_transfer(2, 32'h5555_5555, 32'h9999_9999, 1);
            begin
                while(!mst_hgrant[2]) @(posedge hclk); // Wait for master 2 address phase
                @(posedge hclk);
                #1;
                hready = 1'b0; // Force low ready condition to lock up transit paths
                $display(">>> SLAVE BACKPRESSURE ASSERTED (hready = 0) <<<");
                #(CLK_PERIOD * 3);
                hready = 1'b1; // Release the bus fabric
                $display(">>> SLAVE BACKPRESSURE RELEASED (hready = 1) <<<");
            end
        join

        #(CLK_PERIOD * 4);

        // TEST CASE 6: Parking State Tracking
        $display("\n[TEST CASE 6] Confirming Idle Default Master Parking Layout...");
        #(CLK_PERIOD * 2);

        $display("\n==========================================================================================");
        $display("SIMULATION COMPLETE");
        $display("==========================================================================================");
        $finish;
    end

endmodule
