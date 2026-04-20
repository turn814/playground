`timescale 1ns/1ps // Set the time units

module tb_uart();
    reg clk;          // We create a 'reg' to act as our fake clock signal
    reg rx_line;      // We create a 'reg' to act as our fake UART Rx line
    wire tx_line;     // We create a 'wire' to see what the UART Tx line outputs
    wire dbg_empty;   // We create a 'wire' to see the buffer empty debug signal
    wire dbg_read_ptr_0; // We create a 'wire' to see the buffer read pointer debug signal
    wire dbg_read_ptr_1; // We create a 'wire' to see the buffer read pointer debug signal
    wire dbg_read_ptr_2; // We create a 'wire' to see the buffer read pointer debug signal
    wire dbg_read_ptr_3; // We create a 'wire' to see the buffer read pointer debug signal

    top uut (
        .clk(clk),
        .rx_line(rx_line),
        .tx_line(tx_line),
        .dbg_empty(dbg_empty),
        .dbg_read_ptr_0(dbg_read_ptr_0),
        .dbg_read_ptr_1(dbg_read_ptr_1),
        .dbg_read_ptr_2(dbg_read_ptr_2),
        .dbg_read_ptr_3(dbg_read_ptr_3)
    );

    // Clock Generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5ns
    end

    // Simulation Control
    initial begin
        $dumpfile("dump.vcd"); // Creates the file for GTKWave
        $dumpvars(0, tb_uart);
        #1000000 $finish;          // Stop simulation after 1000000ns
    end

    always @(posedge clk) begin
        // Simulate a UART transmission of the byte 0xA5 (10100101 in binary)
        // Start bit (0), data bits (1,0,1,0,0,1,0,1), stop bit (1)
        #520 rx_line = 0; // Start bit
        #520 rx_line = 1; // Bit 0
        #520 rx_line = 0; // Bit 1
        #520 rx_line = 1; // Bit 2
        #520 rx_line = 0; // Bit 3
        #520 rx_line = 0; // Bit 4
        #520 rx_line = 1; // Bit 5
        #520 rx_line = 0; // Bit 6
        #520 rx_line = 1; // Bit 7
        #520 rx_line = 1; // Stop bit
    end
endmodule