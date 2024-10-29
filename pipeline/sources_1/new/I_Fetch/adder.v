`timescale 1ns / 1ps

module adder#(
    //Parameters:
    parameter NBITS = 32
  ) (
    input  [NBITS-1:0] i_pc,

    output [NBITS-1:0] o_pc_next
  );

  // Increment the input by one (o_pc_next = i_pc + 1)
  assign o_pc_next = i_pc + 1;

endmodule
