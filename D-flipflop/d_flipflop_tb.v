`timescale 1ns/1ps

module d_flipflop_tb;

reg D;
reg clk;
reg reset;

wire Q;

d_flipflop uut (
    .D(D),
    .clk(clk),
    .reset(reset),
    .Q(Q)
);

// Clock Generation

always #5 clk = ~clk;

initial begin

    $display("================================");
    $display("    D FLIP-FLOP SIMULATION");
    $display("================================");

    $display("Time    Reset   CLK   D   Q");
    $display("--------------------------------");

    $monitor("%4t     %b      %b    %b   %b",
             $time, reset, clk, D, Q);

    // Initial values
    clk = 0;
    D = 0;
    reset = 1;
    #10;

    // Release reset
    reset = 0;

    // Test case 1
    D = 1;
    #10;

    // Test case 2
    D = 0;
    #10;

    // Test case 3
    D = 1;
    #10;

    // Test case 4
    D = 1;
    #10;

    // Test case 5
    D = 0;
    #10;

    // Apply reset
    reset = 1;
    #10;

    reset = 0;
    #10;

    $display("================================");
    $display("    SIMULATION COMPLETED");
    $display("================================");

    $finish;

end

endmodule