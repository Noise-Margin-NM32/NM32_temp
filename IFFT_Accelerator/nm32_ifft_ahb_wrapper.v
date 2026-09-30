//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// Module  : nm32_ifft_ahb_wrapper
// Purpose : AHB slave 5 @ 0x6000_0000 for the 512-point IFFT engine
//           (nm32_ifft_top). Exposes the twiddle RAM and control register on
//           AHB and passes the engine's data-RAM ports straight out to the
//           shared ping-pong RAM (zero-copy - frame data never crosses AHB).
// Clocks  : hclk (system clk); engine reset is active-high (~hresetn).
//
// Register map (offset from BASE_ADDR):
//   0x000-0x7FC  reserved (reads 0; frame data lives in ping_pong_ram)
//   0x800-0xBFC  twiddle RAM, 256 x {cos[31:16], sin[15:0]} Q15.
//                Loaded once by firmware at boot.
//   0xC00        CTRL  write bit0=1 : start (1-cycle pulse)
//                      read  bit1   : DONE (sticky, cleared by next start)
//
// Notes   : ifft_irq = DONE bit (level). ifft_busy is high from start to
//           done. slv_err / slv_running outputs of ahb_slave_wait are unused.
//==========================================================================
`timescale 1ns / 1ps

module nm32_ifft_ahb_wrapper #(
    parameter [31:0] BASE_ADDR = 32'h0000_0000,
    parameter [31:0] ADDR_MASK = 32'h0000_0FFF // 4KB address space
)(
    input  wire        hclk,
    input  wire        hresetn,
    
    // AHB slave bus inputs
    input  wire        slv_hsel,
    input  wire [31:0] slv_haddr,
    input  wire        slv_hwrite,
    input  wire [1:0]  slv_htrans,
    input  wire [2:0]  slv_hsize,
    input  wire [31:0] slv_hwdata,
    input  wire        slv_hready,
    
    // AHB slave outputs
    output wire        slv_hready_out,
    output wire [1:0]  slv_hresp,
    output wire [31:0] slv_hrdata,
    output wire        slv_err,
    
    // Hardware Interrupt to CPU
    output wire        ifft_irq,
    
    // Exposed Shared RAM Interface
    output wire        ram_we_a,
    output wire [8:0]  ram_addr_a,
    output wire [31:0] ram_din_a,
    input  wire [31:0] ram_dout_a,
    
    output wire        ram_we_b,
    output wire [8:0]  ram_addr_b,
    output wire [31:0] ram_din_b,
    input  wire [31:0] ram_dout_b,
    
    // Hardware Status for Arbiter
    output wire        ifft_busy
);

    // -----------------------------------------------------------------------
    // take/ask handshake from ahb_slave_wait
    // -----------------------------------------------------------------------
    wire [31:0] s_wrap_addr;
    wire        s_wrap_take;
    wire [31:0] s_wrap_wdata;
    wire        s_wrap_ask;
    wire        s_wrap_take_ok;
    wire        s_wrap_ask_ok;
    reg  [31:0] s_wrap_rdata;
    
    wire        slv_running;
    
    // -----------------------------------------------------------------------
    // 1. AHB protocol front-end
    // -----------------------------------------------------------------------
    ahb_slave_wait #(
        .NUM_SLV(1),
        .ADDR_LOW(BASE_ADDR),
        .ADDR_HIGH(BASE_ADDR | ADDR_MASK)
    ) ahb_protocol_inst (
        .hresetn(hresetn),
        .hclk(hclk),
        .remap(1'b0),
        
        .slv_hsel(slv_hsel),
        .slv_haddr(slv_haddr),
        .slv_hwrite(slv_hwrite),
        .slv_htrans(slv_htrans),
        .slv_hsize(slv_hsize),
        .slv_hwdata(slv_hwdata),
        .slv_hready(slv_hready),
        
        .slv_hready_out(slv_hready_out),
        .slv_hresp(slv_hresp),
        .slv_hrdata(slv_hrdata),
        .slv_err(slv_err),
        
        // Legacy generator handshake inputs (no effect)
        .mst_running(1'b1),
        .prior_in(1'b1),
        .slv_running(slv_running),
        
        .s_wrap_addr(s_wrap_addr),
        .s_wrap_take(s_wrap_take),
        .s_wrap_wdata(s_wrap_wdata),
        .s_wrap_ask(s_wrap_ask),
        .s_wrap_take_ok(s_wrap_take_ok),
        .s_wrap_ask_ok(s_wrap_ask_ok),
        .s_wrap_rdata(s_wrap_rdata)
    );

    // -----------------------------------------------------------------------
    // Instantiate IFFT Top Module
    // -----------------------------------------------------------------------
    wire clk = hclk;
    wire rst = ~hresetn; // Active-high reset for IFFT module
    
    reg  start;         // 1-cycle start pulse to the engine

    wire tw_we;
    wire [7:0] tw_ext_addr;
    wire [31:0] tw_ext_din;
    wire [31:0] tw_ext_dout;
    
    wire done;
    
    // busy: set by start, cleared by done. Steers the shared ping-pong
    // accelerator port mux in NM32_top.sv.
    reg busy;
    always @(posedge clk or posedge rst) begin
        if (rst) busy <= 0;
        else if (start) busy <= 1;
        else if (done) busy <= 0;
    end
    assign ifft_busy = busy;

    nm32_ifft_top ifft_engine (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ram_we_a(ram_we_a),
        .ram_addr_a(ram_addr_a),
        .ram_din_a(ram_din_a),
        .ram_dout_a(ram_dout_a),
        .ram_we_b(ram_we_b),
        .ram_addr_b(ram_addr_b),
        .ram_din_b(ram_din_b),
        .ram_dout_b(ram_dout_b),
        .tw_we(tw_we),
        .tw_ext_addr(tw_ext_addr),
        .tw_ext_din(tw_ext_din),
        .tw_ext_dout(tw_ext_dout),
        .done(done)
    );

    // -----------------------------------------------------------------------
    // Address Decoding & Glue Logic (Synchronous)
    // -----------------------------------------------------------------------
    // Register map: see file header.
    
    wire [11:0] local_addr = s_wrap_addr[11:0];
    
    wire is_ctrl_reg = (local_addr == 12'hC00);
    wire is_twid_ram = (local_addr >= 12'h800 && local_addr < 12'hC00);
    
    assign tw_ext_addr = local_addr[9:2]; // 256 words
    assign tw_ext_din  = s_wrap_wdata;
    assign tw_we       = (is_twid_ram && s_wrap_take);
    
    // Twiddle RAM reads have 1 cycle of latency -> 1 wait state.
    // CTRL reads and all writes are zero-wait.
    reg read_stall;
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            read_stall <= 1'b0;
        end else begin
            if (s_wrap_ask && is_twid_ram && !read_stall) begin
                read_stall <= 1'b1; // Wait 1 cycle for RAM
            end else if (read_stall) begin
                read_stall <= 1'b0;
            end
        end
    end
    
    assign s_wrap_take_ok = 1'b1;
    assign s_wrap_ask_ok  = (is_twid_ram) ? read_stall : 1'b1;

    // START Pulse Generation & DONE Latching
    reg done_latched;

    // Read Data Mux
    always @(*) begin
        s_wrap_rdata = 32'b0;
        if (is_ctrl_reg) begin
            s_wrap_rdata[1] = done_latched;
            s_wrap_rdata[0] = 1'b0; // start is write-only/auto-clears
        end else if (is_twid_ram) begin
            s_wrap_rdata = tw_ext_dout;
        end
    end
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            start <= 1'b0;
            done_latched <= 1'b0;
        end else begin
            // Start Pulse
            if (is_ctrl_reg && s_wrap_take && s_wrap_wdata[0]) begin
                start <= 1'b1;
            end else begin
                start <= 1'b0;
            end
            
            // Latch Done
            if (start) begin
                done_latched <= 1'b0; // Clear on start
            end else if (done) begin
                done_latched <= 1'b1; // Latch on done pulse
            end
        end
    end
    
    // Drive hardware interrupt out
    assign ifft_irq = done_latched;

endmodule
