`timescale 1ns / 1ps

module aluControl#(
   // Parameters:
      parameter N_BITS  = 6,
      parameter N_ALUOP = 2
)
   // Inputs & Outputs:
(  input  [N_BITS-1:0]  i_funct, // instrucción[5-0] - 6bits
   input  [N_BITS-1:0]  i_op,  // instrucción[31-26] - 6bits
   input  [N_ALUOP-1:0] i_aluOp, // señal de control - 2bits
   
   output reg [N_BITS-1:0] o_opcodeAlu
);

   always@(*) begin
      case(i_aluOp)
      ////////////////////////////////////////
      2'b00: // LW - SW
      begin
         case(i_op) // Se leen los datos de instruccion[31:26] -> OP
            6'b100000: o_opcodeAlu = 6'b010000; // LB -> (dato_A + dato_B) & 32'h0xff
            6'b100001: o_opcodeAlu = 6'b010001; // LH -> (dato_A + dato_B) & 32'h0xffff
            6'b100011: o_opcodeAlu = 6'b010001; // LW -> dato_A + dato_B
            6'b100100: o_opcodeAlu = 6'b010010; // LBU -> ($unsigned(dato_A) + $unsigned(dato_B)) & 32'h0xff
            6'b100101: o_opcodeAlu = 6'b010011; // LHU -> ($unsigned(dato_A) + $unsigned(dato_B)) & 32'h0xffff
            6'b100111: o_opcodeAlu = 6'b000011; // LWU -> $unsigned(dato_A) + $unsigned(dato_B)
            
            6'b101000: o_opcodeAlu = 6'b0; // SB -> 
            6'b101001: o_opcodeAlu = 6'b0; // SH -> 
            6'b101011: o_opcodeAlu = 6'b0; // SW -> 
            
            default: o_opcodeAlu = {N_BITS{1'b1}};  // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      2'b01: // Branch equal
      begin
         case(i_op)
            6'b000100,
            6'b000101: o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      2'b10: // R-Type
      begin
         case(i_funct) // Se leen los datos de instruccion[6:0] -> FUNCT
            6'b100100: o_opcodeAlu = 6'b000000; // AND -> dato_A & dato_B
            6'b100101: o_opcodeAlu = 6'b000001; // OR -> dato_A | dato_B
            6'b100001: o_opcodeAlu = 6'b000011; // ADDU -> $unsigned(dato_A) + $unsigned(dato_B)
            6'b100111: o_opcodeAlu = 6'b000100; // NOR -> ~(dato_A | dato_B)
            6'b100110: o_opcodeAlu = 6'b000101; // XOR -> dato_A ^ dato_B
            6'b000000: o_opcodeAlu = 6'b000010; // SLL -> dato_A << dato_B
            6'b000011: o_opcodeAlu = 6'b001000; // SRA -> dato_A >> dato_B
            6'b000100: o_opcodeAlu = 6'b001001; // SLLV -> 
            6'b000110: o_opcodeAlu = 6'b001010; // SRLV -> 
            6'b000111: o_opcodeAlu = 6'b001010; // SRAV -> 
            6'b100011: o_opcodeAlu = 6'b001100; // SUBU -> 
            6'b100010: o_opcodeAlu = 6'b001101; // SUB -> dato_A - dato_B
            6'b101010: o_opcodeAlu = 6'b001110; // SLT -> dato_A < dato_B
            6'b001000: o_opcodeAlu = {N_BITS{1'b1}}; // JR -> Invalid input for the ALU
            6'b001001: o_opcodeAlu = {N_BITS{1'b1}}; // JALR -> Invalid input for the ALU
            
            default: o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      2'b11: // I-Type
      begin
         case(i_op) // Se leen los datos de instruccion[31:26] -> OP
            6'b001111: o_opcodeAlu = 6'b001111; // LUI -> dato_B << 16
            6'b001000: o_opcodeAlu = 6'b000010; // ADDI -> dato_A + dato_B
            6'b001100: o_opcodeAlu = 6'b000000; // ANDI -> dato_A & dato_B
            6'b001101: o_opcodeAlu = 6'b000001; // ORI -> dato_A | dato_B
            6'b001110: o_opcodeAlu = 6'b000101; // XORI -> dato_A ^ dato_B
            6'b001010: o_opcodeAlu = 6'b001110; // SLTI -> dato_A < dato_B
            
            default: o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      default: o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
      endcase
   end //end_always

endmodule
