// /////////////////////////////////////////////////////////////////////////////////////////////
// //
// //    AMBA Advanced High-Performance Bus to AMPA Advanced Peripheral Bus Bridge RTL Design
// //
// //    Author: Mahmoud Magdi 
// //
// /////////////////////////////////////////////////////////////////////////////////////////////

// `timescale 1ns / 1ps
//  `default_nettype wire
 
// module AHB_to_APB_Bridge #(

//     parameter DATA_WIDTH = 32,
// 	           ADDR_WIDTH = 32,
//               TRAN_WIDTH = 3

// ) (

//     input   logic                       h_clk        ,
//     input   logic                       p_clk        ,
//     input   logic                       h_reset_n    ,
//     input   logic                       h_write      ,
//     input   logic                       h_sel_apb    , 
//     input   logic                       h_ready_in   ,
//     input   logic [TRAN_WIDTH - 1 : 0]  h_trans      ,
//     input   logic [DATA_WIDTH - 1 : 0]  h_wdata      ,
//     input   logic [DATA_WIDTH - 1 : 0]  h_addr       ,
//     input   logic [DATA_WIDTH - 1 : 0]  p_rdata      ,

//     output  logic                       h_resp       ,
//     output  logic                       h_ready_out  ,
//     output  logic                       p_enable     ,
//     output  logic                       p_write      ,
//     output  logic                       p_selx       ,
//     output  logic [DATA_WIDTH - 1 : 0]  p_wdata      ,
//     output  logic [DATA_WIDTH - 1 : 0]  p_addr       ,
//     output  logic [DATA_WIDTH - 1 : 0]  h_rdata                    
// );

// typedef enum logic [2:0] { 
    
//                 IDLE     ,
//                 READ     ,
//                 W_WAIT   ,
//                 WRITE    ,
//                 WRITEP   ,
//                 WENABLE  ,
//                 WENABLEP ,
//                 RENABLE 
                
//                          } state;


// state current_state, next_state;
// logic valid, h_write_Reg;
// logic [ADDR_WIDTH - 1 : 0] ADDR_REG, DATA_REG;

// /////////////////////////////////////////////////////////////////////////////////////////
// // -------------------------             VALID LOGIC            -------------------------
// /////////////////////////////////////////////////////////////////////////////////////////
// always_comb begin : VALID_LOGIC
    
//     if(h_sel_apb == 1'b1 && (h_trans == 2'b10 || h_trans == 2'b11)) begin
        
//         valid = 1'b1;

//     end
//     else begin
        
//         valid = 1'b0;
    
//     end

// end


// /////////////////////////////////////////////////////////////////////////////////////////
// // -------------------------        Current State Logic         -------------------------
// /////////////////////////////////////////////////////////////////////////////////////////

// always_ff @( posedge h_clk or negedge h_reset_n ) begin : blockName
    
//     if (!h_reset_n) begin
        
//         current_state <= IDLE;

//     end else begin
        
//         current_state <= next_state;

//     end

// end



// /////////////////////////////////////////////////////////////////////////////////////////
// // -------------------------          Next State Logic          -------------------------
// /////////////////////////////////////////////////////////////////////////////////////////

// always_comb begin : next_state_logic
//     next_state = IDLE;
    
//     case (current_state)

//         IDLE    :begin

//             if (valid == 1'b0) begin

//                 next_state = IDLE;

//             end else if( valid == 1'b1 && h_write == 'b0 ) begin
                
//                 next_state = READ;

//             end else if( valid == 1'b1 && h_write == 'b1 ) begin
                
//                 next_state = W_WAIT;

//             end

//         end
        
//         READ    :begin
            
//             next_state = RENABLE;

//         end
        
//         W_WAIT   :begin
            
//             if (valid == 1'b0) begin
                
//                 next_state = WRITE;

//             end else begin
                
//                 next_state = WRITEP;

//             end

//         end
        
//         WRITE   :begin

//             if (valid == 1'b0) begin
                
//                 next_state = WENABLE;

//             end else begin
                
//                 next_state = WENABLEP;

//             end

//         end
        
//         WRITEP  :begin
            
//             next_state = WENABLEP;

//         end
        
//         WENABLE  :begin
//             if (valid == 1'b0) begin

//                 next_state = IDLE;

//             end else if( valid == 1'b1 && h_write == 1'b0 ) begin
                
//                 next_state = READ;
            
//             end else if( valid == 1'b1 && h_write == 1'b1 ) begin
                
//                 next_state = W_WAIT;

//             end
//         end

//         WENABLEP :begin
            
//             if (valid == 1'b0 && h_write_Reg == 1'b1) begin
                
//                 next_state = WRITE;
            
//             end else if(valid == 1'b1 && h_write_Reg == 1'b1) begin

//                 next_state = WRITEP;

//             end

//         end
        
//         RENABLE :begin

//             if (valid == 1'b0) begin

//                 next_state = IDLE;
            
//             end else if( valid == 1'b1 && h_write == 1'b1 ) begin

//                 next_state = W_WAIT;

//             end else if(valid == 1'b1 && h_write == 1'b0) begin

//                 next_state = READ;

//             end

//         end

//         default: next_state = IDLE;

//     endcase

// end

// /////////////////////////////////////////////////////////////////////////////////////////
// // -----------------------        Synchronous Output Logic        -----------------------
// /////////////////////////////////////////////////////////////////////////////////////////
// always_ff @( posedge h_clk or negedge h_reset_n ) begin : Sequential_Latching
//     if (!h_reset_n) begin
//         ADDR_REG    <= 'b0;
//         h_write_Reg <= 1'b0;
//     end else begin
//         case (current_state)
//             W_WAIT   : begin
//                 ADDR_REG    <= h_addr;
//                 h_write_Reg <= h_write;
//             end
            
//             WRITEP   : begin
//                 ADDR_REG    <= h_addr;
//                 h_write_Reg <= h_write;
//             end
            
//             READ     : begin
//                 ADDR_REG    <= h_addr;
//                 h_write_Reg <= 1'b0;
//             end
//         endcase
//     end
// end

// always_comb begin : Combinational_Outputs
//     h_resp      = 1'b0;
//     h_ready_out = 1'b1;
//     p_enable    = 1'b0;
//     p_write     = 1'b0;
//     p_selx      = 1'b0;
//     p_wdata     = 32'b0;
//     p_addr      = 32'b0;

//     case (current_state)
//         IDLE     : begin
//             p_selx      = 1'b0;
//             p_enable    = 1'b0;
//             h_ready_out = 1'b0;
//         end

//         READ     : begin
//             p_addr      = ADDR_REG;
//             p_selx      = 1'b1;
//             p_write     = 1'b0;
//             p_enable    = 1'b0;
//             h_ready_out = 1'b0;
//         end
        
//         W_WAIT   : begin
//             p_enable    = 1'b0;
//             h_ready_out = 1'b0;
//         end
        
//         WRITE    : begin
//             p_addr      = ADDR_REG;
//             p_wdata     = h_wdata;
//             p_selx      = 1'b1;
//             p_write     = 1'b1;
//             p_enable    = 1'b0;
//             h_ready_out = 1'b0;
//         end
        
//         WRITEP   : begin
//             p_addr      = ADDR_REG;
//             p_wdata     = h_wdata;
//             p_selx      = 1'b1;
//             p_write     = 1'b1;
//             p_enable    = 1'b0;
//             h_ready_out = 1'b0;
//         end
        
//         WENABLE  : begin
//             p_addr      = ADDR_REG;
//             p_wdata     = h_wdata;
//             p_selx      = 1'b1;
//             p_write     = 1'b1;
//             p_enable    = 1'b1;
//             h_ready_out = 1'b1;
//         end
        
//         WENABLEP : begin
//             p_addr      = ADDR_REG;
//             p_wdata     = h_wdata;
//             p_selx      = 1'b1;
//             p_write     = 1'b1;
//             p_enable    = 1'b1;
//             h_ready_out = 1'b1; 
//         end
        
//         RENABLE : begin
//             p_addr      = ADDR_REG;
//             p_selx      = 1'b1;
//             p_write     = 1'b0;
//             p_enable    = 1'b1;
//             h_ready_out = 1'b1; 
//         end
        
//         default: begin
//             h_resp      = 1'b0;
//             h_ready_out = 1'b0;
//             p_enable    = 1'b0;
//             p_write     = 1'b0;
//             p_selx      = 1'b0;
//             p_wdata     = 32'b0;
//             p_addr      = 32'b0;
//         end
//     endcase
// end
    
//     assign h_rdata = p_rdata;

// endmodule



`timescale 1ns / 1ps

// Peripheral map (one-hot slot → address range)
//   PSEL[0] / PRDATA[0] / PREADY[0]  -  I2S RX  (0x8000_0000 - 0x8000_0FFF)
//   PSEL[1] / PRDATA[1] / PREADY[1]  -  I2S TX  (0x8000_1000 - 0x8000_1FFF)
//   PSEL[2] / PRDATA[2] / PREADY[2]  -  GPIO    (0x8000_2000 - 0x8000_2FFF)
//   PSEL[3] / PRDATA[3] / PREADY[3]  -  WDT     (0x8800_0000 - 0x8BFF_FFFF)


//IF new Slaves must be added, then update this file and NM32_top.sv (address map and port connections) accordingly. 
//Also, update the parameter list in both files to include the new slave's base address and size.

module ahb_apb_bridge #(

    parameter logic [31:0] I2S_RX_BASE = 32'h8000_0000,
    parameter logic [31:0] I2S_RX_SIZE = 32'h0000_1000,   // 4 KB

    parameter logic [31:0] I2S_TX_BASE = 32'h8000_1000,
    parameter logic [31:0] I2S_TX_SIZE = 32'h0000_1000,   // 4 KB

    parameter logic [31:0] GPIO_BASE   = 32'h8000_2000,
    parameter logic [31:0] GPIO_SIZE   = 32'h0000_1000,   // 4 KB

    parameter logic [31:0] WDT_BASE    = 32'h8800_0000,
    parameter logic [31:0] WDT_SIZE    = 32'h0400_0000     // 64 MB
) (
    input  logic        Hclk,
    input  logic        Pclk,
    input  logic        Hresetn,
    input  logic        HSEL,     
    input  logic        Hwrite,
    input  logic        Hreadyin,
    input  logic [1:0]  Htrans,
    input  logic [31:0] Haddr,
    input  logic [31:0] Hwdata,

    output logic        Hreadyout,
    output logic [1:0]  Hresp,
    output logic [31:0] Hrdata,

    output logic        Penable,
    output logic        Pwrite,
    output logic [31:0] Paddr,
    output logic [31:0] Pwdata,
    output logic [3:0]  PSEL,  
    
    input  logic [3:0][31:0] PRDATA,
    input  logic [3:0]       PREADY  
);
    logic [31:0] Haddr1, Haddr2;
    logic        Hwritereg;

    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) begin
            Haddr1    <= 32'h0;
            Haddr2    <= 32'h0;
            Hwritereg <= 1'b0;
        end else begin
            Haddr1    <= Haddr;
            Haddr2    <= Haddr1;
            Hwritereg <= Hwrite;
        end
    end

    // valid: a real AHB transaction is on the bus AND the arbiter selected us.
    logic valid;
    always_comb begin
        valid = Hresetn && HSEL && Hreadyin &&
                (Htrans == 2'b10 || Htrans == 2'b11);  
    end

    logic rise_pclk;
    
    logic pclk_last;
    
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) rise_pclk <= 1'b0;
        else          pclk_last <= Pclk;
    end

    assign rise_pclk = (Pclk && ~pclk_last);

    localparam logic [31:0] I2S_RX_HIGH = I2S_RX_BASE + I2S_RX_SIZE;
    localparam logic [31:0] I2S_TX_HIGH = I2S_TX_BASE + I2S_TX_SIZE;
    localparam logic [31:0] GPIO_HIGH   = GPIO_BASE   + GPIO_SIZE;
    localparam logic [31:0] WDT_HIGH    = WDT_BASE    + WDT_SIZE;

    logic [3:0] tempselx;   // one-hot: bit0=RX, bit1=TX, bit2=GPIO, bit3=WDT
    always_comb begin
        tempselx = 4'b0000;
        if (Hresetn) begin
            if      (Haddr >= I2S_RX_BASE && Haddr < I2S_RX_HIGH) tempselx = 4'b0001;
            else if (Haddr >= I2S_TX_BASE && Haddr < I2S_TX_HIGH) tempselx = 4'b0010;
            else if (Haddr >= GPIO_BASE   && Haddr < GPIO_HIGH)   tempselx = 4'b0100;
            else if (Haddr >= WDT_BASE    && Haddr < WDT_HIGH)    tempselx = 4'b1000;
        end
    end

    assign Hresp = 2'b00;   // always OKAY

    // ================================================================
    //   ST_IDLE     idle, watch the bus for a valid transaction
    //   ST_WWAIT    write: 1-cycle wait for Hwdata to arrive (AHB pipeline)
    //   ST_ENABLE_R read:  APB setup + enable in one state (loops on ~PREADY)
    //   ST_SETUP_W  write: APB setup phase  (PSEL=1, Penable=0)
    //   ST_ENABLE_W write: APB enable phase (PSEL=1, Penable=1, loops on ~PREADY)
    // ================================================================
    typedef enum logic [2:0] {
        ST_IDLE     = 3'b000,
        ST_WWAIT    = 3'b001,
        ST_ENABLE_R = 3'b010,
        ST_SETUP_W  = 3'b011,
        ST_ENABLE_W = 3'b100
    } state_t;

    state_t PRESENT_STATE, NEXT_STATE;

    logic [3:0]  Pselx;

    logic [31:0] Prdata_mux;
    logic        Pready_mux;

    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) PRESENT_STATE <= ST_IDLE;
        else          PRESENT_STATE <= NEXT_STATE;
    end

    always_comb begin : NSL
        case (PRESENT_STATE)
            ST_IDLE: begin
                if      (~valid)            NEXT_STATE = ST_IDLE;
                else if (valid &&  Hwrite)  NEXT_STATE = ST_WWAIT;
                else                        NEXT_STATE = ST_ENABLE_R;
            end

            ST_WWAIT:   NEXT_STATE = ST_SETUP_W;  

            ST_ENABLE_R: begin
                if      (~Pready_mux || ~rise_pclk)       NEXT_STATE = ST_ENABLE_R; 
                else if (~valid)            NEXT_STATE = ST_IDLE;
                else if (valid &&  Hwrite)  NEXT_STATE = ST_WWAIT;
                else                        NEXT_STATE = ST_ENABLE_R;
            end

            ST_SETUP_W: NEXT_STATE = ST_ENABLE_W;   

            ST_ENABLE_W: begin
                if      (~Pready_mux || ~rise_pclk)        NEXT_STATE = ST_ENABLE_W; 
                else if (~valid)             NEXT_STATE = ST_IDLE;
                else if (valid && Hwritereg) NEXT_STATE = ST_SETUP_W; 
                else if (valid &&  Hwrite)   NEXT_STATE = ST_WWAIT;    
                else                         NEXT_STATE = ST_ENABLE_R; 
            end

            default: NEXT_STATE = ST_IDLE;
        endcase
    end

    logic        Penable_temp, Hreadyout_temp, Pwrite_temp;
    logic [3:0]  Pselx_temp;
    logic [31:0] Paddr_temp, Pwdata_temp;

    always_comb begin : OCL
        Penable_temp   = 1'b0;
        Hreadyout_temp = 1'b1;
        Pwrite_temp    = 1'b0;
        Pselx_temp     = 4'b0000;
        Pwdata_temp    = Pwdata;  

        case (PRESENT_STATE)

            ST_IDLE: begin
                if (valid && ~Hwrite) begin
                    Paddr_temp     = Haddr;
                    Pselx_temp     = tempselx;
                    Hreadyout_temp = 1'b0;   
                end else if (valid && Hwrite) begin
                    Hreadyout_temp = 1'b1; 
                end
            end

            ST_WWAIT: begin
                Paddr_temp     = Haddr1;      
                Pwrite_temp    = 1'b1;
                Pselx_temp     = tempselx;
                Pwdata_temp    = Hwdata;
                Hreadyout_temp = 1'b0;
            end

            ST_ENABLE_R: begin
                Paddr_temp     = Haddr1;      
                Pselx_temp     = tempselx;
                Penable_temp   = 1'b1;
                if (~Pready_mux) begin
                    Hreadyout_temp = 1'b0;
                end else begin
                    Hreadyout_temp = 1'b1;
                    if (valid && ~Hwrite) begin
                        Paddr_temp     = Haddr;
                        Pselx_temp     = tempselx;
                        Penable_temp   = 1'b0;
                        Hreadyout_temp = 1'b0;
                    end
                end
            end

            ST_SETUP_W: begin
                Pselx_temp     = Pselx;
                Pwrite_temp    = 1'b1;
                Penable_temp   = 1'b0;
                Hreadyout_temp = 1'b0;
            end

            ST_ENABLE_W: begin
                Pselx_temp     = Pselx;       
                Pwrite_temp    = 1'b1;
                Penable_temp   = 1'b1;
                if (~Pready_mux) begin
                    Hreadyout_temp = 1'b0;
                end else begin
                    Hreadyout_temp = 1'b1;
                    if (valid && Hwritereg) begin
                        Paddr_temp     = Haddr2;
                        Pwrite_temp    = 1'b1;
                        Pselx_temp     = tempselx;
                        Penable_temp   = 1'b0;
                        Pwdata_temp    = Hwdata;
                        Hreadyout_temp = 1'b0;
                    end
                end
            end
        endcase
    end
    
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (!Hresetn) begin
            Paddr     <= 32'h0;
            Pwrite    <= 1'b0;
            Pselx     <= 4'b0000;
            Pwdata    <= 32'h0;
            Penable   <= 1'b0;
            Hreadyout <= 1'b0;
        end else begin
            Paddr     <= Paddr_temp;
            Pwrite    <= Pwrite_temp;
            Pselx     <= Pselx_temp;
            Pwdata    <= Pwdata_temp;
            Penable   <= Penable_temp;
            Hreadyout <= Hreadyout_temp;
        end
    end

    assign PSEL = Pselx;

    always_comb begin
        case (1'b1)
            PSEL[0]: begin Prdata_mux = PRDATA[0]; Pready_mux = PREADY[0]; end // I2S RX
            PSEL[1]: begin Prdata_mux = PRDATA[1]; Pready_mux = PREADY[1]; end // I2S TX
            PSEL[2]: begin Prdata_mux = PRDATA[2]; Pready_mux = PREADY[2]; end // GPIO
            PSEL[3]: begin Prdata_mux = PRDATA[3]; Pready_mux = PREADY[3]; end // WDT
            default: begin Prdata_mux = 32'h0;     Pready_mux = 1'b1;      end // unmapped
        endcase
    end

    assign Hrdata = Prdata_mux;  

endmodule