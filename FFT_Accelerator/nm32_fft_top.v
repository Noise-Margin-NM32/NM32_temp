//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : nm32_fft_top
// Purpose : 512-point in-place iterative radix-2 FFT engine using one folded
//           butterfly (butterfly_folded). Reads/writes the frame directly in the
//           ping-pong RAM bank owned by the accelerators.
// Clocks  : clk, active-high rst
// Notes   : - 9 stages x 256 butterflies, ~11 clk per butterfly.
//           - Expects BIT-REVERSED input order and produces natural order
//             (firmware does the reordering, see main.c bit_reverse9()).
//           - Each butterfly scales by 1/2, so the result is scaled by 1/512.
//           - Data format {re[31:16], im[15:0]}, signed Q15.
//           - Twiddle RAM: port A = AHB (tw_*_ext), port B = engine.
//==========================================================================
`timescale 1ns / 1ps

module nm32_fft_top (
    input wire clk,
    input wire rst,
    input wire start,
    output wire ram_we_a,
    output wire [8:0] ram_addr_a,
    output wire [31:0] ram_din_a,
    input  wire [31:0] ram_dout_a,
    
    output wire ram_we_b,
    output wire [8:0] ram_addr_b,
    output wire [31:0] ram_din_b,
    input  wire [31:0] ram_dout_b,

    
    // Twiddle RAM Write Ports (Mapped to AHB)
    input wire tw_we,
    input wire [7:0] tw_ext_addr,
    input wire [31:0] tw_ext_din,
    output wire [31:0] tw_ext_dout,
    
    output reg done
);

    reg [31:0] ram_din_a_reg, ram_din_b_reg;
    reg [8:0] ram_addr_a_reg, ram_addr_b_reg;
    reg ram_we_a_reg, ram_we_b_reg;

    // Registered data-RAM ports (to ping_pong_ram via the wrapper)
    assign ram_we_a   = ram_we_a_reg;
    assign ram_addr_a = ram_addr_a_reg;
    assign ram_din_a  = ram_din_a_reg;

    assign ram_we_b   = ram_we_b_reg;
    assign ram_addr_b = ram_addr_b_reg;
    assign ram_din_b  = ram_din_b_reg;

    // -----------------------------------------------------------------
    // Twiddle RAM (256 x 32-bit words)
    // -----------------------------------------------------------------
    reg [31:0] twiddle_ram [0:255];
    reg [31:0] tw_rdata_ext;
    reg [31:0] tw_rdata_math;
    reg [7:0] tw_addr;
    
    always @(posedge clk) begin
        // Port A: External AHB Write/Read
        if (tw_we) begin
            twiddle_ram[tw_ext_addr] <= tw_ext_din;
        end
        tw_rdata_ext <= twiddle_ram[tw_ext_addr];
        
        // Port B: Internal Math Engine Read
        tw_rdata_math <= twiddle_ram[tw_addr];
    end
    
    assign tw_ext_dout = tw_rdata_ext;
    
    wire signed [15:0] tw_re = tw_rdata_math[31:16];
    wire signed [15:0] tw_im = tw_rdata_math[15:0];

    reg bf_start;
    wire bf_done;
    reg signed [15:0] bf_A_re, bf_A_im, bf_B_re, bf_B_im, bf_W_re, bf_W_im;
    wire signed [15:0] bf_X_re, bf_X_im, bf_Y_re, bf_Y_im;

    butterfly_folded math_engine (
        .clk(clk),
        .rst(rst),
        .start(bf_start),
        .A_re(bf_A_re), .A_im(bf_A_im),
        .B_re(bf_B_re), .B_im(bf_B_im),
        .W_re(bf_W_re), .W_im(bf_W_im),
        .X_re(bf_X_re), .X_im(bf_X_im),
        .Y_re(bf_Y_re), .Y_im(bf_Y_im),
        .done(bf_done)
    );

    // ---- Loop counters for the 9-stage radix-2 schedule ----
    reg [3:0] s;        // stage, 1..9
    reg [9:0] m;        // butterfly group span = 2^s
    reg [8:0] m2;       // half span = 2^(s-1) = distance between A and B
    reg [9:0] k;        // group base index
    reg [8:0] j;        // index inside the group; twiddle = W^(j*512/m)
    reg [2:0] state;

    // ---- Control FSM ----
    //   0 IDLE     wait for start
    //   1 ADDR     drive A=k+j, B=k+j+m2 and twiddle address
    //   2 WAIT     RAM / twiddle read latency
    //   3 LOAD     capture A, B, W and start the butterfly
    //   4 BFLY     wait for bf_done, then write X->A, Y->B (in place)
    //   5 NEXT     advance j/k/s
    //   7 SETTLE   one idle cycle so counters are stable before ADDR
    //   6 DONE     1-cycle done pulse
`ifdef NM32_TRACE

    always @(posedge clk) begin
        if (state != 0) begin
            $display("Time=%0t: [FFT ENGINE] state=%d s=%d k=%d j=%d bf_start=%b bf_done=%b done=%b", 
                     $time, state, s, k, j, bf_start, bf_done, done);
        end
    end
`endif

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            bf_start <= 0;
            ram_we_a_reg <= 0; ram_we_b_reg <= 0;
            ram_addr_a_reg <= 0; ram_addr_b_reg <= 0;
            s <= 1; m <= 2; m2 <= 1; k <= 0; j <= 0;
        end else begin
            case (state)
                0: begin
                    done <= 0;
                    ram_we_a_reg <= 0;
                    ram_we_b_reg <= 0;
                    ram_din_a_reg <= 0;
                    
                    if (start) begin
                        s <= 1; m <= 2; m2 <= 1; k <= 0; j <= 0;
                        ram_we_a_reg <= 0;
                        state <= 1;
                    end
                end
                
                1: begin
                    ram_addr_a_reg <= k + j;
                    ram_addr_b_reg <= k + j + m2;
                    tw_addr <= j << (9 - s);
                    state <= 2;
                end
                
                2: begin
                    state <= 3;
                end
                
                3: begin
                    bf_A_re <= ram_dout_a[31:16]; bf_A_im <= ram_dout_a[15:0];
                    bf_B_re <= ram_dout_b[31:16]; bf_B_im <= ram_dout_b[15:0];
                    bf_W_re <= tw_re; bf_W_im <= tw_im;
                    bf_start <= 1;
                    state <= 4;
                end
                
                4: begin
                    bf_start <= 0;
                    if (bf_done) begin
                        ram_din_a_reg <= {bf_X_re, bf_X_im};
                        ram_din_b_reg <= {bf_Y_re, bf_Y_im};
                        ram_we_a_reg <= 1; ram_we_b_reg <= 1;
                        state <= 5;
                    end
                end
                
                5: begin
                    ram_we_a_reg <= 0; ram_we_b_reg <= 0;
                    if (j + 1 == m2) begin
                        j <= 0;
                        if (k + m >= 512) begin
                            k <= 0;
                            if (s == 9) begin
                                state <= 6;
                            end else begin
                                s <= s + 1;
                                m <= m << 1;
                                m2 <= m2 << 1;
                                state <= 7; // Go to idle latching state
                            end
                        end else begin
                            k <= k + m;
                            state <= 7; // Go to idle latching state
                        end
                    end else begin
                        j <= j + 1;
                        state <= 7; // Go to idle latching state
                    end
                end
                
                7: begin
                    // Idle latching state to ensure counters (j, k, s) are entirely stable 
                    // for a full clock cycle before they are used to compute ram_addr_a/b
                    state <= 1;
                end
                
                6: begin
                    done <= 1;
                    state <= 0;
                end
                
                default: state <= 0;
            endcase
        end
    end
endmodule
