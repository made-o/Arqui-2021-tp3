// We can instantiate here the uut_fifo_rx and the uut_fifo_tx
//! @title Interface UART
//! @author Johnston
//! @author Orona
//! El objetivo de este módulo de interfaz es gestionar la comunicación entre el resto del sistema y las FIFOs, sin que el sistema necesite conocer la implementación interna de las FIFOs.

module interface_uart
  #(
     parameter DATA_WIDTH = 8,  //! Ancho de los datos
     parameter FIFO_DEPTH = 16  //! Profundidad de la FIFO
   ) (
     input  wire i_reset,  //! Señal de reset para ambas FIFOs
     input  wire i_clock, //! 100Mhz Clock

     // Señales de FIFO_Rx:
     input  wire [DATA_WIDTH-1:0] i_rx_data,  //! Datos de entrada para FIFO_Rx
     input  wire i_rx_write,   //! Señal de escritura para FIFO_Rx
     input  wire i_rx_read,    //! Señal de lectura para FIFO_Rx

     output wire [DATA_WIDTH-1:0] o_rx_fifo_data, //! Datos de salida del FIFO_Rx
     output wire o_rx_empty,   //! Señal que indica si el FIFO_Rx está vacío
     output wire o_rx_full,    //! Señal que indica si el FIFO_Rx está lleno


     // Señales de FIFO_Tx:
     input  wire [DATA_WIDTH-1:0] i_tx_fifo_data, //! Datos de entrada para FIFO_Tx
     input  wire i_tx_write,  //! Señal de escritura para FIFO_Tx
     input  wire i_tx_read,   //! Señal de lectura para FIFO_Tx

     output wire [DATA_WIDTH-1:0] o_tx_data, //! Datos de salida del FIFO_Tx
     output wire o_tx_empty,  //! Señal que indica si el FIFO_Tx está vacío
     output wire o_tx_full    //! Señal que indica si el FIFO_Tx está lleno
   );

  // Instanciar la FIFO para recepción:
  FIFO #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH))
       FIFO_Rx (
         .i_reset    (i_reset),
         .i_clock    (i_clock),
         .i_write    (i_rx_write),
         .i_read     (i_rx_read),
         .i_w_data   (i_rx_data),
         .o_r_data   (o_rx_fifo_data),
         .o_empty    (o_rx_empty),
         .o_full     (o_rx_full)
       );

  // Instanciar la FIFO para transmisión
  FIFO #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH))
       FIFO_Tx (
         .i_reset  (i_reset),
         .i_clock  (i_clock),
         .i_write  (i_tx_write),
         .i_read   (i_tx_read),
         .i_w_data (i_tx_fifo_data),
         .o_r_data (o_tx_data),
         .o_empty  (o_tx_empty),
         .o_full   (o_tx_full)
       );

endmodule
