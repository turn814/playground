module fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] data_in,
    input write_en,
    output [DATA_WIDTH-1:0] data_out,
    input read_en,
    output empty,
    output full,
    output nearly_full,
    output [ADDR_WIDTH-1:0] read_ptr_debug   // debug
);

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
reg [ADDR_WIDTH:0] write_ptr = 0;
reg [ADDR_WIDTH:0] read_ptr = 0;

assign empty = (read_ptr == write_ptr);
assign full = (read_ptr[ADDR_WIDTH] != write_ptr[ADDR_WIDTH]) && (read_ptr[ADDR_WIDTH-1:0] == write_ptr[ADDR_WIDTH-1:0]);
wire [ADDR_WIDTH:0] count = write_ptr - read_ptr;
assign nearly_full = (count >= (1 << ADDR_WIDTH) - 2);

assign data_out = mem[read_ptr[ADDR_WIDTH-1:0]-1];

assign read_ptr_debug = read_ptr[ADDR_WIDTH-1:0]; // debug

always @(posedge clk) begin
    // reset logic
    if (rst) begin
        write_ptr <= 0;
        read_ptr <= 0;
    end else begin

        // write logic
        if (write_en && !full) begin
            mem[write_ptr[ADDR_WIDTH-1:0]] <= data_in;
            write_ptr <= write_ptr + 1;
        end
        
        // read logic
        if (read_en && !empty) begin
            read_ptr <= read_ptr + 1;
        end
    end
end

endmodule