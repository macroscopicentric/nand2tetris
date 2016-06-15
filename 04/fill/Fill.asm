// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input. 
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel. When no key is pressed, the
// program clears the screen, i.e. writes "white" in every pixel.

// Put your code here.

// Initialize the current pixel offset to 0.
@SP
M=0

// Main logic of program.
(MAINLOOP)
@KBD
D=M
@BLKSCRN
D;JNE
@WHTSCRN
D;JEQ

// Blackening loop.
(BLKSCRN)
@SP
D=M
@SCREEN
A=D+A
M=-1

@SP // Check if @SP (my pixel offset counter) is at the end of the screen, bc don't want to increment it above that.
D=M
@131072
D=A-D
@MAINLOOP
D;JEQ

@SP
M=M+1
@MAINLOOP
0;JMP

// Clearing loop.
(WHTSCRN)
@SP
D=M
@SCREEN
A=D+A
M=0

@SP // Check if @SP (my pixel offset counter) is zero, bc don't want to increment it below that.
D=M
@MAINLOOP
D;JEQ

@SP
M=M-1
@MAINLOOP
0;JMP
