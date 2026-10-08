`timescale 1ns/1ps

module tb;

    // Clock & Reset Signals
    reg clk;
    reg rstn;

    // Interfaces
    wire [0:0] rx_ws, rx_sck, sdi;
    wire [0:0] tx_ws, tx_sck, sdo;

    // Loopback unused I2S channels
    assign rx_ws  = tx_ws;
    assign rx_sck = tx_sck;
    assign sdi    = sdo;

    // SPI Master Signals
    wire       spi_clk;
    wire [3:0] spi_csn;
    wire [1:0] spi_mode;
    wire [3:0] spi_sdo;
    wire [3:0] spi_sdi;

    // GPIO Signals
    reg  [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;

    initial gpio_in = 8'h00;

    // Instantiate Flash Model (Loads compiled firmware_flash.hex)
    flash flash_inst (
        .sck(spi_clk),
        .csn(spi_csn[0]),
        .sdo(spi_sdo[0]),
        .sdi(spi_sdi[0])
    );

    assign spi_sdi[3:1] = 3'b000;

    // Device Under Test (DUT)
    nm32_top dut (
        .clk(clk),
        .rstn(rstn),
        .rx_ws(rx_ws),
        .rx_sck(rx_sck),
        .sdi(sdi),
        .tx_ws(tx_ws),
        .tx_sck(tx_sck),
        .sdo(sdo),
        .spi_clk(spi_clk),
        .spi_csn(spi_csn),
        .spi_mode(spi_mode),
        .spi_sdo(spi_sdo),
        .spi_sdi(spi_sdi),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe)
    );

    // 100MHz Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Safety Timeout Sequence (Allows up to 3.0ms for SPI copy + I2S frame delivery)
    initial begin
        rstn = 0;
        #100;
        rstn = 1;
        $display("Time=%0t ns: [SYS] Reset released. SPI Bootloader started...", $time);

        #3000000;
        $display("------------------------------------------------------------------");
        $display(" Time=%0t ns: [TIMEOUT] Test stalled or exceeded execution window!", $time);
        $display(" Final GPIO Output State = 0x%02h", gpio_out);
        $display("------------------------------------------------------------------");
        $finish;
    end

    // Monitor SPI End-of-Transmission events
    reg prev_eot = 0;
    always @(posedge clk) begin
        if (dut.spi_inst.events_o[1] && !prev_eot) begin
            $display("Time=%0t ns: [SPI HARDWARE] SPI Word Read Completed (s_eot pulsed).", $time);
        end
        prev_eot <= dut.spi_inst.events_o[1];
    end

    // INDICATION 1: Monitor CPU Interrupt Vector Jump
    always @(posedge clk) begin
        if (dut.cpu.mem_valid && dut.cpu.mem_ready && (dut.cpu.mem_addr == 32'h00000010)) begin
            $display("==================================================================");
            $display(" Time=%0t ns: [INDICATION 1: IRQ RAISED & VECTOR JUMP] CPU entered vector 0x00000010!", $time);
            $display("==================================================================");
        end
    end

    // INDICATIONS 2 & 3: Monitor GPIO Handshake State Updates
    reg [7:0] prev_gpio = 8'h00;
    always @(posedge clk) begin
        if (gpio_out !== prev_gpio) begin
            $display("Time=%0t ns: [GPIO STATE UPDATE] gpio_out changed: 0x%02h -> 0x%02h", $time, prev_gpio, gpio_out);

            if (gpio_out == 8'h01) begin
                $display("Time=%0t ns: [BOOT COMPLETE] SPI Flash copy completed! Entering main app loop...", $time);
            end
            if (gpio_out == 8'hAA) begin
                $display("Time=%0t ns: [INDICATION 2: IRQ ACKNOWLEDGED] ISR c_irq_handler() executing!", $time);
            end
            if (gpio_out == 8'hBB) begin
                $display("Time=%0t ns: [INDICATION 3: TRANSFER COMPLETED] Audio block copied into FFT Bank!", $time);
            end
            if (gpio_out == 8'hFF) begin
                $display("==================================================================");
                $display(" Time=%0t ns: [TEST PASSED] Full SPI Boot -> I2S IRQ -> FFT Bank Transfer Verified!", $time);
                $display("==================================================================");
                #100;
                $finish;
            end
            prev_gpio <= gpio_out;
        end
    end

    // CPU Trap Watchdog
    always @(posedge clk) begin
        if (dut.cpu.trap) begin
            $display("Time=%0t ns: [FATAL ERROR] CPU Trap asserted! Memory Address=0x%08h", $time, dut.cpu.mem_addr);
            $finish;
        end
    end

endmodule