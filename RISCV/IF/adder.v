`timescale 1ns / 100ps

(* keep *)module adder#(
    //Parameters:
    parameter NBITS = 32
  ) (
    input  [NBITS-1:0]  i_pc,
    input               i_reset,

    output [NBITS-1:0]  o_pc_next
  );

  assign o_pc_next = i_reset ? {NBITS{1'b0}} : i_pc + 1;

endmodule

