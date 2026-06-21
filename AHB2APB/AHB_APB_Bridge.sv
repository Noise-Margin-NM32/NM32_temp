`timescale 1ns / 1ps
`default_nettype wire

module AHB_to_APB_Bridge #(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 32,
              TRAN_WIDTH = 3
) (
    input   logic                       h_clk        ,
    input   logic                       pclk         , // ADDED: APB clock
    input   logic                       h_reset_n    ,
    input   logic                       h_write      ,
    input   logic                       h_sel_apb    , 
    input   logic                       h_ready_in   ,
    input   logic [TRAN_WIDTH - 1 : 0]  h_trans      ,
    input   logic [DATA_WIDTH - 1 : 0]  h_wdata      ,
    input   logic [DATA_WIDTH - 1 : 0]  h_addr       ,
    input   logic [DATA_WIDTH - 1 : 0]  p_rdata      ,

    output  logic                       h_resp       ,
    output  logic                       h_ready_out  ,
    output  logic                       p_enable     ,
    output  logic                       p_write      ,
    output  logic                       p_selx       ,
    output  logic [DATA_WIDTH - 1 : 0]  p_wdata      ,
    output  logic [DATA_WIDTH - 1 : 0]  p_addr       ,
    output  logic [DATA_WIDTH - 1 : 0]  h_rdata                    
);

    logic valid;
    assign valid = (h_sel_apb && (h_trans == 2'b10 || h_trans == 2'b11));

    logic pclk_d;
    always_ff @(posedge h_clk) pclk_d <= pclk;
    wire pclk_fall = (pclk == 0 && pclk_d == 1);

    typedef enum logic [2:0] {
        IDLE,
        LATCH,
        SETUP,
        ACCESS
    } state_t;

    state_t state, next_state;

    logic [ADDR_WIDTH-1:0] addr_reg;
    logic                  write_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;

    always_ff @(posedge h_clk or negedge h_reset_n) begin
        if (!h_reset_n) begin
            state <= IDLE;
            addr_reg <= 0;
            write_reg <= 0;
        end else begin
            state <= next_state;
            if (state == IDLE && valid) begin
                addr_reg <= h_addr;
                write_reg <= h_write;
            end
        end
    end

    always_ff @(posedge h_clk or negedge h_reset_n) begin
        if (!h_reset_n) wdata_reg <= 0;
        else if (state == LATCH || (state == IDLE && valid && write_reg == 0)) begin
            wdata_reg <= h_wdata;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid) next_state = LATCH;
            end
            LATCH: begin
                // Wait for pclk_fall to align APB signals
                if (pclk_fall) next_state = SETUP;
            end
            SETUP: begin
                if (pclk_fall) next_state = ACCESS;
            end
            ACCESS: begin
                if (pclk_fall) begin
                    // If there's a back-to-back transfer pending, we could go to LATCH, 
                    // but for safety let's return to IDLE and process it.
                    next_state = IDLE;
                end
            end
        endcase
    end

    always_comb begin
        h_ready_out = 1'b0;
        h_resp = 1'b0;
        p_selx = 1'b0;
        p_enable = 1'b0;
        p_write = write_reg;
        p_addr = addr_reg;
        p_wdata = (state == SETUP || state == ACCESS) ? (write_reg ? h_wdata : 32'b0) : 32'b0;
        // Wait, standard AHB provides h_wdata during the data phase. 
        // In SETUP and ACCESS, we are in the data phase, so h_wdata is valid.
        
        case (state)
            IDLE: begin
                h_ready_out = 1'b1;
            end
            LATCH: begin
                h_ready_out = 1'b0;
            end
            SETUP: begin
                h_ready_out = 1'b0;
                p_selx = 1'b1;
                p_enable = 1'b0;
                p_wdata = write_reg ? h_wdata : 32'b0;
            end
            ACCESS: begin
                // Assert h_ready_out on the LAST h_clk cycle of the ACCESS phase
                // so the AHB master completes the transfer.
                // It completes when pclk_fall is true.
                h_ready_out = pclk_fall;
                p_selx = 1'b1;
                p_enable = 1'b1;
                p_wdata = write_reg ? h_wdata : 32'b0;
            end
        endcase
    end

    assign h_rdata = p_rdata;

endmodule
