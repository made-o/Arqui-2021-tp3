`timescale 1ns / 1ps

(* keep *)module mux_2_1 #(
    parameter NBITS = 32
  ) (
    input  [NBITS-1:0] i_A, //! Entrada A
    input  [NBITS-1:0] i_B, //! Entrada B
    input  select,          //! Selector

    output [NBITS-1:0] o_out  //! Salida A o B, de acuerdo a la elección del selector
  );

  assign    o_out = select ? i_B : i_A; //! If select == 1, then o_out = in_B.

endmodule
