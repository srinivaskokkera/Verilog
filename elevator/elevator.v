`timescale 1ns/1ps

module elevator (
    input clk,
    input reset,
    input request,
    input [1:0] target_floor,

    output reg [1:0] current_floor,
    output reg moving_up,
    output reg moving_down,
    output reg door_open
);

reg [1:0] state;
reg [1:0] destination;

// State definitions
parameter IDLE = 2'b00,
          UP   = 2'b01,
          DOWN = 2'b10,
          DOOR = 2'b11;

// Elevator controller
always @(posedge clk or posedge reset) begin

    if (reset) begin
        current_floor <= 2'b00;
        destination <= 2'b00;
        state <= IDLE;
        moving_up <= 0;
        moving_down <= 0;
        door_open <= 0;
    end

    else begin

        moving_up <= 0;
        moving_down <= 0;
        door_open <= 0;

        case (state)

            // Waiting for floor request
            IDLE: begin

                if (request) begin

                    destination <= target_floor;

                    if (target_floor > current_floor)
                        state <= UP;

                    else if (target_floor < current_floor)
                        state <= DOWN;

                    else
                        state <= DOOR;

                end

            end

            // Moving upward
            UP: begin

                moving_up <= 1;

                if (current_floor < destination) begin

                    current_floor <= current_floor + 1'b1;

                    if (current_floor + 1'b1 == destination)
                        state <= DOOR;

                end
                else begin
                    state <= DOOR;
                end

            end

            // Moving downward
            DOWN: begin

                moving_down <= 1;

                if (current_floor > destination) begin

                    current_floor <= current_floor - 1'b1;

                    if (current_floor - 1'b1 == destination)
                        state <= DOOR;

                end
                else begin
                    state <= DOOR;
                end

            end

            // Open elevator door
            DOOR: begin

                door_open <= 1;
                state <= IDLE;

            end

            default: state <= IDLE;

        endcase

    end

end

endmodule