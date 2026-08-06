`timescale 1ns / 1ps

module fowarding_unit #(
   // Parameters:
   parameter N_BITS_REG = 5
)
   // Inputs & Outputs:
(  // Inputs de la etapa ID/EX:
   input  [N_BITS_REG-1:0] i_rs1_id,
   input  [N_BITS_REG-1:0] i_rs2_id,
   
   // Inputs de la etapa EX/MEM:
   input  [N_BITS_REG-1:0] i_rd_EX_MEM,
   input  i_regWrite_EX_MEM,
   
   // Inputs de la etapa MEM/WB:
   input  [N_BITS_REG-1:0] i_rd_MEM_WB, 
   input  i_regWrite_MEM_WB,
   
   output reg [1:0] o_forwardA,
   output reg [1:0] o_forwardB
);

   reg condition1_EX;  
   reg condition2_EX;  
   reg condition1_MEM;
   reg condition2_MEM; 

////////////////////////////////////////////////////
   // Start-code:
   
   always @(*) begin 
      o_forwardA = 2'b00;
      o_forwardB = 2'b00;
      
      // Concatenaci�n de inputs para riesgos de EX: 
      // Concatenaci�n de 3-bits
      condition1_EX = {i_regWrite_EX_MEM && 
                     (i_rd_EX_MEM != 0)&& 
                     (i_rd_EX_MEM == i_rs1_id)};
      condition2_EX = {i_regWrite_EX_MEM && 
                     (i_rd_EX_MEM != 0) && 
                     (i_rd_EX_MEM == i_rs2_id)};
      
      if(condition1_EX == 1'b1)
         o_forwardA = 2'b10; // Se�al para la ALU
      if(condition2_EX == 1'b1)
         o_forwardB = 2'b10; // Se�al para la ALU
      
      // Concatenaci�n de inputs para riesgos de MEM:
      // Concatenaci�n de 4-bits
      condition1_MEM = {i_regWrite_MEM_WB && 
                        (i_rd_MEM_WB != 0) &&
                       ~(condition1_EX) && //La condicion1_EX tiene prioridad
                        (i_rd_MEM_WB == i_rs1_id)};
      condition2_MEM = {i_regWrite_MEM_WB && 
                        (i_rd_MEM_WB != 0) &&
                       ~(condition2_EX) && //La condicion2_EX tiene prioridad
                        (i_rd_MEM_WB == i_rs2_id)};
      
      if(condition1_MEM == 1'b1)
         o_forwardA = 2'b01; // Se�al para la MEM
      if(condition2_MEM == 1'b1)
         o_forwardB = 2'b01; // Se�al para la MEM
      
   
   end//end_always
endmodule
