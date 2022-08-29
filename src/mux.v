`timescale 1ns / 1ps

module mux #(
   //Parameters:
   parameter NBITS = 32
)
   //Input and outputs:
(  input [NBITS-1:0] in_A,
   input [NBITS-1:0] in_B,
   input select,
    
   output [NBITS-1:0] out
);

   // if select = 1, choose (a), else (b)
   assign out = select ? in_B : in_A;


endmodule