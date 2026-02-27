`timescale 1ns / 1ps

module memory #(
   parameter N_BITS = 32,
   parameter N_BITS_REG = 5,
   parameter RAM_DEPTH = 128
)
(  // INPUTS:
   input  i_clk,
   input  i_reset,
   input  i_halt,
   //input  i_valid,
   
   // Se�ales de control (que vienen de la etapa ID)
   //input  i_branch,
   input  i_memRead,
   input  i_memWrite,
   
   // Se�ales de control (para la etapa WB)
   input  i_memToReg,
   input  i_regWrite,
   
   //input  i_ceroSignal,
   
   // Entradas que van a ser salidas directas a la sig. etapa
   input  [N_BITS-1:0]     i_aluResult, // retorna para la etapa EX - (i_memData)
   input  [N_BITS-1:0]     i_datoLeido2, 
   input  [N_BITS_REG-1:0] i_rt_OR_rd,
   input  [N_BITS_REG-1:0] i_rd_EX_MEM, // retorna para la etapa EX - bloque forwarding
   input                   i_exec_mode,
   input                   i_step,
   
   input [$clog2(RAM_DEPTH)-1:0] i_addr_tx_MEM,
   // OUTPUTS:
   output [N_BITS-1:0] o_data_send_tx_MEM,

   output reg o_memToReg_MEM_WB,
   output reg o_regWrite_MEM_WB,
   
   // se�ales de control
   //output wire o_pcSource, // que va a la etapa IF
   //output reg o_cpu_finished,
   output reg o_halt,

   output reg [N_BITS-1:0]     o_readData,
   output reg [N_BITS-1:0]     o_aluResult,
   output reg [N_BITS_REG-1:0] o_rt_OR_rd,
   output reg [N_BITS_REG-1:0] o_rd_MEM
);
   
   // Variables internas:
   //reg memToReg;
   //reg regWrite;
   
   wire [N_BITS-1:0] w_readData;
   //reg pcSource;
   //reg [N_BITS-1:0] readData;
   //reg [N_BITS-1:0] aluResult;
   //reg [N_BITS_REG-1:0] rd_MEM;
   
   ////////////////////////////////////////////////////
   // Start-code:
   /* no es necesario se adelanta a la etapa ID
   // Branch Logic:
   always @(i_branch or i_ceroSignal) begin
      if(i_branch == 1'b1 & i_ceroSignal == 1'b1)
         pcSource = 1'b1;
      else
         pcSource = 1'b0;
   end
   assign o_pcSource = pcSource;
   */ 
   ////////////////////////////////////////////////////
   // Instanciacion de m�dulo de memory_data:
   dataMemory #(
        .RAM_WIDTH(N_BITS),
        .RAM_DEPTH(RAM_DEPTH)
    )u_dataMemory (
      .i_address(i_aluResult[$clog2(RAM_DEPTH)-1:0]),
      .i_write_data(i_datoLeido2),
      //.i_valid(i_valid),
      .i_clk(i_clk),
      .i_read_enable(i_memRead),
      .i_write_enable(i_memWrite),
      .i_addr_tx(i_addr_tx_MEM),
      
      .o_data_send_tx(o_data_send_tx_MEM),
      .o_read_data(w_readData)
   );

   always @(posedge i_clk) begin: ID_EX

      if(i_reset) begin
         o_readData        <= {N_BITS{1'b0}};
         o_rd_MEM          <= {N_BITS_REG{1'b0}};
         o_rt_OR_rd        <= {N_BITS_REG{1'b0}};
         o_memToReg_MEM_WB <= 1'b0;
         o_regWrite_MEM_WB <= 1'b0;
         o_aluResult         <= {N_BITS{1'b0}};
      end

      if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)))begin
         // datos de 32 bits
         o_readData        <= w_readData;
         o_aluResult       <= i_aluResult;
         // Para el modulo forwarding
         o_rd_MEM          <= i_rd_EX_MEM;
         // Direccion de carga en la memoria de registros.
         o_rt_OR_rd        <= i_rt_OR_rd;
         // Bits de control
         o_memToReg_MEM_WB <= i_memToReg;//selecciona entre los dos datos de 32 bits
         o_regWrite_MEM_WB <= i_regWrite;//Define si se escribe o no en los registros(tambien forwarding)
         o_halt    <= i_halt;
      end    
   end
   
   
endmodule