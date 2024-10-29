`timescale 1ns / 1ps

module pc #(
    parameter NBITS = 32 //! Tamaño de las direcciones (32 bits)
  ) (
    input  i_clk,    //! Clock (100 MHz)
    input  i_reset,  //! Reinicio
    input  i_enable, //! Señal para habilitar la actualización del PC
    input  i_halt,   //! Señal para detener la actualización del PC
    input  i_stall,  //! Señal para pausar temporalmente la actualización del PC
    input  [NBITS-1:0] i_pc,

    output [NBITS-1:0] o_new_pc //! Nueva dirección del PC
  );

  reg [NBITS-1:0] newPc; //! Registro auxiliar


  //! Update pc with the new PC value:
  //  always @(posedge i_clk or negedge i_reset)
  //  begin : assignPC
  //    if (!i_reset) //Reset se activa por bajo (cuando reset=0)
  //    begin
  //      // Si hay reset, el PC se reinicia a 0
  //      newPc <= {NBITS{1'b0}};
  //    end
  //    else if (i_halt)
  //    begin
  //      // Si se activa halt, el PC no cambia, se mantiene el valor actual
  //      newPc <= o_new_pc;
  //    end
  //    else if (i_stall)
  //    begin
  //      // Si hay stall, el PC tampoco debe cambiar
  //      newPc <= o_new_pc;
  //    end
  //    else if (i_enable)
  //    begin
  //      // Si enable está activo, el PC se actualiza con i_pc
  //      newPc <= i_pc;
  //    end
  //  end

  always @(posedge i_clk)
  begin : assignPC
    if (!i_reset) //Reset se activa por bajo (cuando reset=0)
    begin
      // Si hay reset, el PC se reinicia a 0
      newPc <= {NBITS{1'b0}};
    end
    else
    begin
      if (i_enable && !i_halt && !i_stall)
      begin
        // Si enable está activo, el PC se actualiza con i_pc
        newPc <= i_pc;
      end
    end
  end

  //! Asigno la salida elegida:
  assign o_new_pc = newPc;

endmodule
