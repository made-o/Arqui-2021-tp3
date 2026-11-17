`timescale 1ns / 100ps

module writeBack #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 5
)
(  
   input  i_clk,
   input  i_reset,
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
   input  [N_BITS_REG-1:0] i_rd, //registro a escribir en etapa ID
   
   
   output reg o_cpu_finished,

   output reg  [N_BITS-1:0]      o_WB_writeData, //salida del multiplexor
   output wire [N_BITS-1:0]      o_WB_writeData_forwarding,
   output wire [N_BITS_REG-1:0]  o_rd, // reg a escribir en la etapa ID
   output wire                   o_WB_regWrite //se�al de escritura en etapa ID

);

   ////////////////////////////////////////////////////
   // Start-code:
   reg [N_BITS-1:0] r_WB_writeData;
   // Multiplexor for MemToReg signal:
   always @(*) begin
      case(i_memToReg)
         1'b0: r_WB_writeData = i_AluResult;
         1'b1: r_WB_writeData = i_datoLeido_MEM;
      endcase
   end//end_always
   
   //--------------------------------------------
   // Lectura y escritura: (update outputs)
   always @(posedge i_clk) begin: WB

      if(i_reset) begin       
         o_WB_writeData  <= 32'b0;
         o_cpu_finished  <= 1'b0; 
      end
      else if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)))begin 
         o_WB_writeData  <= r_WB_writeData;
         o_cpu_finished  <= i_halt;       
      end    
   end
   assign o_WB_writeData_forwarding = r_WB_writeData;
   assign o_rd = i_reset ? 5'b0 : i_rd;
   assign o_WB_regWrite = i_reset ? 1'b0 : i_regWrite;
endmodule
