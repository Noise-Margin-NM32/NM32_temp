`timescale 1ns/1ps

module dma_tb_simple;

// ── Clocks & Reset 
reg PCLK, HCLK, PRESETN, HRESETN;
initial PCLK = 0; always #5 PCLK = ~PCLK;
initial HCLK = 0; always #5 HCLK = ~HCLK;


// ── DUT ports 
reg         PSEL, PENABLE, PWRITE;
reg  [31:0] PADDR, PWDATA;
wire [31:0] PRDATA;
wire        PREADY;
reg         HGRANT, HREADY;
reg  [31:0] HRDATA;
wire        HBUSREQ;
wire [31:0] HADDR, HWDATA;
wire [1:0]  HTRANS;
wire        HWRITE, irq, check;


// ── DUT 
dma_controller dut (
    .PCLK(PCLK), .HCLK(HCLK),
    .PRESETN(PRESETN), .HRESETN(HRESETN),
    .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
    .PADDR(PADDR), .PWDATA(PWDATA),
    .PRDATA(PRDATA), .PREADY(PREADY),
    .HGRANT(HGRANT), .HBUSREQ(HBUSREQ),
    .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE),
    .HREADY(HREADY), .HRDATA(HRDATA), .HWDATA(HWDATA),
    .irq(irq), .check(check)
);


// ── Memory: 64 words 
// Word 0..7   = SOURCE  (0x000–0x01C)
// Word 32..39 = DEST    (0x080–0x09C)  — all zero before transfer
reg [31:0] mem [0:63];
integer i;

initial begin
    for (i = 0; i < 8;  i = i + 1) mem[i]      = 32'hCAFE_0000 + i;
    for (i = 8; i < 64; i = i + 1) mem[i]       = 32'h0000_0000;
end


// ── AHB slave (the memory model) 
always @(posedge HCLK) begin
    if (HTRANS[1]) begin          // NONSEQ or SEQ
        if (!HWRITE)
            HRDATA <= mem[HADDR[7:2]];   // read
        else
            mem[HADDR[7:2]] <= HWDATA;   // write
    end
    HREADY <= 1'b1;
end


// ── Arbiter: grant after 2 cycles of HBUSREQ 
integer req_cnt;
initial req_cnt = 0;
always @(posedge HCLK) begin
    if (HBUSREQ) begin
        req_cnt <= req_cnt + 1;
        if (req_cnt >= 1) HGRANT <= 1;
    end else begin
        HGRANT  <= 0;
        req_cnt <= 0;
    end
end



// ── APB write task ────────────────────────────────────────────
task apb_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(posedge PCLK); #1;
        PSEL = 1; PWRITE = 1; PADDR = addr; PWDATA = data; PENABLE = 0;
        @(posedge PCLK); #1;
        PENABLE = 1;
        @(posedge PCLK); #1;
        PSEL = 0; PENABLE = 0; PWRITE = 0;
    end
endtask


// ── Print memory contents ─────────────────────────────────────
task print_memory;
    input [31:0] start_word;   // starting word index
    input [31:0] n_words;      // how many words to print
    input [63:0] label;        // just pass a number (0=SRC, 1=DST)
    integer j;
    begin
        if (label == 0)
            $display("  SOURCE memory (words %0d to %0d):", start_word, start_word+n_words-1);
        else
            $display("  DEST   memory (words %0d to %0d):", start_word, start_word+n_words-1);
        for (j = 0; j < n_words; j = j + 1)
            $display("    word[%0d]  addr=0x%03X  value=0x%08X",
                     start_word+j,
                     (start_word+j)*4,
                     mem[start_word+j]);
    end
endtask

// ── MAIN TEST ─────────────────────────────────────────────────
initial begin
    // defaults
    PSEL=0; PENABLE=0; PWRITE=0; PADDR=0; PWDATA=0;
    HGRANT=0; HREADY=1; HRDATA=0;

    // reset
    PRESETN=0; HRESETN=0;
    repeat(4) @(posedge HCLK);
    PRESETN=1; HRESETN=1;
    repeat(2) @(posedge HCLK);

    // ── Print memory BEFORE transfer ──────────────────────────
    $display("\n============================");
    $display("  BEFORE TRANSFER");
    $display("============================");
    print_memory(0,  8, 0);   // source  words 0-7
    $display("");
    print_memory(32, 8, 1);   // dest    words 32-39

    // ── Program DMA ───────────────────────────────────────────
    apb_write(32'h00, 32'h0000_0000);   // SRC_ADDR = 0x000
    apb_write(32'h04, 32'h0000_0080);   // DST_ADDR = 0x080 (word 32)
    apb_write(32'h08, 32'h0000_0008);   // LEN      = 8 words
    apb_write(32'h0C, 32'h0000_0001);   // CTRL: EN=1  → DMA starts

    // ── Wait for IRQ ──────────────────────────────────────────
    @(posedge irq);
    repeat(4) @(posedge HCLK);   // let last write settle

    // ── Print memory AFTER transfer ───────────────────────────
    $display("\n============================");
    $display("  AFTER TRANSFER");
    $display("============================");
    print_memory(0,  8, 0);   // source (should be unchanged)
    $display("");
    print_memory(32, 8, 1);   // dest   (should match source)

    // ── Quick pass/fail ───────────────────────────────────────
    $display("\n============================");
    $display("  VERIFICATION");
    $display("============================");
    for (i = 0; i < 8; i = i + 1) begin
        if (mem[32+i] === mem[i])
            $display("  word[%0d]  PASS  0x%08X", i, mem[32+i]);
        else
            $display("  word[%0d]  FAIL  got=0x%08X  expected=0x%08X",
                     i, mem[32+i], mem[i]);
    end
    $display("============================\n");

    $finish;
end

// ── Watchdog ──────────────────────────────────────────────────
initial begin
    #50000;
    $display("WATCHDOG: timeout!");
    $finish;
end

endmodule



























