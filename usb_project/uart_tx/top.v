module top (
    input clk;
    input btn1;
    output reg uart_tx;
);

parameter STATE_IDLE    = 2'b00;
parameter STATE_START   = 2'b01;
parameter STATE_DATA    = 2'b10;
parameter STATE_STOP    = 2'b11;

reg [1:0] current_state = STATE_IDLE;
reg [7:0] baud_counter = 0;
reg [2:0] bit_index = 0;

initial uart_tx = 1'b1;

always @(posedge clk) begin
    case (current_state)
        STATE_IDLE: begin
            if (btn1 == 1'b0) begin
                current_state <= STATE_START;
        end

        STATE_START: begin
            
        end
    endcase
end

endmodule