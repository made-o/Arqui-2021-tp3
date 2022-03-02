`timescale 1ns / 1ps

module fowarding_unit #(
   // Parameters:
   parameter N_BITS_REG = 6
)
   // Inputs & Outputs:
(  // Inputs de la etapa ID/EX:
   input  [N_BITS_REG-1:0] i_rt_id,
   input  [N_BITS_REG-1:0] i_rs_id,
   
   // Inputs de la etapa EX/MEM:
   input  [N_BITS_REG-1:0] i_rd_EX_MEM,
   input  i_regWrite_EX_MEM,
   
  // Inputs de la etapa MEM/WB:
   input  [N_BITS_REG-1:0] i_rd_MEM_WB, 
   input  i_regWrite_MEM_WB,
   
   output reg [1:0] o_forwardA,
   output reg [1:0] o_forwardB
);

   reg [2:0] temp1_EX;  // 3-bits
   reg [2:0] temp2_EX;  // 3-bits
   reg [3:0] temp1_MEM; // 4-bits
   reg [3:0] temp2_MEM; // 4-bits

////////////////////////////////////////////////////
   // Start-code:
   
   always @(*) begin 
   o_forwardA = 2'b00;
   o_forwardB = 2'b00;
   
   // Concatenación de inputs para riesgos de EX: 
   // Concatenación de 3-bits
   temp1_EX = {i_regWrite_EX_MEM, 
                  (i_rd_EX_MEM != 0), 
                  (i_rd_EX_MEM == i_rs_id)};
   temp2_EX = {i_regWrite_EX_MEM, 
                  (i_rd_EX_MEM != 0), 
                  (i_rd_EX_MEM == i_rt_id)};
   
   if(temp1_EX == 3'b111)
      o_forwardA = 2'b10; // Señal para la ALU
   if(temp2_EX == 3'b111)
      o_forwardB = 2'b10; // Señal para la ALU
   
   // Concatenación de inputs para riesgos de MEM:
   // Concatenación de 4-bits
   temp1_MEM = {i_regWrite_MEM_WB, 
                  (i_rd_MEM_WB != 0),
                 ~(i_regWrite_EX_MEM && (i_rd_EX_MEM != 0) && (i_rd_EX_MEM != i_rs_id)), 
                  (i_rd_MEM_WB == i_rs_id)};
   temp2_MEM = {i_regWrite_MEM_WB, 
                  (i_rd_MEM_WB != 0),
                 ~(i_regWrite_EX_MEM && (i_rd_EX_MEM != 0) && (i_rd_EX_MEM != i_rt_id)), 
                  (i_rd_MEM_WB == i_rt_id)};
   
   if(temp1_MEM == 4'b1111)
      o_forwardA = 2'b10; // Señal para la MEM
   if(temp2_MEM == 4'b1111)
      o_forwardB = 2'b10; // Señal para la MEM
   
   
   end//end_always
endmodule
