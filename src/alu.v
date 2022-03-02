// Declaración de códigos de operacion:
`define AND  6'b000000   // AND (bit-a-bit)
`define OR   6'b000001   // OR (bit-a-bit)
`define ADD  6'b000010   // ADD Word
`define ADDU 6'b000011   // ADD Unsigned Word
`define NOR  6'b000100   // logical NOR
`define XOR  6'b000101   // logical XOR
`define SLL  6'b000110   // Shift Word Left Logic (desplazamiento a la izquierda)
`define SRL  6'b000111   // Shift Word Right Logic (desplazamiento a la derecha)
`define SRA  6'b001000   // Shift Right Arithmetic
`define SLLV 6'b001001   // Shift Left Logical Variable
`define SRLV 6'b001010   // Shift Right Logical Variable
`define SRAV 6'b001011   // Shift Right Arithmetic Variable
`define SUBU 6'b001100   // Subtract Unsigned Word
`define SUB  6'b001101   // 
`define SLT  6'b001110   // Set Less Than
`define LUI  6'b001111   // Load Upper Immediate
`define LB   6'b010000   // Load Byte
`define LH   6'b010001   // Load Half Word
`define LBU  6'b010010   // Load Byte Unsigned
`define LHU  6'b010011   // Load Half Word Unsigned
 
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
   output reg o_cero
);

   ////////////////////////////////////////////////////
   // Start-code:
   always @(*) begin
      case(i_opcode)
         `AND:  o_aluResult = i_datoA & i_datoB;
         `OR:   o_aluResult = i_datoA | i_datoB;
         `ADD:  o_aluResult = i_datoA + i_datoB;
         `ADDU: o_aluResult = $unsigned(i_datoA) + $unsigned(i_datoB);
         `NOR:  o_aluResult = ~(i_datoA | i_datoB);
         `XOR:  begin
                o_aluResult = i_datoA ^ i_datoB; 
                //o_cero = (!(i_datoA ^ i_datoB)) ? 1 : 0; // o_cero = 1 si las entradas son iguales
                end
         `SLL:  o_aluResult = i_datoA << i_datoB;
         `SRL:  o_aluResult = i_datoA >> i_datoB;
         `SRA:  o_aluResult = i_datoA >>> i_datoB;
         `SLLV: o_aluResult = i_datoB << i_datoA;
         `SRLV: o_aluResult = i_datoB >> i_datoA;
         `SRAV: o_aluResult = i_datoB >>> i_datoA;
         `SUBU: o_aluResult = $unsigned(i_datoA) - $unsigned(i_datoB);
         `SUB:  o_aluResult = i_datoA - i_datoB;
         `SLT:  o_aluResult = i_datoA < i_datoB;
         `LUI:  o_aluResult = i_datoB << 16;
         `LB:   o_aluResult = (i_datoA + i_datoB) & 32'h0xff;
         `LH:   o_aluResult = (i_datoA + i_datoB) & 32'h0xffff;
         `LBU:  o_aluResult = ($unsigned(i_datoA) + $unsigned(i_datoB)) & 32'h0xff;
         `LHU:  o_aluResult = ($unsigned(i_datoA) + $unsigned(i_datoB)) & 32'h0xffff;
         
         default: o_aluResult = {N_BITS{1'b0}}; 
      
      endcase
      
      assign o_cero = (o_aluResult == 0);
      
   end//end_always

endmodule
