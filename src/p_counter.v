`timescale 1ns / 1ps

module p_counter #(
   //Parameters:
   parameter NBITS = 32
)
   //Input and outputs:
(  input i_clk, i_reset, i_enable,
   input i_halt,
   input i_stall,
   input [NBITS-1:0] i_PC,
   
   output reg [NBITS-1:0] o_newPC
);

   // Update pc:
   always @(posedge i_clk) begin
      if(i_reset)
         o_newPC = {NBITS{1'b0}};
      else if(i_enable && !i_halt && !i_stall)
         o_newPC = i_PC;
      else if(i_PC != {NBITS{1'b0}) // en el caso inprobable que se genere un halt 
         o_newPC = i_PC - 1;        // en la instruccion -1 => no se porduciria un UnderFlow
      else                          // entonces se ejecuta la instruccion 0
         o_newPC = {NBITS{1'b0}};
   end   
    
endmodule
