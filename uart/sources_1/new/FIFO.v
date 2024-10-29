//! @title uart Fifo
//! @author Madeeee

module FIFO #(
    parameter DATA_WIDTH = 8,  //! Ancho de datos
    parameter DEPTH = 16   //! Profundidad del FIFO
  ) (
    // inputs:
    input wire i_reset,
    input wire i_clock,    //! 100Mhz Clock
    input wire i_write,    //! Señal de escritura
    input wire i_read,     //! Señal de lectura
    input wire [DATA_WIDTH-1:0] i_w_data, //! Datos de entrada

    // outputs:
    output wire [DATA_WIDTH-1:0] o_r_data, //! Datos de salida
    output wire o_empty,  //! Indicador de FIFO vacío
    output wire o_full    //! Indicador de FIFO lleno
  );

  // Variables auxiliares:
  reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1]; //! Memoria FIFO
  reg [DATA_WIDTH-1:0] wr_ptr = 0; //! Puntero de escritura
  reg [DATA_WIDTH-1:0] rd_ptr = 0; //! Puntero de lectura
  reg [DATA_WIDTH-1:0] count = 0;  //! Contador de elementos en FIFO

  // Indicadores de estado:
  assign o_empty = (count == 0); // El FIFO está vacío si count es 0
  assign o_full = (count == DEPTH); // El FIFO está lleno si count es igual a la profundidad
  assign o_r_data = fifo_mem[rd_ptr];  // Dato de salida del FIFO, apuntado por rd_ptr


  // Lógica secuencial: se ejecuta en cada flanco positivo del reloj o del reset:
  always @(posedge i_clock or posedge i_reset)
  begin : LogicaSecuencial
    if (i_reset)
    begin
      //! Si se activa el reset, se reinician los punteros y el contador
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
    end
    else
    begin
      //! Escribir en el FIFO
      if (i_write && !o_full)
      begin
        fifo_mem[wr_ptr] <= i_w_data; // Escribir el dato en la posición indicada por wr_ptr
        wr_ptr <= wr_ptr + 1; // Incrementar el puntero de escritura
        count <= count + 1; // Incrementar el contador de elementos
      end

      //! Leer del FIFO
      if (i_read && !o_empty)
      begin
        rd_ptr <= rd_ptr + 1; // Incrementar el puntero de lectura
        count <= count - 1; // Decrementar el contador de elementos
      end
    end
  end

endmodule
