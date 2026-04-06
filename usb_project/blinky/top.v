module top (
    input clk,
    output reg [3:0] led
);

reg [23:0] counter;

initial counter = 0;
initial led = 4'b0000;

always @(posedge clk) begin
    counter <= counter + 1;
end

always @(*) begin
    led[0] = counter[23];
    led[1] = counter[22];
    led[2] = counter[21];
    led[3] = counter[20];
end

endmodule