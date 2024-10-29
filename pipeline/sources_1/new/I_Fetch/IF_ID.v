module IF_ID #(
    parameter NBITS = 32      //! Tamaño de las intrucciones
  )(
    input  i_clk,          //! Clock
    input  i_reset,        //! Reset
    input  i_enable,       //! Enable
    input  i_halt_signal,  //! Señal para detener el PC
    input  i_stall_signal, //! Señal para pausar el PC
    input  [NBITS-1:0] i_pc_next,     //! Valor del PC
    input  [NBITS-1:0] i_instruction, //! Instrucción

    output reg [NBITS-1:0] o_pc_next,     //! Valor del PC
    output reg [NBITS-1:0] o_instruction, //! Instrucción completa
    output reg [NBITS-1:0] o_instr_rs,    //! Instrucción → sólo bits del RS → instruction[25:21]
    output reg [NBITS-1:0] o_instr_rt,    //! Instrucción → sólo bits del RT → instruction[20:16]
    output reg [NBITS-1:0] o_instr_rd     //! Instrucción → sólo bits del RD → instruction[15:11]
  );

  // Inicialización del módulo:
  initial
  begin : initialization
    o_instruction <= 0;
    o_pc_next <= 0;
  end

  //! Actualización del valor:
  always @(posedge i_clk)
  begin : updateValues
    if (i_reset)
    begin
      o_instruction <= 0;
      o_pc_next <= 0;
    end
    else if (i_enable && !i_stall_signal)
    begin
      o_pc_next <= i_pc_next;
      o_instruction <= i_instruction;
      o_instr_rs <= i_instruction[25:21];
      o_instr_rt <= i_instruction[20:16];
      o_instr_rd <= i_instruction[15:11];
    end

  end

endmodule
