`timescale 1ns / 1ps

module tb_I_Fetch;

  // Definir parámetros
  localparam NBITS = 32;
  localparam CLK_PERIOD = 10;

  // Señales de prueba
  reg clk;
  reg reset;
  reg enable;
  reg halt;
  reg stall;
  reg [NBITS-1:0] jump_address;
  reg jump_select;

  wire [NBITS-1:0] instruction;
  wire halt_signal;

  // Instanciar el módulo I_Fetch
  I_Fetch #(.NBITS(NBITS)) uut (
            .i_clk(clk),
            .i_reset(reset),
            .i_enable(enable),
            .i_halt(halt),
            .i_stall(stall),
            .i_jump_address(jump_address),
            .i_jump_select(jump_select),
            .o_instruction(instruction),
            .o_halt_signal(halt_signal)
          );

  // Generar señal de reloj (clk)
  //always #5 clk = ~clk;  // Periodo del reloj: 10 unidades de tiempo

  // Generar el clock
  initial
    clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // Test de verificaci�n
  initial
  begin
    // Inicializar todas las se�ales
    clk = 0;
    reset = 1; // reset activo bajo
    enable = 0;
    halt = 0;
    stall = 0;
    jump_address = 0;
    jump_select = 0; //para que no salte

    // Monitoreo de salidas
    $monitor("Time: %0d, PC: %0h, Instruction: %h, Halt: %b",
             $time, uut.w_pc_current, instruction, halt_signal);

    // 1. Aplicar reset
    #10 reset = 0;  // Activar reset
    #20 reset = 1;  // Desactivar reset

    // 2. Habilitar el m�dulo y empezar a leer instrucciones
    enable = 1;
    #50;

    // 3. Dejar que el PC avance y se lean instrucciones
    // Ver�s que el PC deber�a ir incrementando y se deber�an leer instrucciones

    // 6. Continuar leyendo instrucciones
    #200;

    // 7. Detener la simulaci�n
    #500 $finish;
  end


endmodule
