// module dma_controller(
   
//   // Global Signals
//     input  wire        PCLK,      // APB Clock for configuration 
//     input  wire        HCLK,      // AHB Clock for data movement 
//     input  wire        PRESETN,   // APB Reset (Active Low) 
//     input  wire        HRESETN,   // AHB Reset (Active Low) 
    
//     // --- PART 1: APB SLAVE INTERFACE ---
//     input  wire        PSEL,      // DMA chip-select 
//     input  wire        PENABLE,   // 2-cycle enable strobe 
//     input  wire        PWRITE,    // 1=Write to DMA, 0=Read from DMA 
//     input  wire [31:0] PADDR,     // Register offset select 
//     input  wire [31:0] PWDATA,    // Data from CPU to DMA registers 
//     output reg  [31:0] PRDATA,    // Data from DMA registers to CPU 
//     output wire        PREADY,    // Slave stall signal (tied to 1) 

//     // --- PART 2/3: AHB MASTER & SIDEBAND ---
//     input  wire        HGRANT,    // Bus grant from arbiter [cite: 37]
//     output reg         HBUSREQ,   // Bus request to arbiter [cite: 37]
//     output reg  [31:0] HADDR,     // 32-bit address for AHB beat [cite: 42]
//     output reg  [1:0]  HTRANS,    // Transfer type (IDLE/NONSEQ) [cite: 42]
//     output reg         HWRITE,    // 0=Read, 1=Write [cite: 42]
//     input  wire        HREADY,    // Slave ready signal [cite: 45]
//     output reg         irq,        // Interrupt to CPU [cite: 52]

//     input wire [31:0] HRDATA, // input from AHB
//     output reg [31:0] HWDATA,

//     output reg check // have added this to see if write-data state is coming properly or not.
// );

// // part 1:: configuration regiters
// reg [31:0] src_addr_reg; // 0x00
// reg [31:0] dst_addr_reg; // 0x04
// reg [31:0] len_reg; // 0x08
// reg [31:0] ctrl_reg; // 0x0c when this is high (ctrl_reg[0]==1 then we start the FSM of AHB)
// reg [31:0] status_reg; // 0x00


// // part 2 : internal registers
// reg [31:0] src_ptr;
// reg [31:0] dst_ptr;
// reg [31:0] len_cnt;
// reg [31:0] data_buf;

// reg [31:0] jump = 32'h0004;

// // FSM State 
// localparam  IDLE = 3'b000,
//             BUS_REQ = 3'b001,
//             ADDR_PHASE = 3'b010, /// Read Address
//             READ_DATA = 3'b100, // Wait for Hread (AHB retrurn )
//             WRITE_DATA = 3'b101, 
//             DONE = 3'b110;


// // ----Logic block A; APB Write

// always @(posedge PCLK or negedge PRESETN) begin
//     if(!PRESETN) begin
//         src_addr_reg <=32'h0;
//         dst_addr_reg <=32'h0;
//         len_reg <=32'h0;
//         ctrl_reg <=32'h0;
//     end else if (PSEL && PENABLE && PWRITE) begin 
//         case (PADDR[7:0]) 
//             8'h00: src_addr_reg <= PWDATA;
//             8'h04: dst_addr_reg <= PWDATA;
//             8'h08: len_reg      <= PWDATA;
//             8'h0C: ctrl_reg     <= PWDATA;
//         endcase
//     end 
// end


// // ----Logic Blcok B:
// always @(posedge HCLK or negedge HRESETN) begin
//     if (!HRESETN) begin
//             src_ptr <= 32'h0;
//             dst_ptr <= 32'h0;
//             len_cnt <= 32'h0;
//             irq <= 1'b0;
//         end

//     // // Initialization Phase: Copy config values to working pointers [cite: 115]
//     //     else if (ctrl_reg[0] == 1'b1) begin 
//     //         src_ptr <= src_addr_reg;
//     //         dst_ptr <= dst_addr_reg;
//     //         len_cnt <= len_reg;
//     //     end
// end

//     assign PREADY = 1'b1;


// reg [2:0] current_state, next_state; /// should value of next state be IDLE when reset ?


// // FSM State Transition 
// always @(posedge HCLK or negedge HRESETN) begin 
//     if(!HRESETN) begin
//         current_state <=IDLE;
//         irq <= 1'b0;

//         HTRANS  <= 2'b00;
//     HADDR   <= 32'h0;
//     HWRITE  <= 1'b0;
//     // HSIZE   <= 3'b010; // Hardcoded to 32-bit Word 
//     HWDATA  <= 32'h0;


//     end else
//         current_state <= next_state; // should valus next_state be IDLE when reset ???
// end


// // Finding out what is the next state
// always @(*) begin 
//     case(current_state)
//         IDLE:   next_state = (ctrl_reg[0]) ? BUS_REQ : IDLE;
//         BUS_REQ: next_state = (HGRANT) ? ADDR_PHASE : BUS_REQ;
//         ADDR_PHASE: next_state = READ_DATA;
//         READ_DATA: next_state = (HREADY) ? WRITE_DATA : READ_DATA;
//         WRITE_DATA: if (HREADY)
//                         next_state = (len_cnt==1)? DONE: ADDR_PHASE;

//                     else
//                         next_state = WRITE_DATA;
//         DONE: next_state = IDLE; 
//         default: next_state = IDLE;
//     endcase

// end


// // ---AHB Master Output (Combinational ppart of the FSM)
// always @(*) begin

//     HBUSREQ = (current_state != IDLE && current_state != DONE);
//     // HTRANS  = 2'b00;
//     // HADDR   = 32'h0;
//     // HWRITE  = 1'b0;
//     // HSIZE   = 3'b010; // Hardcoded to 32-bit Word 
//     // HWDATA  = 32'h0;

//     case (current_state) 
//         BUS_REQ: begin 
//             HTRANS = 2'b00; //
//         end

//         ADDR_PHASE: begin
//             if(HGRANT) begin 
//                 HADDR = src_ptr;
//                 HTRANS = 2'b10;
//                 HWRITE = 1'b0;
//             end 
//         end

//         READ_DATA: begin
//             HADDR = dst_ptr;
//             HTRANS = 2'b10;
//             HWRITE = 1'b1;
//         end

//         // WRITE_DATA: begin 
//         //     HWDATA = data_buf;
//         // end

//         default: begin 
//             HBUSREQ = 1'b0;
//             HTRANS = 2'b00;
//         end
//     endcase

// end


// // Sequential part of the FSM 
// always @(posedge HCLK or negedge HRESETN) begin 

//     if(!HRESETN) begin 
//         src_ptr <= 32'h0;
//         dst_ptr <= 32'h0;
//         len_cnt <= 32'h0;
//     end else begin
//         case(current_state)
//             IDLE: begin 
//                 if(ctrl_reg[0]) begin
//                     src_ptr <= src_addr_reg;
//                     dst_ptr <= dst_addr_reg;
//                     len_cnt <= len_reg;
//                 end
//             end

//             READ_DATA: begin 
//                 if(HREADY) begin
//                     data_buf <= HRDATA; // caputred read
//                     src_ptr <= src_ptr+jump; // 
//                 end 
//             end

//             WRITE_DATA: begin
//                 check <= 1'b1;
//                 HWDATA <= data_buf;
//                 if(HREADY) begin 
//                     dst_ptr <= dst_ptr + jump;
//                     len_cnt <= len_cnt - 1;
//                 end 
//             end

//             DONE: begin
//                 irq <= 1'b1;
//             end  
//         endcase
    
//     end 



// end
// endmodule 








module dma_controller(
    input  wire        PCLK,
    input  wire        HCLK,
    input  wire        PRESETN,
    input  wire        HRESETN,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    input  wire        HGRANT,
    output reg         HBUSREQ,
    output reg  [31:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    input  wire        HREADY,
    output reg         irq,
    input  wire [31:0] HRDATA,
    output reg  [31:0] HWDATA,
    output reg         check
);
 
reg [31:0] src_addr_reg, dst_addr_reg, len_reg, ctrl_reg, status_reg;
reg [31:0] src_ptr, dst_ptr, len_cnt, data_buf;
 
localparam JUMP = 32'h4;
 
// ─────────────────────────────────────────────────────────────
// THE CORE FIX — add WRITE_ADDR state to properly separate
// the two halves of the AHB write transaction:
//
//  Old (broken) flow:
//    ADDR_PHASE → READ_DATA → WRITE_DATA
//    READ_DATA drove the write address AND loaded data_buf
//    on the SAME clock edge — memory saw stale data_buf.
//
//  New (correct) flow:
//    ADDR_PHASE → READ_DATA → WRITE_ADDR → WRITE_DATA
//
//    READ_DATA  : drive src read address, wait for HRDATA
//                 On HREADY: latch HRDATA into data_buf
//    WRITE_ADDR : drive dst write address on bus (1 cycle)
//                 data_buf is now fully stable (loaded last cycle)
//    WRITE_DATA : HWDATA=data_buf is captured by the memory
//                 slave on THIS cycle's posedge — correct data
//
// This matches the AHB spec: address phase and data phase are
// always separated by at least 1 clock.
// ─────────────────────────────────────────────────────────────
localparam IDLE       = 3'b000,
           BUS_REQ    = 3'b001,
           ADDR_PHASE = 3'b010,   // drive src read address
           READ_DATA  = 3'b011,   // wait for HRDATA, latch it
           WRITE_ADDR = 3'b100,   // drive dst write address
           WRITE_DATA = 3'b101,   // HWDATA captured by slave
           DONE       = 3'b110;
 
reg [2:0] current_state, next_state;
 
reg [31:0] len_cnt_next;
always @(*) begin
    if (current_state == WRITE_DATA && HREADY)
        len_cnt_next = len_cnt - 1;
    else
        len_cnt_next = len_cnt;
end
 
//  APB write 
always @(posedge PCLK or negedge PRESETN) begin
    if (!PRESETN) begin
        src_addr_reg <= 0; dst_addr_reg <= 0;
        len_reg <= 0; ctrl_reg <= 0;
    end else if (PSEL && PENABLE && PWRITE) begin
        case (PADDR[7:0])
            8'h00: src_addr_reg <= PWDATA;
            8'h04: dst_addr_reg <= PWDATA;
            8'h08: len_reg      <= PWDATA;
            8'h0C: ctrl_reg     <= PWDATA;
            8'h14: begin ctrl_reg[0] <= 0; status_reg <= 0; end
        endcase
    end
end
 
always @(*) begin
    case (PADDR[7:0])
        8'h00: PRDATA = src_addr_reg;
        8'h04: PRDATA = dst_addr_reg;
        8'h08: PRDATA = len_reg;
        8'h0C: PRDATA = ctrl_reg;
        8'h10: PRDATA = status_reg;
        default: PRDATA = 32'hDEADBEEF;
    endcase
end
 
assign PREADY = 1'b1;
 
// ── State register ────────────────────────────────────────────
always @(posedge HCLK or negedge HRESETN) begin
    if (!HRESETN) current_state <= IDLE;
    else          current_state <= next_state;
end
 
// ── Next-state logic ──────────────────────────────────────────
always @(*) begin
    case (current_state)
        IDLE:       next_state = ctrl_reg[0] ? BUS_REQ    : IDLE;
        BUS_REQ:    next_state = HGRANT      ? ADDR_PHASE : BUS_REQ;
        ADDR_PHASE: next_state = READ_DATA;
        READ_DATA:  next_state = HREADY      ? WRITE_ADDR : READ_DATA;
        WRITE_ADDR: next_state = WRITE_DATA;
        WRITE_DATA: next_state = HREADY
                                   ? (len_cnt_next == 0 ? DONE : ADDR_PHASE)
                                   : WRITE_DATA;
        DONE:       next_state = IDLE;
        default:    next_state = IDLE;
    endcase
end
 
// ── HWDATA — combinational from data_buf 
always @(*) HWDATA = data_buf;
 
// ── AHB combinational outputs ─────────────────────────────────
always @(*) begin
    HBUSREQ = (current_state != IDLE && current_state != DONE);
    HTRANS  = 2'b00;
    HADDR   = 32'h0;
    HWRITE  = 1'b0;
 
    case (current_state)
        BUS_REQ:    begin HTRANS = 2'b00; end
 
        ADDR_PHASE: begin                  // read address phase
            HADDR  = src_ptr;
            HTRANS = 2'b10;
            HWRITE = 1'b0;
        end
 
        READ_DATA:  begin                  // read data phase (slave responding)
            HTRANS = 2'b00;               // no new address yet
        end
 
        WRITE_ADDR: begin                  // write address phase
            HADDR  = dst_ptr;
            HTRANS = 2'b10;
            HWRITE = 1'b1;
        end
 
        WRITE_DATA: begin                  // write data phase (HWDATA valid)
            HTRANS = 2'b00;
        end
 
        default: begin HBUSREQ = 1'b0; HTRANS = 2'b00; end
    endcase
end
 
// ── Sequential datapath ───────────────────────────────────────
always @(posedge HCLK or negedge HRESETN) begin
    if (!HRESETN) begin
        src_ptr <= 0; dst_ptr <= 0; len_cnt <= 0;
        data_buf <= 0; irq <= 0; status_reg <= 0; check <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                irq <= 0; check <= 0;
                if (ctrl_reg[0]) begin
                    src_ptr    <= src_addr_reg;
                    dst_ptr    <= dst_addr_reg;
                    len_cnt    <= len_reg;
                    status_reg <= 32'h1;   // BUSY
                end
            end
 
            READ_DATA: begin
                if (HREADY) begin
                    data_buf <= HRDATA;            // latch read data
                    src_ptr  <= src_ptr + JUMP;    // advance source
                end
            end
 
            WRITE_DATA: begin
                check <= 1'b1;
                if (HREADY) begin
                    dst_ptr <= dst_ptr + JUMP;     // advance dest
                    len_cnt <= len_cnt_next;
                end
            end
 
            DONE: begin
                irq        <= 1'b1;
                status_reg <= 32'h2;   // DONE
            end
        endcase
    end
end
 
endmodule
 