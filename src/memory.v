`timescale 1ns / 1ps

module memory #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 5
)
(  input  wire i_clk,
   input  wire i_reset,
   input  wire i_valid,
   
   // Señales de control (que vienen de la etapa ID)
   input  wire i_branch,
   input  wire i_memRead,
   input  wire i_memWrite,
   
   // Señales de control (para la etapa WB)
   input  wire i_memToReg,
   input  wire i_regWrite,
   
   input  wire i_ceroSignal,
   
   input  wire [N_BITS-1:0] i_aluResult,
   input  wire [N_BITS-1:0] datoLeido2,
   input  wire [N_BITS_REG-1:0] i_rt_EX,
   input  wire [N_BITS_REG-1:0] i_rd_EX,
   
   
  

)


endmodule