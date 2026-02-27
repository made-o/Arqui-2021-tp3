`timescale 1ns / 1ps

module writeBack #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 6
)
(  
   input  i_clk,
   input  i_reset,
   //input  i_valid,
   input  i_exec_mode,
   input  i_step,
   input  i_halt,
   
   //se�ales de control:
   input  i_memToReg, 
   
   //entradas al mux:
   input  [N_BITS-1:0] i_datoLeido_MEM,
   input  [N_BITS-1:0] i_AluResult,
   
   //entradas que directamente salen:
   input  i_regWrite, //habilita la escritura en la etapa ID
   input  [N_BITS_REG-1:0] i_rd_MemToWb,  //cortocircuito etapa EX
   input  [N_BITS_REG-1:0] i_rt_OR_rd, //registro a escribir en etapa ID
   
   
   output reg o_cpu_finished,

   output reg [N_BITS-1:0] o_WB_writeData, //salida del multiplexor
   output reg [N_BITS_REG-1:0] o_rt_OR_rd, // reg a escribir en la etapa ID
   output reg [N_BITS_REG-1:0] o_rd_MEM_WB, // para el cortocircuito de la etapa EX
   output reg o_WB_regWrite //se�al de escritura en etapa ID

);

   ////////////////////////////////////////////////////
   // Start-code:
   reg [N_BITS-1:0] w_WB_writeData;
   // Multiplexor for MemToReg signal:
   always @(*) begin
      case(i_memToReg)
         1'b0: w_WB_writeData <= i_datoLeido_MEM;
         1'b1: w_WB_writeData <= i_AluResult;
      endcase
   end//end_always
   
   //--------------------------------------------
   // Lectura y escritura: (update outputs)
   always @(posedge i_clk) begin: ID_EX

      if(i_reset) begin       
         o_WB_writeData  <= 32'b0;
         o_rt_OR_rd      <= 1'b0;
         o_rd_MEM_WB     <= 1'b0;
         o_WB_regWrite   <= 1'b0;
         o_cpu_finished  <= 1'b0; 
      end

      if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)))begin 
         o_WB_writeData  <= w_WB_writeData;
         o_rt_OR_rd      <= i_rt_OR_rd;
         o_rd_MEM_WB     <= i_rd_MemToWb;
         o_WB_regWrite   <= i_regWrite;
         o_cpu_finished  <= i_halt;       
      end    
   end
   
endmodule
