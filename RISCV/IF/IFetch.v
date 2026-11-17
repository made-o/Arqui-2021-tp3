`timescale 1ns / 100ps

(* keep = "true" *)module I_Fetch #(
    parameter NBITS = 32,      //! Tamaño de las intrucciones
    parameter ADDR_WIDTH = 5
  )(
    input               i_clk,            //! Clock
    input               i_reset,          //! Reset
    input               i_enable,         //! Enable
    input               i_stall,          //! Señal para pausar el PC
    input               i_inicializando,
    input  [NBITS-1:0]  i_jump_address,   //! Dirección de salto en caso de branch/jump
    input               i_flush,  
    input               i_pc_selec,  
    
    input i_WriteEnable,
    input [ADDR_WIDTH-1:0] i_addr_carga,
    input [NBITS-1:0] i_data_carga,
    
    input  i_exec_mode,
    input  i_step,
    
    output [NBITS-1:0] o_instruction, //! Instrucción de la memoria de instrucciones
    output reg o_halt_signal,              //! Señal de halt si se encuentra una instrucción HALT
    output reg [NBITS-1:0] o_pc_UART,
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

  //! Instancia del PC
(* keep = "true" *)  pc #(.NBITS(NBITS))
     program_counter (
        .i_clk(i_clk),           //! Reloj
        .i_reset(i_reset),       //! Reset
        .i_enable(i_enable),    
        .i_halt(halt_signal),         //! Señal de halt
        .i_stall(i_stall),       //! Señal de stall
        .i_inicializando (i_inicializando),
        .i_pc(halt_signal ? w_pc_jump : w_pc_incremented),
       
        .i_exec_mode(i_exec_mode),
        .i_step(i_step),
    
        .o_new_pc(w_pc_next),      //! Valor actual del PC
        .o_pc_current(w_pc_current)
     );
  
  //! Instancia del sumador
 (* keep = "true" *) adder #(.NBITS(NBITS))
        pc_adder (
          .i_pc(w_pc_jump),
          .i_reset(i_reset),
          
          .o_pc_next(w_pc_incremented) //! PC incrementado en 1
        );

  //! Instancia del multiplexor
(* keep = "true" *)  mux_2_1 #(.NBITS(NBITS))
          pc_mux (
            .i_A(w_pc_next), 
            .i_B(i_jump_address),     //! Dirección de salto
            .select(i_pc_selec),   //! Selección de la entrada
            .o_out(w_pc_jump)         //! Salida del mux
          );

  //! Instancia de la memoria de instrucciones
 (* keep = "true" *) instruction_mem #(.DATA_WIDTH(NBITS))
                  instr_mem (
                    .i_clk(i_clk),
                    .i_valid(i_enable),
                    .i_address(w_pc_jump[4:0]),    //! Dirección del PC
                    
                    .i_WriteEnable(i_WriteEnable),
                    .i_addr_carga(i_addr_carga),
                    .i_data_carga(i_data_carga),
                    .i_stall(i_stall),
                    .i_flush(i_flush),
                           
                    .i_exec_mode(i_exec_mode),
                    .i_step(i_step),
    
                    .o_data(w_instruction),    //! Instrucción en la dirección actual
                    .o_data_send_tx(o_data_send_tx),
                    .o_haltSignal(halt_signal) //! Señal HALT si se detecta una instrucción HALT
                  );
  assign o_pc = w_pc_current;
  assign o_instruction = w_instruction;

  always @(posedge i_clk) begin: FD_ID
    if (i_reset) begin
      o_halt_signal <= 1'b0;
    end
    else
    begin
      if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)) && !i_stall)
      begin
        o_halt_signal  <= halt_signal;
        o_pc_UART <= w_pc_jump;
      end
    end
  end


endmodule