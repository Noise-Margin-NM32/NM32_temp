//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : ibex_to_ahb
// Purpose : Bridges one Ibex memory port (instruction or data: req/gnt/
//           rvalid protocol) to an AHB master port. Two instances in
//           NM32_top.sv: imem (AHB master 0) and dmem (AHB master 1).
// Clocks  : clk_i (system clk)
//
// Protocol mapping:
//   - Address phase: req_i -> HBUSREQ + NONSEQ. gnt_o is given in the cycle the
//     address is accepted (HGRANT && HREADY).
//   - Data phase (ST_DATA): rvalid_o when HREADY returns; HWDATA is the
//     wdata registered at gnt. A new request may start in the same cycle
//     (pipelined back-to-back).
//
// Byte lanes: Ibex always issues a WORD-ALIGNED addr_i and marks the bytes
//   with be_i (data already sits in those lanes of wdata_i). AHB slaves pick
//   the lane from HADDR[1:0] + HSIZE, so both are rebuilt from be_i:
//     0001/0010/0100/1000 -> byte     at offset 0/1/2/3
//     0011/1100           -> halfword at offset 0/2
//     1111                -> word
//   Other patterns (0110, 0111, 1110 - only produced by misaligned accesses)
//   cannot be expressed on AHB; they go out as a word access and are flagged
//   with $error in simulation. Compile firmware without misaligned accesses.
//
// Notes   : err_o = HRESP[0]; Ibex only samples it together with rvalid_o.
//==========================================================================
module ibex_to_ahb (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Ibex memory interface
    input  logic        req_i,
    output logic        gnt_o,
    input  logic [31:0] addr_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic        err_o,

    // AHB master interface
    output logic [31:0] HADDR,
    output logic [1:0]  HTRANS,
    output logic [2:0]  HSIZE,
    output logic        HWRITE,
    output logic [31:0] HWDATA,
    input  logic [31:0] HRDATA,
    input  logic        HREADY,
    input  logic [1:0]  HRESP,

    // Arbitration
    output logic        HBUSREQ,
    input  logic        HGRANT
);

    typedef enum logic {
        ST_IDLE,    // no transfer in its data phase
        ST_DATA     // a granted transfer is in its data phase
    } state_t;

    state_t state_q, state_d;
    logic [31:0] hwdata_q;

    // ---------------------------------------------------------------------
    // 1. Byte enables -> HSIZE + byte offset
    // ---------------------------------------------------------------------
    logic [2:0] hsize;
    logic [1:0] byte_off;
    logic       be_ok;

    always_comb begin
        be_ok = 1'b1;
        case (be_i)
            4'b0001: begin hsize = 3'b000; byte_off = 2'd0; end
            4'b0010: begin hsize = 3'b000; byte_off = 2'd1; end
            4'b0100: begin hsize = 3'b000; byte_off = 2'd2; end
            4'b1000: begin hsize = 3'b000; byte_off = 2'd3; end
            4'b0011: begin hsize = 3'b001; byte_off = 2'd0; end
            4'b1100: begin hsize = 3'b001; byte_off = 2'd2; end
            4'b1111: begin hsize = 3'b010; byte_off = 2'd0; end
            default: begin hsize = 3'b010; byte_off = 2'd0; be_ok = 1'b0; end
        endcase
    end

    // ---------------------------------------------------------------------
    // 2. Transfer FSM
    // ---------------------------------------------------------------------
    always_comb begin
        state_d  = state_q;
        gnt_o    = 1'b0;
        rvalid_o = 1'b0;

        HBUSREQ = 1'b0;
        HTRANS  = 2'b00;                          // IDLE
        HADDR   = {addr_i[31:2], byte_off};
        HWRITE  = we_i;
        HSIZE   = hsize;

        case (state_q)
            ST_IDLE: begin
                if (req_i) begin
                    HBUSREQ = 1'b1;
                    HTRANS  = 2'b10;              // NONSEQ
                    if (HGRANT && HREADY) begin
                        gnt_o   = 1'b1;
                        state_d = ST_DATA;
                    end
                end
            end

            ST_DATA: begin
                if (HREADY) begin
                    rvalid_o = 1'b1;
                    // Pipelined back-to-back request
                    if (req_i) begin
                        HBUSREQ = 1'b1;
                        HTRANS  = 2'b10;          // NONSEQ
                        if (HGRANT) begin
                            gnt_o   = 1'b1;
                            state_d = ST_DATA;
                        end else begin
                            state_d = ST_IDLE;
                        end
                    end else begin
                        state_d = ST_IDLE;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q  <= ST_IDLE;
            hwdata_q <= 32'b0;
        end else begin
            state_q <= state_d;
            if (gnt_o) hwdata_q <= wdata_i;       // HWDATA for the data phase
        end
    end

    assign HWDATA  = hwdata_q;
    assign rdata_o = HRDATA;
    assign err_o   = HRESP[0];

`ifndef SYNTHESIS
    always_ff @(posedge clk_i) begin
        if (gnt_o && !be_ok)
            $error("[ibex_to_ahb] unsupported byte-enable pattern %b at 0x%08h (misaligned access?)", be_i, addr_i);
    end
`endif

endmodule
