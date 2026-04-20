module top (
    input clk,
    input rx_line,
    output tx_line,
    output rts,
    output dbg_empty,
    output dbg_read_ptr_0,  // debug
    output dbg_read_ptr_1,  // debug
    output dbg_read_ptr_2,  // debug
    output dbg_read_ptr_3  // debug
);

wire [7:0] rx_byte;
wire [7:0] tx_byte;
wire rx_done;
wire tx_active;
wire buffer_empty, buffer_full, buffer_nearly_full;
reg read_en;

assign rts = !buffer_nearly_full;

wire [3:0] dbg_read_ptr; // debug

assign dbg_empty = buffer_empty;

assign dbg_read_ptr_0 = dbg_read_ptr[0];
assign dbg_read_ptr_1 = dbg_read_ptr[1];
assign dbg_read_ptr_2 = dbg_read_ptr[2];
assign dbg_read_ptr_3 = dbg_read_ptr[3];

uart_rx receiver (
    .clk(clk),
    .rx(rx_line),
    .data(rx_byte),
    .ready(rx_done)
);

uart_tx transmitter (
    .clk(clk),
    .data(tx_byte),
    .start(read_en),
    .tx(tx_line),
    .busy(tx_active)
);

fifo #(.ADDR_WIDTH(4)) buffer (
    .clk(clk),
    .rst(1'b0),
    .data_in(rx_byte),
    .write_en(rx_done),
    .data_out(tx_byte),
    .read_en(read_en),
    .empty(buffer_empty),
    .full(buffer_full),
    .nearly_full(buffer_nearly_full),
    .read_ptr_debug(dbg_read_ptr)  // debug
);

always @(posedge clk) begin
    read_en <= 0;
    if (!buffer_empty && !tx_active) begin
        read_en <= 1;
    end
end

endmodule