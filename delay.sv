module delay #(
    parameter MAX_DELAY = 256 // Maximum delay (number of inputs)
) (
    input logic clk,            // Clock signal
    input logic rst,          // Active-low reset
    input wire logic [31:0] data_in [MAX_DELAY-1:0], // Input data
    output wire logic [31:0] data_out[MAX_DELAY-1:0] // Triangle of outputs
);

    logic [31:0] delays[MAX_DELAY][MAX_DELAY]; // 2D array for triangle structure

    // Generate the triangle of shift registers
    genvar i, j;
    generate
        for (i = 1; i < MAX_DELAY; i++) begin : gen_shift_rows
            for (j = 0; j < i; j++) begin : gen_shift_cols
                if (j == 0) begin
                    // First flip-flop in the row
                    always_ff @(posedge clk) begin
                        if (rst)
                            delays[i][j] <= 0;
                        else
                            delays[i][j] <= data_in[i];
                    end
                end else begin
                    // Subsequent flip-flops in the row
                    always_ff @(posedge clk) begin
                        if (rst)
                            delays[i][j] <= 0;
                        else
                            delays[i][j] <= delays[i][j-1];
                    end
                end
            end
        end

        // Assign outputs from the last column of each row
        assign data_out[0] = data_in[0]; // First row output is directly from input
        for(i = 1; i < MAX_DELAY; i++) begin : gen_output
            // Assign outputs from the last column of each row
            assign data_out[i] = delays[i][i];
        end
    endgenerate

endmodule