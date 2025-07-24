# Systolic Array Project

This project implements a systolic array architecture for matrix operations, including a controller and supporting modules in SystemVerilog.

## Project Structure

- [`controller.sv`](controller.sv): Main controller module for managing state transitions, error checking, and interfacing with buffers and PISO.
- [`counter.sv`](counter.sv): Counter module used for sequencing operations in the controller.
- [`delay.sv`](delay.sv): Delay logic for timing control.
- [`inputCache.sv`](inputCache.sv): Input buffer/cache for incoming data.
- [`PISO.sv`](PISO.sv): Parallel-In Serial-Out module for output serialization.
- [`processing_element.sv`](processing_element.sv): Core processing element for matrix computations.
- [`systolic_array.sv`](systolic_array.sv): Top-level systolic array module integrating all components.
- [`TPU.sv`](TPU.sv): Top-level module for the TPU (Tensor Processing Unit) system.
- `documentation`(documentation): check the documentation folder for schematic and more info

## Main Features

- **Controller**: Handles state transitions (IDLE, DIMENSIONS, ERROR, LOAD, PAUSE, PROCESS, SEND, WAIT) and coordinates matrix loading, processing, and output.
- **Error Checking**: Validates input dimensions and signals errors.
- **Buffer Management**: Controls read/write operations to matrix buffers A and B.
- **PISO Output**: Manages serialization of output data.
- **Counter Logic**: Sequences matrix operations and transitions between states.

## Usage

1. **Simulation**: Use ModelSim/Questa or compatible simulator. Compile all `.sv` files in the project.
2. **Top-Level Module**: Instantiate [`TPU.sv`](TPU.sv) or [`systolic_array.sv`](systolic_array.sv) for system-level simulation.
3. **Inputs**:
    - `rst`: Active-high reset.
    - `clk`: Clock signal.
    - `enable`: Start operation.
    - `valid`: Data ready for processing.
    - `data_in`: 32-bit input data (dimensions encoded).
4. **Outputs**:
    - `err`: Error signal.
    - `ready`: Controller ready for next operation.
    - `done`: Operation complete.

## State Machine (Controller)

- **IDLE**: Waits for `enable` and `valid`.
- **DIMENSIONS**: Latches matrix dimensions from `data_in`.
- **ERROR**: Signals error if dimensions are invalid.
- **LOAD**: Loads matrix data into buffers.
- **PAUSE**: Waits if `enable` or `valid` is low.
- **PROCESS**: Performs matrix computation.
- **SEND**: Sends output data via PISO.
- **WAIT**: Waits for `enable` to resume sending.

For more details, see the comments in each module file.

## Idea of Operation

A systolic array is a 2D grid of Processing Elements (PEs) that compute and pass data in a rhythmic, pipelined fashion. Each PE performs multiply-accumulate (MAC): acc += a * b Data flows in from the edges and is passed from PE to PE Intermediate results are accumulated within the PEs.

![Systolic array operation](/documentation/systolic%20array.jpg)
[Image source](https://www.researchgate.net/figure/A-3-3-systolic-array-for-matrix-multiplication_fig1_380392345)
