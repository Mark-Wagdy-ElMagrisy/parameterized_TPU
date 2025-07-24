module systolic_array #(
        parameter M = 256,
        parameter N = 256
    )(
        input logic clk,
        input logic rst,

        input wire logic [31:0] data_inA [N-1:0],
        input wire logic [31:0] data_inB [M-1:0],

        output wire logic [31:0] array_out [N-1:0][M-1:0]
    );

    // Internal signals
    wire [31:0] outsA [N-1:0][M-1:0];
    wire [31:0] outsB [M-1:0][M-1:0];
        genvar i, j;
generate
  for (i = 0; i < N; i++) begin : row_gen
    for (j = 0; j < M; j++) begin : col_gen
      processing_element pe0 (
        .clk(clk),
        .rst(rst),
        .inA((j == 0) ? data_inA[i] : outsA[i][j-1]),
        .inB((i == 0) ? data_inB[j] : outsB[i-1][j]),
        .outA(outsA[i][j]),
        .outB(outsB[i][j]),
        .outC(array_out[i][j])
      );
    end
  end
endgenerate

endmodule