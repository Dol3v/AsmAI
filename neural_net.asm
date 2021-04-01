
; Functions that affect the whole neural network.

%include "util.asm"

; Defines a four-layered network.
; 
; All four parameters define the size of the different layers:
; param 1: number of input values, divided by 4
; param 2: number of values in first hidden layer, divided by 4
; param 3: number of values in second hidden layer, divided by 4
; Number of outputs is constant and equal to two.
%macro BINARY_NEURAL_NET 3
    times %1*4*YMM_BYTE_LENGTH dq 0 ;input layer
    times %1*4*YMM_BYTE_LENGTH*%2*4 dq 0 ;weights
    times %2*4*YMM_BYTE_LENGTH dq 0 ;biases
    times %2*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

    times %2*4*YMM_BYTE_LENGTH dq 0 ;first hidden layer inputs
    times %2*4*YMM_BYTE_LENGTH*%3*4 dq 0 ;weights
    times %3*4*YMM_BYTE_LENGTH dq 0 ;biases
    times %3*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

    times %3*4*YMM_BYTE_LENGTH dq 0 ;output layer inputs
    times %3*4*YMM_BYTE_LENGTH*2 dq 0 ;weights
    times 2*YMM_BYTE_LENGTH dq 0 ;outputs, without activation
    times 2*YMM_BYTE_LENGTH dq 0 ;neural net output
%endmacro
