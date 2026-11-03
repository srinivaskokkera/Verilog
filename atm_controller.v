`timescale 1ns/1ps

module atm_controller (
    input clk,
    input reset,

    input card_inserted,
    input pin_entered,
    input pin_valid,

    input withdraw,
    input balance_enquiry,
    input exit,

    input [7:0] amount,

    output reg [7:0] balance,
    output reg cash_dispensed,
    output reg show_balance,
    output reg transaction_error,
    output reg card_eject
);

// State definitions

parameter IDLE        = 3'b000,
          PIN_ENTRY   = 3'b001,
          MENU        = 3'b010,
          CHECK_FUNDS = 3'b011,
          DISPENSE    = 3'b100,
          BALANCE     = 3'b101,
          ERROR       = 3'b110,
          EJECT       = 3'b111;

reg [2:0] state;

// FSM Sequential Logic

always @(posedge clk or posedge reset) begin

    if (reset) begin
        state <= IDLE;
        balance <= 8'd100;
    end

    else begin

        case (state)

            // Waiting for ATM card

            IDLE: begin
                if (card_inserted)
                    state <= PIN_ENTRY;
            end

            // PIN validation

            PIN_ENTRY: begin
                if (pin_entered) begin
                    if (pin_valid)
                        state <= MENU;
                    else
                        state <= ERROR;
                end
            end

            // Transaction selection

            MENU: begin
                if (withdraw)
                    state <= CHECK_FUNDS;

                else if (balance_enquiry)
                    state <= BALANCE;

                else if (exit)
                    state <= EJECT;
            end

            // Check available balance

            CHECK_FUNDS: begin
                if (amount <= balance)
                    state <= DISPENSE;
                else
                    state <= ERROR;
            end

            // Dispense cash

            DISPENSE: begin
                balance <= balance - amount;
                state <= MENU;
            end

            // Display balance

            BALANCE: begin
                state <= MENU;
            end

            // Error condition

            ERROR: begin
                state <= EJECT;
            end

            // Eject ATM card

            EJECT: begin
                state <= IDLE;
            end

            default: state <= IDLE;

        endcase

    end

end

// FSM Output Logic

always @(*) begin

    cash_dispensed = 0;
    show_balance = 0;
    transaction_error = 0;
    card_eject = 0;

    case (state)

        DISPENSE: begin
            cash_dispensed = 1;
        end

        BALANCE: begin
            show_balance = 1;
        end

        ERROR: begin
            transaction_error = 1;
        end

        EJECT: begin
            card_eject = 1;
        end

    endcase

end

endmodule