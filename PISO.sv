module PISO #(
    parameter M = 256,
    parameter N = 256
)(
    input logic clk,
    input logic rst,

    input logic send,
    input wire logic [31:0] data_in [N-1:0][M-1:0],
    input logic [7:0] selO_n,
    input logic [7:0] selO_m,
    
    output logic [31:0] data_out
);

    always_ff @( posedge clk ) begin
        if (rst) begin
            data_out <= 32'b0;
        end else if (send) begin
            data_out <= data_in[selO_n][selO_m];
        end else begin
            data_out <= data_out;
        end
    end
endmodule