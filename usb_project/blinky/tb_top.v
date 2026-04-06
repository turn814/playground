`timescale 1ns/1ps // Set the time units

module tb_counter();
    reg clk;          // We create a 'reg' to act as our fake clock signal
    wire [3:0] count; // We create a 'wire' to see what the counter outputs

    // TODO: Connect the 'counter' module to this testbench. 
    // This is called "instantiation." 
    // Syntax: counter my_instance_name (.clk(clk), .out(count));

    top uut (
        .clk(clk),
        .count(led)
    );

    // Clock Generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5ns
    end

    // Simulation Control
    initial begin
        $dumpfile("dump.vcd"); // Creates the file for GTKWave
        $dumpvars(0, tb_counter);
        #100 $finish;          // Stop simulation after 100ns
    end
endmodule