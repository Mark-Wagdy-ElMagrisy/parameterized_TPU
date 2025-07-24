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
    wire [31:0] outsA [N-1:0];
    wire [31:0] outsB [M-1:0];
        genvar i,j;
        generate
            for (i = 0; i < N; i++) begin
                for(j=0; j < M; j++) begin
                    if (i==0 && j==0) begin
                        // First processing element
                        processing_element pe_inst (
                            .clk(clk),
                            .rst(rst),
                            .inA(data_inA[i]),
                            .inB(data_inB[j]),

                            .outA(outsA[i]),
                            .outB(outsB[j]),
                            .outC(array_out[i][j])
                        );
                    end
                    else if(i==0) begin
                        processing_element pe_inst (
                            .clk(clk),
                            .rst(rst),
                            .inA(outsA[i-1]),
                            .inB(data_inB[j]),
    
                            .outA(outsA[i]),
                            .outB(outsB[j]),
                            .outC(array_out[i][j])
                        );
                    end
                    else if(j==0) begin
                        processing_element pe_inst (
                            .clk(clk),
                            .rst(rst),
                            .inA(data_inA[i]),
                            .inB(outsB[j-1]),

                            .outA(outsA[i]),
                            .outB(outsB[j]),
                            .outC(array_out[i][j])
                        );
                    end
                    else begin
                        processing_element pe_inst (
                            .clk(clk),
                            .rst(rst),
                            .inA(outsA[i-1]),
                            .inB(outsB[j-1]),

                            .outA(outsA[i]),
                            .outB(outsB[j]),
                            .outC(array_out[i][j])
                        );
                    end
                end
            end
        endgenerate

endmodule