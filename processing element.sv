module processing_element (
    input logic clk,
    input logic rst,
    input logic [31:0] inA,
    input logic [31:0] inB,

    output logic [31:0] outA,
    output logic [31:0] outB,
    output logic [31:0] outC
);

always_ff @(posedge clk) begin
    if (rst) begin
        outA <= 0;
        outB <= 0;
        outC <= 0;
    end else begin
        outA <= inA;
        outB <= inB;
        outC <= outC + (inA * inB);
    end
end
endmodule