//change enable to valid
//add ready state like pause while sending
module controller (
    input logic rst,
    input logic clk,
    input logic enable,

    //signlas to shift registers
    output logic [$clog2(M)-1:0] selB,
    output logic [$clog2(M)-1:0] selA,
    output logic load,

    //signals to PISO
    output logic send,
    output logic rst_piso
);

    parameter N = 3;    //matrix A N*A, matrix B A*M
    parameter M = 3;
    parameter A = 4;

    localparam max = (M * A > N * A) ? M * A : N * A; // Maximum count value
    localparam count_width = (max == 0) ? 1 : $clog2(max + 1); // Width of the counter
    localparam half_max = N + M; // Half of the maximum count value
    localparam PISO_FULL = M * N; // Full count for PISO

    logic [2:0] current_state, next_state;
    logic counter_full, semi_counter, count_A, piso_full;
    logic rst_counter, enable_counter;
    logic [count_width-1:0] counter_out;

    counter #(
        .MAX(max),
        .HALF_MAX(half_max),
        .DEPTH(A),
        .PISO_FULL(PISO_FULL)
    ) counter_inst (
        .clk(clk),
        .rst_counter(rst_counter),
        .enable(enable_counter),
        .full(counter_full),            //counts till max(M*A-1, N*A-1)
        .count_A(count_A),              //counts till A for matrix A input rows
        .semi(semi_counter),            //counts till N+M
        .piso_full(rst_piso),              // counts till M*N
        .counter_out(counter_out)       // output for counter
    );


    // State encoding
    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam PAUSE = 3'b010; // New state for pause functionality
    localparam PROCESS = 3'b011;
    localparam SEND = 3'b100;


    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                if (enable) begin
                    next_state <= LOAD;
                end else begin
                    next_state <= IDLE;
                end
            end
            LOAD: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if(!enable) begin
                    next_state <= PAUSE; // Transition to PAUSE state if enable is low
                end else if (counter_full) begin
                    next_state <= PROCESS;
                end else begin
                    next_state <= LOAD;
                end
            end
            PAUSE: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (enable) begin
                    next_state <= LOAD; // Stay in PAUSE state if enable is low
                end else begin
                    next_state <= PAUSE;
                end
            end
            PROCESS: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (semi_counter) begin
                    next_state <= SEND; // Transition to SEND state when semi_counter is high
                end else begin
                    next_state <= PROCESS;
                end
            end
            SEND: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (rst_piso) begin
                    next_state <= IDLE; // Transition to IDLE state when rst_piso is high
                end else begin
                    next_state <= SEND; // Stay in SEND state until rst_piso is asserted
                end
            end
            default: begin
                next_state <= IDLE;
            end
        endcase
    end

    // Output logic
    always @(*) begin

        case (current_state)
        IDLE: begin
                selB = 2'b00;
                selA = 2'b00;
                load = 1'b0;
                send = 1'b0;
                rst_piso = 1'b1;

                rst_counter = 1'b1; // Reset counter in IDLE state
                enable_counter = 1'b0; // Disable counter in IDLE state
            end
            LOAD: begin
                selB = count_width[$clog2(M)-1:0];
                selA = (count_A==1) ? (selA + count_A) : selA; // Increment selA when count_A is high
                load = 1'b1;
                send = 1'b0;
                rst_piso = 1'b1;
                enable_counter = 1'b1; // Enable counter in LOAD state

                if(counter_full) begin
                    rst_counter = 1'b1; // Reset counter when full
                end else begin
                    rst_counter = 1'b0; // Do not reset counter otherwise
                end
            end
            PAUSE: begin
                selB = 0; // Reset selB for processing
                selA = 0; // Reset selA for processing
                load = 1'b0;
                send = 1'b0;
                rst_piso = 1'b1;

                enable_counter = 1'b0; // Disable counter in PAUSE state
                rst_counter = 1'b0; // Do not reset counter in PAUSE state
            end
            PROCESS: begin
                selB = 0; // Reset selB for processing
                selA = 0; // Reset selA for processing
                load = 1'b0;
                send = 1'b0;
                rst_piso = 1'b1;
                enable_counter = 1'b1; // Enable counter in PROCESS state

                if(semi_counter) begin
                    rst_counter = 1'b1; // Reset counter when semi_counter is high
                end else begin
                    rst_counter = 1'b0; // Do not reset counter otherwise
                end
            end
            SEND: begin
                selB = 0; // Reset selB for processing
                selA = 0; // Reset selA for processing
                load = 1'b0;
                send = 1'b1;
                enable_counter = 1'b1; // Enable counter in SEND state

                if(rst_piso) begin
                    rst_counter = 1'b1; // Reset counter when rst_piso is high
                end else begin
                    rst_counter = 1'b0; // Do not reset counter otherwise
                end
            end
        endcase
    end

endmodule