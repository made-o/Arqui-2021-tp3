`timescale 1ns / 1ps

module writeBack #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 6
)
(  input  i_clk,
   input  i_reset,
   input  i_valid,
   
   //señales de control:
   input  i_memToReg, 
   
   //entradas al mux:
   input  [N_BITS-1:0] i_datoLeido_MEM,
   input  [N_BITS-1:0] i_AluResult,
   
   //entradas que directamente salen:
   input  i_regWrite, //habilita la escritura en la etapa ID
   input  [N_BITS_REG-1:0] i_rd_MemToWb,  //cortocircuito etapa EX
   input  [N_BITS_REG-1:0] i_rt_OR_rd, //registro a escribir en etapa ID
   
   
   output reg [N_BITS-1:0] o_WB_writeData, //salida del multiplexor
   output reg [N_BITS_REG-1:0] o_rt_OR_rd, // reg a escribir en la etapa ID
   output reg [N_BITS_REG-1:0] o_rd_MEM_WB, // para el cortocircuito de la etapa EX
   output reg o_WB_regWrite //señal de escritura en etapa ID

);

   ////////////////////////////////////////////////////
   // Start-code:
   
   // Multiplexor for MemToReg signal:
   always @(i_datoLeido_MEM or i_AluResult or i_memToReg) begin
      case(i_memToReg)
         1'b0: o_WB_writeData <= i_datoLeido_MEM;
         1'b1: o_WB_writeData <= i_AluResult;
      endcase
   end//end_always
   
   //--------------------------------------------
   // Lectura y escritura: (update outputs)
   always @(posedge i_clk) begin: lectura
      if(i_reset) begin
         o_rt_OR_rd    <= 0;
         o_rd_MEM_WB   <= 0;
         o_WB_regWrite <= 0;
      end
      else if(i_valid) begin
         o_rt_OR_rd    <= i_rt_OR_rd;
         o_rd_MEM_WB   <= i_rd_MemToWb;
         o_WB_regWrite <= i_regWrite;
      end
   end //end_always
   
endmodule
