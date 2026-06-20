`timescale 1ns / 1ps
// Combinatorial APB Decoder — 4-Peripheral Configuration
//
// Two jobs:
//   1. Pass-through: Pselx[3:0] from bridge → PSEL[3:0] to each peripheral (one-hot)
//   2. Mux-back:     PRDATA[3:0][31:0] + PREADY[3:0] → single lane back to bridge
//      Uses case(1'b1) one-hot mux for clean priority-free selection.
//      Default guard holds PREADY=1 so unmapped addresses never deadlock the bus.

module APB_Decoder (
    input  logic [3:0]       Pselx_from_bridge,
    input  logic [31:0]      Paddr_from_bridge,   // available for debug / future use

    output logic [3:0]       PSEL,

    output logic [31:0]      Prdata_to_bridge,
    output logic             Pready_to_bridge,

    input  logic [3:0][31:0] PRDATA,
    input  logic [3:0]       PREADY
);

    // 1. Direct pass-through — bridge already produces clean one-hot
    assign PSEL = Pselx_from_bridge;

    // 2. Return-path mux — route the active peripheral's feedback to bridge
    always_comb begin
        case (1'b1)
            PSEL[0]: begin  // I2S RX
                Prdata_to_bridge = PRDATA[0];
                Pready_to_bridge = PREADY[0];
            end
            PSEL[1]: begin  // I2S TX
                Prdata_to_bridge = PRDATA[1];
                Pready_to_bridge = PREADY[1];
            end
            PSEL[2]: begin  // GPIO
                Prdata_to_bridge = PRDATA[2];
                Pready_to_bridge = PREADY[2];
            end
            PSEL[3]: begin  // WDT
                Prdata_to_bridge = PRDATA[3];
                Pready_to_bridge = PREADY[3];
            end
            default: begin  // unmapped address — safe open-space terminator
                Prdata_to_bridge = 32'h0;
                Pready_to_bridge = 1'b1;  // PREADY=1 prevents bus deadlock
            end
        endcase
    end

endmodule
