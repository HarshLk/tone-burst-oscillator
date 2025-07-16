// Tone Burst Oscillator Register Bank
// Scalable and maintainable register bank for tone burst parameters

module tone_burst_register_bank #(
    parameter DATA_WIDTH = 32,          // Width of data bus
    parameter ADDR_WIDTH = 4,           // Width of address bus (supports 16 registers)
    parameter NUM_REGISTERS = 7         // Number of registers implemented (reduced from 8)
)(
    input  wire clk,
    input  wire rst_n,                  // Synchronous active-low reset
    
    // External interface for register access
    input  wire                     reg_write_en,
    input  wire [ADDR_WIDTH-1:0]    reg_addr,
    input  wire [DATA_WIDTH-1:0]    reg_write_data,
    output reg  [DATA_WIDTH-1:0]    reg_read_data,
    
    // Outputs to tone burst state machine
    output wire [DATA_WIDTH-1:0]    pulse_count,        // Number of pulses in single burst
    output wire [DATA_WIDTH-1:0]    burst_count,        // Number of bursts to generate
    output wire [DATA_WIDTH-1:0]    duty_cycle,         // Duty cycle (0-100 or 0-1024 for precision)
    output wire [DATA_WIDTH-1:0]    inter_burst_delay,  // Delay between bursts
    output wire [DATA_WIDTH-1:0]    pulse_period,       // Period of each pulse
    output wire                     enable,             // Global enable
    output wire                     trigger,            // Software trigger
    
    // Status outputs
    output wire [DATA_WIDTH-1:0]    status_reg,         // Status register
    input  wire [DATA_WIDTH-1:0]    status_inputs       // Status inputs from state machine
);

// Register addresses - makes code more maintainable
localparam ADDR_CONTROL         = 4'h0;  // Control register
localparam ADDR_PULSE_COUNT     = 4'h1;  // Pulses per burst
localparam ADDR_BURST_COUNT     = 4'h2;  // Number of bursts
localparam ADDR_DUTY_CYCLE      = 4'h3;  // Duty cycle
localparam ADDR_INTER_BURST_DLY = 4'h4;  // Inter-burst delay
localparam ADDR_PULSE_PERIOD    = 4'h5;  // Pulse period
localparam ADDR_STATUS          = 4'h6;  // Status register (read-only)

// Default values for registers
localparam DEFAULT_PULSE_COUNT     = 32'd10;      // 10 pulses per burst
localparam DEFAULT_BURST_COUNT     = 32'd5;       // 5 bursts
localparam DEFAULT_DUTY_CYCLE      = 32'd512;     // 50% duty cycle (out of 1024)
localparam DEFAULT_INTER_BURST_DLY = 32'd1000;    // 1000 clock cycles between bursts
localparam DEFAULT_PULSE_PERIOD    = 32'd100;     // 100 clock cycles per pulse

// Register bank storage
reg [DATA_WIDTH-1:0] registers [0:NUM_REGISTERS-1];

// Control register bit definitions
wire ctrl_enable    = registers[ADDR_CONTROL][0];
wire ctrl_trigger   = registers[ADDR_CONTROL][1];
wire ctrl_reset     = registers[ADDR_CONTROL][2];
wire ctrl_auto_mode = registers[ADDR_CONTROL][3];

// Initialize registers with default values
initial begin
    registers[ADDR_CONTROL]         = 32'h0;
    registers[ADDR_PULSE_COUNT]     = DEFAULT_PULSE_COUNT;
    registers[ADDR_BURST_COUNT]     = DEFAULT_BURST_COUNT;
    registers[ADDR_DUTY_CYCLE]      = DEFAULT_DUTY_CYCLE;
    registers[ADDR_INTER_BURST_DLY] = DEFAULT_INTER_BURST_DLY;
    registers[ADDR_PULSE_PERIOD]    = DEFAULT_PULSE_PERIOD;
    registers[ADDR_STATUS]          = 32'h0;
end

// Write logic with synchronous reset
always @(posedge clk) begin
    if (!rst_n) begin
        // Synchronous reset - reset occurs only on rising edge of clock
        registers[ADDR_CONTROL]         <= 32'h0;
        registers[ADDR_PULSE_COUNT]     <= DEFAULT_PULSE_COUNT;
        registers[ADDR_BURST_COUNT]     <= DEFAULT_BURST_COUNT;
        registers[ADDR_DUTY_CYCLE]      <= DEFAULT_DUTY_CYCLE;
        registers[ADDR_INTER_BURST_DLY] <= DEFAULT_INTER_BURST_DLY;
        registers[ADDR_PULSE_PERIOD]    <= DEFAULT_PULSE_PERIOD;
        registers[ADDR_STATUS]          <= 32'h0;
    end else begin
        // Handle register writes
        if (reg_write_en && (reg_addr < NUM_REGISTERS)) begin
            // Prevent writing to status register (read-only)
            if (reg_addr != ADDR_STATUS) begin
                registers[reg_addr] <= reg_write_data;
            end
        end
        
        // Update status register with inputs from state machine
        registers[ADDR_STATUS] <= status_inputs;
        
        // Self-clearing trigger bit
        if (registers[ADDR_CONTROL][1]) begin
            registers[ADDR_CONTROL][1] <= 1'b0;
        end
    end
end

// Read logic (combinational - no reset needed)
always @(*) begin
    if (reg_addr < NUM_REGISTERS) begin
        reg_read_data = registers[reg_addr];
    end else begin
        reg_read_data = {DATA_WIDTH{1'b0}};
    end
end

// Output assignments
assign pulse_count       = registers[ADDR_PULSE_COUNT];
assign burst_count       = registers[ADDR_BURST_COUNT];
assign duty_cycle        = registers[ADDR_DUTY_CYCLE];
assign inter_burst_delay = registers[ADDR_INTER_BURST_DLY];
assign pulse_period      = registers[ADDR_PULSE_PERIOD];
assign enable            = ctrl_enable;
assign trigger           = ctrl_trigger;
assign status_reg        = registers[ADDR_STATUS];

// Parameter validation (optional - can be enabled with parameter)
`ifdef PARAM_VALIDATION
    always @(posedge clk) begin
        if (reg_write_en) begin
            case (reg_addr)
                ADDR_PULSE_COUNT: begin
                    if (reg_write_data == 0) begin
                        $display("Warning: Pulse count cannot be zero");
                    end
                end
                ADDR_BURST_COUNT: begin
                    if (reg_write_data == 0) begin
                        $display("Warning: Burst count cannot be zero");
                    end
                end
                ADDR_DUTY_CYCLE: begin
                    if (reg_write_data > 1024) begin
                        $display("Warning: Duty cycle exceeds maximum value");
                    end
                end
            endcase
        end
    end
`endif

endmodule

// Register Bank Interface Wrapper (for easier external access)
// Modified to use synchronous reset
module tone_burst_reg_interface #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,          // Synchronous active-low reset
    
    // Simple register interface
    input  wire                     write_pulse,
    input  wire [ADDR_WIDTH-1:0]    address,
    input  wire [DATA_WIDTH-1:0]    write_data,
    output wire [DATA_WIDTH-1:0]    read_data,
    
    // Connect to register bank
    output wire                     reg_write_en,
    output wire [ADDR_WIDTH-1:0]    reg_addr,
    output wire [DATA_WIDTH-1:0]    reg_write_data,
    input  wire [DATA_WIDTH-1:0]    reg_read_data
);

// Simple interface logic (no reset needed for combinational logic)
assign reg_write_en   = write_pulse;
assign reg_addr       = address;
assign reg_write_data = write_data;
assign read_data      = reg_read_data;

endmodule