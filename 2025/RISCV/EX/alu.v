`timescale 1ns / 100ps
// Declaraci�n de c�digos de operacion:
`define AND  6'b000000   // AND (bit-a-bit)
`define OR   6'b000001   // OR (bit-a-bit)
`define ADD  6'b000010   // ADD Word
//`define ADDU 6'b000011   // ADD Unsigned Word
//`define NOR  6'b000100   // logical NOR
`define XOR  6'b000101   // logical XOR
`define SLL  6'b000110   // Shift Word Left Logic (desplazamiento a la izquierda)
`define SRL  6'b000111   // Shift Word Right Logic (desplazamiento a la derecha)
`define SRA  6'b001000   // Shift Right Arithmetic
`define SLTU 6'b001010   // 
//`define SRLV 6'b001010   // Shift Right Logical Variable
//`define SRAV 6'b001011   // Shift Right Arithmetic Variable
//`define SUBU 6'b001100   // Subtract Unsigned Word
`define SUB  6'b001101   // 
`define SLT  6'b001110   // Set Less Than
`define LUI  6'b001111   // Load Upper Immediate
//`define LB   6'b010000   // Load Byte
`define LSs  6'b010001   // Loads Signed, suma al fin
`define LUs  6'b010010   // Loads Unsigned, ADD Unsigned Word
//`define LHU  6'b010011   // Load Half Word Unsigned
 
//////////////////////////////////////////////////////////////
module alu #(
   // Parameters:
   parameter N_BITS = 32,
   parameter N_OPCODE = 6
)
   // Inputs & Outputs:
(  input [N_BITS-1:0]   i_datoA,
   input [N_BITS-1:0]   i_datoB,
   input [N_OPCODE-1:0] i_opcode,
   
   output reg  [N_BITS-1:0] o_aluResult,
   output                   o_cero
);

   ////////////////////////////////////////////////////
   // Start-code:
   always @(*) begin
      case(i_opcode)
         `AND:  o_aluResult = i_datoA & i_datoB;
         `OR:   o_aluResult = i_datoA | i_datoB;
         `ADD:  o_aluResult = i_datoA + i_datoB;
         `XOR:  o_aluResult = i_datoA ^ i_datoB;
         `SUB:  o_aluResult = i_datoA - i_datoB;

         `SLL:  o_aluResult = i_datoA << i_datoB;
         `SRL:  o_aluResult = i_datoA >> i_datoB;
         `SRA:  o_aluResult = i_datoA >>> i_datoB;

         `SLTU: o_aluResult = ($unsigned(i_datoA) < $unsigned(i_datoB))? 32'b1: 32'b0;
         
         `SLT:  o_aluResult = (i_datoA < i_datoB)? 32'b1: 32'b0;
         `LSs:  o_aluResult = (i_datoA + i_datoB);// & 32'h0xffff;
         `LUs:  o_aluResult = ($unsigned(i_datoA) + $unsigned(i_datoB));// & 32'h0xff;
         
         `LUI:  o_aluResult = i_datoB;

         default: o_aluResult = {N_BITS{1'b0}}; 
      
      endcase
      
   end//end_always
      
   assign o_cero = (o_aluResult == 0);

endmodule