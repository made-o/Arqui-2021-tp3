`timescale 1ns / 1ps

module sumador #(
   //Parameters:
   parameter NBITS = 32
)
   //Input and outputs:
(  input  [NBITS-1:0] i_PC,

   output [NBITS-1:0] o_PC_4
);
   
   // Increment the input by one (PC_out = PC_in + 4)
   assign o_PC_4 = i_PC + 1;


endmodule