module pico_to_ahb (
    input  wire        clk,
    input  wire        resetn,

    // ===== Pico native interface =====
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output reg         mem_ready,
    output reg  [31:0] mem_rdata,

    // ===== AHB Master interface =====
    output reg  [31:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    output reg  [2:0]  HSIZE,
    output reg  [31:0] HWDATA,

    input  wire [31:0] HRDATA,
    input  wire        HREADY,
    input  wire        HRESP
);

    // FSM states
    localparam IDLE  = 2'd0;
    localparam ADDR  = 2'd1;
    localparam DATA  = 2'd2;

    reg [1:0] state;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state      <= IDLE;
            HTRANS     <= 2'b00; // IDLE
            mem_ready  <= 0;
        end else begin
            case (state)

            // =========================
            // IDLE: wait for request
            // =========================
            IDLE: begin
                mem_ready <= 0;

                if (mem_valid) begin
                    HADDR  <= mem_addr;
                    HWRITE <= |mem_wstrb;
                    HSIZE  <= 3'b010; // 32-bit
                    HWDATA <= mem_wdata;

                    HTRANS <= 2'b10; // NONSEQ
                    state  <= ADDR;
                end
            end

            // =========================
            // ADDR phase
            // =========================
            ADDR: begin
                if (HREADY) begin
                    HTRANS <= 2'b00; // IDLE next
                    state  <= DATA;
                end
            end

            // =========================
            // DATA phase
            // =========================
            DATA: begin
                if (HREADY) begin
                    mem_ready <= 1;
                    mem_rdata <= HRDATA;
                    state <= IDLE;
                end
            end

            endcase
        end
    end

endmodule
