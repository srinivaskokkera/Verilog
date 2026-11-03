`timescale 1ns/1ps

module half_adder4_tb;

reg [3:0] A;
reg [3:0] B;

wire [3:0] Sum;
wire [3:0] Carry;

half_adder4 uut (
    .A(A),
    .B(B),
    .Sum(Sum),
    .Carry(Carry)
);

initial begin

    $display("======================================");
    $display("     4-BIT HALF ADDER SIMULATION");
    $display("======================================");

    $display("Time    A      B      Sum    Carry");
    $display("--------------------------------------");

    $monitor("%4t   %b   %b   %b   %b",
             $time, A, B, Sum, Carry);

    // Test case 1
    A = 4'b0000;
    B = 4'b0000;
    #20;

    // Test case 2
    A = 4'b0101;
    B = 4'b0011;
    #20;

    // Test case 3
    A = 4'b1111;
    B = 4'b1111;
    #20;

    // Test case 4
    A = 4'b1010;
    B = 4'b0101;
    #20;

    // Test case 5
    A = 4'b1001;
    B = 4'b0110;
    #20;

    $display("======================================");
    $display("       SIMULATION COMPLETED");
    $display("======================================");

    $finish;

end

endmodule