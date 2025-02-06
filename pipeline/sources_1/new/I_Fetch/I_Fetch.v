`timescale 1ns / 1ps

module I_Fetch #(
    parameter NBITS = 32,      //! Tamaño de las intrucciones
    parameter ADDR_WIDTH = 5
  )(
    input  i_clk,         //! Clock
    input  i_reset,       //! Reset
    input  i_enable,      //! Enable
    input  i_halt,        //! Señal para detener el PC
    input  i_stall,       //! Señal para pausar el PC
    input  i_inicializando,
    input  [NBITS-1:0] i_jump_address,  //! Dirección de salto en caso de branch/jump
    input  i_jump_select, //! Selección de salto (branch/jump select)
    
    input [ADDR_WIDTH-1:0] i_addr_tx,
    
    input i_WriteEnable,
    input [ADDR_WIDTH-1:0] i_addr_carga,
    input [NBITS-1:0] i_data_carga,
    
    input  i_exec_mode,
    input  i_step,
    
    output [NBITS-1:0] o_instruction, //! Instrucción de la memoria de instrucciones
    output [NBITS-1:0] o_data_send_tx,
    output o_halt_signal,              //! Señal de halt si se encuentra una instrucción HALT
    output [NBITS-1:0] o_pc
  );

  //! Señales internas:
  wire [NBITS-1:0] w_pc_current;     //! Valor actual del PC
  wire [NBITS-1:0] w_pc_next;        //! Valor del PC seleccionado (salto o secuencial)
  wire [NBITS-1:0] w_pc_incremented; //! Valor del PC incrementado (PC + 1)

  //! Instancia del PC
  pc #(.NBITS(NBITS))
     program_counter (
       .i_clk(i_clk),           //! Reloj
       .i_reset(i_reset),       //! Reset
       .i_enable(i_enable),     //! Habilitación constante (en este caso está siempre activo)
       .i_halt(i_halt),         //! Señal de halt
       .i_stall(i_stall),       //! Señal de stall
       .i_inicializando (i_inicializando),
       .i_pc(w_pc_next),        //! Siguiente valor del PC (seleccionado por el mux)
       
       .i_exec_mode(i_exec_mode),
       .i_step(i_step),
    
       .o_new_pc(w_pc_current)      //! Valor actual del PC
     );

  //! Instancia del sumador
  adder #(.NBITS(NBITS))
        pc_adder (
          .i_pc(w_pc_current),
          .o_pc_next(w_pc_incremented) //! PC incrementado en 1
        );

  //! Instancia del multiplexor
  mux_2_1 #(.NBITS(NBITS))
          pc_mux (
            .i_A(w_pc_incremented),   //! Valor incrementado
            .i_B(i_jump_address),     //! Dirección de salto
            .select(i_jump_select),   //! Selección de la entrada
            .o_out(w_pc_next)         //! Salida del mux
          );

  //! Instancia de la memoria de instrucciones
  instruction_mem #(.DATA_WIDTH(NBITS))
                  instr_mem (
                    .i_clk(i_clk),
                    .i_valid(i_enable),
                    .i_address(w_pc_current),    //! Dirección del PC
                    .i_addr_tx(i_addr_tx), // Direccion de la memoria que se quiere enviar por uart
                    .i_WriteEnable(i_WriteEnable),
                    .i_addr_carga(i_addr_carga),
                    .i_data_carga(i_data_carga),
                    .o_data(o_instruction),    //! Instrucción en la dirección actual
                    .o_data_send_tx(o_data_send_tx),
                    .o_haltSignal(o_halt_signal) //! Señal HALT si se detecta una instrucción HALT
                  );
   assign o_pc = w_pc_next;

endmodule
