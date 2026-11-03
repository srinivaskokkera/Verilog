`timescale 1ns/1ps

module half_adder_dff_tb;

reg [3:0] A;
reg [3:0] B;
reg clk;
reg reset;

wire [3:0] Sum;
wire [3:0] Carry;

// DUT Instantiation

half_adder_dff uut (
    .A(A),
    .B(B),
    .clk(clk),
    .reset(reset),
    .Sum(Sum),
    .Carry(Carry)
);

// Clock Generation

always #5 clk = ~clk;

initial begin

    $dumpfile("half_adder_dff.vcd");
    $dumpvars(0, half_adder_dff_tb);

    $display("==============================================");
    $display("    HALF ADDER WITH D FLIP-FLOP SIMULATION");
    $display("==============================================");

    $display("Time  A     B     CLK  RESET  SUM   CARRY");

    $monitor("%4t  %b  %b   %b     %b    %b   %b",
             $time, A, B, clk, reset, Sum, Carry);

    clk = 0;
    reset = 1;
    A = 4'b0000;
    B = 4'b0000;
    #10;

    reset = 0;

    // Test case 1
    A = 4'b0101;
    B = 4'b0011;
    #20;

    // Test case 2
    A = 4'b1111;
    B = 4'b1111;
    #20;

    // Test case 3
    A = 4'b1010;
    B = 4'b0101;
    #20;

    // Test case 4
    A = 4'b1001;
    B = 4'b0110;
    #20;

    // Test case 5
    A = 4'b1100;
    B = 4'b1010;
    #20;

    $display("==============================================");
    $display("        SIMULATION COMPLETED");
    $display("==============================================");

    $finish;

end

endmodule