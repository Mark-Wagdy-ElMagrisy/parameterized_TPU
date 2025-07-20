//change enable to valid
//add ready state like pause while sending
module controller #(
    parameter int A = 60000, // Dimension A
    parameter int M = 256,  // Dimension M
    parameter int N = 256   // Dimension N
)(
    input logic rst,    // Active-high reset
    input logic clk,    // Clock signal

    //interface with the outside world
    input logic enable,                 // Enable signal to start the operation
    input logic valid,                  // Valid signal to indicate data is ready for processing
    input logic signed [31:0] data_in,  // Input data
    output logic err,                   // Error signal to indicate any issues
    output logic ready,                 // Ready signal to indicate the controller is ready for the next operation
    output logic done,                  // Done signal to indicate the operation is complete

    
    //signals to bufferA
    output logic [15:0] selA_a,         // Select signal for matrix A (a dimension)
    output logic [7:0] selA_n,          // Select signal for matrix A (n dimension)
    output logic wr_rd_A,               // Write(1)/Read(0) signal for buffer A
    output logic mem_enableA,           //memory A is currently selected
    
    //signals to bufferB
    output logic [15:0] selB_a,         // Select signal for matrix B (a dimension)
    output logic [7:0] selB_m,          // Select signal for matrix B (m dimension)
    output logic wr_rd_B,               // Write(1)/Read(0) signal for buffer B
    output logic mem_enableB,           // memory B is currently selected

    //signals to PISO
    output logic send,                  // Send signal to PISO
    output logic [7:0] selO_n,          // Select signal for output matrix (n dimension)
    output logic [7:0] selO_m           // Select signal for output matrix (m dimension)
);

    //======================================================
    // Internal signals
    //======================================================
    //dimension registers
    logic [15:0] a_latch;
    logic [7:0] n_latch;
    logic [7:0] m_latch;
    logic err_sig, errA, errN, errM; // Error signal for internal processing
    logic A_done;


    //=======================================================
    //counter and counter signals
    //=======================================================
    logic rst_counter, enable_counter, load_counter;
    logic [31:0] counter_in, subcounter_in;
    logic [31:0] counter_out, subcounter_out;
    
    counter counter_inst (
        .clk(clk),
        .rst_counter(rst_counter),
        .enable(enable_counter),
        .load(load_counter), // Load signal to load the counter with a value
        
        .load_value(counter_in), // Load value for the counter
        .counter_full(counter_full), // Signal to indicate if the counter is full
        .counter_out(counter_out), // Current value of the counter
        
        .load_subvalue(subcounter_in), // Value to load into the sub
        .subcounter_full(subcounter_full), // Signal to indicate if the subcounter is full
        .subcounter_out(subcounter_out) // Current value of the subcounter
        );
        
        
        
        //=======================================================
        // State encoding
        //=======================================================
        localparam IDLE = 3'b000;       // Initial state
        localparam DIMENSIONS = 3'b001; // State for setting dimensions
        localparam ERROR = 3'b010;      // Error state
        localparam LOAD = 3'b011;      // State for loading matrix A
        localparam PAUSE = 3'b100;      // Updated state for pause functionality
        localparam PROCESS = 3'b101;    // State for processing data
        localparam SEND = 3'b110;       // State for sending data
        localparam WAIT = 3'b111;       // State for waiting while sending data
        
        // State transition logic
    logic [3:0] current_state, next_state;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end



    //=======================================================
    // Next state logic
    //=======================================================
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                if (enable && valid) begin
                    next_state <= DIMENSIONS;
                end else begin
                    next_state <= IDLE;
                end
            end
            DIMENSIONS: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (err_sig || !enable) begin
                    next_state <= ERROR; // Transition to ERROR state when there's error
                end else begin
                    next_state <= LOAD; // transition to LOAD state after one cycle and no error
                end
            end
            ERROR: begin
                    next_state <= IDLE; // Reset state
            end
            LOAD: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if(!enable || !valid) begin
                    next_state <= PAUSE; // Transition to PAUSE state if enable is low
                end else if (counter_full && A_done) begin
                    next_state <= PROCESS;
                end else begin
                    next_state <= LOAD; // Stay in LOAD state until counter is full
                end
            end
            PAUSE: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (enable) begin
                    next_state <= LOAD;
                end else begin
                    next_state <= PAUSE;
                end
            end
            PROCESS: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (subcounter_full) begin
                    next_state <= SEND; // Transition to SEND state when op_counter is high
                end else begin
                    next_state <= PROCESS;
                end
            end
            SEND: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if(!enable) begin
                    next_state <= WAIT; // Transition to WAIT state if enable is low
                end else if (counter_full) begin
                    next_state <= IDLE; // Transition to IDLE state when rst_piso is high
                end else begin
                    next_state <= SEND; // Stay in SEND state until rst_piso is asserted
                end
            end
            WAIT: begin
                if (rst) begin
                    next_state <= IDLE; // Reset state
                end else if (enable) begin
                    next_state <= SEND; // Transition back to SEND state when ready
                end else begin
                    next_state <= WAIT; // Stay in WAIT state until enable is asserted
                end
            end
            default: begin
                next_state <= IDLE;
            end
        endcase
    end

    // Output logic
    assign errA = (data_in[31:16] > A) || (data_in[31:16] == 0);  // Check if A is within valid range
    assign errM = (data_in[15:8] > M) || (data_in[15:8] == 0);    // Check if M is within valid range
    assign errN = (data_in[7:0] > N) || (data_in[7:0] == 0);      // Check if N is within valid range
    assign err_sig = errA || errN || errM;

    always @(*) begin
        case (current_state)
            IDLE: begin
                err = 1'b0;
                ready = 1'b1;
                done = 1'b0;

                //signals to bufferA
                selA_a = 1'b0;
                selA_n = 1'b0;
                wr_rd_A = 1'b0;
                mem_enableA = 1'b0;

                //signals to bufferB
                selB_a = 1'b0;
                selB_m = 1'b0;
                wr_rd_B = 1'b0;
                mem_enableA = 1'b0;
            
                //signals to PISO
                send = 1'b0;
                selO_n = 1'b0;
                selO_m = 1'b0;

                //inputs to counter
                rst_counter = 1'b1;
                enable_counter = 1'b0;
                load_counter = 1'b0;
                counter_in = 0;
                subcounter_in = 0;

                A_done = 0;
            end
            DIMENSIONS: begin

                if(!err_sig) begin
                    a_latch = data_in[23:16] - 1; // Set dimension A
                    m_latch = data_in[15:8] - 1;  // Set dimension M
                    n_latch = data_in[7:0] - 1;   // Set dimension N

                    //inputs to counter to prep for load A
                    rst_counter = 1'b0;
                    enable_counter = 1'b0;
                    load_counter = 1'b1;
                    counter_in = n_latch;
                    subcounter_in = a_latch;
                end else begin
                    a_latch = 0; // Reset dimensions if error
                    m_latch = 0;
                    n_latch = 0;
                end
            end
            ERROR: begin
                err = 1'b1;
                ready = 1'b0;
                done = 1'b0;

                //signals to bufferA
                selA_a = 1'b0;
                selA_n = 1'b0;
                wr_rd_A = 1'b0;
                mem_enableA = 1'b0;

                //signals to bufferB
                selB_a = 1'b0;
                selB_m = 1'b0;
                wr_rd_B = 1'b0;
                mem_enableB = 1'b0;

                //signals to PISO
                send = 1'b0;
                selO_n = 1'b0;
                selO_m = 1'b0;

                //inputs to counter
                rst_counter = 1'b1;
                enable_counter = 1'b0;
                load_counter = 1'b0;
                counter_in = 0;
                subcounter_in = 0;
            end
            LOAD: begin
                err = 1'b0;
                ready = 1'b1;
                done = 1'b0;

                //signals to PISO
                send = 1'b0;
                selO_n = 1'b0;
                selO_m = 1'b0;
                if(A_done && counter_full) begin    //prep for PROCESS
                    rst_counter = 1'b1;
                    enable_counter = 1'b0;
                    load_counter = 1'b1;
                    subcounter_in = n_latch + m_latch + a_latch - 2;
                    counter_in = 1'b1;
                end
                else if (!A_done && counter_full) begin    //prep for B
                    rst_counter = 1'b1;
                    enable_counter = 1'b0;
                    load_counter = 1'b1;
                    counter_in = a_latch;
                    subcounter_in = m_latch;

                    //specify that A is finished in next cycle
                    A_done = 1'b1;
                end
                else if(A_done) begin       //matrix B is selected
                    //signals to bufferA
                    selA_a = 1'b0;
                    selA_n = 1'b0;
                    wr_rd_A = 1'b0;
                    mem_enableA = 1'b0;
                    
                    //signals to bufferB
                    selB_a = counter_out[15:0];
                    selB_m = subcounter_out[7:0];
                    wr_rd_B = 1'b1;
                    mem_enableB = 1'b1;
                    
                    //signals to counter
                    rst_counter = 1'b0;
                    enable_counter = 1'b1;
                    load_counter = 1'b0;
                end else begin              //matrix A is selected
                    //signals to bufferA
                    selA_a = subcounter_out[15:0];
                    selA_n = counter_out[7:0];
                    wr_rd_A = 1'b1;
                    mem_enableA = 1'b1;
                    mem_enableB = 1'b0;
                    
                    //signals to bufferB
                    selB_a = 1'b0;
                    selB_m = 1'b0;
                    wr_rd_B = 1'b0;
                    
                    //signals to counter
                    rst_counter = 1'b0;
                    enable_counter = 1'b1;
                    load_counter = 1'b0;
                end

            end
            PAUSE: begin
                err = 1'b0;
                ready = 1'b1;
                done = 1'b0;
                
                //inputs to counter
                rst_counter = 1'b0;
                enable_counter = 1'b0;
                load_counter = 1'b0;
                
                //signals to PISO
                send = 1'b0;
                selO_n = 1'b0;
                selO_m = 1'b0;
                
                wr_rd_A = 1'b0;
                wr_rd_B = 1'b0;
                mem_enableA = 1'b0;
                mem_enableB = 1'b0;
            end
            PROCESS: begin
                if(counter_full) begin  //prep to send
                    rst_counter = 1'b1;
                    enable_counter = 1'b0;
                    load_counter = 1'b1;
                    subcounter_in = m_latch;
                    counter_in = n_latch;
                end else begin
                    rst_counter = 1'b0;
                    enable_counter = 1'b1;
                    load_counter = 1'b0;
                end

                err = 1'b0;
                ready = 1'b0;
                done = 1'b0;
                mem_enableA = 1'b1;
                mem_enableB = 1'b1;

                //signals to PISO
                send = 1'b0;
                selO_n = 1'b0;
                selO_m = 1'b0;

                //signals to bufferA
                selA_a = subcounter_out[15:0];
                wr_rd_A = 1'b0;

                //signals to bufferB
                selB_a = subcounter_out[15:0];
                wr_rd_B = 1'b0;

                A_done = 0;
            end
            SEND: begin
                err = 1'b0;
                ready = 1'b0;
                done = 1'b0;
                
                //signals to bufferA
                selA_a = 1'b0;
                selA_n = 1'b0;
                wr_rd_A = 1'b0;
                mem_enableA = 1'b0;
                
                //signals to bufferB
                selB_a = 1'b0;
                selB_m = 1'b0;
                wr_rd_B = 1'b0;
                mem_enableB = 1'b0;
            
                //signals to PISO
                send = 1'b1;
                selO_m = subcounter_out[7:0];
                selO_n = counter_out[7:0];

                //inputs to counter
                rst_counter = 1'b0;
                enable_counter = 1'b1;
                load_counter = 1'b0;
            end
            WAIT: begin
                err = 1'b0;
                ready = 1'b0;
                done = 1'b0;

                //signals to bufferA
                selA_a = 1'b0;
                selA_n = 1'b0;
                wr_rd_A = 1'b0;
                mem_enableA = 1'b0;

                //signals to bufferB
                selB_a = 1'b0;
                selB_m = 1'b0;
                wr_rd_B = 1'b0;
                mem_enableB = 1'b0;
            
                //signals to PISO
                send = 1'b0;
                selO_m = subcounter_out[7:0];
                selO_n = counter_out[7:0];

                //inputs to counter
                rst_counter = 1'b0;
                enable_counter = 1'b0;
                load_counter = 1'b0;
            end
        endcase
    end

endmodule