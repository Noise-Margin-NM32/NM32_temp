`timescale 1ns / 1ps
// Simplified 5-State APB FSM Controller
//
// States
//   ST_IDLE     - idle, watching AHB bus for a valid transaction
//   ST_WWAIT    - write: one-cycle buffer waiting for Hwdata to arrive
//   ST_ENABLE_R - read:  APB setup + enable phase (loops on ~PREADY)
//   ST_SETUP_W  - write: APB setup phase  (PSEL=1, Penable=0)
//   ST_ENABLE_W - write: APB enable phase (PSEL=1, Penable=1, loops on ~PREADY)

module APB_FSM_Controller (
    input  logic        Hclk,
    input  logic        Hresetn,
    input  logic        valid,
    input  logic [31:0] Haddr1,
    input  logic [31:0] Haddr2,
    input  logic [31:0] Hwdata,
    input  logic [31:0] Prdata,
    input  logic        Hwrite,
    input  logic [31:0] Haddr,
    input  logic        Hwritereg,
    input  logic [3:0]  tempselx,
    input  logic        PREADY,

    output logic        Pwrite,
    output logic        Penable,
    output logic [3:0]  Pselx,
    output logic [31:0] Paddr,
    output logic [31:0] Pwdata,
    output logic        Hreadyout
);

    // ------------------------------------------------------------------
    // State encoding
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE     = 3'b000,
        ST_WWAIT    = 3'b001,
        ST_ENABLE_R = 3'b010,
        ST_SETUP_W  = 3'b011,
        ST_ENABLE_W = 3'b100
    } state_t;

    state_t PRESENT_STATE, NEXT_STATE;

    // State register - asynchronous active-low reset
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (~Hresetn) PRESENT_STATE <= ST_IDLE;
        else          PRESENT_STATE <= NEXT_STATE;
    end

    // ------------------------------------------------------------------
    // Next-state logic
    // ------------------------------------------------------------------
    always_comb begin : NSL
        case (PRESENT_STATE)

            ST_IDLE: begin
                if      (~valid)               NEXT_STATE = ST_IDLE;
                else if (valid &&  Hwrite)     NEXT_STATE = ST_WWAIT;
                else                           NEXT_STATE = ST_ENABLE_R;
            end

            ST_WWAIT: begin
                // Always advance - data has arrived on Hwdata
                NEXT_STATE = ST_SETUP_W;
            end

            ST_ENABLE_R: begin
                if      (~PREADY)              NEXT_STATE = ST_ENABLE_R;  // peripheral busy
                else if (~valid)               NEXT_STATE = ST_IDLE;
                else if (valid &&  Hwrite)     NEXT_STATE = ST_WWAIT;
                else                           NEXT_STATE = ST_ENABLE_R;  // back-to-back read
            end

            ST_SETUP_W: begin
                // Always advance to enable phase
                NEXT_STATE = ST_ENABLE_W;
            end

            ST_ENABLE_W: begin
                if      (~PREADY)              NEXT_STATE = ST_ENABLE_W;  // peripheral busy
                else if (~valid)               NEXT_STATE = ST_IDLE;
                else if (valid && Hwritereg)   NEXT_STATE = ST_SETUP_W;   // burst write
                else if (valid &&  Hwrite)     NEXT_STATE = ST_WWAIT;     // new write
                else                           NEXT_STATE = ST_ENABLE_R;  // new read
            end

            default: NEXT_STATE = ST_IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // Combinatorial output logic
    // ------------------------------------------------------------------
    logic        Penable_temp, Hreadyout_temp, Pwrite_temp;
    logic [3:0]  Pselx_temp;
    logic [31:0] Paddr_temp, Pwdata_temp;

    always_comb begin : OCL
        // Safe defaults - outputs hold unless a state overrides them
        Penable_temp   = 1'b0;
        Hreadyout_temp = 1'b1;
        Pwrite_temp    = 1'b0;
        Pselx_temp     = 4'b0000;
        Paddr_temp     = Paddr;   // hold registered value
        Pwdata_temp    = Pwdata;  // hold registered value

        case (PRESENT_STATE)

            ST_IDLE: begin
                if (valid && ~Hwrite) begin
                    // Pre-load read address - this becomes APB setup cycle next state
                    Paddr_temp     = Haddr;
                    Pselx_temp     = tempselx;
                    Hreadyout_temp = 1'b0;   // stall CPU until read completes
                end else if (valid && Hwrite) begin
                    Hreadyout_temp = 1'b1;   // CPU can issue data phase while we go to WWAIT
                end
            end

            ST_WWAIT: begin
                // Latch write address and data; wait for data to land on Hwdata
                Paddr_temp     = Haddr1;     // registered address (stable)
                Pwrite_temp    = 1'b1;
                Pselx_temp     = tempselx;   // look-ahead decode of current bus
                Pwdata_temp    = Hwdata;     // data arrived this cycle
                Hreadyout_temp = 1'b0;
            end

            ST_ENABLE_R: begin
                // APB read - assert PSEL + Penable, wait for PREADY
                // Note: on the very first cycle in this state the registered Penable
                // output is still 0 (set in ST_IDLE). That cycle acts as the APB
                // setup phase. The Penable_temp=1 here registers one cycle later
                // as the enable phase. Both APB phases happen inside this one state.
                Paddr_temp     = Haddr1;     // locked - never follow live Haddr here
                Pselx_temp     = tempselx;
                Penable_temp   = 1'b1;
                if (~PREADY) begin
                    Hreadyout_temp = 1'b0;
                end else begin
                    Hreadyout_temp = 1'b1;
                    if (valid && ~Hwrite) begin
                        // Next read already on bus - pre-load its address (setup phase)
                        Paddr_temp     = Haddr;
                        Pselx_temp     = tempselx;
                        Penable_temp   = 1'b0;
                        Hreadyout_temp = 1'b0;
                    end
                end
            end

            ST_SETUP_W: begin
                // APB write setup phase: PSEL=1, Penable=0
                // Lock Pselx to registered value - prevents burst contention
                // where look-ahead tempselx may already point at next peripheral
                Pselx_temp     = Pselx;
                Pwrite_temp    = 1'b1;
                Penable_temp   = 1'b0;
                Hreadyout_temp = 1'b0;
            end

            ST_ENABLE_W: begin
                // APB write enable phase: PSEL=1, Penable=1
                Pselx_temp     = Pselx;     // locked
                Pwrite_temp    = 1'b1;
                Penable_temp   = 1'b1;
                if (~PREADY) begin
                    Hreadyout_temp = 1'b0;
                end else begin
                    Hreadyout_temp = 1'b1;
                    if (valid && Hwritereg) begin
                        // Burst write: next valid write already in pipeline - pre-load
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

    // ------------------------------------------------------------------
    // Output registers - asynchronous active-low reset
    // ------------------------------------------------------------------
    always_ff @(posedge Hclk or negedge Hresetn) begin
        if (~Hresetn) begin
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

endmodule