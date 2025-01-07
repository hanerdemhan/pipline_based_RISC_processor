module advanced_processor (
    input wire clk,            // System clock
    input wire rst,            // System reset
    input wire [31:0] inst_in, // Instruction input
    input wire [31:0] data_in, // Data input for memory operations
    output wire [31:0] data_out, // Data output for memory operations
    output wire [31:0] pc_out  // Program counter output for debugging
);

    // Parameters
    parameter CACHE_SIZE = 16;       // Cache size (16 lines)
    parameter INIT_PC = 32'h0000_0000; // Initial program counter value

    // Registers
    reg [31:0] pc;                   // Program counter
    reg [31:0] instruction_register; // Instruction register
    reg [31:0] data_register;        // Data register

    // Cache memory
    reg [31:0] cache[CACHE_SIZE-1:0]; // Instruction cache
    reg [31:0] cache_tags[CACHE_SIZE-1:0]; // Cache tags
    reg [CACHE_SIZE-1:0] cache_valid; // Cache validity bits

    // Branch prediction
    reg [1:0] branch_history_table [0:3]; // Simple 2-bit predictor
    reg branch_prediction;                // Branch prediction result

    // Forwarding and hazard detection
    reg forwarding_enabled;               // Forwarding control
    reg stall;                            // Pipeline stall signal

    // Debugging
    reg [63:0] cycle_counter;             // Counts total clock cycles
    reg branch_mispredict_count;          // Counts branch mispredictions

    // ALU
    reg [31:0] alu_result;                // ALU result
    reg alu_zero;                         // ALU zero flag

    // Instruction decoding (simple)
    wire [5:0] opcode = instruction_register[31:26]; // Opcode
    wire [4:0] rs = instruction_register[25:21];     // Source register
    wire [4:0] rt = instruction_register[20:16];     // Target register
    wire [15:0] immediate = instruction_register[15:0]; // Immediate value

    // Initialize registers
    initial begin
        pc = INIT_PC;
        cycle_counter = 0;
        branch_mispredict_count = 0;
        forwarding_enabled = 1'b1; // Enable forwarding by default
        cache_valid = {CACHE_SIZE{1'b0}}; // Invalidate all cache lines
    end

    // Debug: Program counter output
    assign pc_out = pc;

    // Main always block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            pc <= INIT_PC;
            cycle_counter <= 0;
            branch_mispredict_count <= 0;
        end else begin
            // Increment cycle counter
            cycle_counter <= cycle_counter + 1;

            // Fetch stage
            if (!stall) begin
                // Check cache for instruction
                integer cache_index = pc % CACHE_SIZE;
                if (cache_valid[cache_index] && cache_tags[cache_index] == pc) begin
                    instruction_register <= cache[cache_index]; // Cache hit
                end else begin
                    instruction_register <= inst_in; // Fetch from memory
                    cache[cache_index] <= inst_in;  // Update cache
                    cache_tags[cache_index] <= pc;  // Update tag
                    cache_valid[cache_index] <= 1'b1; // Mark valid
                end
                pc <= pc + 4; // Default PC increment
            end

            // Decode and Execute stage
            case (opcode)
                6'b000000: begin // ADD
                    alu_result <= rs + rt;
                end
                6'b000001: begin // SUB
                    alu_result <= rs - rt;
                end
                6'b000010: begin // Branch if Equal
                    if (rs == rt) begin
                        pc <= pc + immediate; // Branch taken
                        branch_prediction <= 1'b1; // Assume branch is taken
                    end else begin
                        branch_prediction <= 1'b0; // Assume branch not taken
                    end
                end
                default: begin
                    alu_result <= 32'b0; // Default ALU result
                end
            endcase

            // Check branch prediction
            if (opcode == 6'b000010) begin
                if (branch_prediction != (rs == rt)) begin
                    branch_mispredict_count <= branch_mispredict_count + 1;
                    pc <= pc - 4; // Flush pipeline and correct PC
                end
            end

            // Memory stage
            if (opcode == 6'b000100) begin // LOAD
                data_register <= data_in;
            end else if (opcode == 6'b000101) begin // STORE
                data_out <= data_register;
            end
        end
    end
endmodule
