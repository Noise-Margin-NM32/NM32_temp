/////////////////////////////////////////////////////////////////////////////////////////////
//
//    AMBA Advanced High-Performance Bus to AMPA Advanced Peripheral Bus Bridge RTL Design
//
//    Author: Mahmoud Magdi 
//
/////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
 `default_nettype wire
 
module AHB_to_APB_Bridge #(

    parameter DATA_WIDTH = 32,
	           ADDR_WIDTH = 32,
              TRAN_WIDTH = 3

) (

    input   logic                       h_clk        ,
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

typedef enum logic [2:0] { 
    
                IDLE     ,
                READ     ,
                W_WAIT   ,
                WRITE    ,
                WRITEP   ,
                WENABLE  ,
                WENABLEP ,
                RENABLE 
                
                         } state;


state current_state, next_state;
logic valid, h_write_Reg;
logic [ADDR_WIDTH - 1 : 0] ADDR_REG, DATA_REG;

/////////////////////////////////////////////////////////////////////////////////////////
// -------------------------             VALID LOGIC            -------------------------
/////////////////////////////////////////////////////////////////////////////////////////
always_comb begin : VALID_LOGIC
    
    if(h_sel_apb == 1'b1 && (h_trans == 2'b01 || h_trans == 2'b11)) begin
        
        valid = 1'b1;

    end
    else begin
        
        valid = 1'b0;
    
    end

end


/////////////////////////////////////////////////////////////////////////////////////////
// -------------------------        Current State Logic         -------------------------
/////////////////////////////////////////////////////////////////////////////////////////

always_ff @( posedge h_clk or negedge h_reset_n ) begin : blockName
    
    if (!h_reset_n) begin
        
        current_state <= IDLE;

    end else begin
        
        current_state <= next_state;

    end

end



/////////////////////////////////////////////////////////////////////////////////////////
// -------------------------          Next State Logic          -------------------------
/////////////////////////////////////////////////////////////////////////////////////////

always_comb begin : next_state_logic
    next_state = IDLE;
    
    case (current_state)

        IDLE    :begin

            if (valid == 1'b0) begin

                next_state = IDLE;

            end else if( valid == 1'b1 && h_write == 'b0 ) begin
                
                next_state = READ;

            end else if( valid == 1'b1 && h_write == 'b1 ) begin
                
                next_state = W_WAIT;

            end

        end
        
        READ    :begin
            
            next_state = RENABLE;

        end
        
        W_WAIT   :begin
            
            if (valid == 1'b0) begin
                
                next_state = WRITE;

            end else begin
                
                next_state = WRITEP;

            end

        end
        
        WRITE   :begin

            if (valid == 1'b0) begin
                
                next_state = WENABLE;

            end else begin
                
                next_state = WENABLEP;

            end

        end
        
        WRITEP  :begin
            
            next_state = WENABLEP;

        end
        
        WENABLE  :begin
            if (valid == 1'b0) begin

                next_state = IDLE;

            end else if( valid == 1'b1 && h_write == 1'b0 ) begin
                
                next_state = READ;
            
            end else if( valid == 1'b1 && h_write == 1'b1 ) begin
                
                next_state = W_WAIT;

            end
        end

        WENABLEP :begin
            
            if (valid == 1'b0 && h_write_Reg == 1'b1) begin
                
                next_state = WRITE;
            
            end else if(valid == 1'b1 && h_write_Reg == 1'b1) begin

                next_state = WRITEP;

            end

        end
        
        RENABLE :begin

            if (valid == 1'b0) begin

                next_state = IDLE;
            
            end else if( valid == 1'b1 && h_write == 1'b1 ) begin

                next_state = W_WAIT;

            end else if(valid == 1'b1 && h_write == 1'b0) begin

                next_state = READ;

            end

        end

        default: next_state = IDLE;

    endcase

end

/////////////////////////////////////////////////////////////////////////////////////////
// -----------------------        Synchronous Output Logic        -----------------------
/////////////////////////////////////////////////////////////////////////////////////////
always_ff @( posedge h_clk or negedge h_reset_n ) begin : Output_Logic
    
    if (!h_reset_n) begin

        h_resp      <= 'b0;
        h_ready_out <= 'b0;
        p_enable    <= 'b0;
        p_write     <= 'b0;
        p_selx      <= 'b0;
        p_wdata     <= 'b0;
        p_addr      <= 'b0;
        h_rdata     <= 'b0;  


        ADDR_REG    <= 'b0;
        h_write_Reg <= 1'b0;

    end else begin

        case (current_state)

            IDLE     : begin

                p_selx      <= 1'b0;
                p_enable    <= 1'b0;
                h_ready_out <= 1'b1;

            end

            READ     : begin

                p_addr      <= h_addr;
                p_selx      <= 1'b1;
                p_write     <= 1'b0;
                p_enable    <= 1'b0;
                h_ready_out <= 1'b0;

            end
            
            W_WAIT   : begin

                ADDR_REG    <= h_addr;
                h_write_Reg <= h_write;
                p_enable    <= 1'b0;
                p_enable    <= 1'b0;
                h_ready_out <= 1'b0;

            end
            
            WRITE    : begin

                p_addr      <= ADDR_REG;
                p_wdata     <= h_wdata;
                p_selx      <= 1'b1;
                p_write     <= 1'b1;
                p_enable    <= 1'b0;
                h_ready_out <= 1'b0;

            end
            
            WRITEP   : begin

                p_addr      <= ADDR_REG;
                p_wdata     <= h_wdata;
                ADDR_REG    <= h_addr;
                h_write_Reg <= h_write;
                p_selx      <= 1'b1;
                p_write     <= 1'b1;
                p_enable    <= 1'b0;
                h_ready_out <= 1'b0;

            end
            
            WENABLE  : begin

                p_enable    <= 1'b1;
                h_ready_out <= 1'b1;
                
            end
            
            WENABLEP : begin

                p_enable    <= 1'b1;
                h_ready_out <= 1'b1; 

            end
            
            RENABLE  : begin

                p_enable    <= 1'b1;
                h_ready_out <= 1'b1;
                h_rdata     <= p_rdata;
                
            end 
            
            default: begin
                
                    h_resp      <= 'b0;
                    h_ready_out <= 'b0;
                    p_enable    <= 'b0;
                    p_write     <= 'b0;
                    p_selx      <= 'b0;
                    p_wdata     <= 'b0;
                    p_addr      <= 'b0;
                    h_rdata     <= 'b0;  

            end

        endcase
    end

end
    
endmodule

