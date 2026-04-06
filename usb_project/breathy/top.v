module top (
    input clk,
    output reg led
);

reg [23:0] counter;

initial counter = 0;
initial led = 0;

always @(posedge clk) begin
    counter <= counter + 1;
end

always @(*) begin
    if (counter[15:8] < counter[23:16])
        led = 1'b1;
    else
        led = 1'b0;
end

endmodule