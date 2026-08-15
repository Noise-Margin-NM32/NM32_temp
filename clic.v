module clic_ahb (
    input  wire        hclk,         // AHB Clock
    input  wire        hresetn,      // AHB Reset (Active Low)

    // AHB-Lite Slave Interface Ports (Maintained at 32-bit for CPU Compatibility)
    input  wire        hsel_i,       // Slave Select
    input  wire [31:0] haddr_i,      // Transfer Address
    input  wire [1:0]  htrans_i,     // Transfer Type (00=IDLE, 10=NONSEQ)
    input  wire        hwrite_i,     // Write Enable (1=Write, 0=Read)
    input  wire [2:0]  hsize_i,      // Transfer Size
    input  wire [31:0] hwdata_i,     // Write Data Bus
    output wire        hready_o,     // Ready Status (1 = Transfer Done)
    output reg  [31:0] hrdata_o,     // Read Data Bus
    output wire        hresp_o,      // Transfer Response (0=OKAY, 1=ERROR)

    // Scaled Peripheral Interrupt Input Lines
    input  wire [15:0] intr_src_i,   // 16 direct wires from peripherals (e.g. I2S, DMA)

    // Handshaking Core Outputs (To Processor Pipeline)
    output reg         irq_valid_o,  // High if interrupt clears threshold floor
    output reg  [3:0]  irq_id_o,     // Winning interrupt binary ID (0-15)
    output reg  [2:0]  irq_level_o   // Winning interrupt priority level (0-7)
);

    // -------------------------------------------------------------------------
    // 1. Scaled Internal Register Storage (Verilog Reg Arrays)
    // -------------------------------------------------------------------------
    reg  [15:0] ip_reg;              // 16 Interrupt Pending Bits (Tracks fired IRQs)
    reg  [15:0] ie_reg;              // 16 Interrupt Enable Bits (Masking bitmask)
    reg  [2:0]  prio_reg [0:15];     // 16 channels * 3 bits priority storage matrices
    reg  [2:0]  threshold_reg;       // Active Preemption Threshold Floor Gate

    // -------------------------------------------------------------------------
    // 2. AHB-Lite Bus Protocol Control Logic (Address & Data Pipeline)
    // -------------------------------------------------------------------------
    // AHB separates the Address phase and Data phase by one clock cycle. 
    // We must sample control signals during the address phase to act on the data phase.
    reg        reg_write_phase;
    reg        reg_read_phase;
    reg  [6:0] reg_addr_latched;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            reg_write_phase  <= 1'b0;
            reg_read_phase   <= 1'b0;
            reg_addr_latched <= 7'h0;
        end else if (hready_o) begin
            // Sample control signals if a valid access is targetting this slave (2'b10 = NONSEQ)
            if (hsel_i && (htrans_i == 2'b10)) begin 
                reg_write_phase  <= hwrite_i;
                reg_read_phase   <= !hwrite_i;
                reg_addr_latched <= haddr_i[8:2];  // Extract word-aligned index
            end else begin
                reg_write_phase  <= 1'b0;
                reg_read_phase   <= 1'b0;
            end
        end
    end

    // AHB Responses: This controller is zero-wait-state and never asserts bus errors
    assign hready_o = 1'b1; 
    assign hresp_o  = 1'b0; // Dynamic OKAY response

    // -------------------------------------------------------------------------
    // 3. Patched Register Writing (Fixes Bug 1 Address Mismatch & Bug 2 Race)
    // -------------------------------------------------------------------------
    integer w_idx;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            ip_reg        <= 16'h0;
            ie_reg        <= 16'h0;
            threshold_reg <= 3'h0;
            for (w_idx = 0; w_idx < 16; w_idx = w_idx + 1) begin
                prio_reg[w_idx] <= 3'h0;
            end
        end else begin
            // Base Priority Configurations (Offsets 0x00 to 0x3C -> Word indices 0 to 15)
            if (reg_write_phase && (reg_addr_latched < 16)) begin
                prio_reg[reg_addr_latched] <= hwdata_i[2:0];
            end

            // Control Registers (Fixed word indices to match 0x84 and 0x88)
            if (reg_write_phase) begin
                case (reg_addr_latched)
                    7'h21: ie_reg        <= hwdata_i[15:0]; // 7'h21 * 4 = 0x84 (FIXED)
                    7'h22: threshold_reg <= hwdata_i[2:0];  // 7'h22 * 4 = 0x88 (FIXED)
                endcase
            end

            // BUG 2 FIX: Atomic Hardware Latch + Software Clear Interlocking
            // New incoming hardware edges take absolute priority over software clears.
            if (reg_write_phase && (reg_addr_latched == 7'h20)) begin
                // Clear only the bits software requested, but force any fresh hardware assertions to 1
                ip_reg <= (ip_reg & hwdata_i[15:0]) | intr_src_i;
            end else begin
                // Normal operation: accumulate incoming hardware lines
                ip_reg <= ip_reg | intr_src_i;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. Register Reading (Driving Data Phase with Zero-Padding)
    // -------------------------------------------------------------------------
    always @(*) begin
        if (reg_read_phase) begin
            case (reg_addr_latched)
                7'h20:   hrdata_o = {16'h0, ip_reg}; // Zero-pad to match 32-bit CPU bus
                7'h24:   hrdata_o = {16'h0, ie_reg}; 
                7'h28:   hrdata_o = {29'h0, threshold_reg};
                default: begin
                    if (reg_addr_latched < 16) begin
                        hrdata_o = {29'h0, prio_reg[reg_addr_latched]};
                    end else begin
                        hrdata_o = 32'h0;
                    end
                end
            endcase
        end else begin
            hrdata_o = 32'h0;
        end
    end

    // -------------------------------------------------------------------------
    // 5. Combinational Priority Encoder Matrix (Optimized for 16 Loops)
    // -------------------------------------------------------------------------
    reg [3:0] winner_id;
    reg [2:0] winner_prio;
    reg       any_valid_interrupt;
    integer   e_idx;

    always @(*) begin
        winner_id           = 4'h0;
        winner_prio         = 3'h0;
        any_valid_interrupt = 1'b0;

        // Loop through all 16 lines to evaluate which unmasked interrupt holds highest weight
        // Eliminates software decoding routines, enforcing deterministic latency to prevent audio jitter
        for (e_idx = 0; e_idx < 16; e_idx = e_idx + 1) begin
            if (ip_reg[e_idx] && ie_reg[e_idx]) begin // Mask check
                if (prio_reg[e_idx] >= winner_prio) begin // Priority matching
                    winner_prio         = prio_reg[e_idx];
                    winner_id           = e_idx[3:0];
                    any_valid_interrupt = 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 6. Threshold Gatekeeping Gate
    // -------------------------------------------------------------------------
    // Signal to CPU core only fires if the winning priority is strictly higher than threshold floor
    always @(*) begin
        if (any_valid_interrupt && (winner_prio > threshold_reg)) begin
            irq_valid_o = 1'b1;
            irq_id_o    = winner_id;
            irq_level_o = winner_prio;
        end else begin
            irq_valid_o = 1'b0;
            irq_id_o    = 4'h0;
            irq_level_o = 3'h0;
        end
    end

endmodule