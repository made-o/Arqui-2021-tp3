`timescale 1ns / 1ps

(* keep = "true" *)module I_Fetch #(
    parameter NBITS = 32,      //! Tamaño de las intrucciones
    parameter ADDR_WIDTH = 5
  )(
    input  i_clk,         //! Clock
    input  i_reset,       //! Reset
    input  i_enable,      //! Enable
    //input  i_halt,        //! Señal para detener el PC
    input  i_stall,       //! Señal para pausar el PC
    input  i_inicializando,
    input  [NBITS-1:0] i_jump_address,  //! Dirección de salto en caso de branch/jump
    input  i_jump_select, //! Selección de salto (branch/jump select)
    
    //input [ADDR_WIDTH-1:0] i_addr_tx,
    
    input i_WriteEnable,
    input [ADDR_WIDTH-1:0] i_addr_carga,
    input [NBITS-1:0] i_data_carga,
    
    input  i_exec_mode,
    input  i_step,
    
    output reg [NBITS-1:0] o_instruction, //! Instrucción de la memoria de instrucciones
    output [NBITS-1:0] o_data_send_tx,
    output reg o_halt_signal,              //! Señal de halt si se encuentra una instrucción HALT
    //output [NBITS-1:0] o_pc_current,   //! Valor actual del PC
    output [NBITS-1:0] o_pc
  );

  //! Señales internas:
  wire [NBITS-1:0] w_pc_current;     //! Valor actual del PC
  wire [NBITS-1:0] w_pc_next;        //! Valor del PC seleccionado (salto o secuencial)
  wire [NBITS-1:0] w_pc_jump; 
  wire [NBITS-1:0] w_pc_incremented; //! Valor del PC incrementado (PC + 1)

  //latch IF_ID
  wire halt_signal;
  wire [NBITS-1:0] w_instruction;

  wire [NBITS-1:0] w_pc_to_register;

  //assign w_pc_to_register = (i_reset | i_inicializando) ? {NBITS{1'b0}} : w_pc_jump;

  //always @(posedge i_clk)
  //begin
   // if(i_reset)
   //   w_pc_current <=  {NBITS{1'b0}};
  //dsdend
  //! Instancia del PC
(* keep = "true" *)  pc #(.NBITS(NBITS))
     program_counter (
       .i_clk(i_clk),           //! Reloj
       .i_reset(i_reset),       //! Reset
       .i_enable(i_enable),     //! Habilitación constante (en este caso está siempre activo)
       .i_halt(halt_signal),         //! Señal de halt
       .i_stall(i_stall),       //! Señal de stall
       .i_inicializando (i_inicializando),
       .i_pc(w_pc_jump),        //! Siguiente valor del PC (seleccionado por el mux)
       
       .i_exec_mode(i_exec_mode),
       .i_step(i_step),
    
       .o_new_pc(w_pc_next),      //! Valor actual del PC
       .o_pc_current(w_pc_current)
     );
  //assign w_pc_next = w_pc_current;
  //! Instancia del sumador
 (* keep = "true" *) adder #(.NBITS(NBITS))
        pc_adder (
          .i_pc(w_pc_next),
          //.i_reset(i_reset),
          //.i_enable(i_enable),
          
          .o_pc_next(w_pc_incremented) //! PC incrementado en 1
        );

  //! Instancia del multiplexor
(* keep = "true" *)  mux_2_1 #(.NBITS(NBITS))
          pc_mux (
            .i_A(w_pc_incremented),   //! Valor incrementado
            .i_B(i_jump_address),     //! Dirección de salto
            .select(i_jump_select),   //! Selección de la entrada
            .o_out(w_pc_jump)         //! Salida del mux
          );

  //! Instancia de la memoria de instrucciones
 (* keep = "true" *) instruction_mem #(.DATA_WIDTH(NBITS))
                  instr_mem (
                    .i_clk(i_clk),
                    .i_valid(i_enable),
                    .i_address(w_pc_next[4:0]),    //! Dirección del PC
                    
                    //.i_addr_tx(i_addr_tx), // Direccion de la memoria que se quiere enviar por uart
                    .i_WriteEnable(i_WriteEnable),
                    .i_addr_carga(i_addr_carga),
                    .i_data_carga(i_data_carga),
                    .i_stall(i_stall),
                    .i_flush(i_jump_select),
                           
                    .i_exec_mode(i_exec_mode),
                    .i_step(i_step),
    
                    .o_data(w_instruction),    //! Instrucción en la dirección actual
                    .o_data_send_tx(o_data_send_tx),
                    .o_haltSignal(halt_signal) //! Señal HALT si se detecta una instrucción HALT
                  );
   assign o_pc = w_pc_current;
   //assign o_pc_current = w_pc_current;

  always @(posedge i_clk) begin: FD_ID
    if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)) && !i_stall)
    begin
      o_halt_signal <= halt_signal;
      o_instruction <= w_instruction;
    end
  end


endmodule