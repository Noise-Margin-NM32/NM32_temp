`timescale 1ns/1ps
`default_nettype none

/*
    EF_I2S_TX_APB

    Simple APB wrapper for EF_I2S_TX.

    Direction:
        APB write TXDATA -> TX FIFO -> I2S TX serializer -> sdo

    Register map, lower 16 bits of PADDR:
        0x0000 TXDATA               W    APB write pushes one sample into TX FIFO
        0x0004 PR                   R/W  SCK prescaler
        0x0010 CTRL                 R/W  bit0: tx_en, bit1: fifo_en
        0x0014 CFG                  R/W  bit[1:0]: channels
                                         bit[3]: left_justified
                                         bit[9:4]: sample_size
        0xFE00 TX_FIFO_LEVEL        R    TX FIFO level
        0xFE04 TX_FIFO_THRESHOLD    R/W  TX FIFO threshold
        0xFE08 TX_FIFO_FLUSH        W    write 1 to flush TX FIFO, auto clears
        0xFE0C TX_STATUS            R    bit0 empty, bit1 below/equal threshold,
                                         bit2 full, bit3 tx_busy
        0xFF00 IM                   R/W  interrupt mask
        0xFF04 MIS                  R    masked interrupt status
        0xFF08 RIS                  R    raw interrupt status
        0xFF0C IC                   W    interrupt clear
        0xFF10 GCLK                 R/W  bit0: internal enable gate

    Interrupt bits:
        bit0 TX FIFO empty
        bit1 TX FIFO level <= threshold
        bit2 TX FIFO full
        bit3 TX busy falling/done condition is not latched separately;
             this wrapper uses live tx_busy in TX_STATUS only.

    Main use:
        For streaming audio output, CPU/DMA writes TXDATA whenever
        TX FIFO level is low or TX FIFO is empty.
*/

module EF_I2S_TX_APB #(
    parameter DW = 32,
    parameter AW = 4
)(
    input  wire         sc_testmode,

    input  wire         PCLK,
    input  wire         PRESETn,
    input  wire         PWRITE,
    input  wire [31:0]  PWDATA,
    input  wire [31:0]  PADDR,
    input  wire         PENABLE,
    input  wire         PSEL,

    output wire         PREADY,
    output wire [31:0]  PRDATA,
    output wire         IRQ,

    output wire         ws,
    output wire         sck,
    output wire         sdo
);

    localparam TXDATA_REG_OFFSET            = 16'h0000;
    localparam PR_REG_OFFSET                = 16'h0004;
    localparam CTRL_REG_OFFSET              = 16'h0010;
    localparam CFG_REG_OFFSET               = 16'h0014;
    localparam TX_FIFO_LEVEL_REG_OFFSET     = 16'hFE00;
    localparam TX_FIFO_THRESHOLD_REG_OFFSET = 16'hFE04;
    localparam TX_FIFO_FLUSH_REG_OFFSET     = 16'hFE08;
    localparam TX_STATUS_REG_OFFSET         = 16'hFE0C;
    localparam IM_REG_OFFSET                = 16'hFF00;
    localparam MIS_REG_OFFSET               = 16'hFF04;
    localparam RIS_REG_OFFSET               = 16'hFF08;
    localparam IC_REG_OFFSET                = 16'hFF0C;
    localparam GCLK_REG_OFFSET              = 16'hFF10;

    wire apb_valid = PSEL & PENABLE;
    wire apb_we    = PWRITE & apb_valid;
    wire apb_re    = (~PWRITE) & apb_valid;

    assign PREADY = PSEL & PENABLE & PCLK; // Ensure PREADY is synchronized with PCLK

    // ------------------------------------------------------------
    // Registers
    // ------------------------------------------------------------
    reg [0:0] GCLK_REG;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            GCLK_REG <= 1'b0;
        else if (apb_we && (PADDR[15:0] == GCLK_REG_OFFSET))
            GCLK_REG <= PWDATA[0];
    end

    reg [7:0] PR_REG;
    wire [7:0] sck_prescaler = PR_REG;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            PR_REG <= 8'd0;
        else if (apb_we && (PADDR[15:0] == PR_REG_OFFSET))
            PR_REG <= PWDATA[7:0];
    end

    reg [1:0] CTRL_REG;
    wire tx_en_reg   = CTRL_REG[0];
    wire fifo_en_reg = CTRL_REG[1];

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            CTRL_REG <= 2'b00;
        else if (apb_we && (PADDR[15:0] == CTRL_REG_OFFSET))
            CTRL_REG <= PWDATA[1:0];
    end

    reg [11:0] CFG_REG;
    wire [1:0] channels       = CFG_REG[1:0];
    wire       left_justified = CFG_REG[3];
    wire [5:0] sample_size    = CFG_REG[9:4];

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            CFG_REG <= 12'h123; // sample_size=18, left_justified=0 by default? user can rewrite
        else if (apb_we && (PADDR[15:0] == CFG_REG_OFFSET))
            CFG_REG <= PWDATA[11:0];
    end

    reg [AW-1:0] TX_FIFO_THRESHOLD_REG;
    wire [AW-1:0] tx_fifo_threshold = TX_FIFO_THRESHOLD_REG;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            TX_FIFO_THRESHOLD_REG <= {AW{1'b0}};
        else if (apb_we && (PADDR[15:0] == TX_FIFO_THRESHOLD_REG_OFFSET))
            TX_FIFO_THRESHOLD_REG <= PWDATA[AW-1:0];
    end

    reg TX_FIFO_FLUSH_REG;
    wire tx_fifo_flush = TX_FIFO_FLUSH_REG;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            TX_FIFO_FLUSH_REG <= 1'b0;
        else if (apb_we && (PADDR[15:0] == TX_FIFO_FLUSH_REG_OFFSET))
            TX_FIFO_FLUSH_REG <= PWDATA[0];
        else
            TX_FIFO_FLUSH_REG <= 1'b0;
    end

    // ------------------------------------------------------------
    // TX FIFO APB write interface
    // ------------------------------------------------------------
    wire txdata_write = apb_we && (PADDR[15:0] == TXDATA_REG_OFFSET);

    wire          tx_fifo_wr    = txdata_write;
    wire [DW-1:0] tx_fifo_wdata = PWDATA[DW-1:0];

    // ------------------------------------------------------------
    // TX core signals
    // ------------------------------------------------------------
    wire          tx_fifo_full;
    wire          tx_fifo_empty;
    wire [AW-1:0] tx_fifo_level;
    wire          tx_busy;

    wire clock_gate_enabled = sc_testmode ? 1'b1 : GCLK_REG[0];
    wire tx_core_en = tx_en_reg & clock_gate_enabled;

    EF_I2S_TX #(
        .DW(DW),
        .AW(AW)
    ) instance_to_wrap (
        .clk(PCLK),
        .rst_n(PRESETn),

        .fifo_wr(tx_fifo_wr),
        .fifo_wdata(tx_fifo_wdata),
        .fifo_flush(tx_fifo_flush),
        .fifo_en(fifo_en_reg),

        .fifo_full(tx_fifo_full),
        .fifo_empty(tx_fifo_empty),
        .fifo_level(tx_fifo_level),

        .en(tx_core_en),
        .sample_size(sample_size),
        .sck_prescaler(sck_prescaler),
        .left_justified(left_justified),
        .channels(channels),

        .sck(sck),
        .ws(ws),
        .sdo(sdo),

        .tx_busy(tx_busy)
    );

    // ------------------------------------------------------------
    // Status and interrupt logic
    // ------------------------------------------------------------
    wire tx_fifo_below_threshold = (tx_fifo_level <= tx_fifo_threshold);
    wire [31:0] TX_STATUS_WIRE = {
        28'd0,
        tx_busy,
        tx_fifo_full,
        tx_fifo_below_threshold,
        tx_fifo_empty
    };

    reg [2:0] IM_REG;
    reg [2:0] IC_REG;
    reg [2:0] RIS_REG;

    wire [2:0] event_sources;
    assign event_sources[0] = tx_fifo_empty;
    assign event_sources[1] = tx_fifo_below_threshold;
    assign event_sources[2] = tx_fifo_full;

    wire [2:0] MIS_REG = RIS_REG & IM_REG;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            IM_REG <= 3'b000;
        else if (apb_we && (PADDR[15:0] == IM_REG_OFFSET))
            IM_REG <= PWDATA[2:0];
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            IC_REG <= 3'b000;
        else if (apb_we && (PADDR[15:0] == IC_REG_OFFSET))
            IC_REG <= PWDATA[2:0];
        else
            IC_REG <= 3'b000;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            RIS_REG <= 3'b000;
        else begin
            if (IC_REG[0])
                RIS_REG[0] <= 1'b0;
            else if (event_sources[0])
                RIS_REG[0] <= 1'b1;

            if (IC_REG[1])
                RIS_REG[1] <= 1'b0;
            else if (event_sources[1])
                RIS_REG[1] <= 1'b1;

            if (IC_REG[2])
                RIS_REG[2] <= 1'b0;
            else if (event_sources[2])
                RIS_REG[2] <= 1'b1;
        end
    end

    assign IRQ = |MIS_REG;

    // ------------------------------------------------------------
    // APB read mux
    // ------------------------------------------------------------
    assign PRDATA =
        (PADDR[15:0] == TXDATA_REG_OFFSET)            ? 32'h00000000 :
        (PADDR[15:0] == PR_REG_OFFSET)                ? {24'd0, PR_REG} :
        (PADDR[15:0] == CTRL_REG_OFFSET)              ? {30'd0, CTRL_REG} :
        (PADDR[15:0] == CFG_REG_OFFSET)               ? {20'd0, CFG_REG} :
        (PADDR[15:0] == TX_FIFO_LEVEL_REG_OFFSET)     ? {{(32-AW){1'b0}}, tx_fifo_level} :
        (PADDR[15:0] == TX_FIFO_THRESHOLD_REG_OFFSET) ? {{(32-AW){1'b0}}, TX_FIFO_THRESHOLD_REG} :
        (PADDR[15:0] == TX_FIFO_FLUSH_REG_OFFSET)     ? {31'd0, TX_FIFO_FLUSH_REG} :
        (PADDR[15:0] == TX_STATUS_REG_OFFSET)         ? TX_STATUS_WIRE :
        (PADDR[15:0] == IM_REG_OFFSET)                ? {29'd0, IM_REG} :
        (PADDR[15:0] == MIS_REG_OFFSET)               ? {29'd0, MIS_REG} :
        (PADDR[15:0] == RIS_REG_OFFSET)               ? {29'd0, RIS_REG} :
        (PADDR[15:0] == GCLK_REG_OFFSET)              ? {31'd0, GCLK_REG} :
                                                         32'hDEADBEEF;

endmodule

`default_nettype wire
