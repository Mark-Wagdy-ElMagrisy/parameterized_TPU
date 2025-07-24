module delay #(
    parameter MAX_DELAY = 256 // Maximum delay (number of inputs)
) (
    input logic clk,            // Clock signal
    input logic rst,          // Active-low reset
    input wire logic [31:0] data_in [MAX_DELAY-1:0], // Input data
    output logic [31:0] data_out[MAX_DELAY-1:0] // Triangle of outputs
);

    wire [31:0] delays[MAX_DELAY][MAX_DELAY]; // 2D array for triangle structure

    // Generate the triangle of shift registers
    genvar i, j;
    generate
        assign data_out[0] = data_in[0];
        for (i = 1; i < MAX_DELAY; i++) begin : gen_shift_rows
            for (j = 0; j < i; j++) begin : gen_shift_cols
                register reg_instance (
                    .clk(clk),
                    .rst(rst),
                    .d((j == 0) ? data_in[i] : delays[i][j-1]),
                    .q(delays[i][j])
                );
            end
        end

        for (i = 1; i < MAX_DELAY; i++) begin : assign_delays
            assign data_out[i] = delays[i][i-1];
        end
    endgenerate

endmodule