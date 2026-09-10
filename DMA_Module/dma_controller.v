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
 
// State Machine definition
localparam IDLE       = 3'b000,
           REQ_READ   = 3'b001,   // wait for HGRANT to drive read address
           READ_DATA  = 3'b010,   // wait for HREADY to latch HRDATA
           REQ_WRITE  = 3'b011,   // wait for HGRANT to drive write address
           WRITE_DATA = 3'b100,   // wait for HREADY for slave to capture HWDATA
           DONE       = 3'b101;
 
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
    end else begin
        if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[7:0])
                8'h00: src_addr_reg <= PWDATA;
                8'h04: dst_addr_reg <= PWDATA;
                8'h08: len_reg      <= PWDATA;
                8'h0C: ctrl_reg     <= PWDATA;
                8'h14: begin ctrl_reg[0] <= 0; end
            endcase
        end
        
        // Automatically clear ctrl_reg[0] once DMA has started so it doesn't loop
        if (current_state != IDLE) begin
            ctrl_reg[0] <= 1'b0;
        end
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
        IDLE:       next_state = ctrl_reg[0] ? REQ_READ : IDLE;
        REQ_READ:   next_state = (HGRANT && HREADY) ? READ_DATA : REQ_READ;
        READ_DATA:  next_state = HREADY ? REQ_WRITE : READ_DATA;
        REQ_WRITE:  next_state = (HGRANT && HREADY) ? WRITE_DATA : REQ_WRITE;
        WRITE_DATA: next_state = HREADY
                                   ? (len_cnt_next == 0 ? DONE : REQ_READ)
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
    HTRANS  = 2'b00; // default IDLE
    HADDR   = 32'h0;
    HWRITE  = 1'b0;
 
    case (current_state)
        REQ_READ: begin
            if (HGRANT) begin
                HTRANS = 2'b10; // NONSEQ
                HADDR  = src_ptr;
                HWRITE = 1'b0;
            end
        end
 
        REQ_WRITE: begin
            if (HGRANT) begin
                HTRANS = 2'b10; // NONSEQ
                HADDR  = dst_ptr;
                HWRITE = 1'b1;
            end
        end
        // READ_DATA and WRITE_DATA keep HTRANS = 00 (IDLE) because the address phase was already issued.
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
                end else if (PSEL && PENABLE && PWRITE && PADDR[7:0] == 8'h10 && PWDATA[0]) begin
                    status_reg <= 32'h0;   // CLEAR STATUS from CPU write
                    irq <= 1'b0;
                end
            end
 
            READ_DATA: begin
                if (HREADY) begin
                    data_buf <= HRDATA;            // latch read data
                    if (ctrl_reg[1]) src_ptr <= src_ptr + JUMP;    // advance source
                end
            end
 
            WRITE_DATA: begin
                check <= 1'b1;
                if (HREADY) begin
                    if (ctrl_reg[2]) dst_ptr <= dst_ptr + JUMP;     // advance dest
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