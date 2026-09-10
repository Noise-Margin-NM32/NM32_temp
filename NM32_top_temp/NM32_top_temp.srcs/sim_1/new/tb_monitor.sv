module tb_monitor(input clk, input [3:0] spi_csn, input spi_clk, input [31:0] spi_status, input [3:0] spi_state);
    initial begin
        $monitor("Time=%0t spi_csn=%b spi_clk=%b spi_status=%h state=%h", $time, spi_csn, spi_clk, spi_status, spi_state);
    end
endmodule
