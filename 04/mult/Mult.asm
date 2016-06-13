// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Put your code here.

// Initialize M2 and M3 to 0.
@ARG
M=0
@THIS
M=0

(LOOP)
// Check if M3 has counted up to V1.
@SP // Set A to M0.
D=M // Set D to Memory[M0].
@THIS // Set A to M3.
D=D-M // Set D equal to D minus A (M3).
@END
D;JEQ // If D is equal to zero, jump to END.

// Add one V2 to itself and store in M2.
@ARG // Set A to M2.
D=M // Set D to Memory[M2].
@LCL // Set A to M1.
D=D+M // Set D to D + M.
@ARG // Set A to M2.
M=D // Put new value back into M.

// Increment M3 by 1.
@THIS
M=M+1

// Jump to beginning.
@LOOP
0;JMP

// Done.
(END)
@END
0;JMP // Infinite loop.
