`timescale 1ns/1ps

`ifndef OK_RESP
  `define IDLE       2'b00
  `define NONSEQ     2'b10
  `define SEQ        2'b11
  `define OK_RESP    2'b00
  `define ERROR_RESP 2'b01
`endif

module tb_ahb_decoder_20cases;

    // -----------------------------------------------------------------------
    // Design Configuration & Signals
    // -----------------------------------------------------------------------
    parameter NUM_ARB_MSTS = 4;
    parameter NUM_SLVS     = 4;

    parameter [32*NUM_SLVS-1:0] ADDR_LOW_FLAT  = {32'h4000_0000, 32'h3000_0000, 32'h2000_0000, 32'h1000_0000};
    parameter [32*NUM_SLVS-1:0] ADDR_HIGH_FLAT = {32'h4000_27FF, 32'h3000_27FF, 32'h2000_27FF, 32'h1000_27FF};

    reg                hclk;
    reg                hresetn;
    reg  [3:0]         master_sel;
    reg  [31:0]        sel_haddr;
    reg  [1:0]         sel_htrans;
    
    wire [NUM_SLVS-1:0]    slv_hsel;
    wire                   hready;
    reg  [NUM_SLVS-1:0]    slv_hready_in_v;
    reg  [NUM_SLVS*2-1:0]  slv_hresp_flat;
    reg  [NUM_SLVS*32-1:0] slv_hrdata_flat;

    wire               slv_hready_mux;
    wire [1:0]         slv_hresp_mux;
    wire [31:0]        slv_hrdata_mux;

    integer pass_count;
    integer fail_count;

    // -----------------------------------------------------------------------
    // Device Under Test (DUT)
    // -----------------------------------------------------------------------
    ahb_decoder #(
        .NUM_ARB_MSTS(NUM_ARB_MSTS),
        .NUM_SLVS(NUM_SLVS),
        .ADDR_LOW_FLAT(ADDR_LOW_FLAT),
        .ADDR_HIGH_FLAT(ADDR_HIGH_FLAT)
    ) dut (
        .hclk(hclk), .hresetn(hresetn), .master_sel(master_sel),
        .sel_haddr(sel_haddr), .sel_htrans(sel_htrans),
        .slv_hsel(slv_hsel), .hready(hready),
        .slv_hready_in_v(slv_hready_in_v), .slv_hresp_flat(slv_hresp_flat), .slv_hrdata_flat(slv_hrdata_flat),
        .slv_hready_mux(slv_hready_mux), .slv_hresp_mux(slv_hresp_mux), .slv_hrdata_mux(slv_hrdata_mux)
    );

    // Clock Generator
    always #5 hclk = ~hclk;

    // Parallel Memory Tables
    reg [31:0] ts_addr[0:21];
    reg [1:0]  ts_trans[0:21];
    integer    ts_expected_slv[0:21]; 
    reg [31:0] ts_rdata_payload[0:21];
    integer    ts_wait_states[0:21];

    integer i, w, active_slv;

    initial begin
        pass_count = 0;
        fail_count = 0;

        hclk            = 0;
        hresetn         = 0;
        master_sel      = 4'd1;
        sel_haddr       = 32'h0;
        sel_htrans      = `IDLE;
        slv_hready_in_v = {NUM_SLVS{1'b1}};
        
        slv_hrdata_flat = {32'hDDDD_DDDD, 32'h5555_5555, 32'hBBBB_BBBB, 32'hAAAA_AAAA};
        slv_hresp_flat  = {4{`OK_RESP}};

        // Test Cases Setup
        ts_addr[0] = 32'h1000_0000; ts_trans[0] = `NONSEQ; ts_expected_slv[0] = 0; ts_rdata_payload[0] = 32'hAAAA_AAAA; ts_wait_states[0] = 0;
        ts_addr[1] = 32'h1000_0104; ts_trans[1] = `SEQ;    ts_expected_slv[1] = 0; ts_rdata_payload[1] = 32'hAAAA_AAAA; ts_wait_states[1] = 0;
        ts_addr[2] = 32'h1000_27FF; ts_trans[2] = `SEQ;    ts_expected_slv[2] = 0; ts_rdata_payload[2] = 32'hAAAA_AAAA; ts_wait_states[2] = 1; // Wait cycle
        ts_addr[3] = 32'h2000_0000; ts_trans[3] = `NONSEQ; ts_expected_slv[3] = 1; ts_rdata_payload[3] = 32'hBBBB_BBBB; ts_wait_states[3] = 0;
        ts_addr[4] = 32'h2000_1000; ts_trans[4] = `SEQ;    ts_expected_slv[4] = 1; ts_rdata_payload[4] = 32'hBBBB_BBBB; ts_wait_states[4] = 0;
        ts_addr[5] = 32'h3000_0000; ts_trans[5] = `NONSEQ; ts_expected_slv[5] = 2; ts_rdata_payload[5] = 32'h5555_5555; ts_wait_states[5] = 0;
        ts_addr[6] = 32'h3000_0004; ts_trans[6] = `SEQ;    ts_expected_slv[6] = 2; ts_rdata_payload[6] = 32'h5555_5555; ts_wait_states[6] = 2; // Stalled
        ts_addr[7] = 32'h3000_2500; ts_trans[7] = `SEQ;    ts_expected_slv[7] = 2; ts_rdata_payload[7] = 32'h5555_5555; ts_wait_states[7] = 0;
        ts_addr[8] = 32'h4000_0000; ts_trans[8] = `NONSEQ; ts_expected_slv[8] = 3; ts_rdata_payload[8] = 32'hDDDD_DDDD; ts_wait_states[8] = 0;
        ts_addr[9] = 32'h4000_27FF; ts_trans[9] = `SEQ;    ts_expected_slv[9] = 3; ts_rdata_payload[9] = 32'hDDDD_DDDD; ts_wait_states[9] = 0;
        
        ts_addr[10] = 32'h1000_5000; ts_trans[10] = `NONSEQ; ts_expected_slv[10] = -1; ts_rdata_payload[10] = 32'h0; ts_wait_states[10] = 0;
        ts_addr[11] = 32'h0000_0000; ts_trans[11] = `IDLE;   ts_expected_slv[11] = -1; ts_rdata_payload[11] = 32'h0; ts_wait_states[11] = 0;
        
        ts_addr[12] = 32'h3000_1000; ts_trans[12] = `NONSEQ; ts_expected_slv[12] = 2;  ts_rdata_payload[12] = 32'h5555_5555; ts_wait_states[12] = 0;
        ts_addr[13] = 32'h4000_1234; ts_trans[13] = `NONSEQ; ts_expected_slv[13] = 3;  ts_rdata_payload[13] = 32'hDDDD_DDDD; ts_wait_states[13] = 0;
        
        ts_addr[14] = 32'h5000_0000; ts_trans[14] = `NONSEQ; ts_expected_slv[14] = -1; ts_rdata_payload[14] = 32'h0; ts_wait_states[14] = 0;
        ts_addr[15] = 32'h0000_0000; ts_trans[15] = `IDLE;   ts_expected_slv[15] = -1; ts_rdata_payload[15] = 32'h0; ts_wait_states[15] = 0;
        
        ts_addr[16] = 32'h1000_2000; ts_trans[16] = `NONSEQ; ts_expected_slv[16] = 0;  ts_rdata_payload[16] = 32'hAAAA_AAAA; ts_wait_states[16] = 0;
        ts_addr[17] = 32'h2000_27FF; ts_trans[17] = `NONSEQ; ts_expected_slv[17] = 1;  ts_rdata_payload[17] = 32'hBBBB_BBBB; ts_wait_states[17] = 0;
        ts_addr[18] = 32'h3000_0008; ts_trans[18] = `NONSEQ; ts_expected_slv[18] = 2;  ts_rdata_payload[18] = 32'h5555_5555; ts_wait_states[18] = 0;
        ts_addr[19] = 32'h4000_0010; ts_trans[19] = `NONSEQ; ts_expected_slv[19] = 3;  ts_rdata_payload[19] = 32'hDDDD_DDDD; ts_wait_states[19] = 0;
        
        ts_addr[20] = 32'h0000_0000; ts_trans[20] = `IDLE;   ts_expected_slv[20] = -1; ts_rdata_payload[20] = 32'h0; ts_wait_states[20] = 0;
        ts_addr[21] = 32'h0000_0000; ts_trans[21] = `IDLE;   ts_expected_slv[21] = -1; ts_rdata_payload[21] = 32'h0; ts_wait_states[21] = 0;

        #15 hresetn = 1; #10;
        
        $display("\n=========================================================================");
        $display("   STARTING REALISTIC 20-CASE PIPELINED AHB VERIFICATION                 ");
        $display("=========================================================================\n");

        // Drive Initial Case 0 Address Phase
        sel_haddr  = ts_addr[0];
        sel_htrans = ts_trans[0];
        $display("[ADDR PHASE] Initializing Pipeline -> Addr: 0x%h, Trans: %b", sel_haddr, sel_htrans);
        
        @(posedge hclk);

        for (i = 1; i <= 21; i = i + 1) begin
            
            // 1. Shift data/address controls right after the active clock edge
            #1; 

            // Validate Data Phase from the previous iteration loop index (i-1)
            if (ts_expected_slv[i-1] == -1 && (ts_trans[i-1] == `NONSEQ || ts_trans[i-1] == `SEQ)) begin
                $display("[DATA PHASE] Evaluating Unmapped Error Handshake Boundary Cycle...");
                
                if (slv_hready_mux === 1'b0 && slv_hresp_mux === `ERROR_RESP) begin
                    $display("  -> [SUCCESS] Error Handshake Cycle 1 Confirmed.");
                    pass_count = pass_count + 1;
                end else begin
                    $display("  -> [FAILURE] Error Handshake Cycle 1 Misaligned! Ready: %b, Resp: %b", slv_hready_mux, slv_hresp_mux);
                    fail_count = fail_count + 1;
                end

                @(posedge hclk); #1; // Advance to Error Cycle 2 Evaluation
                if (slv_hready_mux === 1'b1 && slv_hresp_mux === `ERROR_RESP) begin
                    $display("  -> [SUCCESS] Error Handshake Cycle 2 Confirmed.");
                    pass_count = pass_count + 1;
                end else begin
                    $display("  -> [FAILURE] Error Handshake Cycle 2 Misaligned! Ready: %b, Resp: %b", slv_hready_mux, slv_hresp_mux);
                    fail_count = fail_count + 1;
                end
            end
            else if (ts_trans[i-1] == `NONSEQ || ts_trans[i-1] == `SEQ) begin
                active_slv = ts_expected_slv[i-1];
                
                if (ts_wait_states[i-1] > 0) begin
                    $display("[STALL] Driving %0d Wait States into Slave channel %0d data lines...", ts_wait_states[i-1], active_slv);
                    for (w = 0; w < ts_wait_states[i-1]; w = w + 1) begin
                        slv_hready_in_v[active_slv] = 1'b0;
                        #1; // Let combinational passthrough lock down
                        if (slv_hready_mux === 1'b0) begin
                            pass_count = pass_count + 1;
                        end else begin
                            $display("  -> [FAILURE] Mux circuit structural error during slave wait sequence.");
                            fail_count = fail_count + 1;
                        end
                        @(posedge hclk); #1;
                    end
                    slv_hready_in_v[active_slv] = 1'b1; 
                    #1;
                end

                if (slv_hrdata_mux === ts_rdata_payload[i-1] && slv_hready_mux === 1'b1) begin
                    $display("[DATA PHASE SUCCESS] Case %0d verified -> Data Payload: 0x%h mapped cleanly.", i-1, slv_hrdata_mux);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[DATA PHASE FAILURE] Case %0d payload anomaly -> Expected: 0x%h, Got: 0x%h", 
                             i-1, ts_rdata_payload[i-1], slv_hrdata_mux);
                    fail_count = fail_count + 1;
                end
            end

            // Drive current index 'i' to the address lines
            if (i < 20) begin
                sel_haddr  = ts_addr[i];
                sel_htrans = ts_trans[i];
                $display("[ADDR PHASE] Case %0d -> Driving Addr: 0x%h, Trans: %b", i, sel_haddr, sel_htrans);
            end else begin
                sel_htrans = `IDLE;
            end

            #1; // Allow the live selection combinatorial wire to update safely
            if (i < 20 && ts_expected_slv[i] != -1 && ts_trans[i] != `IDLE) begin
                if (slv_hsel[ts_expected_slv[i]] === 1'b1) begin
                    pass_count = pass_count + 1;
                end else begin
                    $display("  -> [ADDRESS DECODE FAILURE] slv_hsel bit matrix: %b", slv_hsel);
                    fail_count = fail_count + 1;
                end
            end

            @(posedge hclk);
        end

        $display("\n=========================================================================");
        $display("                       FINAL SIMULATION REPORT                            ");
        $display("=========================================================================");
        $display("  TOTAL EVALUATED PASSED ASSERTIONS : %0d", pass_count);
        $display("  TOTAL EVALUATED FAILED ASSERTIONS : %0d", fail_count);
        $display("=========================================================================");
        if (fail_count == 0) begin
            $display("  >>> FINAL STATUS: ALL PASSED CRITERIA MET SUCCESSFUL <<<");
        end else begin
            $display("  >>> FINAL STATUS: TESTBENCH RETURNED FAILURE STRUCTS <<<");
        end
        $display("=========================================================================\n");
        $finish;
    end

endmodule