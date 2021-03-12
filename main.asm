%include "util.asm"

global    _start

section   .data
message  db  "Hello, World", 10   

section   .text

    _start:   
        PRINT message
        
        EXIT                           

         