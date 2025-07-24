module TPU #(
    parameter int A = 4,
    parameter M = 4,
    parameter N = 4

)(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic valid,
    input logic [31:0] data_in,
    output logic ready,
    output logic err,
    output logic done,
    output logic [31:0] data_out);

    // Internal signals
    logic mem_enableA;
    logic wr_rd_A;
    logic [15:0] selA_a;
    logic [7:0] selA_n;

    logic mem_enableB;
    logic wr_rd_B;
    logic [15:0] selB_a;
    logic [7:0] selB_m;

    logic send;
    logic [7:0] selO_n;
    logic [7:0] selO_m;

    logic [31:0] data_in_bufA;
    logic [31:0] data_in_bufB;
    logic [31:0] data_outA [N-1:0];
    logic [31:0] data_outB [M-1:0];
    logic [31:0] data_outdA [N-1:0];
    logic [31:0] data_outdB [M-1:0];
    logic [31:0] data_out_parallel [N-1:0][M-1:0];


    //intantiations
    controller #(
        .A(A),
        .M(M),
        .N(N)
    ) controller_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .valid(valid),
        .data_in(data_in),

        .ready(ready),
        .err(err),
        .done(done),

        .selA_a(selA_a),
        .selA_n(selA_n),
        .wr_rd_A(wr_rd_A),
        .mem_enableA(mem_enableA),

        .selB_a(selB_a),
        .selB_m(selB_m),
        .wr_rd_B(wr_rd_B),
        .mem_enableB(mem_enableB),


        .send(send),
        .selO_n(selO_n),
        .selO_m(selO_m)
    );

    inputCache #(
        .A(A),
        .N(N)
    ) bufferA (
        .clk(clk),
        .rst(rst),

        .data_in(data_in_bufA),
        .mem_enable(mem_enableA),
        .wr_rd(wr_rd_A),

        .sel_a(selA_a),
        .sel_n(selA_n),

        .data_out_mem(data_outA)
    );

    inputCache #(
        .A(A),
        .N(M)
    ) bufferB (
        .clk(clk),
        .rst(rst),

        .data_in(data_in_bufB),
        .mem_enable(mem_enableB),
        .wr_rd(wr_rd_B),

        .sel_a(selB_a),
        .sel_n(selB_m),

        .data_out_mem(data_outB)
    );

    delay #(
        .MAX_DELAY(N)
    ) delay_instA (
        .clk(clk),
        .rst(rst),
        .data_in(data_outA),
        .data_out(data_outdA)
    );

    delay #(
        .MAX_DELAY(M)
    ) delay_instB (
        .clk(clk),
        .rst(rst),
        .data_in(data_outB),
        .data_out(data_outdB)
    );


    systolic_array #(
        .M(M),
        .N(N)
    ) systolic_array_inst (
        .clk(clk),
        .rst(rst),

        .data_inA(data_outdA),
        .data_inB(data_outdB),

        .array_out(data_out_parallel)
    );

    PISO #(
        .M(M),
        .N(N)
    ) PISO_inst (
        .clk(clk),
        .rst(rst),

        .send(send),
        .data_in(data_out_parallel),
        .selO_n(selO_n),
        .selO_m(selO_m),

        .data_out(data_out)
    );
endmodule