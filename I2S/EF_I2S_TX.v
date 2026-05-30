`timescale 1ns/1ps
`default_nettype none

/*
    Simple I2S Transmitter with TX FIFO

    Direction:
        Parallel samples are written into TX FIFO.
        TX engine reads FIFO and serializes samples on sdo.

    Basic flow:
        fifo_wr + fifo_wdata
            -> TX FIFO
            -> serializer
            -> sdo, using generated sck and ws

    Notes:
        - Uses ef_util_fifo with parameters DW and AW.
        - sample_size controls number of valid bits shifted out.
        - Data is shifted MSB-first from fifo_rdata[sample_size-1:0].
        - left_justified = 1 means MSB is transmitted immediately in the slot.
        - left_justified = 0 inserts one dummy bit before MSB, similar to standard I2S.
*/

module EF_I2S_TX #(
    parameter DW = 32,
    parameter AW = 4
)(
    input  wire          clk,
    input  wire          rst_n,

    // TX FIFO write side: producer/testbench/APB wrapper writes samples here
    input  wire          fifo_wr,
    input  wire [DW-1:0] fifo_wdata,
    input  wire          fifo_flush,
    input  wire          fifo_en,

    output wire          fifo_full,
    output wire          fifo_empty,
    output wire [AW-1:0] fifo_level,

    // TX configuration
    input  wire          en,
    input  wire [5:0]    sample_size,
    input  wire [7:0]    sck_prescaler,
    input  wire          left_justified,
    input  wire [1:0]    channels,

    // I2S output pins
    output wire          sck,
    output wire          ws,
    output wire          sdo,

    // Debug/status
    output wire          tx_busy
);

    // ---------------------------------------------------------------------
    // TX FIFO
    // ---------------------------------------------------------------------
    wire [DW-1:0] fifo_rdata;
    reg          fifo_rd_int;

    ef_util_fifo #(
        .DW(DW),
        .AW(AW)
    ) TXFIFO (
        .clk(clk),
        .rst_n(rst_n),
        .flush(fifo_flush),

        .wr(fifo_wr & fifo_en & ~fifo_full),
        .rd(fifo_rd_int),

        .wdata(fifo_wdata),
        .rdata(fifo_rdata),

        .full(fifo_full),
        .empty(fifo_empty),
        .level(fifo_level)
    );

    // ---------------------------------------------------------------------
    // SCK generation
    // ---------------------------------------------------------------------
    reg [7:0] div_count;
    reg       sck_reg;
    reg       ws_reg;
    reg       sdo_reg;

    assign sck = sck_reg;
    assign ws  = ws_reg;
    assign sdo = sdo_reg;

    // ---------------------------------------------------------------------
    // Serializer FSM
    // ---------------------------------------------------------------------
    localparam ST_IDLE  = 2'd0;
    localparam ST_READ  = 2'd1;
    localparam ST_LOAD  = 2'd2;
    localparam ST_SHIFT = 2'd3;

    reg [1:0]    state;
    reg [DW-1:0] shift_sample;
    reg [5:0]    bit_index;
    reg          delay_bit;

    assign tx_busy = (state != ST_IDLE);

    // Valid sample_size guard.
    // If sample_size is accidentally programmed as 0, use 1 bit to avoid underflow.
    wire [5:0] safe_sample_size = (sample_size == 6'd0) ? 6'd1 : sample_size;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_count    <= 8'd0;
            sck_reg      <= 1'b0;
            ws_reg       <= 1'b0;
            sdo_reg      <= 1'b0;

            fifo_rd_int  <= 1'b0;
            state        <= ST_IDLE;
            shift_sample <= {DW{1'b0}};
            bit_index    <= 6'd0;
            delay_bit    <= 1'b0;
        end else begin
            fifo_rd_int <= 1'b0;

            if (!en) begin
                div_count    <= 8'd0;
                sck_reg      <= 1'b0;
                ws_reg       <= 1'b0;
                sdo_reg      <= 1'b0;

                state        <= ST_IDLE;
                shift_sample <= {DW{1'b0}};
                bit_index    <= 6'd0;
                delay_bit    <= 1'b0;
            end else begin

                // ---------------------------------------------------------
                // FIFO read/load side
                // ---------------------------------------------------------
                case (state)
                    ST_IDLE: begin
                        // channels is kept for compatibility with RX config.
                        // For now, 2'b11 means normal continuous stereo-like slots.
                        // Other values still transmit available FIFO samples.
                        if (fifo_en && !fifo_empty) begin
                            fifo_rd_int <= 1'b1;
                            state       <= ST_READ;
                        end
                    end

                    ST_READ: begin
                        // One cycle after asserting fifo_rd_int.
                        // FIFO updates rdata on this clock edge.
                        state <= ST_LOAD;
                    end

                    ST_LOAD: begin
                        shift_sample <= fifo_rdata;
                        bit_index    <= safe_sample_size - 1'b1;
                        delay_bit    <= ~left_justified;
                        state        <= ST_SHIFT;
                    end

                    ST_SHIFT: begin
                        // Bit shifting happens on generated SCK falling edges below.
                    end

                    default: begin
                        state <= ST_IDLE;
                    end
                endcase

                // ---------------------------------------------------------
                // SCK divider and serial output update
                // We update SDO on SCK falling edge.
                // Receiver/testbench can sample SDO on SCK rising edge.
                // ---------------------------------------------------------
                if (div_count >= sck_prescaler) begin
                    div_count <= 8'd0;
                    sck_reg   <= ~sck_reg;

                    // old sck_reg == 1 means this clock creates a falling edge
                    if (sck_reg == 1'b1) begin
                        if (state == ST_SHIFT) begin
                            if (delay_bit) begin
                                // Standard I2S-style one-bit delay.
                                sdo_reg   <= 1'b0;
                                delay_bit <= 1'b0;
                            end else begin
                                sdo_reg <= shift_sample[bit_index];

                                if (bit_index == 6'd0) begin
                                    state     <= ST_IDLE;
                                    ws_reg    <= ~ws_reg;
                                end else begin
                                    bit_index <= bit_index - 1'b1;
                                end
                            end
                        end else begin
                            sdo_reg <= 1'b0;
                        end
                    end
                end else begin
                    div_count <= div_count + 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire
