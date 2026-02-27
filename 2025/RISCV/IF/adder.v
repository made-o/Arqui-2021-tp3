`timescale 1ns / 1ps

(* keep *)module adder#(
    //Parameters:
    parameter NBITS = 32
  ) (
    input  [NBITS-1:0]  i_pc,
    //input               i_reset,
    //input i_enable,

    output [NBITS-1:0]  o_pc_next
  );

  // Increment the input by one (o_pc_next = i_pc + 1)
  //assign o_pc_next = i_reset ? {NBITS{1'b1}} : i_pc + 1;
  //assign o_pc_next = i_enable ? i_pc + 1 : {NBITS{1'b0}};
  assign o_pc_next = i_pc + 1;

endmodule

