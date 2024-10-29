`define LB  6'b100000   //
`define LH  6'b100001   //
`define LW  6'b100011   //
`define LBU 6'b100100   //
`define LHU 6'b100101   //
`define LWU 6'b100111   //
`define SB  6'b101000   //
`define SH  6'b101001   //
`define SW  6'b101011   //

`define BEQ 6'b000100   //
`define BNE 6'b000101   //

`define AND  6'b100100   // 0 - AND (bit-a-bit)
`define OR   6'b100101   // OR (bit-a-bit)
`define ADD  6'b100000   // ADD Word (sumar palabra)
`define ADDU 6'b100001   // ADD Unsigned Word
`define NOR  6'b100111   // logical NOR
`define XOR  6'b100110   // logical XOR
`define SLL  6'b000000   // Shift Word Left Logic (desplazamiento logico a la izquierda)
`define SRL  6'b000010   // Shift Word Right Logic (desplazamiento logico a la derecha)
`define SRA  6'b000011   // Shift Right Arithmetic (desplazamiento aritmético a la derecha)
`define SLLV 6'b000100   // Shift Left Logical Variable
`define SRLV 6'b000110   // Shift Right Logical Variable
`define SRAV 6'b000111   // Shift Right Arithmetic Variable
`define SUBU 6'b100011   // Subtract Unsigned Word
`define SUB  6'b100010   // Subtract Word (restar palabra)
`define SLT  6'b101010   // Set Less Than

`define JR   6'b001000   //
`define JALR 6'b001001   //

`define LUI  6'b001111   //
`define ADDI 6'b001000   //
`define ANDI 6'b001100   //
`define ORI  6'b001101   //
`define XORI 6'b001110   //
`define SLTI 6'b001010   //


module aluControl#(
    // Parameters:
    parameter N_BITS  = 6,
    parameter N_ALUOP = 2
  )
  // Inputs & Outputs:
  (  input  [N_BITS-1:0]  i_funct, // instrucción[5:0] - 6bits
     input  [N_BITS-1:0]  i_op,    // instrucción[31:26] - 6bits
     input  [N_ALUOP-1:0] i_aluOp, // señal de control - 2bits

     output reg [N_BITS-1:0] o_opcodeAlu
  );

  always@(*)
  begin
    case(i_aluOp)
      ////////////////////////////////////////////////////////////////////////////////
      2'b00: // LW - SW
      begin
        case(i_op) // Se leen los datos de instruccion[31:26] -> OP
          `LB:
            o_opcodeAlu = 6'b010000; // LB -> (dato_A + dato_B) & 32'h0xff
          `LH:
            o_opcodeAlu = 6'b010001; // LH -> (dato_A + dato_B) & 32'h0xffff
          `LW:
            o_opcodeAlu = 6'b000010; // LW -> (usa el mismo que el ADD)
          `LBU:
            o_opcodeAlu = 6'b010010; // LBU -> ($unsigned(dato_A) + $unsigned(dato_B)) & 32'h0xff
          `LHU:
            o_opcodeAlu = 6'b010011; // LHU -> ($unsigned(dato_A) + $unsigned(dato_B)) & 32'h0xffff
          `LWU:
            o_opcodeAlu = 6'b000011; // LWU -> (usa el mismo que el ADDU)

          `SB:
            o_opcodeAlu = 6'b0; // SB ->
          `SH:
            o_opcodeAlu = 6'b0; // SH ->
          `SW:
            o_opcodeAlu = 6'b0; // SW ->

          default:
            o_opcodeAlu = {N_BITS{1'b1}};  // Invalid input for the ALU
        endcase
      end
      ////////////////////////////////////////////////////////////////////////////////
      2'b01: // Branch equal
      begin
        case(i_op) // datos de instruccion[31:26] -> OP
          `BEQ,
          `BNE:
            o_opcodeAlu = 6'b0;
          default:
            o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
        endcase
      end
      ////////////////////////////////////////////////////////////////////////////////
      2'b10: // R-Type
      begin
        case(i_funct) // Se leen los datos de instruccion[5:0] -> FUNCT
          `AND:
            o_opcodeAlu = 6'b000000;
          `OR:
            o_opcodeAlu = 6'b000001;
          `ADD:
            o_opcodeAlu = 6'b000010;
          `ADDU:
            o_opcodeAlu = 6'b000011; // ADDU -> $unsigned(dato_A) + $unsigned(dato_B)
          `NOR:
            o_opcodeAlu = 6'b000100; // NOR -> ~(dato_A | dato_B)
          `XOR:
            o_opcodeAlu = 6'b000101; // XOR -> dato_A ^ dato_B
          `SLL:
            o_opcodeAlu = 6'b000110; // SLL -> dato_A << dato_B
          `SRL:
            o_opcodeAlu = 6'b000111; // SRA -> dato_A >> dato_B
          `SRA:
            o_opcodeAlu = 6'b001000; // SLLV ->
          `SLLV:
            o_opcodeAlu = 6'b001001; // SRLV ->
          `SRLV:
            o_opcodeAlu = 6'b001010; // SRAV ->
          `SRAV:
            o_opcodeAlu = 6'b001011; // SUBU ->
          `SUBU:
            o_opcodeAlu = 6'b001100; // SUB -> dato_A - dato_B
          `SUB:
            o_opcodeAlu = 6'b001101; // SLT -> dato_A < dato_B
          `SLT:
            o_opcodeAlu = 6'b001110;

          `JR,
          `JALR:
            o_opcodeAlu = 6'b0; // Invalid input for the ALU

          default:
            o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
        endcase
      end
      ////////////////////////////////////////////////////////////////////////////////
      2'b11: // I-Type
      begin
        case(i_op) // Se leen los datos de instruccion[31:26] -> OP
          `LUI:
            o_opcodeAlu = 6'b001111; // LUI -> dato_B << 16
          `ADDI:
            o_opcodeAlu = 6'b000010; // (usa el mismo que el ADD)
          `ANDI:
            o_opcodeAlu = 6'b000000; // (usa el mismo que el AND)
          `ORI:
            o_opcodeAlu = 6'b000001; // (usa el mismo que el OR)
          `XORI:
            o_opcodeAlu = 6'b000101; // (usa el mismo que el XOR)
          `SLTI:
            o_opcodeAlu = 6'b001110; // (usa el mismo que el SLT)

          default:
            o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
        endcase
      end
      ////////////////////////////////////////
      default:
        o_opcodeAlu = {N_BITS{1'b1}}; // Invalid input for the ALU
    endcase
  end //end_always

endmodule
