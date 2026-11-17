`timescale 1ns / 100ps

(* keep *)module pc #(
    parameter NBITS = 32 //! Tamaño de las direcciones (32 bits)
  ) (
    input  i_clk,    //! Clock (100 MHz)
    input  i_reset,  //! Reinicio
    input  i_enable, //! Señal para habilitar la actualización del PC
    input  i_stall,  //! Señal para pausar temporalmente la actualización del PC
    input  i_inicializando, // Señal que me determina si se esta cargando las instrucciones.
    input  [NBITS-1:0] i_pc,
    input  i_exec_mode,
    input  i_step,

    output [NBITS-1:0] o_new_pc, 
    output [NBITS-1:0] o_pc_current 
  );

  reg [NBITS-1:0] newPc; //! Registro auxiliar
  reg [NBITS-1:0] pc_current; //! Registro auxiliar

  always @(posedge i_clk)
  begin : assignPC
    if (i_reset) //Reset se activa por alto
    begin
      // Si hay reset, el PC se reinicia a 0
      newPc <= {NBITS{1'b0}};
      pc_current <= {NBITS{1'b0}};
    end
    else
    begin
      if (i_enable && !i_stall && !i_inicializando && 
                 (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
      begin
        // Si enable está activo, el PC se actualiza con i_pc
        pc_current <= newPc;
        newPc <= i_pc;
      end
    end
  end

  //! Asigno la salida elegida:
  assign o_new_pc = newPc;
  assign o_pc_current = pc_current;

endmodule
