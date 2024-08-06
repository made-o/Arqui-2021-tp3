`timescale 1ns / 1ps

module execute #(
   // Parameters:
   parameter N_BITS = 32,
   parameter N_BITS_REG = 6
)
   // Inputs & Outputs:
(  input i_clk, i_reset, i_enable,
   // Se�ales de control de la EX:
   input [1:0] i_aluOP, // 2-bits
   input i_aluSrc,
   input i_regDst,
   
   // Se�ales de control de la unidad de Cortorcircuito:
   input i_forwardA,
   input i_forwardB,
   
   // Datos que vienen de la etapa ID:
   input [N_BITS-1:0] i_datoLeido1, // 32bits
   input [N_BITS-1:0] i_datoLeido2,
   input [N_BITS-1:0] i_datoExtSigno,
   
   input [N_BITS_REG-1:0] i_instruccion, // 6-bits
   input [N_BITS_REG-1:0] i_rt_id, // 6-bits
   input [N_BITS_REG-1:0] i_rd_id, // 6-bits
   input [N_BITS_REG-1:0] i_rt_OR_rd, // 6-bits
   
   // Se�al de entrada al m�dulo de control de la ALU
   input [N_BITS_REG:0]   i_opcode, // 6bits
   
   // Se�ales extras que entran a la unidad de cortocircuito:
   input [N_BITS_REG-1:0] i_rd_EX_MEM, //6-bits
   input [N_BITS_REG-1:0] i_rd_MEM_WB, //6-bits
   input [N_BITS_REG-1:0] i_rs_id,     //6-bits
   
   // Se�ales que vienen de las etapas WB y MEM (para usar en MUX)
   input [N_BITS-1:0] i_wbData,
   input [N_BITS-1:0] i_memData,
   
   // Se�ales que vienen de la etapa ID o de etapas siguientes:
   input i_memToReg,
   input i_regWrite_EX_MEM,
   input i_regWrite_MEM_WB,
   input i_branch,
   input i_memWrite,
   input i_memRead,
   
   
   output wire  o_ceroSignal,
   output wire  [N_BITS-1:0] o_aluResult,
   output wire [N_BITS-1:0] o_datoLeido2,
   output wire [N_BITS_REG-1:0] o_rd_data, //6-bits
   output wire [N_BITS_REG-1:0] o_rt_OR_rd,
   output reg o_memToReg,
   output reg o_regWrite_EX_MEM,
   output reg o_regWrite_MEM_WB,
   output reg o_branch,
   output reg o_memWrite,
   output reg o_memRead
   
);

   // Internal Variables:
   // Se�ales referidas al bloque ALU:
   reg [N_BITS-1:0] dato1ALU; // DatoA que ingresa a la ALU
   reg [N_BITS-1:0] dato2ALU; // DatoB que ingresa a la ALU
   reg [N_BITS-1:0] dato2_preALU; // Dato que sale del MUX-forwardB
   wire [N_BITS_REG-1:0] aluOpcode; // 6-bits que salen del bloque de control e ingresan a la ALU
   
   // Se�ales referidas a la unidad de encaminamiento/cortocircuito:
   reg memToReg;
   reg regWrite_EX_MEM;
   reg regWrite_MEM_WB;
   reg branch;
   reg memWrite;
   reg memRead;
   
   
   ////////////////////////////////////////////////////
   // Start-code:
   
   // Multiplexor for ForwardA:
   always @(i_datoLeido1 or i_wbData or i_memData or i_forwardA) begin
      case(i_forwardA)
         2'b00: dato1ALU <= i_datoLeido1; 
         2'b01: dato1ALU <= i_wbData;
         2'b10: dato1ALU <= i_memData;
      endcase
   end//end_always
   
   // Multiplexor for ForwardB:
   always @(i_datoLeido2 or i_wbData or i_memData or i_forwardB) begin
      case(i_forwardB)
         2'b00: dato2_preALU <= i_datoLeido2; 
         2'b01: dato2_preALU <= i_wbData;
         2'b10: dato2_preALU <= i_memData;
      endcase
   end//end_always
   
   // Multiplexor for ALUSrc:
   always @(dato2_preALU or i_datoLeido2 or i_aluSrc) begin
      case(i_aluSrc)
         1'b0: dato2ALU <= dato2_preALU;
         1'b1: dato2ALU <= i_datoExtSigno;
      endcase
   end//end_always
   
   
   // Asigno a la salida:
   assign o_datoLeido2 = dato2_preALU;
   assign o_rd_data  = i_rd_id;
   assign o_rt_OR_rd = i_rt_OR_rd;
   
   //---------------------------------------------------
   always@(posedge i_clk) begin: lectura// FIJARSE - si faltan variables para setear en cero
      if(i_reset) begin
         memToReg <= 1'b0;
         regWrite_EX_MEM <= 1'b0;
         regWrite_MEM_WB <= 1'b0;
         branch   <= 1'b0;
         memWrite <= 1'b0;
         memRead  <= 1'b0;
      end//end_if
      else begin
         memToReg <= i_memToReg;
         regWrite_EX_MEM <= i_regWrite_EX_MEM;
         regWrite_MEM_WB <= i_regWrite_MEM_WB;
         branch   <= i_branch;
         memWrite <= i_memWrite;
         memRead  <= i_memRead;
      end//end_else
   end//end_always
   

   always@(negedge i_clk) begin: escritura
      if(i_reset) begin
         o_memToReg <= 1'b0;
         o_regWrite_EX_MEM <= 1'b0;
         o_regWrite_MEM_WB <= 1'b0;
         o_branch   <= 1'b0;
         o_memWrite <= 1'b0;
         o_memRead  <= 1'b0;
      end//end_if
      else begin
         o_memToReg <= memToReg;
         o_regWrite_EX_MEM <= regWrite_EX_MEM;
         o_regWrite_MEM_WB <= regWrite_MEM_WB;
         o_branch   <= branch;
         o_memWrite <= memWrite;
         o_memRead  <= memRead;
      end//end_else
   end//end_always
   
   
   ////////////////////////////////////////////////////
   // Instanciacion de m�dulo de Control de ALU:
   aluControl
   u_aluBlock (
      .i_aluOp(i_aluOP),  // 2bits
      .i_funct(i_instruccion[5:0]), // 6bits
      .i_op(i_instruccion[31:26]), // 6bits
      
      .o_opcodeAlu(aluOpcode) // 32bits
   );

   // Instanciacion de m�dulo de ALU:
   alu
   u_alu_1(
      .i_datoA(dato1ALU),
      .i_datoB(dato2ALU),
      .i_opcode(aluOpcode),
      
      .o_aluResult(o_aluResult),
      .o_cero(o_ceroSignal)
   );
   
   // Instanciacion de m�dulo de Cortocircuito:
   fowarding_unit
   u_corto (
      .i_rt_id(i_rt_id),
      .i_rs_id(i_rs_id),
      .i_rd_EX_MEM(i_rd_EX_MEM),
      .i_regWrite_EX_MEM(regWrite_EX_MEM),
      .i_rd_MEM_WB(i_rd_MEM_WB),
      .i_regWrite_MEM_WB(regWrite_MEM_WB),
      
      .o_forwardA(i_forwardA),
      .o_forwardB(i_forwardB)
   );
   
   
   
endmodule