`timescale 1ns / 1ps

module boot_rom_ahb (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire        HREADY,
    
    output wire        HREADYOUT,
    output wire  [31:0] HRDATA,
    output wire [1:0]  HRESP
);

    // 4KB Memory Array (1024 words x 32 bits)
    reg [31:0] memory [0:1023];

    // This is where the magic happens! The simulator loads your compiled code here.
    initial begin
        $readmemh("/home/omkar/SoC_0.1/firmware/firmware.hex", memory);
    end

    // --- AHB Address Phase ---
    reg read_en;
    //reg [31:0] latched_addr;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            read_en      <= 1'b0;
            latched_addr <= 32'b0;
        end else if (HREADY && HSEL && (HTRANS == 2'b10 || HTRANS == 2'b11) && !HWRITE) begin
            // A valid read request was sent to the ROM
            read_en      <= 1'b1;
            latched_addr <= HADDR;
        end else if (HREADY) begin
            read_en      <= 1'b0;
        end
    end

    // // --- AHB Data Phase ---
    // always @(posedge HCLK) begin
    //     if (read_en) begin
    //         // Shift the address down by 2 (divide by 4) to convert byte-address to word-index
    //         HRDATA <= memory[latched_addr[11:2]];
    //     end
    // end

    // // --- AHB Data Phase (Combinational) ---
    // // The moment latched_addr updates on the clock edge, the memory array 
    // // is instantly indexed, guaranteeing HRDATA is valid for the CPU to read!
    // assign HRDATA = read_en ? memory[latched_addr[11:2]] : 32'h00000000;

    // --- AHB Address Latch ---
    reg [31:0] latched_addr;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            latched_addr <= 32'b0;
        end else if (HREADY && HSEL) begin
            // Only update the address when the CPU specifically talks to the ROM
            latched_addr <= HADDR;
        end
    end

    // --- AHB Data Output ---
    // Instantly output the memory at the latched address. 
    // Because we never clear this to zero, the data stays perfectly stable 
    // on the bus, no matter how long the CPU wrapper takes to read it!
    assign HRDATA = memory[latched_addr[11:2]];

    // assign HREADYOUT = 1'b1; 
    // assign HRESP     = 2'b00;


    // ROM is always instantly ready and always returns OKAY (00)
    assign HREADYOUT = 1'b1; 
    assign HRESP     = 2'b00;

endmodule