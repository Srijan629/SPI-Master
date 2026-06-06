`timescale 1ns / 1ps

module spi_master_tb;

    // Testbench Drivers
    reg        clk;
    reg        rst_n;
    reg        start;
    reg  [7:0] tx_data;
    reg        spi_miso;

    // Monitors
    wire [7:0] rx_data;
    wire       ready;
    wire       spi_sclk;
    wire       spi_mosi;
    wire       spi_cs_n;

    // Instantiate Unit Under Test (UUT)
    spi_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ready(ready),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );

    // 100MHz System Clock Generation
    always #5 clk = ~clk;

    // Emulate an external SPI Slave loopback response (Slave echo data pattern)
    always @(negedge spi_sclk) begin
        if (!spi_cs_n)
            spi_miso = spi_mosi; // Loopback MOSI bits straight into MISO line
        else
            spi_miso = 0;
    end

    initial begin
        // System Initialization
        clk      = 0;
        rst_n    = 0;
        start    = 0;
        tx_data  = 8'h00;
        #20;
        
        // Release System Reset
        rst_n = 1;
        #20;

        // Execute SPI Transaction 1: Send Hex Pattern 0xA5
        @(posedge clk);
        if (ready) begin
            start   = 1;
            tx_data = 8'hA5; // Data pattern: 10100101
        end
        @(posedge clk);
        start = 0; // Turn off start pulse immediately
        
        // Wait for full serialization loop execution to conclude
        @(posedge ready);
        #40;

        // Execute SPI Transaction 2: Send Hex Pattern 0x3C
        @(posedge clk);
        if (ready) begin
            start   = 1;
            tx_data = 8'h3C; // Data pattern: 00111100
        end
        @(posedge clk);
        start = 0;
        
        @(posedge ready);
        #40;
        
        $finish;
    end

endmodule