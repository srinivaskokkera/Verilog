`timescale 1ns/1ps

module elevator_tb;

reg clk;
reg reset;
reg request;
reg [1:0] target_floor;

wire [1:0] current_floor;
wire moving_up;
wire moving_down;
wire door_open;

// DUT Instantiation

elevator uut (
    .clk(clk),
    .reset(reset),
    .request(request),
    .target_floor(target_floor),
    .current_floor(current_floor),
    .moving_up(moving_up),
    .moving_down(moving_down),
    .door_open(door_open)
);

// Clock Generation

always #5 clk = ~clk;

initial begin

    $display("==============================================");
    $display("         ELEVATOR SIMULATION");
    $display("==============================================");

    $display("Time  Request Target Current UP DOWN Door");

    $monitor("%4t    %b       %b      %b    %b   %b    %b",
             $time, request, target_floor,
             current_floor, moving_up,
             moving_down, door_open);

    // Initialize
    clk = 0;
    reset = 1;
    request = 0;
    target_floor = 0;

    #10;
    reset = 0;

    // Request floor 3
    #10;
    target_floor = 2'b11;
    request = 1;
    #10;
    request = 0;

    // Wait for elevator
    #50;

    // Request floor 1
    target_floor = 2'b01;
    request = 1;
    #10;
    request = 0;

    #50;

    // Request Ground floor
    target_floor = 2'b00;
    request = 1;
    #10;
    request = 0;

    #50;

    $display("==============================================");
    $display("       SIMULATION COMPLETED");
    $display("==============================================");

    $finish;

end

endmodule