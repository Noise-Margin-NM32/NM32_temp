//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : ibex_imem_router
// Purpose : Splits Ibex's instruction port between the SRAM's dedicated
//           fetch port (port A of SRAM_1024x32_ahb_wrapper) and the AHB
//           path (ibex_to_ahb imem, AHB master 0). Fetches from the SRAM
//           window 0x3000_xxxx never touch AHB; Boot ROM fetches still do.
// Clocks  : clk_i (system clk)
//
// Protocol (Ibex req/gnt/rvalid, responses must stay in order):
//   - SRAM hit: gnt in the request cycle, rvalid + rdata the next cycle
//     (the SRAM registers the address). Back-to-back hits stream at one
//     fetch per clk.
//   - Ordering: an SRAM hit is granted only when no AHB fetch is still
//     waiting for its data (or that data returns in this same cycle), so
//     an SRAM response can never overtake an AHB one. An AHB request may
//     always be forwarded: its data phase ends after any pending SRAM
//     response.
//==========================================================================
module ibex_imem_router (
    input  logic        clk_i,
    input  logic        rst_ni,

    // From Ibex instruction port
    input  logic        req_i,
    input  logic [31:0] addr_i,
    output logic        gnt_o,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic        err_o,

    // To ibex_to_ahb (imem)
    output logic        ahb_req_o,
    input  logic        ahb_gnt_i,
    input  logic        ahb_rvalid_i,
    input  logic [31:0] ahb_rdata_i,
    input  logic        ahb_err_i,

    // To SRAM port A
    output logic        imem_en_o,
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_rdata_i
);

    logic hit;
    logic ahb_out_q;     // an AHB fetch has been granted, data not yet back
    logic sram_pend_q;   // SRAM fetch granted last cycle: rvalid now

    assign hit = (addr_i[31:16] == 16'h3000);

    // ---------------------------------------------------------------------
    // 1. Request steering
    // ---------------------------------------------------------------------
    assign imem_en_o   = req_i && hit && (!ahb_out_q || ahb_rvalid_i);
    assign imem_addr_o = addr_i;
    assign ahb_req_o   = req_i && !hit;
    assign gnt_o       = imem_en_o || ahb_gnt_i;

    // ---------------------------------------------------------------------
    // 2. Outstanding-transfer tracking
    // ---------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ahb_out_q   <= 1'b0;
            sram_pend_q <= 1'b0;
        end else begin
            sram_pend_q <= imem_en_o;
            if (ahb_gnt_i)         ahb_out_q <= 1'b1;
            else if (ahb_rvalid_i) ahb_out_q <= 1'b0;
        end
    end

    // ---------------------------------------------------------------------
    // 3. Response mux (the two sources never respond in the same cycle)
    // ---------------------------------------------------------------------
    assign rvalid_o = sram_pend_q || ahb_rvalid_i;
    assign rdata_o  = sram_pend_q ? imem_rdata_i : ahb_rdata_i;
    assign err_o    = sram_pend_q ? 1'b0 : ahb_err_i;

`ifndef SYNTHESIS
    always_ff @(posedge clk_i) begin
        if (sram_pend_q && ahb_rvalid_i)
            $error("[ibex_imem_router] SRAM and AHB fetch responses collided");
    end
`endif

endmodule
