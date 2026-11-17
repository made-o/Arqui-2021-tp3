`timescale 1ns / 100ps

(* keep = "true" *)module instruction_mem #(
    parameter DATA_WIDTH = 32,  //! RAM ancho de datos
    parameter DATA_DEPTH = 32, //! Direcciones de memoria (128 instrucciones)
    parameter ADDR_WIDTH = 5,   //! Ancho del bus de direcciones → 2^5=32 (Calculado manualmente según DATA_DEPTH)
    parameter FILE_DATA = "D:/FACULTAD/VivadoFiles/memIF.mem" //! archivo que contiene las instrucciones predefinidas
  )
  (
    input  i_clk, //! Clock (100 Mhz)
    input  i_valid,
    input  [ADDR_WIDTH-1:0] i_address, //! Dirección de la memoria
    
    input i_WriteEnable,
    input [ADDR_WIDTH-1:0] i_addr_carga,
    input [DATA_WIDTH-1:0] i_data_carga,
    input i_stall,
    input i_flush,
    
    input  i_exec_mode,
    input  i_step,

    
    output wire [DATA_WIDTH-1:0] o_data, //! Instrucción leída de la memoria
    output wire [DATA_WIDTH-1:0] o_data_send_tx,
    output  o_haltSignal //!
  );
  //! Variables internas
  (* ram_style = "block" *)reg [DATA_WIDTH-1:0] memBlock [DATA_DEPTH-1:0]; //! Array donde se almacenan las instrucciones
  reg [DATA_WIDTH-1:0] ram_data = {DATA_WIDTH{1'b0}}; //! Registro temporal que guarda la instrucción leída desde la memoria
  reg [DATA_WIDTH-1:0] data_send_tx = {DATA_WIDTH{1'b0}}; //! Registro temporal que guarda la instrucción leída desde la memoria
  
    initial
    begin
        memBlock[0] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[1] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[2] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[3] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[4] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[5] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[6] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[7] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[8] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[9] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[10] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[11] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[12] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[13] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[14] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[15] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[16] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[17] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[18] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[19] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[20] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[21] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[22] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[23] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[24] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[25] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[26] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[27] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[28] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[29] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[30] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[31] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
    end

  //! Lectura de la memoria
  //! Asignar el contenido en la dirección de memoria solicitada a los datos
  always @(posedge i_clk)
  begin : lectura
    if(i_valid && !i_stall && (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
    begin
      if((i_address >= DATA_DEPTH)) begin
        ram_data <= 32'hFFFFFFFF;
      end else begin
        ram_data <= memBlock[i_address];
      end
    end
    if (i_flush && (i_exec_mode == 1'b0 || (i_exec_mode && i_step))) begin
        ram_data <= 32'h0;
    end
  end
  
  always@(posedge i_clk)
  begin: carga
    if(i_WriteEnable)
    begin
        memBlock[i_addr_carga] <= i_data_carga;
    end
  end
  
  //! Comprobar instrucción HALT
  assign o_haltSignal = (((i_address >= DATA_DEPTH)||(memBlock[i_address] == 32'hFFFFFFFF)) && !i_flush);
  
  //! Asignación de la salida:
  assign o_data = ram_data;
  assign o_data_send_tx = data_send_tx;

endmodule
