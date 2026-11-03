
`timescale 1ns/1ps

module riscv_5stage (
    input wire clk,
    input wire reset
);

    parameter NOP = 32'h00000013;

    // Memories and register file
    reg [31:0] pc;
    reg [31:0] instruction_mem [0:63];
    reg [31:0] data_mem [0:63];
    reg [31:0] registers [0:31];

    integer i;

    // =========================================
    // IF STAGE
    // =========================================

    reg [31:0] if_id_instruction;
    reg [31:0] if_id_pc;

    // =========================================
    // ID STAGE
    // =========================================

    wire [6:0] id_opcode = if_id_instruction[6:0];
    wire [4:0] id_rs1 = if_id_instruction[19:15];
    wire [4:0] id_rs2 = if_id_instruction[24:20];

    wire [31:0] imm_i =
        {{20{if_id_instruction[31]}},
          if_id_instruction[31:20]};

    wire [31:0] imm_s =
        {{20{if_id_instruction[31]}},
          if_id_instruction[31:25],
          if_id_instruction[11:7]};

    wire [31:0] imm_b =
        {{19{if_id_instruction[31]}},
          if_id_instruction[31],
          if_id_instruction[7],
          if_id_instruction[30:25],
          if_id_instruction[11:8],
          1'b0};

    wire [31:0] id_imm =
        (id_opcode == 7'b0100011) ? imm_s :
        (id_opcode == 7'b1100011) ? imm_b :
                                    imm_i;

    wire [31:0] wb_data;

    reg [31:0] id_data1;
    reg [31:0] id_data2;

    // =========================================
    // ID/EX PIPELINE REGISTER
    // =========================================

    reg [31:0] id_ex_instruction;
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_data1;
    reg [31:0] id_ex_data2;
    reg [31:0] id_ex_imm;

    // =========================================
    // EX STAGE
    // =========================================

    wire [6:0] ex_opcode = id_ex_instruction[6:0];
    wire [2:0] ex_funct3 = id_ex_instruction[14:12];
    wire [6:0] ex_funct7 = id_ex_instruction[31:25];

    wire [4:0] ex_rs1 = id_ex_instruction[19:15];
    wire [4:0] ex_rs2 = id_ex_instruction[24:20];
    wire [4:0] ex_rd = id_ex_instruction[11:7];

    // =========================================
    // EX/MEM PIPELINE REGISTER DECLARATIONS
    // =========================================

    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_store_data;
    reg [4:0] ex_mem_rd;

    reg ex_mem_regwrite;
    reg ex_mem_memread;
    reg ex_mem_memwrite;
    reg ex_mem_memtoreg;

    // =========================================
    // MEM/WB PIPELINE REGISTER DECLARATIONS
    // =========================================

    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_data;
    reg [4:0] mem_wb_rd;

    reg mem_wb_regwrite;
    reg mem_wb_memtoreg;

    // =========================================
    // WB STAGE
    // =========================================

    assign wb_data =
        mem_wb_memtoreg ?
        mem_wb_mem_data :
        mem_wb_alu_result;

    // =========================================
    // DATA FORWARDING
    // =========================================

    reg [31:0] forwarded_a;
    reg [31:0] forwarded_b;

    always @(*) begin

        forwarded_a = id_ex_data1;
        forwarded_b = id_ex_data2;

        // Forward from EX/MEM
        if (ex_mem_regwrite &&
            !ex_mem_memread &&
            ex_mem_rd != 0 &&
            ex_mem_rd == ex_rs1)
            forwarded_a = ex_mem_alu_result;

        else if (mem_wb_regwrite &&
                 mem_wb_rd != 0 &&
                 mem_wb_rd == ex_rs1)
            forwarded_a = wb_data;

        // Forward second operand
        if (ex_mem_regwrite &&
            !ex_mem_memread &&
            ex_mem_rd != 0 &&
            ex_mem_rd == ex_rs2)
            forwarded_b = ex_mem_alu_result;

        else if (mem_wb_regwrite &&
                 mem_wb_rd != 0 &&
                 mem_wb_rd == ex_rs2)
            forwarded_b = wb_data;

    end

    // =========================================
    // ALU AND CONTROL SIGNALS
    // =========================================

    reg [31:0] ex_alu_result;
    reg [31:0] ex_store_data;

    reg ex_regwrite;
    reg ex_memread;
    reg ex_memwrite;
    reg ex_memtoreg;

    reg ex_branch_taken;
    reg [31:0] ex_branch_target;

    always @(*) begin

        ex_alu_result = 0;
        ex_store_data = forwarded_b;

        ex_regwrite = 0;
        ex_memread = 0;
        ex_memwrite = 0;
        ex_memtoreg = 0;

        ex_branch_taken = 0;
        ex_branch_target = id_ex_pc + id_ex_imm;

        case (ex_opcode)

            // R-type
            7'b0110011: begin

                case (ex_funct3)

                    // ADD / SUB
                    3'b000: begin

                        ex_regwrite = 1;

                        if (ex_funct7 == 7'b0100000)
                            ex_alu_result =
                                forwarded_a - forwarded_b;
                        else
                            ex_alu_result =
                                forwarded_a + forwarded_b;

                    end

                    // AND
                    3'b111: begin
                        ex_regwrite = 1;
                        ex_alu_result =
                            forwarded_a & forwarded_b;
                    end

                    // OR
                    3'b110: begin
                        ex_regwrite = 1;
                        ex_alu_result =
                            forwarded_a | forwarded_b;
                    end

                    default: begin
                        ex_regwrite = 0;
                    end

                endcase
            end

            // ADDI
            7'b0010011: begin

                if (ex_funct3 == 3'b000) begin

                    ex_alu_result =
                        forwarded_a + id_ex_imm;

                    ex_regwrite = 1;

                end
            end

            // LW
            7'b0000011: begin

                if (ex_funct3 == 3'b010) begin

                    ex_alu_result =
                        forwarded_a + id_ex_imm;

                    ex_regwrite = 1;
                    ex_memread = 1;
                    ex_memtoreg = 1;

                end
            end

            // SW
            7'b0100011: begin

                if (ex_funct3 == 3'b010) begin

                    ex_alu_result =
                        forwarded_a + id_ex_imm;

                    ex_memwrite = 1;

                end
            end

            // BEQ
            7'b1100011: begin

                if (ex_funct3 == 3'b000) begin

                    ex_branch_taken =
                        (forwarded_a == forwarded_b);

                    ex_branch_target =
                        id_ex_pc + id_ex_imm;

                end
            end

            default: begin
                ex_alu_result = 0;
            end

        endcase

    end

    // =========================================
    // HAZARD DETECTION
    // =========================================

    wire uses_rs1 =
        (id_opcode == 7'b0110011) ||
        (id_opcode == 7'b0010011) ||
        (id_opcode == 7'b0000011) ||
        (id_opcode == 7'b0100011) ||
        (id_opcode == 7'b1100011);

    wire uses_rs2 =
        (id_opcode == 7'b0110011) ||
        (id_opcode == 7'b0100011) ||
        (id_opcode == 7'b1100011);

    wire load_use_stall =
        (ex_opcode == 7'b0000011) &&
        (ex_rd != 0) &&
        ((uses_rs1 && ex_rd == id_rs1) ||
         (uses_rs2 && ex_rd == id_rs2));

    // =========================================
    // REGISTER READ
    // =========================================

    always @(*) begin

        id_data1 = 0;
        id_data2 = 0;

        if (id_rs1 != 0) begin

            if (mem_wb_regwrite &&
                mem_wb_rd == id_rs1)
                id_data1 = wb_data;

            else
                id_data1 = registers[id_rs1];

        end

        if (id_rs2 != 0) begin

            if (mem_wb_regwrite &&
                mem_wb_rd == id_rs2)
                id_data2 = wb_data;

            else
                id_data2 = registers[id_rs2];

        end

    end

    // =========================================
    // PIPELINE SEQUENTIAL LOGIC
    // =========================================

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            pc <= 0;

            if_id_instruction <= NOP;
            if_id_pc <= 0;

            id_ex_instruction <= NOP;
            id_ex_pc <= 0;
            id_ex_data1 <= 0;
            id_ex_data2 <= 0;
            id_ex_imm <= 0;

            ex_mem_alu_result <= 0;
            ex_mem_store_data <= 0;
            ex_mem_rd <= 0;

            ex_mem_regwrite <= 0;
            ex_mem_memread <= 0;
            ex_mem_memwrite <= 0;
            ex_mem_memtoreg <= 0;

            mem_wb_alu_result <= 0;
            mem_wb_mem_data <= 0;
            mem_wb_rd <= 0;

            mem_wb_regwrite <= 0;
            mem_wb_memtoreg <= 0;

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 0;

        end

        else begin

            // STAGE 5: WRITE BACK

            if (mem_wb_regwrite && mem_wb_rd != 0)
                registers[mem_wb_rd] <= wb_data;

            registers[0] <= 0;

            // STAGE 4: MEMORY ACCESS

            if (ex_mem_memwrite)
                data_mem[ex_mem_alu_result[7:2]]
                    <= ex_mem_store_data;

            mem_wb_mem_data <=
                ex_mem_memread ?
                data_mem[ex_mem_alu_result[7:2]] : 0;

            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd <= ex_mem_rd;

            mem_wb_regwrite <= ex_mem_regwrite;
            mem_wb_memtoreg <= ex_mem_memtoreg;

            // STAGE 3: EXECUTE

            ex_mem_alu_result <= ex_alu_result;
            ex_mem_store_data <= ex_store_data;
            ex_mem_rd <= ex_rd;

            ex_mem_regwrite <= ex_regwrite;
            ex_mem_memread <= ex_memread;
            ex_mem_memwrite <= ex_memwrite;
            ex_mem_memtoreg <= ex_memtoreg;

            // BRANCH FLUSH

            if (ex_branch_taken) begin

                pc <= ex_branch_target;

                if_id_instruction <= NOP;
                if_id_pc <= 0;

                id_ex_instruction <= NOP;
                id_ex_pc <= 0;
                id_ex_data1 <= 0;
                id_ex_data2 <= 0;
                id_ex_imm <= 0;

            end

            // LOAD-USE STALL

            else if (load_use_stall) begin

                pc <= pc;

                if_id_instruction <= if_id_instruction;
                if_id_pc <= if_id_pc;

                id_ex_instruction <= NOP;
                id_ex_pc <= 0;
                id_ex_data1 <= 0;
                id_ex_data2 <= 0;
                id_ex_imm <= 0;

            end

            // NORMAL PIPELINE OPERATION

            else begin

                // ID to EX
                id_ex_instruction <= if_id_instruction;
                id_ex_pc <= if_id_pc;
                id_ex_data1 <= id_data1;
                id_ex_data2 <= id_data2;
                id_ex_imm <= id_imm;

                // IF
                if_id_instruction <=
                    instruction_mem[pc[7:2]];

                if_id_pc <= pc;

                pc <= pc + 32'd4;

            end

        end

    end

endmodule
