
`timescale 1ns/1ps

module tb_riscv_5stage;

    reg clk;
    reg reset;

    integer k;

    // DUT Instantiation
    riscv_5stage dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // =====================================
    // I-TYPE INSTRUCTION ENCODING
    // =====================================

    function [31:0] enc_i;
        input integer imm;
        input integer rs1;
        input integer funct3;
        input integer rd;
        input [6:0] opcode;

        begin
            enc_i = {imm[11:0], rs1[4:0],
                     funct3[2:0], rd[4:0], opcode};
        end
    endfunction

    // =====================================
    // R-TYPE INSTRUCTION ENCODING
    // =====================================

    function [31:0] enc_r;
        input integer funct7;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        input integer rd;
        input [6:0] opcode;

        begin
            enc_r = {funct7[6:0], rs2[4:0],
                     rs1[4:0], funct3[2:0],
                     rd[4:0], opcode};
        end
    endfunction

    // =====================================
    // S-TYPE INSTRUCTION ENCODING
    // =====================================

    function [31:0] enc_s;
        input integer imm;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        input [6:0] opcode;

        begin
            enc_s = {imm[11:5], rs2[4:0],
                     rs1[4:0], funct3[2:0],
                     imm[4:0], opcode};
        end
    endfunction

    // =====================================
    // B-TYPE INSTRUCTION ENCODING
    // =====================================

    function [31:0] enc_b;
        input integer offset;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        input [6:0] opcode;

        reg [12:0] b;

        begin
            b = offset;

            enc_b = {b[12], b[10:5],
                     rs2[4:0], rs1[4:0],
                     funct3[2:0], b[4:1],
                     b[11], opcode};
        end
    endfunction

    // =====================================
    // MAIN TEST PROGRAM
    // =====================================

    initial begin

        clk = 0;
        reset = 1;

        // Initialize instruction and data memories

        for (k = 0; k < 64; k = k + 1) begin
            dut.instruction_mem[k] = 32'h00000013;
            dut.data_mem[k] = 32'd0;
        end

        // ---------------------------------
        // Instruction 1: ADDI x1, x0, 5
        // x1 = 5
        // ---------------------------------

        dut.instruction_mem[0] =
            enc_i(5, 0, 0, 1, 7'b0010011);

        // ---------------------------------
        // Instruction 2: ADDI x2, x0, 7
        // x2 = 7
        // ---------------------------------

        dut.instruction_mem[1] =
            enc_i(7, 0, 0, 2, 7'b0010011);

        // ---------------------------------
        // Instruction 3: ADD x3, x1, x2
        // x3 = 5 + 7 = 12
        // ---------------------------------

        dut.instruction_mem[2] =
            enc_r(0, 2, 1, 0, 3, 7'b0110011);

        // ---------------------------------
        // Instruction 4: SUB x4, x3, x1
        // x4 = 12 - 5 = 7
        // ---------------------------------

        dut.instruction_mem[3] =
            enc_r(7'b0100000, 1, 3, 0, 4, 7'b0110011);

        // ---------------------------------
        // Instruction 5: SW x3, 0(x0)
        // MEM[0] = 12
        // ---------------------------------

        dut.instruction_mem[4] =
            enc_s(0, 3, 0, 2, 7'b0100011);

        // ---------------------------------
        // Instruction 6: LW x5, 0(x0)
        // x5 = MEM[0] = 12
        // ---------------------------------

        dut.instruction_mem[5] =
            enc_i(0, 0, 2, 5, 7'b0000011);

        // ---------------------------------
        // Instruction 7: BEQ x4, x2, +8
        // If equal, skip next instruction
        // ---------------------------------

        dut.instruction_mem[6] =
            enc_b(8, 2, 4, 0, 7'b1100011);

        // ---------------------------------
        // Instruction 8: ADDI x6, x0, 99
        // Should be skipped by branch
        // ---------------------------------

        dut.instruction_mem[7] =
            enc_i(99, 0, 0, 6, 7'b0010011);

        // ---------------------------------
        // Instruction 9: ADDI x7, x0, 11
        // x7 = 11
        // ---------------------------------

        dut.instruction_mem[8] =
            enc_i(11, 0, 0, 7, 7'b0010011);

        // =====================================
        // RELEASE RESET
        // =====================================

        #12;
        reset = 0;

        // Allow pipeline execution
        repeat (30) @(posedge clk);

        #1;

        // =====================================
        // DISPLAY RESULTS
        // =====================================

        $display("");
        $display("==========================================");
        $display("       5-STAGE RISC-V PROCESSOR");
        $display("==========================================");

        $display("Register x1  = %0d (Expected 5)",
                 dut.registers[1]);

        $display("Register x2  = %0d (Expected 7)",
                 dut.registers[2]);

        $display("Register x3  = %0d (Expected 12)",
                 dut.registers[3]);

        $display("Register x4  = %0d (Expected 7)",
                 dut.registers[4]);

        $display("Register x5  = %0d (Expected 12)",
                 dut.registers[5]);

        $display("Register x6  = %0d (Expected 0)",
                 dut.registers[6]);

        $display("Register x7  = %0d (Expected 11)",
                 dut.registers[7]);

        $display("Memory [0]   = %0d (Expected 12)",
                 dut.data_mem[0]);

        $display("------------------------------------------");

        // =====================================
        // AUTOMATIC VERIFICATION
        // =====================================

        if (dut.registers[1] == 5 &&
            dut.registers[2] == 7 &&
            dut.registers[3] == 12 &&
            dut.registers[4] == 7 &&
            dut.registers[5] == 12 &&
            dut.registers[6] == 0 &&
            dut.registers[7] == 11 &&
            dut.data_mem[0] == 12)

            $display("5-STAGE RISC-V TEST PASSED");

        else

            $display("5-STAGE RISC-V TEST FAILED");

        $display("==========================================");

        $finish;

    end

endmodule
