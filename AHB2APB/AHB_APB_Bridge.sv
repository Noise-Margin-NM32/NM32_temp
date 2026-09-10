`timescale 1ns / 1ps
`default_nettype wire

module AHB_to_APB_Bridge #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TRAN_WIDTH = 3,
    parameter NUM_APB_SLAVES = 1,

    parameter [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_START = 0,
    parameter [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_END   = 0
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
    input   logic [NUM_APB_SLAVES-1:0][DATA_WIDTH - 1 : 0]  p_rdata      ,
    // input  logic [NUM_APB_SLAVES-1:0]  pready       ,

    output  logic                       h_resp       ,
    output  logic                       h_ready_out  ,
    output  logic                       p_enable     ,
    output  logic                       p_write      ,
    output  logic [NUM_APB_SLAVES-1:0]  p_selx       ,
    output  logic [DATA_WIDTH - 1 : 0]  p_wdata      ,
    output  logic [DATA_WIDTH - 1 : 0]  p_addr       ,
    output  logic [DATA_WIDTH-1:0]  h_rdata      ,
    
    input   logic [NUM_APB_SLAVES-1:0]  pready             
);
    // reg [NUM_APB_SLAVES-1:0] slave_sel_mask;

    logic [NUM_APB_SLAVES-1:0] decoded_sel;
    reg [31:0] addr_low_tmp;
    reg [31:0] addr_high_tmp;
    integer i;

    always @(*) begin
        for (i = 0; i < NUM_APB_SLAVES; i = i + 1) begin
            addr_low_tmp = SLAVE_ADDR_START[i];
            addr_high_tmp = SLAVE_ADDR_END[i];
            if(p_addr >= addr_low_tmp && p_addr <= addr_high_tmp)begin
                p_selx[i] = 1'b1;
            end else begin
                p_selx[i] = 1'b0;
            end
        end
    end
    
    // assign p_selx = (state == SETUP || state == ACCESS) ? decoded_sel : '0;


    logic valid;
    assign valid = (h_sel_apb && (h_trans == 2'b10 || h_trans == 2'b11) && h_ready_in);

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
            if ((state == IDLE || state == ACCESS) && valid) begin
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
                next_state = SETUP;
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                if (valid) next_state = LATCH;
                else       next_state = IDLE;
            end
        endcase
    end

    always_comb begin
        h_ready_out = 1'b0;
        h_resp = 1'b0;
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
                p_enable = 1'b0;
                p_wdata = write_reg ? h_wdata : 32'b0;
            end
            ACCESS: begin
                h_ready_out = 1'b1;
                p_enable = 1'b1;
                p_wdata = write_reg ? h_wdata : 32'b0;
            end
        endcase
    end

    always_comb begin
        h_rdata = 0;
        for (int j = 0; j < NUM_APB_SLAVES; j++) begin
            if (p_selx[j]) begin
                h_rdata = p_rdata[j];
            end
        end
    end

    always @(state, valid) begin
        $display("Time=%0t: [APB_BRIDGE] state=%0d next_state=%0d valid=%b h_ready_in=%b h_ready_out=%b h_addr=%h addr_reg=%h h_wdata=%h p_addr=%h p_wdata=%h p_enable=%b p_selx=%b p_write=%b",
            $time, state, next_state, valid, h_ready_in, h_ready_out, h_addr, addr_reg, h_wdata, p_addr, p_wdata, p_enable, p_selx, p_write);
    end
endmodule
