`timescale 1ns/1ps

`ifndef OK_RESP
  `define IDLE       2'b00
  `define NONSEQ     2'b10
  `define SEQ        2'b11
  `define OK_RESP    2'b00
  `define ERROR_RESP 2'b01
`endif

module tb_ahb_combined_interconnect;

    // -----------------------------------------------------------------------
    // Core Parameters
    // -----------------------------------------------------------------------
    parameter NUM_ARB_MSTS = 4;
    parameter DEF_ARB_MST  = 0;
    parameter NUM_SLVS     = 4;

    // Strict 10KB Aligned Peripherals Mapping Array Bounds
    parameter [32*16-1:0] ADDR_LOW_FLAT  = {324'h0, 32'h4000_0000, 32'h3000_0000, 32'h2000_0000, 32'h1000_0000};
    parameter [32*16-1:0] ADDR_HIGH_FLAT = {324'h0, 32'h4000_27FF, 32'h3000_27FF, 32'h2000_27FF, 32'h1000_27FF};

    // -----------------------------------------------------------------------
    // Interface Ports
    // -----------------------------------------------------------------------
    reg                      hclk;
    reg                      hresetn;
    reg [14:0]               mst_hbusreq;
    reg [29:0]               mst_htrans;
    reg [15*32-1:0]          mst_haddr_flat;
    reg [14:0]               mst_hwrite;
    reg [15*32-1:0]          mst_hwdata_flat;
    reg [15*3-1:0]           mst_hsize_flat;

    wire [14:0]              mst_hgrant;
    wire                     slv_hready_mux;
    wire [1:0]               slv_hresp_mux;
    wire [31:0]              slv_hrdata_mux;

    wire [NUM_SLVS-1:0]      slv_hsel;
    wire                     hready;
    wire [31:0]              sel_haddr;
    wire [31:0]              sel_hwdata;
    wire                     sel_hwrite;
    wire [2:0]               sel_hsize;
    wire [1:0]               sel_htrans;

    reg [NUM_SLVS-1:0]       slv_hready_in_v;
    reg [NUM_SLVS*2-1:0]     slv_hresp_flat;
    reg [NUM_SLVS*32-1:0]    slv_hrdata_flat;

    integer pass_count;
    integer fail_count;

    // -----------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // -----------------------------------------------------------------------
    ahb_decoder_and_arbiter #(
        .NUM_ARB_MSTS    (NUM_ARB_MSTS),
        .DEF_ARB_MST     (DEF_ARB_MST),
        .NUM_SLVS        (NUM_SLVS),
        .ADDR_LOW_FLAT   (ADDR_LOW_FLAT),
        .ADDR_HIGH_FLAT  (ADDR_HIGH_FLAT)
    ) dut (
        .hclk            (hclk),
        .hresetn         (hresetn),
        .mst_hbusreq     (mst_hbusreq),
        .mst_htrans      (mst_htrans),
        .mst_haddr_flat  (mst_haddr_flat),
        .mst_hwrite      (mst_hwrite),
        .mst_hwdata_flat (mst_hwdata_flat),
        .mst_hsize_flat  (mst_hsize_flat),
        .mst_hgrant      (mst_hgrant),
        .slv_hready_mux  (slv_hready_mux),
        .slv_hresp_mux   (slv_hresp_mux),
        .slv_hrdata_mux  (slv_hrdata_mux),
        .slv_hsel        (slv_hsel),
        .hready          (hready),
        .sel_haddr       (sel_haddr),
        .sel_hwdata      (sel_hwdata),
        .sel_hwrite      (sel_hwrite),
        .sel_hsize       (sel_hsize),
        .sel_htrans      (sel_htrans),
        .slv_hready_in_v (slv_hready_in_v),
        .slv_hresp_flat  (slv_hresp_flat),
        .slv_hrdata_flat (slv_hrdata_flat)
    );

    // Clock Generator (100MHz Matrix)
    always #5 hclk = ~hclk;

    // -----------------------------------------------------------------------
    // Driver Helper Tasks
    // -----------------------------------------------------------------------
    task drive_master_request;
        input integer master_idx;
        input [31:0]  addr;
        input [1:0]   trans;
        input         write_en;
        input [31:0]  wdata;
        begin
            mst_hbusreq[master_idx] = 1'b1;
            mst_htrans[2*master_idx +: 2] = trans;
            mst_haddr_flat[32*master_idx +: 32] = addr;
            mst_hwrite[master_idx] = write_en;
            mst_hwdata_flat[32*master_idx +: 32] = wdata;
            mst_hsize_flat[3*master_idx +: 3] = 3'b010; // Word access size configurations
        end
    endtask

    task clear_master_request;
        input integer master_idx;
        begin
            mst_hbusreq[master_idx] = 1'b0;
            mst_htrans[2*master_idx +: 2] = `IDLE;
        end
    endtask

    // -----------------------------------------------------------------------
    // Stimulus Engine
    // -----------------------------------------------------------------------
    initial begin
        hclk            = 0;
        hresetn         = 0;
        mst_hbusreq     = 15'b0;
        mst_htrans      = 30'b0;
        mst_haddr_flat  = {15{32'h0}};
        mst_hwrite      = 15'b0;
        mst_hwdata_flat = {15{32'h0}};
        mst_hsize_flat  = {15{3'b000}};
        
        slv_hready_in_v = {NUM_SLVS{1'b1}};
        slv_hresp_flat  = {NUM_SLVS{`OK_RESP}};
        
        // Configured hardware slave flat array responses (Ordered Slave 3 down to 0)
        slv_hrdata_flat = {32'hDDDD_DDDD, 32'h5555_5555, 32'hBBBB_BBBB, 32'hAAAA_AAAA};

        pass_count = 0;
        fail_count = 0;

        // Reset Phase
        #15 hresetn = 1; #10;

        $display("\n=========================================================================");
        $display("   STARTING COMBINED ARBITER & DECODER COMPLETE VERIFICATION            ");
        $display("=========================================================================\n");

        // -----------------------------------------------------------------------
        // TEST SEQUENCE 1: Fallback Default Master Grant allocation
        // -----------------------------------------------------------------------
        $display("[RUNNING] Test Sequence 1: Verifying Fallback Master Grant...");
        #1;
        if (mst_hgrant[DEF_ARB_MST] === 1'b1) begin
            $display("  -> [SUCCESS] Master 0 correctly holds master default assignment.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Default master allocation missing.");
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // TEST SEQUENCE 2: Basic Arbitration & Address Decode
        // -----------------------------------------------------------------------
        $display("[RUNNING] Test Sequence 2: Request from Master 1 bound for I2S_TX (Slave 1)...");
        @(posedge hclk); #1;
        drive_master_request(1, 32'h2000_0100, `NONSEQ, 1'b0, 32'h0); 

        @(posedge hclk); #1;
        if (mst_hgrant[1] === 1'b1 && slv_hsel[1] === 1'b1) begin
            $display("  -> [SUCCESS] Master 1 won bus allocation and matched address targets.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Grant or selection mismatch. Grants: %b, HSEL: %b", mst_hgrant, slv_hsel);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // TEST SEQUENCE 3: Sticky Round-Robin Contention & Cross Master Pipelining
        // -----------------------------------------------------------------------
        $display("[RUNNING] Test Sequence 3: Testing Sticky Round-Robin Contention...");
        drive_master_request(1, 32'h2000_0104, `SEQ, 1'b0, 32'h0);
        drive_master_request(2, 32'h3000_0500, `NONSEQ, 1'b0, 32'h0); // Master 2 targeted to Slave 2
        drive_master_request(3, 32'h4000_1000, `NONSEQ, 1'b0, 32'h0); 

        @(posedge hclk); #1;
        if (mst_hgrant[1] === 1'b1) begin
            $display("  -> [SUCCESS] Arbiter is sticky; held allocation for active Master 1 burst.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Arbiter dropped allocation mid-burst sequence.");
            fail_count = fail_count + 1;
        end

        clear_master_request(1);

        @(posedge hclk); #1;
        if (mst_hgrant[2] === 1'b1 && slv_hsel[2] === 1'b1) begin
            $display("  -> [SUCCESS] Round-robin correctly advanced to Master 2.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Round-robin sequence skip. Grants: %b", mst_hgrant);
            fail_count = fail_count + 1;
        end

        clear_master_request(2);

        // Turn clock edge 1: Transits Master 3 into its valid address phase
        @(posedge hclk); #1;
        
        // Turn clock edge 2 FIXED: Moves Master 3 from Address Phase into true Data Phase execution window
        @(posedge hclk); #1;
        if (mst_hgrant[3] === 1'b1 && slv_hrdata_mux === 32'hDDDD_DDDD) begin
            $display("  -> [SUCCESS] Round-robin stepped to Master 3, muxed Slave 2 data.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Master 3 allocation or data verification error. Got: 0x%h", slv_hrdata_mux);
            fail_count = fail_count + 1;
        end

        clear_master_request(3);
        @(posedge hclk); #1;

        // -----------------------------------------------------------------------
        // TEST SEQUENCE 4: Out of Bounds Default Slave Verification
        // -----------------------------------------------------------------------
        $display("[RUNNING] Test Sequence 4: Driving out-of-bounds address to test Default Slave error response...");
        drive_master_request(0, 32'hDEAD_BEEF, `NONSEQ, 1'b0, 32'h0);

        // Account for top-level interconnect arbitration routing stage delay
        @(posedge hclk); #1; 
        
        // Error Cycle 1 Validation
        if (slv_hready_mux === 1'b0 && slv_hresp_mux === `ERROR_RESP) begin
            $display("  -> [SUCCESS] Error Handshake Cycle 1 Verified (HREADY=0, HRESP=ERROR).");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Error Handshake Cycle 1 failed. Ready: %b, Resp: %b", slv_hready_mux, slv_hresp_mux);
            fail_count = fail_count + 1;
        end

        // Error Cycle 2 Validation
        @(posedge hclk); #1;
        if (slv_hready_mux === 1'b1 && slv_hresp_mux === `ERROR_RESP) begin
            $display("  -> [SUCCESS] Error Handshake Cycle 2 Verified (HREADY=1, HRESP=ERROR).");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> [FAILURE] Error Handshake Cycle 2 failed. Ready: %b, Resp: %b", slv_hready_mux, slv_hresp_mux);
            fail_count = fail_count + 1;
        end

        clear_master_request(0);
        @(posedge hclk); #1;

        // -----------------------------------------------------------------------
        // Report Sign-Off Summary
        // -----------------------------------------------------------------------
        $display("\n=========================================================================");
        $display("                       FINAL INTERCONNECT REPORT                           ");
        $display("=========================================================================");
        $display("  TOTAL PASSED STEPS : %0d", pass_count);
        $display("  TOTAL FAILED STEPS : %0d", fail_count);
        $display("=========================================================================");
        if (fail_count == 0) begin
            $display("  >>> STATUS: ALL CORE ARCHITECTURAL TEST SEQUENCES PASSED <<<");
        end else begin
            $display("  >>> STATUS: SYSTEM INTERCONNECT MATRIX RETURNED FAILURES   <<<");
        end
        $display("=========================================================================\n");

        $finish;
    end

endmodule