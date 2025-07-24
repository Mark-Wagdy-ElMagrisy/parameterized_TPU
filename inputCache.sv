module inputCache #(
    parameter A = 60000,
    parameter N = 256
)(
    input logic clk,
    input logic rst,

    input logic [31:0] data_in,
    input logic mem_enable,
    input logic wr_rd,

    input logic [15:0] sel_a,
    input logic [7:0] sel_n,

    output logic [31:0] data_out_mem [N-1:0]
);
    logic [31:0] bufferA_mem [A-1:0][N-1:0]; // Memory for buffer A

    // Write or read from the memory based on wr_rd signal
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset memory
            for (int i = 0; i < A; i++) begin
                for (int j = 0; j < N; j++) begin
                    bufferA_mem[i][j] <= 0;
                end
            end
        end else if (mem_enable) begin
            if (wr_rd) begin
                // Write operation
                bufferA_mem[sel_a][sel_n] <= data_in;
            end else begin
                // Read operation
                data_out_mem <= bufferA_mem[sel_a];
                bufferA_mem[sel_a][sel_n] <= bufferA_mem[sel_a][sel_n];
            end
        end else begin
            bufferA_mem[sel_a][sel_n] <= bufferA_mem[sel_a][sel_n];
        end
        end
endmodule