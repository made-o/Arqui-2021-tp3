`timescale 1ns / 1ps

module aluControl#(
   // Parameters:
      parameter N_OPCODE_O = 6,
      parameter N_OP_I     = 7,
      parameter N_FUNC7    = 7,
      parameter N_FUNC3    = 3,
      parameter N_ALUOP    = 2
)
   // Inputs & Outputs:
(  input  [N_FUNC3-1:0]    i_func3, // instrucci�n[14-12] - 3bits
   input  [N_FUNC7-1:0]    i_func7, // instrucci�n[31-25] - 7bits
   input  [N_OP_I-1:0]     i_op,    // instrucci�n[6-0] - 7bits
   input  [N_ALUOP-1:0]    i_aluOp, // se�al de control - 2bits
   
   output reg [N_OPCODE_O-1:0] o_opcodeAlu
);

   always@(*) begin
      o_opcodeAlu = {N_OPCODE_O{1'b1}};
      case(i_aluOp)
      ////////////////////////////////////////
      2'b00: // LW - SW
      begin
         case({i_op,i_func3}) // Se leen los datos de {instrucci�n[6-0],instruccion[14-12]} -> OP+FUNC3
            10'b0000011_000: o_opcodeAlu = 6'b010001; // LB -> (dato_A + dato_B)
            10'b0000011_001: o_opcodeAlu = 6'b010001; // LH -> (dato_A + dato_B)
            10'b0000011_010: o_opcodeAlu = 6'b010001; // LW -> dato_A + dato_B
            10'b0000011_100: o_opcodeAlu = 6'b010010; // LBU -> ($unsigned(dato_A) + $unsigned(dato_B))
            10'b0000011_101: o_opcodeAlu = 6'b010010; // LHU -> ($unsigned(dato_A) + $unsigned(dato_B))
            
            10'b0100011_000: o_opcodeAlu = 6'b000010; // SB -> dato_A + dato_B
            10'b0100011_001: o_opcodeAlu = 6'b000010; // SH -> dato_A + dato_B
            10'b0100011_010: o_opcodeAlu = 6'b000010; // SW -> dato_A + dato_B
            
            default: o_opcodeAlu = {N_OPCODE_O{1'b1}};  // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      2'b01: // Branch equal, J y LUI
      begin
         case(i_op)
            7'b1100011,7'b1100111,
            7'b1101111: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // Invalid input for the ALU
            7'b0110111: o_opcodeAlu = 6'b001111;
         endcase
      end
      ////////////////////////////////////////
      2'b10: // R-Type
      begin
         case({i_func3, i_func7}) // Se leen los datos de instruccion[6:0] -> FUNCT
            10'b111_0000000: o_opcodeAlu = 6'b000000; // AND -> dato_A & dato_B
            10'b110_0000000: o_opcodeAlu = 6'b000001; // OR -> dato_A | dato_B
            10'b000_0000000: o_opcodeAlu = 6'b000010; // ADD -> (dato_A) + (dato_B)
            //7'b0110011_: o_opcodeAlu = 6'b000100; // NOR -> ~(dato_A | dato_B)
            10'b100_0000000: o_opcodeAlu = 6'b000101; // XOR -> dato_A ^ dato_B
            10'b001_0000000: o_opcodeAlu = 6'b000110; // SLL -> dato_A << dato_B
            10'b101_0000000: o_opcodeAlu = 6'b000111; // SRL -> dato_A >> dato_B
            10'b101_0100000: o_opcodeAlu = 6'b001000; // SRA -> ;
            10'b011_0000000: o_opcodeAlu = 6'b001010; // SLTU -> (unsign(dato_A) < unsign(dato_B)) ? 1 : 0;
            10'b000_0100000: o_opcodeAlu = 6'b001101; // SUB -> dato_A - dato_B
            10'b010_0000000: o_opcodeAlu = 6'b001110; // SLT -> (dato_A < dato_B) ? 1 : 0
            //7'b0110011_: o_opcodeAlu = 6'b001100; // SUBU -> 
            //7'b0110011_: o_opcodeAlu = 6'b001110; // SLT -> dato_A < dato_B
            //7'b0110011_: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // JR -> Invalid input for the ALU
            //7'b0110011_: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // JALR -> Invalid input for the ALU
            
            default: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      2'b11: // I-Type
      begin
         casex({i_func3, i_func7}) // Se leen los datos de instruccion[31:26] -> OP
            //10'b010_0000000: o_opcodeAlu = 6'b001111; // LUI -> dato_B << 16
            10'b000_xxxxxxx: o_opcodeAlu = 6'b000010; // ADDI -> dato_A + dato_B
            10'b111_xxxxxxx: o_opcodeAlu = 6'b000000; // ANDI -> dato_A & dato_B
            10'b110_xxxxxxx: o_opcodeAlu = 6'b000001; // ORI -> dato_A | dato_B
            10'b100_xxxxxxx: o_opcodeAlu = 6'b000101; // XORI -> dato_A ^ dato_B
            10'b010_xxxxxxx: o_opcodeAlu = 6'b001110; // SLTI -> dato_A < dato_B
            10'b011_xxxxxxx: o_opcodeAlu = 6'b001010; // SLTIU
            10'b001_000000x: o_opcodeAlu = 6'b000110; // SLLI
            10'b101_000000x: o_opcodeAlu = 6'b000111; // SRLI
            10'b101_010000x: o_opcodeAlu = 6'b001000; // SRAI
            
            default: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // Invalid input for the ALU
         endcase
      end
      ////////////////////////////////////////
      default: o_opcodeAlu = {N_OPCODE_O{1'b1}}; // Invalid input for the ALU
      endcase
   end //end_always

endmodule
