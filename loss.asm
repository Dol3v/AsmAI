
; Different loss functions

%include "math.asm"

section .text

    ; Calculates the mean squared loss:
    ; MSE(y_pred, y_true) = \sum_i (y_true - y_pred)^2
    ;
    ; param %1: the predicted output
    ; param %2: the target output
    ; param %3: function's output
    ; param %4: xmm register of %3
    ; param %5: different xmm register
    ; returns: MSE in %3
    %macro MSE 5
        vsubpd %1,  %1, %2
        DOTPROD %3, %1, %1, %4, %5
    %endmacro
    