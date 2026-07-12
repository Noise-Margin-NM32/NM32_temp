`timescale 1ns / 1ps

module flash (
    input wire sck,
    input wire csn,
    input wire sdo, // Serial Data Out from SoC Master -> Flash Input
    output reg sdi  // Serial Data In to SoC Master <- Flash Output
);

    // 64KB Flash Memory Array (65,536 bytes)
    reg [31 : 0] flash_mem [0:65535]; 
    
    // Internal registers
    reg [23:0] shift_reg;
    reg [31:0] bit_count;
    reg [7:0]  current_cmd;
    reg [23:0] current_addr;

    // Pre-load the compiled firmware binary hex image at the start of simulation
    initial begin
        $readmemh("./../../../../../firmware/firmware_flash.hex", flash_mem);
    end

    //-------------------------------------------------------------------------
    // Input Logic (SPI Mode 0: Sample on Rising Edge)
    //-------------------------------------------------------------------------
    always @(posedge sck or posedge csn) begin
        if (csn) begin
            bit_count    <= 0;
            current_cmd  <= 0;
            current_addr <= 0;
            shift_reg    <= 0;
        end else begin
            // Shift register tracks history of previous bits
            shift_reg <= {shift_reg[22:0], sdo};
            bit_count <= bit_count + 1;
            
            // Capture Command Byte at Bit 7 
            // Combining previous shifted bits with the live 'sdo' line avoids LSB lag
            if (bit_count == 7) begin
                current_cmd <= {shift_reg[6:0], sdo};
                $display("Time=%0t: [FLASH] Captured Command = 0x%02h", $time, {shift_reg[6:0], sdo});
            end
            
            // Capture 24-bit Address at Bit 31
            if (bit_count == 31) begin
                current_addr <= {shift_reg[22:0], sdo};
                $display("Time=%0t: [FLASH] Captured Address = 0x%06h", $time, {shift_reg[22:0], sdo});
            end
            
            // Auto-increment the internal flash address on every 8-bit byte boundary 
            // after the read transaction has officially commenced
            if (bit_count > 31 && (bit_count[2:0] == 7) && (current_cmd == 8'h03)) begin
                current_addr <= current_addr + 1;
            end
        end
    end

    //-------------------------------------------------------------------------
    // Output Logic (SPI Mode 0: Drive on Falling Edge for Master Setup Window)
    //-------------------------------------------------------------------------
    wire [7:0] current_byte = flash_mem[current_addr[23:2]] >> (current_addr[1:0] * 8);

    always @(negedge sck or posedge csn) begin
        if (csn) begin
            sdi <= 1'bz; // High impedance when Flash is unselected
        end else begin
            // If we have received the full command + address, and it's a standard READ (0x03)
            if (bit_count >= 32 && current_cmd == 8'h03) begin
                // Drive bits out MSB-first out of the currently indexed byte
                // bit_count[2:0] indicates which bit of the *next* byte is being requested
                sdi <= current_byte[7 - bit_count[2:0]];
            end else begin
                sdi <= 1'b0;
            end
        end
    end

endmodule