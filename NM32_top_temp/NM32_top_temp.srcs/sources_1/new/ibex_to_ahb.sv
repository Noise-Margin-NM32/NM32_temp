module ibex_to_ahb (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Ibex Memory Interface
    input  logic        req_i,
    output logic        gnt_o,
    input  logic [31:0] addr_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic        err_o,

    // AHB-Lite Master Interface
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
        ST_IDLE,
        ST_DATA
    } state_t;

    state_t state_q, state_d;
    logic [31:0] hwdata_q;
    
    // HSIZE decoding
    logic [2:0] hsize;
    always_comb begin
        case (be_i)
            4'b0001, 4'b0010, 4'b0100, 4'b1000: hsize = 3'b000; // Byte
            4'b0011, 4'b1100:                   hsize = 3'b001; // Halfword
            default:                            hsize = 3'b010; // Word
        endcase
    end

    always_comb begin
        state_d = state_q;
        gnt_o = 1'b0;
        rvalid_o = 1'b0;
        
        HBUSREQ = 1'b0;
        HTRANS = 2'b00; // IDLE
        HADDR = addr_i;
        HWRITE = we_i;
        HSIZE = hsize;
        
        case (state_q)
            ST_IDLE: begin
                if (req_i) begin
                    HBUSREQ = 1'b1;
                    HTRANS = 2'b10; // NONSEQ
                    if (HGRANT && HREADY) begin
                        gnt_o = 1'b1;
                        state_d = ST_DATA;
                    end
                end
            end
            
            ST_DATA: begin
                if (HREADY) begin
                    rvalid_o = 1'b1;
                    // Support back-to-back
                    if (req_i) begin
                        HBUSREQ = 1'b1;
                        HTRANS = 2'b10; // NONSEQ
                        if (HGRANT) begin
                            gnt_o = 1'b1;
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
            state_q <= ST_IDLE;
            hwdata_q <= 32'b0;
        end else begin
            state_q <= state_d;
            if (gnt_o) begin
                hwdata_q <= wdata_i;
            end
        end
    end

    assign HWDATA = hwdata_q;
    assign rdata_o = HRDATA;
    assign err_o = HRESP[0];

endmodule
