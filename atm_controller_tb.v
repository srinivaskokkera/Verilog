`timescale 1ns/1ps

module atm_controller_tb;

reg clk;
reg reset;

reg card_inserted;
reg pin_entered;
reg pin_valid;

reg withdraw;
reg balance_enquiry;
reg exit;

reg [7:0] amount;

wire [7:0] balance;
wire cash_dispensed;
wire show_balance;
wire transaction_error;
wire card_eject;

// DUT Instantiation

atm_controller uut (
    .clk(clk),
    .reset(reset),
    .card_inserted(card_inserted),
    .pin_entered(pin_entered),
    .pin_valid(pin_valid),
    .withdraw(withdraw),
    .balance_enquiry(balance_enquiry),
    .exit(exit),
    .amount(amount),
    .balance(balance),
    .cash_dispensed(cash_dispensed),
    .show_balance(show_balance),
    .transaction_error(transaction_error),
    .card_eject(card_eject)
);

// Clock Generation

always #5 clk = ~clk;

initial begin

    $dumpfile("atm_controller.vcd");
    $dumpvars(0, atm_controller_tb);

    $display("==============================================");
    $display("          ATM CONTROLLER SIMULATION");
    $display("==============================================");

    $display("Time  Card PIN  Valid Withdraw Balance_enquiry Amount Balance Cash Error Eject");

    $monitor("%4t   %b    %b    %b      %b          %b       %d     %b    %b   %b",
        $time, card_inserted, pin_entered, pin_valid,
        withdraw, balance_enquiry, amount,
        balance, cash_dispensed, transaction_error, card_eject);

    // Initial values

    clk = 0;
    reset = 1;

    card_inserted = 0;
    pin_entered = 0;
    pin_valid = 0;

    withdraw = 0;
    balance_enquiry = 0;
    exit = 0;

    amount = 0;

    #10;
    reset = 0;

    // Insert ATM card

    @(negedge clk);
    card_inserted = 1;

    @(negedge clk);
    card_inserted = 0;

    // Enter correct PIN

    pin_entered = 1;
    pin_valid = 1;

    @(negedge clk);
    pin_entered = 0;

    // Balance enquiry

    balance_enquiry = 1;

    @(negedge clk);
    balance_enquiry = 0;

    // Withdraw Rs.30

    amount = 8'd30;
    withdraw = 1;

    @(negedge clk);
    withdraw = 0;

    // Wait for transaction

    repeat(3) @(negedge clk);

    // Withdraw Rs.120 (insufficient balance)

    amount = 8'd120;
    withdraw = 1;

    @(negedge clk);
    withdraw = 0;

    // Wait for error and card ejection

    repeat(3) @(negedge clk);

    // Exit ATM

    exit = 1;

    @(negedge clk);
    exit = 0;

    repeat(3) @(negedge clk);

    $display("==============================================");
    $display("         SIMULATION COMPLETED");
    $display("==============================================");

    $finish;

end

endmodule