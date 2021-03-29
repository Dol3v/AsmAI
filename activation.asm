
; Contains all of the used activation functions

section .text

    ; Calculates the ReLu activation function:
    ; 
    ; ReLu(x) = max(x, 0)
    ;
    ; param %1: input/output
    ; param %2: helper
    %macro RELU 2
        vpxor %2, %2 ;zero helper
        vblendvpd %1, %1, %2, %1 ;if the sign bit is 1, the number is negative hence we move 0.0 to it
    %endmacro
