`timescale 1ns/1ps

module EF_GPIO8_APB_tb;

    //-----------------------------------------
    // APB Signals
    //-----------------------------------------

    reg         PCLK;
    reg         PRESETn;

    reg         PWRITE;
    reg [31:0]  PWDATA;
    reg [31:0]  PADDR;
    reg         PENABLE;
    reg         PSEL;

    wire [31:0] PRDATA;
    wire        PREADY;
    wire        IRQ;

    //-----------------------------------------
    // GPIO Signals
    //-----------------------------------------

    reg  [7:0] io_in;
    wire [7:0] io_out;
    wire [7:0] io_oe;

    //-----------------------------------------
    // DUT
    //-----------------------------------------

    EF_GPIO8_APB dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PADDR(PADDR),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PREADY(PREADY),
        .PRDATA(PRDATA),
        .IRQ(IRQ),
        .io_in(io_in),
        .io_out(io_out),
        .io_oe(io_oe)
    );

    //-----------------------------------------
    // Address Map
    //-----------------------------------------

    localparam DATAI = 32'h0000;
    localparam DATAO = 32'h0004;
    localparam DIR   = 32'h0008;

    localparam IM    = 32'hFF00;
    localparam MIS   = 32'hFF04;
    localparam RIS   = 32'hFF08;
    localparam IC    = 32'hFF0C;
    localparam GCLK  = 32'hFF10;

    //-----------------------------------------
    // Clock
    //-----------------------------------------

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    //-----------------------------------------
    // APB WRITE
    //-----------------------------------------

    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin

            @(posedge PCLK);

            PADDR   <= addr;
            PWDATA  <= data;
            PWRITE  <= 1'b1;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;

            @(posedge PCLK);

            PENABLE <= 1'b1;

            @(posedge PCLK);

            PSEL    <= 0;
            PENABLE <= 0;
            PWRITE  <= 0;

        end
    endtask

    //-----------------------------------------
    // APB READ
    //-----------------------------------------

    task apb_read;
        input  [31:0] addr;
        output [31:0] data;

        begin

            @(posedge PCLK);

            PADDR   <= addr;
            PWRITE  <= 0;
            PSEL    <= 1;
            PENABLE <= 0;

            @(posedge PCLK);

            PENABLE <= 1;

            @(posedge PCLK);

            data = PRDATA;

            PSEL    <= 0;
            PENABLE <= 0;

        end
    endtask

    //-----------------------------------------
    // Test Variables
    //-----------------------------------------

    reg [31:0] rdata;

    //-----------------------------------------
    // Main Test
    //-----------------------------------------

    initial begin

        //-------------------------------------
        // Init
        //-------------------------------------

        PADDR   = 0;
        PWDATA  = 0;
        PWRITE  = 0;
        PSEL    = 0;
        PENABLE = 0;
        io_in   = 0;

        //-------------------------------------
        // Reset
        //-------------------------------------

        PRESETn = 0;

        repeat(5) @(posedge PCLK);

        PRESETn = 1;

        $display("RESET RELEASED");

        //-------------------------------------
        // Enable GPIO Clock
        //-------------------------------------

        apb_write(GCLK,32'h1);

        $display("GPIO CLOCK ENABLED");

        //-------------------------------------
        // TEST 1
        // Direction Register
        //-------------------------------------

        apb_write(DIR,32'hFF);

        apb_read(DIR,rdata);

        if(rdata[7:0] == 8'hFF)
            $display("PASS DIR");
        else
            $display("FAIL DIR");

        //-------------------------------------
        // TEST 2
        // Output Register
        //-------------------------------------

        apb_write(DATAO,32'hAA);

        #20;

        if(io_out == 8'hAA)
            $display("PASS DATAO");
        else
            $display("FAIL DATAO");

        //-------------------------------------
        // TEST 3
        // Input Read
        //-------------------------------------

        apb_write(DIR,32'h00);

        io_in = 8'h5A;

        #20;

        apb_read(DATAI,rdata);

        if(rdata[7:0] == 8'h5A)
            $display("PASS DATAI");
        else
            $display("FAIL DATAI");

        //-------------------------------------
        // TEST 4
        // Interrupt
        //-------------------------------------

        apb_write(IM,32'h00000001);

        io_in[0] = 0;

        #20;

        io_in[0] = 1;

        #50;

        apb_read(RIS,rdata);

        $display("RIS = %h",rdata);

        if(IRQ)
            $display("PASS IRQ");
        else
            $display("FAIL IRQ");

        //-------------------------------------
        // TEST 5
        // Interrupt Clear
        //-------------------------------------

        apb_write(IC,32'h1);

        #20;

        if(!IRQ)
            $display("PASS IC");
        else
            $display("FAIL IC");

        //-------------------------------------
        // Finish
        //-------------------------------------

        #100;

        $display("--------------------------------");
        $display("GPIO APB TEST COMPLETED");
        $display("--------------------------------");

        $finish;

    end

endmodule