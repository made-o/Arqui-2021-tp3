module execute #(
    parameter NBITS = 32 //! Tamaño de las direcciones (32 bits)
  ) (
    input  i_clk,    //! Clock (100 MHz)
    input  i_reset,  //! Reinicio
    input  [NBITS-1:0] i_pc,

    output [NBITS-1:0] o_new_pc //! Nueva dirección del PC
  );



endmodule