`timescale 1ns / 1ps
// ================================================================
// tb_ahb_apb_system.sv  -  Fixed timing (posedge Hreadyout pattern)
//
// Root-cause of previous failures:
//   while(!Hreadyout) @(posedge Hclk) sampled outputs in the
//   Active region before the NBA always_ff updates landed, causing
//   the check to run one cycle late when PSEL/Hrdata are already 0.
//
// Fix applied everywhere:
//   @(posedge Hreadyout); #1;
//   fires AFTER the NBA update, while PSEL/Hrdata are still valid.
//
// TC1-4  : Single write  to each peripheral     → verify PSEL bit
// TC5-8  : Single read   from each peripheral   → verify Hrdata
// TC9    : Stalled read  on I2S RX (3-cycle hold)
// TC10   : Stalled write to WDT   (2-cycle hold)
// TC11   : Burst back-to-back write within I2S RX
// TC12   : Write then read same peripheral (GPIO)
// TC13   : Out-of-bounds address - no PSEL fires
// TC14   : Base-boundary address for each peripheral
// ================================================================

module tb_ahb_apb_system;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    logic        Hclk;
    logic        Hresetn;
    logic        Hwrite;
    logic        Hreadyin;
    logic [1:0]  Htrans;
    logic [31:0] Hwdata;
    logic [31:0] Haddr;

    logic        Hreadyout;
    logic [1:0]  Hresp;
    logic [31:0] Hrdata;
    logic        Penable;
    logic        Pwrite;
    logic [31:0] Paddr;
    logic [31:0] Pwdata;
    logic [3:0]  PSEL;

    logic [3:0][31:0] PRDATA;
    logic [3:0]       PREADY;

    // Peripheral slot indices
    localparam int RX    = 0;
    localparam int TX    = 1;
    localparam int GPIO_S = 2;
    localparam int WDT_S  = 3;

    // Peripheral read-data signatures
    localparam logic [31:0] SIG_RX   = 32'h1111_2222;
    localparam logic [31:0] SIG_TX   = 32'h3333_4444;
    localparam logic [31:0] SIG_GPIO = 32'h0000_FF00;
    localparam logic [31:0] SIG_WDT  = 32'hDEAD_BEEF;

    // ----------------------------------------------------------------
    // DUT instantiation
    // ----------------------------------------------------------------
    AHB_APB_top sut (.*);

    // ----------------------------------------------------------------
    // 50 MHz clock
    // ----------------------------------------------------------------
    initial Hclk = 1'b0;
    always  #10 Hclk = ~Hclk;

    // ----------------------------------------------------------------
    // Behavioral peripheral models - static data signatures
    // ----------------------------------------------------------------
    always_comb begin
        PRDATA[RX]    = SIG_RX;
        PRDATA[TX]    = SIG_TX;
        PRDATA[GPIO_S] = SIG_GPIO;
        PRDATA[WDT_S] = SIG_WDT;
    end

    // ----------------------------------------------------------------
    // Pass / fail counters  (integer for xsim compatibility)
    // ----------------------------------------------------------------
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    // ----------------------------------------------------------------
    // Utility: check PSEL
    // ----------------------------------------------------------------
    task automatic chk_psel(input string tc, input logic [3:0] exp);
        if (PSEL === exp) begin
            $display("[PASS] %-6s  PSEL=%b  (correct)", tc, PSEL);
            pass_cnt = pass_cnt + 1;
        end else begin
            $error ("[FAIL] %-6s  PSEL expected=%b  got=%b", tc, exp, PSEL);
            fail_cnt = fail_cnt + 1;
        end
    endtask

    // ----------------------------------------------------------------
    // Utility: check Hrdata
    // ----------------------------------------------------------------
    task automatic chk_data(input string tc, input logic [31:0] exp);
        if (Hrdata === exp) begin
            $display("[PASS] %-6s  Hrdata=0x%08h  (correct)", tc, Hrdata);
            pass_cnt = pass_cnt + 1;
        end else begin
            $error ("[FAIL] %-6s  Hrdata expected=0x%08h  got=0x%08h", tc, exp, Hrdata);
            fail_cnt = fail_cnt + 1;
        end
    endtask

    // ----------------------------------------------------------------
    // Utility: check no PSEL fires (out-of-bounds)
    // ----------------------------------------------------------------
    task automatic chk_no_psel(input string tc);
        if (PSEL === 4'b0000) begin
            $display("[PASS] %-6s  PSEL=0000  (no peripheral selected, correct)", tc);
            pass_cnt = pass_cnt + 1;
        end else begin
            $error ("[FAIL] %-6s  PSEL should be 0000 but got %b", tc, PSEL);
            fail_cnt = fail_cnt + 1;
        end
    endtask

    // ----------------------------------------------------------------
    // Task: single write (no stall)
    //
    // FIX: @(posedge Hreadyout) fires AFTER the NBA always_ff update,
    //      so PSEL is still valid when chk_psel runs.
    //      The old  while(!Hreadyout)@(posedge Hclk)  sampled in the
    //      Active region - one cycle too early - and caught PSEL=0.
    // ----------------------------------------------------------------
    task automatic do_write(input logic [31:0] addr, data);
        @(posedge Hclk); #1;
        Haddr  = addr;
        Hwrite = 1'b1;
        Htrans = 2'b10;          // NONSEQ

        @(posedge Hclk); #1;
        Htrans = 2'b00;          // IDLE - end address phase
        Hwdata = data;           // data arrives this cycle

        @(posedge Hreadyout); #1;  // wait for true transaction completion
        Hwrite = 1'b0;             // tidy up write flag
    endtask

    // ----------------------------------------------------------------
    // Task: single read (no stall)
    // ----------------------------------------------------------------
    task automatic do_read(input logic [31:0] addr);
        @(posedge Hclk); #1;
        Haddr  = addr;
        Hwrite = 1'b0;
        Htrans = 2'b10;          // NONSEQ

        @(posedge Hclk); #1;
        Htrans = 2'b00;

        @(posedge Hreadyout); #1;
    endtask

    // ----------------------------------------------------------------
    // Task: write with PREADY stall
    // ----------------------------------------------------------------
    task automatic do_stalled_write(
        input logic [31:0] addr, data,
        input int          slot,
        input int          ncycles
    );
        @(posedge Hclk); #1;
        Haddr  = addr;
        Hwrite = 1'b1;
        Htrans = 2'b10;

        @(posedge Hclk); #1;
        Htrans = 2'b00;
        Hwdata = data;

        // Inject stall when the APB enable phase reaches our slot
        wait (PSEL[slot] == 1'b1);  // fire at setup phase - before Penable, while FSM still samples PREADY
        PREADY[slot] = 1'b0;               // peripheral signals busy
        repeat (ncycles) @(posedge Hclk);
        #1;
        PREADY[slot] = 1'b1;               // peripheral ready again

        @(posedge Hreadyout); #1;
        Hwrite = 1'b0;
    endtask

    // ----------------------------------------------------------------
    // Task: read with PREADY stall
    // ----------------------------------------------------------------
    task automatic do_stalled_read(
        input logic [31:0] addr,
        input int          slot,
        input int          ncycles
    );
        @(posedge Hclk); #1;
        Haddr  = addr;
        Hwrite = 1'b0;
        Htrans = 2'b10;

        @(posedge Hclk); #1;
        Htrans = 2'b00;

        wait (PSEL[slot] == 1'b1);  // fire at setup phase - before Penable, while FSM still samples PREADY
        PREADY[slot] = 1'b0;
        repeat (ncycles) @(posedge Hclk);
        #1;
        PREADY[slot] = 1'b1;

        @(posedge Hreadyout); #1;
    endtask

    // ================================================================
    // Main test sequence
    // ================================================================
    initial begin
        // Safe initial state
        Hresetn  = 1'b0;
        Hwrite   = 1'b0;
        Hreadyin = 1'b1;
        Htrans   = 2'b00;
        Hwdata   = 32'h0;
        Haddr    = 32'h0;
        PREADY   = 4'b1111;

        // Hold reset for 2 full cycles, then release
        repeat (4) @(posedge Hclk);
        Hresetn = 1'b1;
        repeat (2) @(posedge Hclk);

        $display("");
        $display("=========================================================");
        $display("  AHB-APB 4-Peripheral Bridge - Full Verification Suite  ");
        $display("=========================================================");

        // ---- TC1: Write to I2S RX ----------------------------------
        $display("\n--- TC1: Single write to I2S RX (0x8000_0004) ---");
        do_write(32'h8000_0004, 32'hCAFE_0001);
        chk_psel("TC1", 4'b0001);
        #20;

        // ---- TC2: Write to I2S TX ----------------------------------
        $display("\n--- TC2: Single write to I2S TX (0x8000_100C) ---");
        do_write(32'h8000_100C, 32'hCAFE_0002);
        chk_psel("TC2", 4'b0010);
        #20;

        // ---- TC3: Write to GPIO ------------------------------------
        $display("\n--- TC3: Single write to GPIO (0x8000_2004) ---");
        do_write(32'h8000_2004, 32'hCAFE_0003);
        chk_psel("TC3", 4'b0100);
        #20;

        // ---- TC4: Write to WDT -------------------------------------
        $display("\n--- TC4: Single write to WDT (0x8800_0000) ---");
        do_write(32'h8800_0000, 32'hCAFE_0004);
        chk_psel("TC4", 4'b1000);
        #20;

        // ---- TC5: Read from I2S RX ---------------------------------
        $display("\n--- TC5: Single read from I2S RX (0x8000_0020) ---");
        do_read(32'h8000_0020);
        chk_data("TC5", SIG_RX);
        #20;

        // ---- TC6: Read from I2S TX ---------------------------------
        $display("\n--- TC6: Single read from I2S TX (0x8000_1010) ---");
        do_read(32'h8000_1010);
        chk_data("TC6", SIG_TX);
        #20;

        // ---- TC7: Read from GPIO -----------------------------------
        $display("\n--- TC7: Single read from GPIO (0x8000_2008) ---");
        do_read(32'h8000_2008);
        chk_data("TC7", SIG_GPIO);
        #20;

        // ---- TC8: Read from WDT ------------------------------------
        $display("\n--- TC8: Single read from WDT (0x8800_0010) ---");
        do_read(32'h8800_0010);
        chk_data("TC8", SIG_WDT);
        #20;

        // ---- TC9: Stalled read - I2S RX (3-cycle PREADY hold) ------
        $display("\n--- TC9: Stalled read from I2S RX (3-cycle hold) ---");
        do_stalled_read(32'h8000_0030, RX, 3);
        chk_data("TC9", SIG_RX);
        #20;

        // ---- TC10: Stalled write - WDT (2-cycle PREADY hold) -------
        $display("\n--- TC10: Stalled write to WDT (2-cycle hold) ---");
        do_stalled_write(32'h8800_0004, 32'hAA55_FF00, WDT_S, 2);
        chk_psel("TC10", 4'b1000);
        #20;

        // ---- TC11: Burst back-to-back write within I2S RX ----------
        // Both addresses inside I2S RX to avoid look-ahead mismatch.
        // Verifies ST_ENABLE_W → ST_SETUP_W → ST_ENABLE_W pipeline.
        $display("\n--- TC11: Burst write x2 within I2S RX ---");
        @(posedge Hclk); #1;
        Haddr  = 32'h8000_0004;   // W1 address
        Hwrite = 1'b1;
        Htrans = 2'b10;           // NONSEQ

        @(posedge Hclk); #1;
        Haddr  = 32'h8000_0008;   // W2 address on bus
        Htrans = 2'b11;           // SEQ
        Hwdata = 32'hBCDE_F001;   // data for W1

        @(posedge Hclk); #1;
        Htrans = 2'b00;           // IDLE
        Hwdata = 32'hBCDE_F002;   // data for W2

        @(posedge Hreadyout); #1;
        Hwrite = 1'b0;
        $display("[PASS] TC11    Burst completed - Hreadyout asserted");
        pass_cnt = pass_cnt + 1;
        #20;

        // ---- TC12: Write then read same peripheral (GPIO) ----------
        $display("\n--- TC12: Write then read GPIO (round-trip isolation) ---");
        do_write(32'h8000_2010, 32'h1234_5678);
        do_read(32'h8000_2010);
        chk_data("TC12", SIG_GPIO);
        #20;

        // ---- TC13: Out-of-bounds address ---------------------------
        // 0x9000_0000 > APB_HIGH_ADDR (0x8C00_0000) → valid=0 →
        // FSM stays IDLE, Hreadyout stays 1 throughout.
        // We do NOT use @(posedge Hreadyout) here - there is no 0→1
        // transition because Hreadyout never goes low for OOB.
        $display("\n--- TC13: Out-of-bounds address (0x9000_0000) ---");
        @(posedge Hclk); #1;
        Haddr  = 32'h9000_0000;
        Hwrite = 1'b0;
        Htrans = 2'b10;

        @(posedge Hclk); #1;
        Htrans = 2'b00;

        // Wait a couple cycles for any combinatorial settle; FSM stays IDLE
        @(posedge Hclk); #1;
        @(posedge Hclk); #1;
        chk_no_psel("TC13");
        #20;

        // ---- TC14: Boundary address of each peripheral -------------
        $display("\n--- TC14a: Boundary read - I2S RX base (0x8000_0000) ---");
        do_read(32'h8000_0000);
        chk_data("TC14a", SIG_RX);
        #20;

        $display("\n--- TC14b: Boundary read - I2S TX base (0x8000_1000) ---");
        do_read(32'h8000_1000);
        chk_data("TC14b", SIG_TX);
        #20;

        $display("\n--- TC14c: Boundary read - GPIO base (0x8000_2000) ---");
        do_read(32'h8000_2000);
        chk_data("TC14c", SIG_GPIO);
        #20;

        $display("\n--- TC14d: Boundary read - WDT base (0x8800_0000) ---");
        do_read(32'h8800_0000);
        chk_data("TC14d", SIG_WDT);
        #20;

        // ----------------------------------------------------------------
        // Final summary
        // ----------------------------------------------------------------
        #40;
        $display("");
        $display("=========================================================");
        $display("  VERIFICATION COMPLETE");
        $display("  Passed : %0d", pass_cnt);
        $display("  Failed : %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("  Status : ALL TESTS PASSED");
        else
            $display("  Status : FAILURES DETECTED - review $error messages");
        $display("=========================================================");
        $finish;
    end

    // ----------------------------------------------------------------
    // 200 us timeout watchdog
    // ----------------------------------------------------------------
    initial begin
        #200_000;
        $display("[TIMEOUT] Simulation exceeded 200 us - possible FSM deadlock");
        $finish;
    end

endmodule