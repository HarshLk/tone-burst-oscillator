`timescale 1ns / 1ps

module tb_tone_burst_register_bank;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;
    parameter NUM_REGISTERS = 7;
    parameter CLK_PERIOD = 100; // 10MHz clock
    parameter SETUP_TIME = 10;  // Setup time in ns
    parameter HOLD_TIME = 5;    // Hold time in ns
    
    // DUT signals
    reg clk;
    reg rst_n;
    reg reg_write_en;
    reg [ADDR_WIDTH-1:0] reg_addr;
    reg [DATA_WIDTH-1:0] reg_write_data;
    wire [DATA_WIDTH-1:0] reg_read_data;
    
    // DUT outputs
    wire [DATA_WIDTH-1:0] pulse_count;
    wire [DATA_WIDTH-1:0] burst_count;
    wire [DATA_WIDTH-1:0] duty_cycle;
    wire [DATA_WIDTH-1:0] inter_burst_delay;
    wire [DATA_WIDTH-1:0] pulse_period;
    wire enable;
    wire trigger;
    wire [DATA_WIDTH-1:0] status_reg;
    
    // Status inputs to DUT
    reg [DATA_WIDTH-1:0] status_inputs;
    
    // Test variables
    reg [DATA_WIDTH-1:0] expected_data;
    reg [DATA_WIDTH-1:0] read_data_temp;
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // Register addresses (from DUT)
    localparam ADDR_CONTROL         = 4'h0;
    localparam ADDR_PULSE_COUNT     = 4'h1;
    localparam ADDR_BURST_COUNT     = 4'h2;
    localparam ADDR_DUTY_CYCLE      = 4'h3;
    localparam ADDR_INTER_BURST_DLY = 4'h4;
    localparam ADDR_PULSE_PERIOD    = 4'h5;
    localparam ADDR_STATUS          = 4'h6;
    
    // Default values (from DUT)
    localparam DEFAULT_PULSE_COUNT     = 32'd10;
    localparam DEFAULT_BURST_COUNT     = 32'd5;
    localparam DEFAULT_DUTY_CYCLE      = 32'd512;
    localparam DEFAULT_INTER_BURST_DLY = 32'd1000;
    localparam DEFAULT_PULSE_PERIOD    = 32'd100;
    
    // Instantiate DUT
    tone_burst_register_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_REGISTERS(NUM_REGISTERS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write_en(reg_write_en),
        .reg_addr(reg_addr),
        .reg_write_data(reg_write_data),
        .reg_read_data(reg_read_data),
        .pulse_count(pulse_count),
        .burst_count(burst_count),
        .duty_cycle(duty_cycle),
        .inter_burst_delay(inter_burst_delay),
        .pulse_period(pulse_period),
        .enable(enable),
        .trigger(trigger),
        .status_reg(status_reg),
        .status_inputs(status_inputs)
    );
    
    // Clock generation
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize test counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize signals with proper timing
        rst_n = 0;  // Start with reset asserted
        reg_write_en = 0;
        reg_addr = 0;
        reg_write_data = 0;
        status_inputs = 32'h0;
        
        $display("=== Tone Burst Register Bank Testbench ===");
        $display("Time: %0t", $time);
        
        // Test 1: Power-on reset (synchronous with proper timing)
        $display("\n--- Test 1: Synchronous Reset with Proper Timing ---");
        
        // Wait for 3 clock cycles while keeping reset asserted
        repeat(3) @(posedge clk);
        
        // Release reset with proper setup time before next clock edge
        #(CLK_PERIOD - SETUP_TIME) rst_n = 1;
        
        // Wait for the clock edge to propagate reset release
        @(posedge clk);
        
        // Additional settling time
        #(HOLD_TIME);
        
        // Check default values after reset
        check_default_values();
        
        // Test 2: Basic write and read operations
        $display("\n--- Test 2: Basic Write/Read Operations ---");
        test_basic_write_read();
        
        // Test 3: Write to all registers
        $display("\n--- Test 3: Write to All Registers ---");
        test_write_all_registers();
        
        // Test 4: Read from all registers
        $display("\n--- Test 4: Read from All Registers ---");
        test_read_all_registers();
        
        // Test 5: Status register (read-only)
        $display("\n--- Test 5: Status Register (Read-Only) ---");
        test_status_register();
        
        // Test 6: Control register functionality
        $display("\n--- Test 6: Control Register Functionality ---");
        test_control_register();
        
        // Test 7: Trigger bit self-clearing
        $display("\n--- Test 7: Trigger Bit Self-Clearing ---");
        test_trigger_self_clear();
        
        // Test 8: Invalid address handling
        $display("\n--- Test 8: Invalid Address Handling ---");
        test_invalid_addresses();
        
        // Test 9: Reset during operation
        $display("\n--- Test 9: Reset During Operation ---");
        test_reset_during_operation();
        
        // Test 10: Output signal verification
        $display("\n--- Test 10: Output Signal Verification ---");
        test_output_signals();
        
        // Test 11: Boundary conditions
        $display("\n--- Test 11: Boundary Conditions ---");
        test_boundary_conditions();
        
        // Test 12: Rapid write/read operations
        $display("\n--- Test 12: Rapid Write/Read Operations ---");
        test_rapid_operations();
        
        // Test 13: Setup and hold time verification
        $display("\n--- Test 13: Setup/Hold Time Verification ---");
        test_setup_hold_times();
        
        // Final results
        $display("\n=== Test Results ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED! ***", fail_count);
        end
        
        $finish;
    end
    
    // Task to check default values
    task check_default_values;
        begin
            // Add small delay to ensure signals are stable
            #(HOLD_TIME);
            @(posedge clk);
            check_register(ADDR_CONTROL, 32'h0, "Control register default");
            check_register(ADDR_PULSE_COUNT, DEFAULT_PULSE_COUNT, "Pulse count default");
            check_register(ADDR_BURST_COUNT, DEFAULT_BURST_COUNT, "Burst count default");
            check_register(ADDR_DUTY_CYCLE, DEFAULT_DUTY_CYCLE, "Duty cycle default");
            check_register(ADDR_INTER_BURST_DLY, DEFAULT_INTER_BURST_DLY, "Inter-burst delay default");
            check_register(ADDR_PULSE_PERIOD, DEFAULT_PULSE_PERIOD, "Pulse period default");
            check_register(ADDR_STATUS, 32'h0, "Status register default");
        end
    endtask
    
    // Task for basic write/read test
    task test_basic_write_read;
        begin
            write_register(ADDR_PULSE_COUNT, 32'd25);
            check_register(ADDR_PULSE_COUNT, 32'd25, "Basic write/read");
        end
    endtask
    
    // Task to test writing to all registers
    task test_write_all_registers;
        begin
            write_register(ADDR_CONTROL, 32'h0F);
            write_register(ADDR_PULSE_COUNT, 32'd20);
            write_register(ADDR_BURST_COUNT, 32'd8);
            write_register(ADDR_DUTY_CYCLE, 32'd256);
            write_register(ADDR_INTER_BURST_DLY, 32'd2000);
            write_register(ADDR_PULSE_PERIOD, 32'd200);
            
            $display("All registers written successfully");
        end
    endtask
    
    // Task to test reading from all registers
    task test_read_all_registers;
        begin
            check_register(ADDR_CONTROL, 32'h0D, "Control register read"); // Trigger bit should be cleared
            check_register(ADDR_PULSE_COUNT, 32'd20, "Pulse count read");
            check_register(ADDR_BURST_COUNT, 32'd8, "Burst count read");
            check_register(ADDR_DUTY_CYCLE, 32'd256, "Duty cycle read");
            check_register(ADDR_INTER_BURST_DLY, 32'd2000, "Inter-burst delay read");
            check_register(ADDR_PULSE_PERIOD, 32'd200, "Pulse period read");
        end
    endtask
    
    // Task to test status register
    task test_status_register;
        begin
            // Try to write to status register (should be ignored)
            write_register(ADDR_STATUS, 32'hDEADBEEF);
            
            // Status should still be 0 (write ignored)
            check_register(ADDR_STATUS, 32'h0, "Status register write protection");
            
            // Update status inputs with proper timing
            #(CLK_PERIOD - SETUP_TIME) status_inputs = 32'h12345678;
            @(posedge clk);
            #(HOLD_TIME);
            check_register(ADDR_STATUS, 32'h12345678, "Status register update from inputs");
        end
    endtask
    
    // Task to test control register functionality
    task test_control_register;
        begin
            // Test individual control bits
            write_register(ADDR_CONTROL, 32'h1); // Enable bit
            #(HOLD_TIME);
            @(posedge clk);
            if (enable !== 1'b1) begin
                $display("FAIL: Enable bit not working");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Enable bit working");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Task to test trigger bit self-clearing
    task test_trigger_self_clear;
        begin
            // Set trigger bit
            write_register(ADDR_CONTROL, 32'h2); // Trigger bit
            #(HOLD_TIME);
            @(posedge clk);
            
            // Check trigger output is high
            if (trigger !== 1'b1) begin
                $display("FAIL: Trigger bit not set");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Trigger bit set");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
            
            // Wait one clock cycle and check if trigger clears
            @(posedge clk);
            #(HOLD_TIME);
            if (trigger !== 1'b0) begin
                $display("FAIL: Trigger bit not self-clearing");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Trigger bit self-clearing");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Task to test invalid address handling
    task test_invalid_addresses;
        begin
            // Test reading from invalid address
            read_register(4'hF); // Invalid address
            if (reg_read_data !== 32'h0) begin
                $display("FAIL: Invalid address should return 0");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Invalid address returns 0");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
            
            // Test writing to invalid address (should be ignored)
            write_register(4'hF, 32'hDEADBEEF);
            read_register(4'hF);
            if (reg_read_data !== 32'h0) begin
                $display("FAIL: Write to invalid address not ignored");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Write to invalid address ignored");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Task to test reset during operation
    task test_reset_during_operation;
        begin
            // Write some values
            write_register(ADDR_PULSE_COUNT, 32'd99);
            write_register(ADDR_BURST_COUNT, 32'd88);
            
            // Apply reset with proper timing
            #(CLK_PERIOD - SETUP_TIME) rst_n = 0;
            @(posedge clk);
            #(HOLD_TIME);
            
            // Release reset with proper timing
            #(CLK_PERIOD - SETUP_TIME) rst_n = 1;
            @(posedge clk);
            #(HOLD_TIME);
            
            // Check if values are back to defaults
            check_register(ADDR_PULSE_COUNT, DEFAULT_PULSE_COUNT, "Reset during operation - pulse count");
            check_register(ADDR_BURST_COUNT, DEFAULT_BURST_COUNT, "Reset during operation - burst count");
        end
    endtask
    
    // Task to test output signals
    task test_output_signals;
        begin
            // Write test values
            write_register(ADDR_PULSE_COUNT, 32'd15);
            write_register(ADDR_BURST_COUNT, 32'd7);
            write_register(ADDR_DUTY_CYCLE, 32'd128);
            write_register(ADDR_INTER_BURST_DLY, 32'd500);
            write_register(ADDR_PULSE_PERIOD, 32'd50);
            
            @(posedge clk);
            #(HOLD_TIME);
            
            // Check output assignments
            if (pulse_count !== 32'd15) begin
                $display("FAIL: Pulse count output mismatch");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Pulse count output correct");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
            
            if (burst_count !== 32'd7) begin
                $display("FAIL: Burst count output mismatch");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Burst count output correct");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Task to test boundary conditions
    task test_boundary_conditions;
        begin
            // Test maximum values
            write_register(ADDR_PULSE_COUNT, 32'hFFFFFFFF);
            check_register(ADDR_PULSE_COUNT, 32'hFFFFFFFF, "Maximum value test");
            
            // Test zero values
            write_register(ADDR_PULSE_COUNT, 32'h0);
            check_register(ADDR_PULSE_COUNT, 32'h0, "Zero value test");
        end
    endtask
    
    // Task to test rapid operations
    task test_rapid_operations;
        begin
            integer i;
            for (i = 0; i < 10; i = i + 1) begin
                write_register(ADDR_PULSE_COUNT, i);
                read_register(ADDR_PULSE_COUNT);
                if (reg_read_data !== i) begin
                    $display("FAIL: Rapid operation %0d failed", i);
                    fail_count = fail_count + 1;
                end
            end
            $display("PASS: Rapid operations completed");
            pass_count = pass_count + 1;
            test_count = test_count + 1;
        end
    endtask
    
    // New task to test setup and hold times
    task test_setup_hold_times;
        begin
            // Test with minimal setup time
            #(CLK_PERIOD - SETUP_TIME) begin
                reg_write_en = 1'b1;
                reg_addr = ADDR_PULSE_COUNT;
                reg_write_data = 32'd123;
            end
            @(posedge clk);
            #(HOLD_TIME) reg_write_en = 1'b0;
            
            // Verify the write was successful
            read_register(ADDR_PULSE_COUNT);
            if (reg_read_data !== 32'd123) begin
                $display("FAIL: Setup time test failed");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Setup time test passed");
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Task to write to a register with proper timing
    task write_register;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            // Setup signals before clock edge
            #(CLK_PERIOD - SETUP_TIME) begin
                reg_write_en = 1'b1;
                reg_addr = addr;
                reg_write_data = data;
            end
            
            @(posedge clk);
            
            // Hold signals after clock edge
            #(HOLD_TIME) reg_write_en = 1'b0;
        end
    endtask
    
    // Task to read from a register with proper timing
    task read_register;
        input [ADDR_WIDTH-1:0] addr;
        begin
            // Setup address before clock edge
            #(CLK_PERIOD - SETUP_TIME) reg_addr = addr;
            @(posedge clk);
            #(HOLD_TIME); // Wait for hold time
            // reg_read_data is available after hold time
        end
    endtask
    
    // Task to check register value
    task check_register;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] expected;
        input [200*8-1:0] test_name;
        begin
            read_register(addr);
            if (reg_read_data !== expected) begin
                $display("FAIL: %s - Expected: 0x%08h, Got: 0x%08h", test_name, expected, reg_read_data);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s", test_name);
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Monitor for debugging
    initial begin
        $monitor("Time: %0t | rst_n: %b | write_en: %b | addr: 0x%h | write_data: 0x%08h | read_data: 0x%08h | enable: %b | trigger: %b", 
                 $time, rst_n, reg_write_en, reg_addr, reg_write_data, reg_read_data, enable, trigger);
    end
    
    // Waveform dump
    initial begin
        $dumpfile("tone_burst_register_bank.vcd");
        $dumpvars(0, tb_tone_burst_register_bank);
    end

endmodule