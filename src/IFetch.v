`timescale 1ns / 1ps

module IFetch #(
   //Parameters:
   parameter NBITS = 32
)
   //Input and outputs:
(  input  i_clk,
   input  i_enable,
   input  i_reset,
   input  i_PCWrite,
   input  i_PCSource,
   input  i_stall,
   input  [NBITS-1:0] i_PC_MEM,
   //input  [NBITS-1:0] i_instruction,
   //input  [NBITS-1:0] i_address,
    
   output o_stall,
   output [NBITS-1:0] o_PC_4,
   output [NBITS-1:0] o_instruction
   
);
    
   //Variables internas:
   wire w_halt;
   wire w_data_instruction;
   wire [NBITS-1:0] w_newPC;
   wire [NBITS-1:0] w_muxToPC;
   wire [NBITS-1:0] w_SumMux;

   
   // Assign outputs:
   assign o_instruction = w_data_instruction;
   assign o_stall = i_stall;
   assign o_PC_4 = w_newPC;
   

   ////////////////////////////////////////////////////
   // MODULES INSTANTIATION:
   mux
   u_mux (
      .in_A(w_SumMux),
      .in_B(i_PC_MEM),
      .select(i_PCSource),
      
      .out(w_muxToPC)
   );
   
   p_counter
   u_pCounter(
      .i_clk(i_clk),
      .i_reset(i_reset),
      .i_enable(i_enable),
      .i_halt(w_halt),
      .i_stall(i_stall),
      .i_PC(w_muxToPC),
      
      .o_newPC(w_newPC)   
   );
   
   sumador
   u_sumador(
      .i_PC(w_newPC),
      
      .o_PC_4(w_SumMux)
   );
   
   instructionMemory 
   u_instr_mem (
       .i_address(w_newPC),
       .i_clk(i_clk),
       .i_valid(i_PCWrite),
       
       .o_data(w_data_instruction),
       .o_haltSignal(w_halt)
   );
   
   
endmodule