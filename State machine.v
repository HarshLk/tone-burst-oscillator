// Tone Burst State Machine
// Generates square wave tone bursts based on register bank parameters

module tone_burst_state_machine #(
    parameter DATA_WIDTH = 32,
    parameter COUNTER_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // Inputs from register bank
    input  wire [DATA_WIDTH-1:0]    pulse_count,
    input  wire [DATA_WIDTH-1:0]    burst_count,
    input  wire [DATA_WIDTH-1:0]    duty_cycle,        // Out of 1024 for precision
    input  wire [DATA_WIDTH-1:0]    inter_burst_delay,
    input  wire [DATA_WIDTH-1:0]    pulse_period,
    input  wire                     enable,
    input  wire                     trigger,
    
    // Status outputs to register bank
    output reg  [DATA_WIDTH-1:0]    status_outputs,
    
    // Tone burst output
    output reg                      tone_out
);

// State machine states
localparam IDLE             = 3'b000;
localparam PULSE_HIGH       = 3'b001;
localparam PULSE_LOW        = 3'b010;
localparam INTER_BURST_DELAY = 3'b011;
localparam SEQUENCE_DONE    = 3'b100;

// State machine registers
reg [2:0] state, next_state;
reg [COUNTER_WIDTH-1:0] pulse_counter;
reg [COUNTER_WIDTH-1:0] burst_counter;
reg [COUNTER_WIDTH-1:0] period_counter;
reg [COUNTER_WIDTH-1:0] delay_counter;
reg [COUNTER_WIDTH-1:0] pulse_high_time;
reg [COUNTER_WIDTH-1:0] pulse_low_time;

// Status bit definitions
wire status_busy     = (state != IDLE);
wire status_complete = (state == SEQUENCE_DONE);

// Calculate duty cycle times
always @(*) begin
    pulse_high_time = (pulse_period * duty_cycle) >> 10;  // Divide by 1024
    pulse_low_time  = pulse_period - pulse_high_time;
end

// State machine sequential logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// State machine combinational logic
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (enable && trigger) begin
                next_state = PULSE_HIGH;
            end
        end
        
        PULSE_HIGH: begin
            if (period_counter >= pulse_high_time) begin
                next_state = PULSE_LOW;
            end
        end
        
        PULSE_LOW: begin
            if (period_counter >= pulse_low_time) begin
                if (pulse_counter >= pulse_count) begin
                    if (burst_counter >= burst_count) begin
                        next_state = SEQUENCE_DONE;
                    end else begin
                        next_state = INTER_BURST_DELAY;
                    end
                end else begin
                    next_state = PULSE_HIGH;
                end
            end
        end
        
        INTER_BURST_DELAY: begin
            if (delay_counter >= inter_burst_delay) begin
                next_state = PULSE_HIGH;
            end
        end
        
        SEQUENCE_DONE: begin
            if (!enable || trigger) begin
                next_state = IDLE;
            end
        end
    endcase
end

// Counter and output logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pulse_counter <= 0;
        burst_counter <= 0;
        period_counter <= 0;
        delay_counter <= 0;
        tone_out <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                pulse_counter <= 0;
                burst_counter <= 0;
                period_counter <= 0;
                delay_counter <= 0;
                tone_out <= 1'b0;
            end
            
            PULSE_HIGH: begin
                tone_out <= 1'b1;
                if (next_state == PULSE_LOW) begin
                    period_counter <= 0;
                end else begin
                    period_counter <= period_counter + 1;
                end
            end
            
            PULSE_LOW: begin
                tone_out <= 1'b0;
                if (next_state == PULSE_HIGH) begin
                    period_counter <= 0;
                    pulse_counter <= pulse_counter + 1;
                end else if (next_state == INTER_BURST_DELAY) begin
                    period_counter <= 0;
                    pulse_counter <= 0;
                    burst_counter <= burst_counter + 1;
                end else begin
                    period_counter <= period_counter + 1;
                end
            end
            
            INTER_BURST_DELAY: begin
                tone_out <= 1'b0;
                if (next_state == PULSE_HIGH) begin
                    delay_counter <= 0;
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end
            
            SEQUENCE_DONE: begin
                tone_out <= 1'b0;
                if (next_state == IDLE) begin
                    pulse_counter <= 0;
                    burst_counter <= 0;
                    period_counter <= 0;
                    delay_counter <= 0;
                end
            end
        endcase
    end
end

// Status output generation
always @(*) begin
    status_outputs = 32'h0;
    status_outputs[0] = status_busy;
    status_outputs[1] = status_complete;
    status_outputs[2] = (state == PULSE_HIGH);
    status_outputs[3] = (state == PULSE_LOW);
    status_outputs[4] = (state == INTER_BURST_DELAY);
    status_outputs[15:8] = pulse_counter[7:0];   // Current pulse count
    status_outputs[23:16] = burst_counter[7:0];  // Current burst count
    status_outputs[31:24] = state;               // Current state
end

endmodule