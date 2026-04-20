module uart_tx(
    input clk,
    input [7:0] data,
    input start,
    output reg tx,
    output reg busy
);

parameter STATE_IDLE    = 3'b000;
parameter STATE_START   = 3'b001;
parameter STATE_DATA    = 3'b010;
parameter STATE_STOP    = 3'b011;
parameter STATE_WAIT    = 3'b100;

reg [2:0] current_state = STATE_IDLE;
reg [7:0] baud_counter = 0;
reg [4:0] bit_index = 0;

always @(posedge clk) begin
    case (current_state)
        STATE_IDLE: begin
            tx <= 1'b1;
            baud_counter <= 0;
            bit_index <= 0;
            busy <= 0;
            if (start == 1) begin
                busy <= 1;
                current_state <= STATE_START;
            end
        end

        STATE_START: begin
            tx <= 1'b0;
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
                    tx <= data[bit_index];
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
            tx <= 1'b1;
            if (baud_counter < 104) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                current_state <= STATE_WAIT;
            end
        end

        STATE_WAIT: begin
            tx <= 1'b1;
            if (start == 0) begin
                current_state <= STATE_IDLE;
            end
        end
    endcase
end

endmodule