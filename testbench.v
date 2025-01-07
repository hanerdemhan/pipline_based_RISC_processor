`timescale 1ns / 1ps

module testbench;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter INIT_PC = 32'h0000_0000;
    parameter CACHE_SIZE = 16;

    // Signals
    reg clk;
    reg rst;
    reg [DATA_WIDTH-1:0] inst_in;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire [DATA_WIDTH-1:0] pc_out;

    // DUT (Device Under Test)
    advanced_processor #(
        .INIT_PC(INIT_PC),
        .CACHE_SIZE(CACHE_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .inst_in(inst_in),
        .data_in(data_in),
        .data_out(data_out),
        .pc_out(pc_out)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period

    // Test vectors
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        inst_in = 0;
        data_in = 0;

        // Reset sequence
        #20 rst = 0;

        // Test Case 1: Basic instruction fetch and increment PC
        inst_in = 32'h0000_0010; // Dummy instruction
        #10;
        $display("Test 1: PC after first instruction: %h", pc_out);

        // Test Case 2: Branch prediction and jump
        inst_in = 32'h1000_0004; // Branch instruction
        #10;
        $display("Test 2: PC after branch: %h", pc_out);

        // Test Case 3: Load operation
        inst_in = 32'h2000_0000; // Load instruction
        data_in = 32'hDEADBEEF;  // Data from memory
        #10;
        $display("Test 3: Data loaded: %h", data_out);

        // Test Case 4: Store operation
        inst_in = 32'h3000_0000; // Store instruction
        #10;
        $display("Test 4: Data stored: %h", data_out);

        // Test Case 5: Cache hit
        inst_in = 32'h4000_0000; // Cached instruction
        #10;
        $display("Test 5: Cache hit - PC: %h", pc_out);

        // Test Case 6: Cache miss
        inst_in = 32'h5000_0000; // Non-cached instruction
        #10;
        $display("Test 6: Cache miss - PC: %h", pc_out);

        // Test Case 7: Branch misprediction
        inst_in = 32'h6000_0000; // Mispredicted branch
        #10;
        $display("Test 7: Branch misprediction count: %d", uut.branch_mispredict_count);

        // End simulation
        $finish;
    end

endmodule
