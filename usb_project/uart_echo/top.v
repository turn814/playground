module top (
    input clk,
    output reg uart_tx,
    input uart_rx
);

parameter STATE_IDLE    = 3'b000;
parameter STATE_START   = 3'b001;
parameter STATE_DATA    = 3'b010;
parameter STATE_STOP    = 3'b011;
parameter STATE_WAIT    = 3'b100;

parameter RX_IDLE       = 3'b000;
parameter RX_START      = 3'b001;
parameter RX_DATA       = 3'b010;
parameter RX_STOP       = 3'b011;

reg [2:0] current_state = STATE_IDLE;
reg [7:0] baud_counter = 0;
reg [4:0] bit_index = 0;

reg [2:0] rx_state = RX_IDLE;
reg [7:0] rx_baud_counter = 0;
reg [4:0] rx_bit_index = 0;
reg [7:0] rx_data_buffer = 0;
reg       rx_ready = 0;

reg [7:0] tx_data [0:4];
initial begin
    tx_data[0] = 8'h48;
    tx_data[1] = 8'h45;
    tx_data[2] = 8'h4C;
    tx_data[3] = 8'h4C;
    tx_data[4] = 8'h4F;
end

initial uart_tx = 1'b1;

always @(posedge clk) begin
    case (rx_state)
        RX_IDLE: begin
            rx_ready <= 0;
            rx_baud_counter <= 0;
            rx_bit_index <= 0;
            if (uart_rx == 0) begin
                rx_state <= RX_START;
            end
        end

        RX_START: begin
            if (rx_baud_counter < 52) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                rx_baud_counter <= 0;
                rx_state <= RX_DATA;
            end
        end

        RX_DATA: begin
            if (rx_baud_counter < 104) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                rx_baud_counter <= 0;
                if (rx_bit_index < 8) begin
                    rx_data_buffer[rx_bit_index] <= uart_rx;
                    rx_bit_index <= rx_bit_index + 1;
                end else begin
                    rx_baud_counter <= 0;
                    rx_bit_index <= 0;
                    rx_state <= RX_STOP;
                end
            end
        end

        RX_STOP: begin
            if (rx_baud_counter < 104) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                rx_ready <= 1;
                rx_state <= RX_IDLE;
            end
        end
    endcase
end

always @(posedge clk) begin
    case (current_state)
        STATE_IDLE: begin
            uart_tx <= 1'b1;
            baud_counter <= 0;
            bit_index <= 0;
            if (rx_ready == 1) begin
                current_state <= STATE_START;
            end
        end

        STATE_START: begin
            uart_tx <= 1'b0;
            if (baud_counter < 104) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                current_state <= STATE_DATA;
            end
        end

        STATE_DATA: begin
            if (bit_index < 8) begin
                if (baud_counter < 104) begin
                    uart_tx <= rx_data_buffer[bit_index];
                    baud_counter <= baud_counter + 1;
                end else begin
                    bit_index <= bit_index + 1;
                    baud_counter <= 0;
                end
            end else begin
                baud_counter <= 0;
                bit_index <= 0;
                current_state <= STATE_STOP;
            end
        end

        STATE_STOP: begin
            uart_tx <= 1'b1;
            if (baud_counter < 104) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                current_state <= STATE_WAIT;
            end
        end

        STATE_WAIT: begin
            uart_tx <= 1'b1;
            if (rx_ready == 0) begin
                current_state <= STATE_IDLE;
            end
        end
    endcase
end

endmodule