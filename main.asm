.include beta.uasm

|; Reg[Rc] <- Reg[Ra] mod Reg[Rb] (Rc should be different from Ra and Rb)
.macro MOD(Ra, Rb, Rc) DIV(Ra, Rb, Rc) MUL(Rc, Rb, Rc) SUB(Ra, Rc, Rc)

|; bootstrap
CMOVE(stack__, SP)
MOVE(SP, BP)
BR(main__)
STORAGE(13)

|; constants
rows = 8
cols = 32
nb_cells = rows * cols 
 
.macro FILL(v) {
	LONG(v) LONG(v) LONG(v) LONG(v)
	LONG(v) LONG(v) LONG(v) LONG(v)
}

.macro H_LINE() FILL(0xFFFFFFFF)
.macro V_LINE() FILL(0xC0C0C0C0)

.macro ROW() {
	H_LINE() H_LINE() V_LINE() V_LINE() 
	V_LINE() V_LINE() V_LINE() V_LINE() 
}

.macro MAZE() {
	ROW() ROW() ROW() ROW()
	ROW() ROW() ROW() ROW()
	H_LINE() H_LINE()
}

maze__:
	MAZE()

visited__:
	STORAGE(8)  |; 8 words saved for the visited bitmap

|; abs(a) 
|; Compute the absolute value of a
abs__: 
	PUSH(LP)
	PUSH(BP)
	MOVE(SP, BP)
	PUSH(R1)
	LD(BP, -12, R1)
	CMPLTC(R1, 0, R0)
	BF(R0, abs_positive__)
	MULC(R1, -1, R0)
	BR(abs_end__)

abs_positive__:
	MOVE(R1, R0)

abs_end__: 
	POP(R1)
	POP(BP)
	POP(LP)
	RTN()

|; main function
main__:
	|; load maze and visited pointers and maze size
	CMOVE(maze__, R1)
	CMOVE(rows, R2)
	CMOVE(cols, R3)
	CMOVE(visited__, R4)

	|; get random cell
	RANDOM()
	PUSH(R0)
	CALL(abs__)
	DEALLOCATE(1)
	MUL(R2, R3, R5)
	MOD(R0, R5, R6)

	|; create the perfect maze
	PUSH(R6)
	PUSH(R4)
	PUSH(R3)
	PUSH(R2)
	PUSH(R1)
	CALL(perfect_maze)
	DEALLOCATE(5)
	.breakpoint
	ADD(R31,R31,R31)
	HALT()
	

.include perfect_maze.asm

	|; check for 0xDEADCAFE in the memory explorer 
	|; to find the base of the stack
	LONG(0xDEADCAFE)
stack__:
	STORAGE(1024)