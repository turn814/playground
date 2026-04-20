module uart_rx (
    input clk,
    input rx,
    output reg [7:0] data,
    output reg ready
);

parameter STATE_IDLE       = 3'b000;
parameter STATE_START      = 3'b001;
parameter STATE_DATA       = 3'b010;
parameter STATE_STOP       = 3'b011;

reg rx_sync_0;
reg rx_sync_1;

reg [2:0] rx_state = STATE_IDLE;
reg [7:0] rx_baud_counter = 0;
reg [4:0] rx_bit_index = 0;
initial   ready = 0;

always @(posedge clk) begin
    // Synchronize the asynchronous rx signal to the clock domain
    rx_sync_0 <= rx;
    rx_sync_1 <= rx_sync_0;
    case (rx_state)
        STATE_IDLE: begin
            ready <= 0;
            rx_baud_counter <= 0;
            rx_bit_index <= 0;
            if (rx_sync_1 == 0) begin
                data <= 0;
                rx_state <= STATE_START;
            end
        end

        STATE_START: begin
            if (rx_baud_counter < 52) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                rx_baud_counter <= 0;
                rx_state <= STATE_DATA;
            end
        end

        STATE_DATA: begin
            if (rx_baud_counter < 104) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                rx_baud_counter <= 0;
                if (rx_bit_index < 8) begin
                    data[rx_bit_index] <= rx;
                    rx_bit_index <= rx_bit_index + 1;
                end else begin
                    rx_baud_counter <= 0;
                    rx_bit_index <= 0;
                    rx_state <= STATE_STOP;
                end
            end
        end

        STATE_STOP: begin
            if (rx_baud_counter < 104) begin
                rx_baud_counter <= rx_baud_counter + 1;
            end else begin
                ready <= 1;
                rx_state <= STATE_IDLE;
            end
        end
    endcase
end

endmodule