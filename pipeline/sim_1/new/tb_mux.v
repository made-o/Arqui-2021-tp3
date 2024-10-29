`timescale 1ns / 1ps
module tb_mux();

  localparam NBITS = 32;
  localparam CLK_PERIOD = 10;

  reg  [NBITS-1:0] next_pc;
  reg  [NBITS-1:0] jump_pc;
  reg  jump_select;

  wire [NBITS-1:0]out;

  // Instanciar el modulo:
  mux_2_1 uut (
            .i_A(next_pc),
            .i_B(jump_pc),
            .select(jump_select),
            .o_out(out)
          );


  initial
  begin
    #20 next_pc = 32'b100011_00000_00001_0000_0000_0000_0001; // 8c010001
    #20 jump_pc = 32'b100011_00000_00010_0000_0000_0000_0010; // 8c020002

    #50 jump_select = 0;
    #50 jump_select = 1;

    // se observa antes que cuando el select = 0 a la salida esta jump_pc (entrada B)
    // y cuando select = 1, a la salida esta next_pc (entrada A)

    #50 $finish;
  end



endmodule
