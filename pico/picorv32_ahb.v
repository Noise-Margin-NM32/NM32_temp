// module pico_to_ahb (
//     input  wire        clk,
//     input  wire        resetn,

//     // ===== Pico native interface =====
//     input  wire        mem_valid,
//     input  wire [31:0] mem_addr,
//     input  wire [31:0] mem_wdata,
//     input  wire [3:0]  mem_wstrb,
//     output reg         mem_ready,
//     output reg  [31:0] mem_rdata,

//     // ===== AHB Master interface =====
//     output reg  [31:0] HADDR,
//     output reg  [1:0]  HTRANS,
//     output reg         HWRITE,
//     output reg  [2:0]  HSIZE,
//     output reg  [31:0] HWDATA,

//     input  wire [31:0] HRDATA,
//     input  wire        HREADY,
//     input  wire        HRESP
// );

//     // FSM states
//     localparam IDLE  = 2'd0;
//     localparam ADDR  = 2'd1;
//     localparam DATA  = 2'd2;

//     reg [1:0] state;

//     always @(posedge clk or negedge resetn) begin
//         if (!resetn) begin
//             state      <= IDLE;
//             HTRANS     <= 2'b00; // IDLE
//             mem_ready  <= 0;

//             HADDR      <= 32'b0;
//             HWRITE     <= 1'b0;
//             HSIZE      <= 3'b0;
//             HWDATA     <= 32'b0;
//             mem_rdata  <= 32'b0;
            
//         end else begin
//             case (state)

//             // =========================
//             // IDLE: wait for request
//             // =========================
//             IDLE: begin
//                 mem_ready <= 0;

//                 if (mem_valid) begin
//                     HADDR  <= mem_addr;
//                     HWRITE <= |mem_wstrb;
//                     HSIZE  <= 3'b010; // 32-bit
//                     HWDATA <= mem_wdata;

//                     HTRANS <= 2'b10; // NONSEQ
//                     state  <= ADDR;
//                 end
//             end

//             // =========================
//             // ADDR phase
//             // =========================
//             ADDR: begin
//                 if (HREADY) begin
//                     HTRANS <= 2'b00; // IDLE next
//                     state  <= DATA;
//                 end
//             end

//             // =========================
//             // DATA phase
//             // =========================
//             DATA: begin
//                 if (HREADY) begin
//                     mem_ready <= 1;
//                     mem_rdata <= HRDATA;
//                     state <= IDLE;
//                 end
//             end

//             endcase
//         end
//     end

// endmodule

module pico_to_ahb (
    input  wire        clk,
    input  wire        resetn,
    
    // PicoRV32 Native Interface
    input  wire        mem_valid,
    output reg         mem_ready,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    input  wire        mem_instr,
    output reg  [31:0] mem_rdata,

    // AHB Master Interface 
    output reg  [31:0] mst_haddr,
    output reg  [1:0]  mst_htrans,
    output reg  [2:0]  mst_hsize,
    output reg         mst_hwrite,
    output reg  [31:0] mst_hwdata,
    input  wire        mst_hready_out,
    input  wire [31:0] mst_hrdata_out,
    input  wire [1:0]  mst_hresp_out,
    output reg         mst_hbusreq,
    output wire        mst_hlock,
    output wire [2:0]  mst_hburst,
    output wire [3:0]  mst_hprot,
    input  wire        mst_hgrant
);

    // Optimized 3-State FSM
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;

    reg [1:0] state;
    
    // Static AHB Tie-offs
    assign mst_hburst = 3'b000;  // SINGLE transfer
    assign mst_hlock  = 1'b0;    // No locked transfers
    assign mst_hprot  = {3'b001, ~mem_instr}; // Data vs Opcode mapping
    
    // Combinational HSIZE decoding
    reg [2:0] next_hsize;
    always @(*) begin
        case (mem_wstrb)
            4'b0000: next_hsize = 3'b010; // Read Word
            4'b1111: next_hsize = 3'b010; // Write Word
            4'b0011, 4'b1100: next_hsize = 3'b001; // Write Halfword
            4'b0001, 4'b0010, 4'b0100, 4'b1000: next_hsize = 3'b000; // Write Byte
            default: next_hsize = 3'b010; // Default to Word
        endcase
    end

    // Sequential FSM Logic
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state       <= IDLE;
            mst_hbusreq <= 1'b0;
            mst_htrans  <= 2'b00; // IDLE
            mem_ready   <= 1'b0;
            mst_haddr   <= 32'd0;
            mst_hwrite  <= 1'b0;
            mst_hsize   <= 3'b010;
            mst_hwdata  <= 32'd0;
            mem_rdata   <= 32'd0;
        end else begin
            
            // Default: clear ready pulse automatically
            mem_ready <= 1'b0; 
            
            case (state)
                IDLE: begin
                    if (mem_valid && !mem_ready) begin
                        mst_hbusreq <= 1'b1; 
                        
                        if (mst_hgrant && mst_hready_out) begin
                            mst_htrans <= 2'b10; // NONSEQ
                            mst_haddr  <= mem_addr;
                            mst_hwrite <= (mem_wstrb != 4'b0000); 
                            mst_hsize  <= next_hsize;
                            if (mem_wstrb != 4'b0000) begin
                                mst_hwdata <= mem_wdata;
                            end
                            state      <= ADDR;
                        end
                    end else begin
                        mst_hbusreq <= 1'b0;
                    end
                end
                
                ADDR: begin
                    if (mst_hready_out) begin
                        mst_htrans <= 2'b00; // Drop to IDLE for single transfer
                        
                        if (mst_hwrite) begin
                            mst_hwdata <= mem_wdata;
                        end 
                        // else begin
                        //     // For reads, we can capture data in the next state seamlessly
                        //     mem_rdata <= mst_hrdata_out;
                        // end
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    if (mst_hready_out) begin
                        
                        // Handle read data capture seamlessly
                        if (!mst_hwrite) begin
                            mem_rdata <= mst_hrdata_out;
                        end
                        
                        // Pulse ready for exactly one cycle and bounce straight to IDLE
                        mem_ready   <= 1'b1; 
                        mst_hbusreq <= 1'b0; 
                        state       <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule