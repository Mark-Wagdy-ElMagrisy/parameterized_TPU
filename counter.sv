module counter (
    //signlas to interface with the outside world
    input logic clk,                    // Clock signal
    input logic rst_counter,            // Active-high reset for the counter
    input logic enable,                 // Enable signal to start the operation
    input logic load,                   // Load signal to load the counter with a value
    
    input logic [31:0] load_value,      // Value to load into the counter
    output logic counter_full,          // Signal to indicate if the counter is full
    output logic [31:0] counter_out,    // Current value of the counter

    input logic [31:0] load_subvalue,   // Value to load into the subcounter
    output logic subcounter_full,       // Signal to indicate if the subcounter is full
    output logic [31:0] subcounter_out  // Current value of the subcounter
);

    // Internal registers
    logic [31:0] counter_reg;       // Register to hold the counter value
    logic [31:0] subcounter_reg;    // Register to hold the subcounter value

    // Counter logic
    always_ff @(posedge clk) begin
        if (rst_counter) begin              // Reset the counter and subcounter, while keeping loaded values
            
            counter_out <= 0;
            subcounter_out <= 0;

        end else if(enable && load) begin   // Load the counter and subcounter with specified values
            
            counter_reg <= load_value; // Load the value into the counter
            subcounter_reg <= load_subvalue; // Load the value into the subcounter
            counter_out <= 0; // Reset output to 0
            subcounter_out <= 0; // Reset subcounter output to 0

        end else if (enable) begin          // Increment the counter and subcounter

            if(subcounter_out < subcounter_reg - 1) begin // -2 because we want to count from 0 to DEPTH-1 and update other counter in last cycle
                subcounter_out <= subcounter_out + 1;
            end else begin
                subcounter_out <= 0;
            end

            if (counter_full) begin
                counter_out <= 0;
            end else if (subcounter_out < subcounter_reg - 2) begin
                counter_out <= counter_out + 1;
            end
            
        end else begin

            counter_reg <= counter_reg; // Hold value if not enabled
            subcounter_reg <= subcounter_reg; // Hold value if not enabled

        end

    end

    assign counter_full = (counter_out == counter_reg - 1) &&
                            (subcounter_out == subcounter_reg - 1);
    assign subcounter_full = (subcounter_out == subcounter_reg - 1);

endmodule