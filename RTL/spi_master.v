// Module: spi_master
// Description: SPI Master Controller (CPOL=0, CPHA=0 Mode)
module spi_master (
    input  wire       clk,          // System clock
    input  wire       rst_n,        // Active-low reset
    input  wire       start,        // Kick-start pulse to trigger transfer
    input  wire [7:0] tx_data,      // 8-bit data byte to transmit
    output reg  [7:0] rx_data,      // 8-bit data byte received
    output reg        ready,        // High when master is idle and ready
    
    // SPI Physical Bus Interface
    output reg        spi_sclk,     // Serial Clock output to slave
    output reg        spi_mosi,     // Master Out Slave In pin
    input  wire       spi_miso,     // Master In Slave Out pin
    output reg        spi_cs_n      // Chip Select line (Active Low)
);

    // FSM State Encoding
    localparam STATE_IDLE     = 2'b00;
    localparam STATE_TRANSFER = 2'b01;
    localparam STATE_DONE     = 2'b10;

    reg [1:0] current_state, next_state;
    reg [2:0] bit_cnt;              // Counter to track 0-7 bits
    reg [3:0] clk_div;              // Internal counter to divide system clock for SCLK
    reg [7:0] shift_reg_tx;         // Internal parallel-to-serial register
    reg [7:0] shift_reg_rx;         // Internal serial-to-parallel register
    
    wire sclk_edge;                 // Signal indicating internal clock tick

    // Simple Clock Divider for SCLK generation (System Clock / 8)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 0;
        else if (current_state == STATE_TRANSFER)
            clk_div <= clk_div + 1;
        else
            clk_div <= 0;
    end
    
    assign sclk_edge = (clk_div == 4'd7); // Triggers edge on toggle rollover

    // FSM State Transition Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    // Next State Combinational Logic
    always @(*) begin
        case (current_state)
            STATE_IDLE:     next_state = start ? STATE_TRANSFER : STATE_IDLE;
            STATE_TRANSFER: next_state = (bit_cnt == 3'd7 && sclk_edge) ? STATE_DONE : STATE_TRANSFER;
            STATE_DONE:     next_state = STATE_IDLE;
            default:        next_state = STATE_IDLE;
        endcase
    end

    // Control and Data Shift Datapath Block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt      <= 0;
            shift_reg_tx <= 0;
            shift_reg_rx <= 0;
            rx_data      <= 0;
            ready        <= 1;
            spi_sclk     <= 0;
            spi_mosi     <= 0;
            spi_cs_n     <= 1;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    ready    <= 1;
                    spi_cs_n <= 1;
                    spi_sclk <= 0;
                    spi_mosi <= 0;
                    bit_cnt  <= 0;
                    if (start) begin
                        shift_reg_tx <= tx_data;
                        spi_cs_n     <= 0;
                        ready        <= 0;
                    end
                end

                STATE_TRANSFER: begin
                    // Toggle SCLK based on internal divided clock tick
                    if (clk_div >= 4'd4) 
                        spi_sclk <= 1;
                    else 
                        spi_sclk <= 0;

                    // Drive data bit out on MOSI (MSB First)
                    spi_mosi <= shift_reg_tx[7];

                    // Sample MISO and shift out tx bits on clock dividers edge boundaries
                    if (sclk_edge) begin
                        shift_reg_rx <= {shift_reg_rx[6:0], spi_miso};
                        shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                        bit_cnt      <= bit_cnt + 1;
                    end
                end

                STATE_DONE: begin
                    rx_data  <= shift_reg_rx;
                    ready    <= 1;
                    spi_cs_n <= 1;
                    spi_mosi <= 0;
                    spi_sclk <= 0;
                end
            endcase
        end
    end

endmodule