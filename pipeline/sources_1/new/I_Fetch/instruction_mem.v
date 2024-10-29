`timescale 1ns / 1ps

module instruction_mem #(
    parameter DATA_WIDTH = 32,  //! RAM ancho de datos
    parameter DATA_DEPTH = 128, //! Direcciones de memoria (128 instrucciones)
    parameter ADDR_WIDTH = 7,   //! Ancho del bus de direcciones → 2^7=128 (Calculado manualmente según DATA_DEPTH)
    parameter FILE_DATA = "D:/FACULTAD/VivadoFiles/memIF.mem" //! archivo que contiene las instrucciones predefinidas
  )
  (
    input  i_clk, //! Clock (100 Mhz)
    input  i_valid,
    input  [ADDR_WIDTH-1:0] i_address, //! Dirección de la memoria

    output wire [DATA_WIDTH-1:0] o_data, //! Instrucción leída de la memoria
    output reg  o_haltSignal //!
  );
  //! Variables internas
  reg [DATA_WIDTH-1:0] memBlock [DATA_DEPTH-1:0]; //! Array donde se almacenan las instrucciones
  reg [DATA_WIDTH-1:0] ram_data = {DATA_WIDTH{1'b0}}; //! Registro temporal que guarda la instrucción leída desde la memoria

  // //! Inicialización de la memoria de manera automática:
  // initial
  // begin : initMemory
  //   if(FILE_DATA != "")
  //   begin
  //     $readmemb(FILE_DATA, memBlock, 0, DATA_DEPTH-1);
  //   end
  // end

  //! Inicialización de la memoria de manera manual:
  initial
  begin
    memBlock[0]  <= 32'b100011_00000_00001_0000_0000_0000_0001;  // LW r1 , 1(r0)
    memBlock[1]  <= 32'b100011_00000_00010_0000_0000_0000_0010;  // LW r2 , 2(r0)
    memBlock[2]  <= 32'b100011_00000_00011_0000_0000_0000_0011;  // LW r3 , 3(r0)
    memBlock[3]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[4]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[5]  <= 32'b000000_00001_00010_00001_00000_100000;   // ADD r1, r1, r2
    memBlock[6]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[7]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[8]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[9]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[10]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
    memBlock[11]  <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP

    memBlock[20] <= 32'b1111_1100_0000_0000_0000_0000_0000_0000; // HALT
    //memBlock[127] <= 32'b1000_0000_0000_0000_0000_0000_0000_0000; // NOP
  end

  //! Lectura de la memoria
  //! Asignar el contenido en la dirección de memoria solicitada a los datos
  always @(posedge i_clk)
  begin : lectura
    if(i_valid)
    begin
      ram_data <= memBlock[i_address];
    end
  end

  //! Comprobar instrucción HALT
  always @(posedge i_clk)
  begin : checkHalt
    if(o_data[31:26] == 6'b111111)
    begin
      o_haltSignal <= 1'b1;
    end
    else
    begin
      o_haltSignal <= 1'b0;
    end
  end

  //! Asignación de la salida:
  assign o_data = ram_data;

endmodule
