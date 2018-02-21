	
|;*******************************CONSTANTS***********************************************************
nb_rows = 8
nb_cols = 32
nb_cells = 256
words_per_mem_line = 8
mem_lines_per_row = 8
words_per_row = 64
nb_maze_words = 512
cells_per_word = 4


OPEN_V_0:
 LONG(0xFFFFFF00)
OPEN_V_1:
 LONG(0xFFFF00FF)
OPEN_V_2:
 LONG(0xFF00FFFF)
OPEN_V_3:
 LONG(0x00FFFFFF)
OPEN_H_0:
 LONG(0xFFFFFFE1)
OPEN_H_1:
 LONG(0xFFFFE1FF)
OPEN_H_2:
 LONG(0xFFE1FFFF)
OPEN_H_3:
 LONG(0xE1FFFFFF)
|;*********************************************************************************************************


|;***********************************MACROS*****************************************************************

|;Reg[Rc] <- Reg[Ra] mod <CC>. 
.macro MODC(Ra, CC, Rc) DIVC(Ra, CC, Rc) MULC(Rc, CC, Rc) SUB(Ra, Rc, Rc)

|;Swap the values stored at addresses a and b.
.macro SWAP(Ra,Rb,Rc) MOVE(Ra,Rc) MOVE(Rb,Ra) MOVE(Rc,Rb)

|;Returns the row of the cell at given index Ra.  Reg[Rc] <- Reg[Ra] / Reg[Rb]
.macro ROW_FROM_INDEX(Ra,Rb,Rc) DIV(Ra,Rb,Rc)

|;Returns the column of the cell at given index Ra. Reg[Rc] <- Reg[Ra] mod Reg[Rc]. Registers must be different. 
.macro COL_FROM_INDEX(Ra,Rb,Rc) MOD(Ra,Rb,Rc)

|; Initialisation for the function start.
.macro INIT() PUSH(LP) PUSH(BP) MOVE(SP,BP)

|; End sequence for the function 
.macro END() MOVE(BP,SP) POP(BP) POP(LP) RTN()
|;**********************************************************************************************************


|;*****************************PERFECT_MAZE FONCTION********************************************************
|; 
|; Creates a perfect maze, i.e. one without any loops or closed circuits, and without any inaccessible areas.
|;
|; ARGUMENTS: 
|; - a pointer to the first element of the maze
|; - the number of rows in the maze
|; - the number of columns in the maze
|; - a pointer to the bitmap showing which cells were visited
|; - a random cell from which the maze construction should start
|;
|; RETURN : nothing
|;
|;************************************************************************************************************
perfect_maze:
	INIT()

	|;Save on the stack the value of the registers we'll use in the function
	PUSH(R1) 
	PUSH(R2)
	PUSH(R3)
	PUSH(R4)
	PUSH(R5)
	PUSH(R6)
	PUSH(R7)
	PUSH(R8)
	PUSH(R9)
	
	|;Load the values we put in the stack in the registers
	LD(BP,-12,R1) |;maze --> R1
	LD(BP,-16,R2) |;nb_rows --> R2
	LD(BP,-20,R3) |;nb_cols --> R3
	LD(BP,-24,R4) |;visited --> R4
	LD(BP,-28,R5) |;curr_cell --> R5

 	|;Update the bitmap by putting 1 in the cell that is visited
	CMOVE(1,R6)
	MODC(R5,32,R8)	|;curr_cell % 32 --> R8
	SHL(R6,R8,R6)	|;shift 1 (<R6>) left by <R8> bits
	DIVC(R5,32,R8)	|;curr_cell/32 --> R8
	MULC(R8,4,R8)	|;R8 * 4 --> R8 (to get the offset)
	ADD(R8,R4,R8)	|;visited (R4) + offset (R8) --> R8
	LD(R8,0,R9)		|;visited[curr_cell /32] --> R9
	OR(R9,R6,R6)	|;put 1 in the curr_cell if not visited yet (OR)
	ST(R6,0,R8)	|;put the updated visited back
	
	COL_FROM_INDEX(R5,R3,R8)	|; col --> R8
	CMOVE(0,R9) 				|; n_valid_neighbours = 0


|;Check left neighbour
checkLeft: 
	CMPLEC(R8,0,R6)		|;if (col <= 0) -> jump at checkRight
	BT(R6,checkRight)
	SUBC(R5,1,R6)		|;curr_cell-1 --> R6
	PUSH(R6)			|;save R6 in the stack
	ADDC(R9,1,R9)		|;n_valid_neighbours++ --> R9


|;Check right neighbour
checkRight:
	SUBC(R3,1,R6)	|;nb_cols-1  --> R6
	CMPLT(R8,R6,R6) |;if (col < nb_cols-1) -> jump at checkTop
	BF(R6,checkTop)
	ADDC(R5,1,R6)	|;curr_cell+1 --> R6
	PUSH(R6)		|;save R6 in the stack
	ADDC(R9,1,R9) 	|;n_valid_neighbours++ --> R9


|;Check top neighbour
checkTop:	
	ROW_FROM_INDEX(R5,R3,R8) |; row --> R8

	CMPLEC(R8,0,R6) 	|;if (row <= 0) -> jump at checkBottom
	BT(R6,checkBottom)
	SUB(R5,R3,R6) 		|;curr_cell-nb_cols --> R6
	PUSH(R6)			|;save R6 in the stack
	ADDC(R9,1,R9) 		|;n_valid_neighbours++ --> R9


|;Check bottom neighbour
checkBottom:
	SUBC(R2,1,R6) 		|;nb_rows-1 --> R6
	CMPLT(R8,R6,R6) 	|;if (row < nb_rows-1) -> jump at while_loop
	BF(R6,while_loop)
	ADD(R5,R3,R6) 		|;curr_cell+nb_cols --> R6
	PUSH(R6)			|;save R6 in the stack
	ADDC(R9,1,R9) 		|;n_valid_neighbours++ --> R9


while_loop:
	|;Loop condition
	CMPLEC(R9,0,R6) 		|;if (n_valid_neighbours <= 0) -> jump out of the loop
	BT(R6,perfect_maze_end)

	|;Randomly select one neighbour
	RANDOM()
	PUSH(R0)
	CALL(abs__)
	DEALLOCATE(1)

	MOD(R0,R9,R8) |;random_neigh_index = (random % n_valid_neighbours/4) --> R8
	MULC(R8,4,R6) 	|;random_neigh_index*4 --> R6 (to get the offset)

	ADDC(R6,4,R6) |; need to add one offset from SP
	SUB(SP,R6,R6) 

	LD(R6,0,R7)  	|;neighbour = neighbours[random_neigh_index] --> R7
	
	POP(R8) |; Take the last neighbour
	ST(R8,0,R6) |; and put at the adress of the randomly taken neighbour 
	
	SUBC(R9,1,R9) 	|;n_valid_neigbours--

	
	|;Check if the neighbour is already visited
	MODC(R7,32,R6) |;neighbour % 32
	DIVC(R7,32,R8) |;neighbour/32 
	MULC(R8,4,R8) 	|;R8*4 (to get the offset)
	ADD(R4,R8,R8)	|;visited+4*neighbour/32 --> R8
	LD(R8,0,R8) 	|;visited[neighbour/32] --> R8
	SHR(R8,R6,R8) 	|;shift right the bitmap of (neighbour % 32)
	ANDC(R8,1,R8) 	|;visited_bit --> R8
	CMPEQC(R8,1,R6) |;if it is 1 (already visited)
	BT(R6,while_loop)


	|;RECURSIVITY
	PUSH(R5) 	|;push curr_cell for connect
	PUSH(R7) 	|;push neigbour (!= neighbours)
	PUSH(R3)	|;push nb_cols	
	PUSH(R1) 	|;push maze

	CALL(connect__)	
	DEALLOCATE(4)

	PUSH(R7) 	|;neighbour becomes new curr_cell
	PUSH(R4) 	|;push visited
	PUSH(R3) 	|;push cols
	PUSH(R2) 	|;push rows
	PUSH(R1) 	|;push maze

	CALL(perfect_maze)
	DEALLOCATE(5) |;  5 registers

	BR(while_loop)

perfect_maze_end:
	POP(R9)
	POP(R8)
	POP(R7)
	POP(R6)
	POP(R5)
	POP(R4)
	POP(R3)
	POP(R2)
	POP(R1)	
	END()	


|;****************************CONNECT FUNCTION***********************************
|;
|; Connects two cells by removing the seperation between them
|;
|; ARGUMENTS:
|; - a pointer to the first element of the maze
|; - the number of columns in the maze
|; - two neighbouring cells that must be connected
|;
|; RETURN : nothing
|;
|;*****************************************************************************

connect__:
	INIT()	
	PUSH(R1) 		
	PUSH(R2) 		
	PUSH(R3) 	
	PUSH(R4)
	PUSH(R5)
	PUSH(R6)
	PUSH(R7)
	PUSH(R8)
	PUSH(R9)
	PUSH(R10) 	
	
	LD(BP,-12,R1) 	|;maze --> R1
	LD(BP,-16,R2) 	|;nb_cols --> R2
	LD(BP,-20,R10)	|;neighbour/destination --> R10
	LD(BP,-24,R3) 	|;curr_cell --> R3
	
	CMPLT(R3,R10,R4) 	|;make sure source < dest (neighbour)
	BT(R4,byte_offset) 	|;if it is true, we jump the swap macro
	SWAP(R10,R3,R4)		|;swap source and destination if false

byte_offset:
	ROW_FROM_INDEX(R10,R2,R4)	|;dest_row --> R4
	MULC(R4,words_per_row,R6) 	|;row_offset = dest_row * WORDS_PER_ROW --> R6
	COL_FROM_INDEX(R3,R2,R4) 	|;source_col --> R4
	CMOVE(cells_per_word,R5) 	|;cells per word --> R5
	ROW_FROM_INDEX(R4,R5,R7) 	|;word_offset_in_line --> R7
	ADD(R6,R7,R6) 			|;word offset = row_offset + word_offset_in_line --> R6
	COL_FROM_INDEX(R4,R5,R7) 	|;byte_offset --> R7


vertical__:
	SUB(R10,R3,R4) 		|;dest - source --> R4
	CMPLEC(R4, 1, R4) 	|;if dest-source <= 1 --> R4 = 1 
	BF(R4,horizontal__)  |; if R4 = 0, jump to horizontal
	
	CMPEQC(R7,0,R4) 	|;byte offset == 0 ?
	BF(R4,openV1)
	CMOVE(OPEN_V_0,R8) |;OPEN_V_0 --> R8
	LD(R8,0,R8)
	BR(vert_loop_init__)

|; Check the byte offset and using the right mask
openV1: 
	CMPEQC(R7,1,R4)	|;byte offset == 1 ?
	BF(R4,openV2)
	CMOVE(OPEN_V_1,R8) |;OPEN_V_1 --> R8
	LD(R8,0,R8)
	BR(vert_loop_init__)

openV2:
	CMPEQC(R7,2,R4)	|;byte offset == 2 ?
	BF(R4,openV3)
	CMOVE(OPEN_V_2,R8) |;OPEN_V_2 --> R8
	LD(R8,0,R8)
	BR(vert_loop_init__)

openV3:
	CMOVE(OPEN_V_3,R8) |;OPEN_V_3 --> R8
	LD(R8,0,R8)
	

vert_loop_init__:
	CMOVE(3,R9) 	|; initialise the iterator to 3
vert_loop__:
	CMPEQC(R9,7, R4)
	BT(R4,connect_end__)
	MULC(R9,words_per_mem_line,R4) |; iterator*words_per_mem_line
	ADD(R6,R4,R4) |; word_offset + iterator*words_per_mem_line
 
	MULC(R4,4,R4) |; R4 now contains the adress of the *word* to be changed
	ADD(R1,R4,R4) |; 
	LD(R4,0,R5) |; load the word to R5
	AND(R5,R8,R7) |; apply the mask
	ST(R7,0,R4) |; put the updated word back
	ADDC(R9,1,R9) |; increment iterator
	BR(vert_loop__)


horizontal__:
	CMPEQC(R7,0,R4) 	|;byte offset == 0 ?
	BF(R4,openH1)
	CMOVE(OPEN_H_0,R8) |;OPEN_H_0 --> R8
	LD(R8,0,R8)
	BR(horitonzal_loop_init__)

|; Check the byte offset and using the right mask
openH1:
	CMPEQC(R7,1,R4)	|;byte offset == 1 ?
	BF(R4,openH2)
	CMOVE(OPEN_H_1,R8) |;OPEN_H_1 --> R8
	LD(R8,0,R8)
	BR(horitonzal_loop_init__)
openH2:
	CMPEQC(R7,2,R4)	|;byte offset == 2 ?
	BF(R4,openH3)
	CMOVE(OPEN_H_2,R8) |;OPEN_H_2 --> R8
	LD(R8,0,R8)
	BR(horitonzal_loop_init__)
openH3:
	CMOVE(OPEN_H_3,R8) |;OPEN_H_3 --> R8
	LD(R8,0,R8)


horitonzal_loop_init__:
	CMOVE(0,R9) 	|; initialise the iterator to 0
horizontal_loop__:
	CMPEQC(R9,2, R4)
	BT(R4,connect_end__)

	MULC(R9,words_per_mem_line,R4) |;iterator*words_per_mem_line --> R4
	ADD(R6,R4,R4) 					|;word_offset + iterator*words_per_mem_line --> R4
	MULC(R4,4,R4) 					|;R4 now contains the adress of the *word* to be changed
	ADD(R1,R4,R4) 					|;maze + word_offset + iterator*words_per_mem_line --> R4
	LD(R4,0,R5) 					|;maze[word_offset + i * WORDS_PER_MEM_LINE] --> R5
	AND(R5,R8,R7) 				|;apply the mask
	ST(R7,0,R4) 					|;put the updated word back
	ADDC(R9,1,R9) 				|;iterator++
	BR(horizontal_loop__)

connect_end__:
	

	POP(R10) 	|;push neigbour
	POP(R9)
	POP(R8)
	POP(R7)
	POP(R6)
	POP(R5)
	POP(R4)
	POP(R3) 	
	POP(R2) 		
	POP(R1) 		
	END()		

