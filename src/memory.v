`timescale 1ns / 1ps

module memory #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 6
)
(  // INPUTS:
   input  i_clk,
   input  i_reset,
   input  i_valid,
   
   // Señales de control (que vienen de la etapa ID)
   input  i_branch,
   input  i_memRead,
   input  i_memWrite,
   
   // Señales de control (para la etapa WB)
   input  i_memToReg,
   input  i_regWrite,
   
   input  i_ceroSignal,
   
   // Entradas que van a ser salidas directas a la sig. etapa
   input  [N_BITS-1:0] i_aluResult, // retorna para la etapa EX - (i_memData)
   input  [N_BITS-1:0] i_datoLeido2, 
   input  [N_BITS_REG-1:0] i_rt_OR_rd,
   input  [N_BITS_REG-1:0] i_rd_EX_MEM, // retorna para la etapa EX - bloque forwarding
   
   // OUTPUTS:
   output reg o_memToReg_MEM_WB,
   output reg o_regWrite_MEM_WB,
   
   // señales de control
   output wire o_pcSource, // que va a la etapa IF
   
   output reg [N_BITS-1:0] o_readData,
   output reg [N_BITS-1:0] o_aluResult,
   output wire [N_BITS_REG-1:0] o_rt_OR_rd,
   output wire [N_BITS_REG-1:0] o_rd_MEM
);
   
   // Variables internas:
   reg memToReg;
   reg regWrite;
   
   reg pcSource;
   reg [N_BITS-1:0] readData;
   reg [N_BITS-1:0] aluResult;
   reg [N_BITS_REG-1:0] rd_MEM;
   
   ////////////////////////////////////////////////////
   // Start-code:
   
   // Branch Logic:
   always @(i_branch or i_ceroSignal) begin
      if(i_branch == 1'b1 & i_ceroSignal == 1'b1)
         pcSource = 1'b1;
      else
         pcSource = 1'b0;
   end
   assign o_pcSource = pcSource;
   
   // Asigno a la salida directamente:
   assign o_rt_OR_rd = i_rt_OR_rd;
   assign o_rd_MEM   = i_rd_EX_MEM;
   
   //---------------------------------------------------
   // Lectura y escritura:
   always @(posedge i_clk) begin: lectura
      if(i_reset) begin
         memToReg  <= 1'b0;
         regWrite  <= 1'b0;
         aluResult <= {N_BITS{1'b0}};
         rd_MEM    <= {N_BITS_REG{1'b0}};
      end//end_if
      else if(i_valid) begin
         memToReg  <= i_memToReg;
         regWrite  <= regWrite;
         aluResult <= i_aluResult;
         rd_MEM    <= i_rd_EX_MEM;
      end//end_if
   end//end_always
   
   
   always @(negedge i_clk) begin: escritura
      if(i_reset) begin
         o_memToReg_MEM_WB <= 1'b0;
         o_regWrite_MEM_WB <= 1'b0;
         o_readData  <= {N_BITS{1'b0}};
         o_aluResult <= {N_BITS{1'b0}};
      end//end_if
      else if(i_valid) begin
         o_memToReg_MEM_WB <= memToReg;
         o_regWrite_MEM_WB <= regWrite;
         o_readData  <= readData;
         o_aluResult <= aluResult;
      end//end_if
   end//end_always
   

   ////////////////////////////////////////////////////
   // Instanciacion de módulo de memory_data:
   dataMemory
   u_dataMemory (
      .i_address(i_aluResult),
      .i_write_data(i_datoLeido2),
      .i_valid(i_valid),
      .i_clk(i_clk),
      .i_read_enable(i_memRead),
      .i_write_enable(i_memWrite),
      
      .o_read_data(o_readData)
   );
   
   
endmodule