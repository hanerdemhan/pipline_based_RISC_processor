module risc_processor (
    input wire clk,           // Clock signal
    input wire rst,           // Reset signal
    input wire [31:0] instr,  // Instruction input
    output reg [31:0] alu_result // Result of the ALU operation
);

    // Pipeline registers
    reg [31:0] if_id_instr;    // Instruction fetched (IF/ID pipeline)
    reg [31:0] id_ex_instr;    // Instruction decoded (ID/EX pipeline)
    reg [31:0] ex_mem_result;  // ALU result (EX/MEM pipeline)
    reg [31:0] mem_wb_result;  // Final write-back result (MEM/WB pipeline)

    // Instruction Decode (Registers and Signals)
    reg [31:0] reg_file [0:31];   // Register file (32 registers, 32-bit each)
    wire [4:0] rs1 = instr[19:15]; // Source register 1
    wire [4:0] rs2 = instr[24:20]; // Source register 2
    wire [4:0] rd = instr[11:7];   // Destination register
    wire [6:0] opcode = instr[6:0]; // Opcode for instruction type
    wire [2:0] func3 = instr[14:12]; // Function type
    wire [6:0] func7 = instr[31:25]; // Additional function bits

    // ALU Control Signals
    reg [31:0] alu_in1, alu_in2;
    reg [3:0] alu_op;

    // ALU (Arithmetic Logic Unit)
    always @(*) begin
        case (alu_op)
            4'b0000: alu_result = alu_in1 + alu_in2;  // ADD
            4'b0001: alu_result = alu_in1 - alu_in2;  // SUB
            4'b0010: alu_result = alu_in1 & alu_in2;  // AND
            4'b0011: alu_result = alu_in1 | alu_in2;  // OR
            4'b0100: alu_result = alu_in1 ^ alu_in2;  // XOR
            default: alu_result = 32'b0;             // Default case
        endcase
    end

    // Pipeline Stages
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset pipeline registers
            if_id_instr <= 32'b0;
            id_ex_instr <= 32'b0;
            ex_mem_result <= 32'b0;
            mem_wb_result <= 32'b0;
        end else begin
            // Instruction Fetch (IF) -> Decode (ID)
            if_id_instr <= instr;

            // Decode (ID) -> Execute (EX)
            id_ex_instr <= if_id_instr;
            alu_in1 <= reg_file[rs1];
            alu_in2 <= reg_file[rs2];
            case (opcode)
                7'b0110011: begin // R-type instructions
                    alu_op <= {func7[5], func3}; // ALU operation control
                end
                7'b0010011: begin // I-type instructions
                    alu_op <= func3;
                end
                default: alu_op <= 4'b0000; // Default NOP
            endcase

            // Execute (EX) -> Memory (MEM)
            ex_mem_result <= alu_result;

            // Memory (MEM) -> Write Back (WB)
            mem_wb_result <= ex_mem_result;
            reg_file[rd] <= mem_wb_result; // Write-back result
        end
    end
endmodule
