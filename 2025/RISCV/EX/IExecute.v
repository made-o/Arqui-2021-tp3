`timescale 1ns / 1ps

module IExecute #(
   // Parameters:
   parameter N_BITS = 32,
   parameter N_BITS_REG = 5,
   parameter N_OPCODE = 6
)
   // Inputs & Outputs:
(  input i_clk, i_reset,
   input  i_exec_mode,
   input  i_step,
   // Se�ales de control de la EX:
   input [1:0] i_aluOP, // 2-bits
   input i_aluSrc,
   //input i_regDst,
   
   // Datos que vienen de la etapa ID:
   input [N_BITS-1:0] i_datoLeido1, // 32bits
   input [N_BITS-1:0] i_datoLeido2,
   input [N_BITS-1:0] i_datoExtSigno,
   
   input [N_BITS-1:0] i_instruccion, // 6-bits
   input [N_BITS_REG-1:0] i_rt_id, // 6-bits
   input [N_BITS_REG-1:0] i_rd_id, // 6-bits
   input [N_BITS_REG-1:0] i_rt_OR_rd, // 6-bits
   
   // Se�al de entrada al m�dulo de control de la ALU
   //input [N_BITS_REG:0]   i_opcode, // 6bits
   
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
   input [1:0] i_branch,
   input i_memWrite,
   input [1:0]i_memRead,
   input i_regWrite,
   input i_halt,
   
   output reg [N_BITS-1:0] o_instruccion,
   output reg  o_ceroSignal,
   output reg  [N_BITS-1:0] o_aluResult,
   output reg [N_BITS-1:0] o_datoLeido2,
   output reg [N_BITS_REG-1:0] o_rd_data, //5-bits
   output reg [N_BITS_REG-1:0] o_rt_OR_rd,
   output reg o_memToReg,
   //output reg o_regWrite_EX_MEM,
   //output reg o_regWrite_MEM_WB,
   output reg [1:0] o_branch,
   output reg o_memWrite,
   output reg o_memRead,
   output reg o_regWrite,

   output reg o_halt
);
   
   wire  [N_BITS-1:0] w_aluResult;
   wire  w_ceroSignal;
   // Se�ales de control de la unidad de Cortorcircuito:
   wire w_forwardA;
   wire w_forwardB;
   // Internal Variables:
   // Se�ales referidas al bloque ALU:
   reg [N_BITS-1:0] dato1ALU; // DatoA que ingresa a la ALU
   reg [N_BITS-1:0] dato2ALU; // DatoB que ingresa a la ALU
   reg [N_BITS-1:0] dato2_preALU; // Dato que sale del MUX-forwardB
   wire [N_OPCODE-1:0] aluOpcode; // 6-bits que salen del bloque de control e ingresan a la ALU
   
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
   always @(*)begin //i_datoLeido1 or i_wbData or i_memData or i_forwardA) begin
      case(w_forwardA)
         2'b00: dato1ALU = i_datoLeido1; 
         2'b01: dato1ALU = i_wbData;
         2'b10: dato1ALU = i_memData;
         default: dato1ALU = 32'h00000000;
      endcase
   end//end_always
   
   // Multiplexor for ForwardB:
   always @(*)begin //i_datoLeido2 or i_wbData or i_memData or i_forwardB) begin
      case(w_forwardB)
         2'b00: dato2_preALU = i_datoLeido2; 
         2'b01: dato2_preALU = i_wbData;
         2'b10: dato2_preALU = i_memData;
         default: dato2_preALU = 32'h00000000;
      endcase
   end//end_always
   
   // Multiplexor for ALUSrc:
   always @(*)begin //dato2_preALU or i_datoLeido2 or i_aluSrc) begin
      case(i_aluSrc)
         1'b0: dato2ALU = dato2_preALU;
         1'b1: dato2ALU = i_datoExtSigno;
         default: dato2ALU = 32'h00000000;
      endcase
   end//end_always
   
   
   // Asigno a la salida:
   //assign o_datoLeido2 = dato2_preALU; //dato que se quiere guardar en MEM
   //assign o_rd_data  = i_rd_id; //direccion de la MEM en donde se guarda el dato
   //assign o_rt_OR_rd = i_rt_OR_rd; //direccion pero de la memoria de registros que se va a usar en Wb
   
   //---------------------------------------------------
   always@(posedge i_clk) begin: EX_MEM
      if(i_reset) begin
         o_memToReg <= 1'b0;
         //o_regWrite_EX_MEM <= 1'b0;
         //o_regWrite_MEM_WB <= 1'b0;
         o_branch   <= 1'b0;
         o_memWrite <= 1'b0;
         o_memRead  <= 1'b0;
         o_aluResult <= 32'h00000000;
         o_ceroSignal <= 1'b0;
         o_datoLeido2 <= 32'h00000000;
         o_rd_data <= 6'b000000;
         o_rt_OR_rd <= 6'b000000;
         o_regWrite  <= 1'b0;
      end//end_if
      else begin
         if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
         begin
            o_instruccion <= i_instruccion;
            o_memToReg <= i_memToReg;
            //o_regWrite_EX_MEM <= i_regWrite_EX_MEM;
            //o_regWrite_MEM_WB <= i_regWrite_MEM_WB;
            o_branch   <= i_branch;
            o_memWrite <= i_memWrite;
            o_memRead  <= i_memRead;
            o_aluResult <= w_aluResult;
            o_ceroSignal <= w_ceroSignal;
            o_datoLeido2 <= dato2_preALU;//dato que se quiere guardar en MEM
            o_rd_data <= i_rd_id;//direccion de la MEM en donde se guarda el dato
            o_rt_OR_rd <= i_rt_OR_rd;//direccion pero de la memoria de registros que se va a usar en Wb
            o_regWrite  <= i_regWrite;
            o_halt      <= i_halt;
         end
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
      
      .o_aluResult(w_aluResult),
      .o_cero(w_ceroSignal)
   );
   
   // Instanciacion de m�dulo de Cortocircuito:
   fowarding_unit
   u_corto (
      .i_rt_id(i_rt_id),
      .i_rs_id(i_rs_id),
      .i_rd_EX_MEM(i_rd_EX_MEM),
      .i_regWrite_EX_MEM(i_regWrite_EX_MEM),
      .i_rd_MEM_WB(i_rd_MEM_WB),
      .i_regWrite_MEM_WB(i_regWrite_MEM_WB),
      
      .o_forwardA(w_forwardA),
      .o_forwardB(w_forwardB)
   );
   
   
   
endmodule