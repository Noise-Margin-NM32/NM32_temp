//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : AHB_to_APB_Bridge
// Purpose : AHB slave (slave 0, 0x2000_0000-0x200F_FFFF) that converts
//           each AHB transfer into one APB SETUP/ACCESS transaction and
//           decodes it onto NUM_APB_SLAVES PSEL lines.
// Clocks  : h_clk (system clk). APB side runs on the same clock.
// Notes   : - PENABLE is high for exactly ONE h_clk cycle (ACCESS state).
//             Every APB peripheral must sample its register writes on the
//             full-rate clk - a peripheral clocked on the divided pclk will
//             silently drop writes (see SPI_BOOT_DEBUG_REPORT.md).
//           - Zero-wait APB only: PREADY/pready is not sampled.
//           - PSLVERR is not supported; h_resp is always OKAY.
//           - Back-to-back AHB transfers are accepted from ACCESS directly
//             (ACCESS -> LATCH) so none are dropped.
//
//  State flow per transfer (h_ready_out shown in brackets):
//     IDLE [1] --valid--> LATCH [0] --> SETUP [0] --> ACCESS [1] --> IDLE
//                                                       |--valid--> LATCH
//==========================================================================
`timescale 1ns / 1ps
`default_nettype wire

module AHB_to_APB_Bridge #(
    parameter DATA_WIDTH     = 32,
    parameter ADDR_WIDTH     = 32,
    parameter TRAN_WIDTH     = 3,
    parameter NUM_APB_SLAVES = 1,

    // Inclusive [start, end] address window of each APB slave, index = PSEL bit
    parameter [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_START = 0,
    parameter [NUM_APB_SLAVES-1:0][31:0] SLAVE_ADDR_END   = 0
) (
    // ---- AHB slave side ----
    input   logic                                           h_clk,
    input   logic                                           h_reset_n,
    input   logic                                           h_write,      // 1 = write
    input   logic                                           h_sel_apb,    // HSEL for this bridge
    input   logic                                           h_ready_in,   // global HREADY
    input   logic [TRAN_WIDTH-1:0]                          h_trans,      // HTRANS
    input   logic [DATA_WIDTH-1:0]                          h_wdata,      // HWDATA (data phase)
    input   logic [DATA_WIDTH-1:0]                          h_addr,       // HADDR  (address phase)
    output  logic                                           h_resp,       // HRESP (always OKAY)
    output  logic                                           h_ready_out,  // HREADYOUT
    output  logic [DATA_WIDTH-1:0]                          h_rdata,      // HRDATA from selected APB slave

    // ---- APB master side (shared by all APB slaves) ----
    output  logic                                           p_enable,
    output  logic                                           p_write,
    output  logic [NUM_APB_SLAVES-1:0]                      p_selx,       // one-hot PSEL
    output  logic [DATA_WIDTH-1:0]                          p_wdata,
    output  logic [DATA_WIDTH-1:0]                          p_addr,
    input   logic [NUM_APB_SLAVES-1:0][DATA_WIDTH-1:0]      p_rdata,      // PRDATA per slave
    input   logic [NUM_APB_SLAVES-1:0]                      pready        // PREADY per slave (unused)
);

    // ---------------------------------------------------------------------
    // 1. APB slave decode (combinational on the latched address)
    // ---------------------------------------------------------------------
    reg [31:0] addr_low_tmp;
    reg [31:0] addr_high_tmp;
    integer i;

    always @(*) begin
        for (i = 0; i < NUM_APB_SLAVES; i = i + 1) begin
            addr_low_tmp  = SLAVE_ADDR_START[i];
            addr_high_tmp = SLAVE_ADDR_END[i];
            p_selx[i] = (p_addr >= addr_low_tmp && p_addr <= addr_high_tmp);
        end
    end

    // ---------------------------------------------------------------------
    // 2. Transfer FSM
    // ---------------------------------------------------------------------
    // A valid AHB transfer to the bridge: selected, NONSEQ/SEQ, bus ready.
    logic valid;
    assign valid = (h_sel_apb && (h_trans == 2'b10 || h_trans == 2'b11) && h_ready_in);

    typedef enum logic [2:0] {
        IDLE,     // waiting for a transfer; HREADYOUT=1
        LATCH,    // address latched, HWDATA now on the bus
        SETUP,    // APB SETUP phase   (PSEL=1, PENABLE=0)
        ACCESS    // APB ACCESS phase  (PSEL=1, PENABLE=1); AHB transfer completes
    } state_t;

    state_t state, next_state;

    logic [ADDR_WIDTH-1:0] addr_reg;   // latched HADDR  -> PADDR
    logic                  write_reg;  // latched HWRITE -> PWRITE

    always_ff @(posedge h_clk or negedge h_reset_n) begin
        if (!h_reset_n) begin
            state     <= IDLE;
            addr_reg  <= 0;
            write_reg <= 0;
        end else begin
            state <= next_state;
            // Accept a new address phase in IDLE, or pipelined in ACCESS.
            if ((state == IDLE || state == ACCESS) && valid) begin
                addr_reg  <= h_addr;
                write_reg <= h_write;
            end
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:   if (valid) next_state = LATCH;
            LATCH:  next_state = SETUP;
            SETUP:  next_state = ACCESS;
            ACCESS: next_state = valid ? LATCH : IDLE;
        endcase
    end

    // ---------------------------------------------------------------------
    // 3. Outputs
    // ---------------------------------------------------------------------
    always_comb begin
        h_resp      = 1'b0;
        p_write     = write_reg;
        p_addr      = addr_reg;
        // HWDATA is valid during the AHB data phase (SETUP/ACCESS) and is
        // forwarded directly rather than registered.
        p_wdata     = ((state == SETUP || state == ACCESS) && write_reg) ? h_wdata : 32'b0;
        h_ready_out = (state == IDLE || state == ACCESS);
        p_enable    = (state == ACCESS);
    end

    // Read data from whichever APB slave is selected.
    always_comb begin
        h_rdata = 0;
        for (int j = 0; j < NUM_APB_SLAVES; j++) begin
            if (p_selx[j]) h_rdata = p_rdata[j];
        end
    end

`ifdef NM32_TRACE
    always @(state, valid) begin
        $display("Time=%0t: [APB_BRIDGE] state=%0d next=%0d valid=%b h_addr=%h p_addr=%h p_wdata=%h p_enable=%b p_selx=%b p_write=%b",
                 $time, state, next_state, valid, h_addr, p_addr, p_wdata, p_enable, p_selx, p_write);
    end
`endif
endmodule
