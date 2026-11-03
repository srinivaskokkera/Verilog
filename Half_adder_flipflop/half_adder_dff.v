`timescale 1ns/1ps

module half_adder_dff (
    input [3:0] A,
    input [3:0] B,
    input clk,
    input reset,

    output reg [3:0] Sum,
    output reg [3:0] Carry
);

wire [3:0] sum_temp;
wire [3:0] carry_temp;

// Half Adder Logic
assign sum_temp = A ^ B;
assign carry_temp = A & B;

// D Flip-Flop
always @(posedge clk or posedge reset) begin

    if (reset) begin
        Sum <= 4'b0000;
        Carry <= 4'b0000;
    end

    else begin
        Sum <= sum_temp;
        Carry <= carry_temp;
    end

end

endmodule