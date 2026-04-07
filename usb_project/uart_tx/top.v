module top (
    input clk,
    input btn1,
    output reg uart_tx
);

parameter STATE_IDLE    = 3'b000;
parameter STATE_START   = 3'b001;
parameter STATE_DATA    = 3'b010;
parameter STATE_STOP    = 3'b011;
parameter STATE_WAIT    = 3'b100;

reg [2:0] current_state = STATE_IDLE;
reg [7:0] baud_counter = 0;
reg [4:0] bit_index = 0;
reg [7:0] tx_data = 8'h41;

initial uart_tx <= 1'b1;

always @(posedge clk) begin
    case (current_state)
        STATE_IDLE: begin
            uart_tx <= 1'b1;
            baud_counter <= 0;
            bit_index <= 0;
            if (btn1 == 1'b0) begin
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
                    uart_tx <= tx_data[bit_index];
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
            if (btn1 == 1'b1) begin
                current_state <= STATE_IDLE;
            end
        end
    endcase
end

endmodule