`timescale 1ns / 1ps

module tb_I_Fetch_seq();

  // Parámetros
  localparam NBITS = 32;
  localparam CLK_PERIOD = 10;

  // Entradas
  reg i_clk;
  reg i_reset;
  reg i_enable;
  reg i_halt;
  reg i_stall;
  reg [NBITS-1:0] i_jump_address;
  reg i_jump_select;

  // Salidas
  wire [NBITS-1:0] o_instruction;
  wire o_halt_signal;

  // Instancia del módulo I_Fetch
  I_Fetch #(.NBITS(NBITS)) uut (
            .i_clk(i_clk),
            .i_reset(i_reset),
            .i_enable(i_enable),
            .i_halt(i_halt),
            .i_stall(i_stall),
            .i_jump_address(i_jump_address),
            .i_jump_select(i_jump_select),
            .o_instruction(o_instruction),
            .o_halt_signal(o_halt_signal)
          );

  // Generar el clock
  initial
    i_clk = 1'b0;
  always #(CLK_PERIOD/2) i_clk = ~i_clk;

  // Proceso de test
  initial
  begin
    // Inicialización de señales
    i_reset = 1'b1;         // Activo el reset
    i_enable = 1'b0;        // Desactivo el enable
    i_halt = 1'b0;          // Desactivo el halt
    i_stall = 1'b0;         // Desactivo el stall
    i_jump_address = 0;     // Sin dirección de salto
    i_jump_select = 1'b0;   // No selecciono salto

    // Esperar algunos ciclos
    #(2*CLK_PERIOD);

    // Desactivar reset y habilitar el enable
    i_reset = 1'b0;
    i_enable = 1'b1;

    // Ahora, la memoria de instrucciones debería comenzar a leer las instrucciones consecutivamente

    // Esperar y verificar instrucciones consecutivas:
    #(CLK_PERIOD);
    $display("Instrucción en PC = 0: %b", o_instruction);  // Verificar instrucción en PC = 0

    #(CLK_PERIOD);
    $display("Instrucción en PC = 1: %b", o_instruction);  // Verificar instrucción en PC = 1

    #(CLK_PERIOD);
    $display("Instrucción en PC = 2: %b", o_instruction);  // Verificar instrucción en PC = 2

    #(CLK_PERIOD);
    $display("Instrucción en PC = 3: %b", o_instruction);  // Verificar instrucción en PC = 3

    // Verificar si alguna de estas instrucciones es un HALT (aunque no debería en este caso)
    if (o_halt_signal)
    begin
      $display("Se detectó una instrucción HALT");
    end
    else
    begin
      $display("No se detectó instrucción HALT");
    end

    // Finalizar simulación
    #(CLK_PERIOD);
    $finish;
  end

endmodule
