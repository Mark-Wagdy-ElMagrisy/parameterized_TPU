# Matrix Multiplication Using Systolic Arrays

## Overview
Matrix multiplication is a key operation in many scientific, signal processing, and machine learning applications. Systolic arrays offer a highly parallel and pipelined architecture optimized for such workloads—especially in deep learning accelerators like Google's TPU.

---

## Matrix Multiplication Algorithm

Given:
- Matrix **A**: size `M × K`
- Matrix **B**: size `K × N`
- Result **C = A × B**: size `M × N`

Each element in C is computed as:

```mathematica
C[i][j] = Σ (A[i][k] × B[k][j]) for k = 0 to K - 1
```

## Systolic arrays

A systolic array is a 2D grid of Processing Elements (PEs) that compute and pass data in a rhythmic, pipelined fashion. Each PE performs multiply-accumulate (MAC): acc += a * b Data flows in from the edges and is passed from PE to PE Intermediate results are accumulated within the PEs.

## Architecture for Matrix Multiplication

Assume: Matrix A streamed row-wise from the left Matrix B streamed column-wise from the top Matrix C is computed inside the PEs Layout: 

```css Copy Edit
          B[0][0]  B[0][1]  ...  B[0][M-1]
          B[1][0]  B[1][1]  ...  B[1][M-1]
             ↓       ↓             ↓
A[0][0] →  [PE] → [PE] → ... → [PE] → C[0][:]
A[1][0] →  [PE] → [PE] → ... → [PE] → C[1][:]
   ...      ...       ...      ...
A[N-1][0]→ [PE] → [PE] → ... → [PE] → C[N-1][:]
             ↓       ↓             ↓
           C[:][0]  C[:][1]  ...  C[:][N-1]
```

B flows vertically down columns Each PE at (i, j) computes partial sum for C[i][j]

## PE (Processing Element) Operation

Each PE does the following per clock cycle: 
```verilog Copy Edit
// Pseudocode
input: a_in, b_in, partial_sum_in
output: a_out, b_out, partial_sum_out
partial_sum = partial_sum_in + a_in * b_in
a_out = a_in // forward to next PE in row
b_out = b_in // forward to next PE in column a_in and b_in are local inputs from left and top PEs.
```
partial_sum is the accumulated result

## Dataflow Timing

Assuming an MxN systolic array:
It takes K + M + N - 2 cycles to fully load and compute the result. After the "wavefront" of data fills the array, one output value is produced per clock cycle

## Images
![Systolic array operation](systolic%20array.jpg)
[Image source](https://www.researchgate.net/figure/A-3-3-systolic-array-for-matrix-multiplication_fig1_380392345)
