module counter #(
    parameter MAX = 12,
    parameter HALF_MAX = 6,
    parameter DEPTH = 4,
    parameter PISO_FULL = 8,
    parameter COUNT_WIDTH = 4
)(
    input logic clk,
    input logic rst_counter,
    input logic enable,
    output logic full,
    output logic count_A,
    output logic semi,
    output logic piso_full,
    output logic [COUNT_WIDTH-1:0] counter_out
);

    // Internal registers
    logic [COUNT_WIDTH-1:0] counter_reg;
    logic [COUNT_WIDTH-1:0] count_A_reg;

    // Counter logic
    always_ff @(posedge clk) begin
        if (rst_counter) begin

            counter_reg <= 0;
            count_A_reg <= 0;

        end else if (enable) begin

            if (counter_reg < MAX - 1) begin
                counter_reg <= counter_reg + 1;
            end else begin
                counter_reg <= 0;
                count_A_reg <= 0;
            end

            if(count_A_reg < DEPTH - 1) begin
                count_A_reg <= count_A_reg + 1;
            end else begin
                count_A_reg <= 0; // Reset count_A when it reaches DEPTH
            end

        end else begin

            counter_reg <= counter_reg; // Hold value if not enabled
            count_A_reg <= count_A_reg; // Hold value if not enabled

        end


    end


    // Assign outputs
    assign full = (counter_reg == MAX - 1);
    assign semi = (counter_reg == HALF_MAX - 1);
    assign piso_full = (counter_reg == PISO_FULL - 1);
    assign count_A = (count_A_reg == DEPTH - 1);
    assign counter_out = counter_reg;

endmodule