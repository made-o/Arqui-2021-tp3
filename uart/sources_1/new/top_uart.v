module top_uart #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
  )
  (
    input wire i_reset,
    input wire i_clock,

    // Señales UART:
    input  wire i_rx,
    output wire o_tx,

    // Señales que se comunican con el pipeline:
    input  wire [DATA_WIDTH-1:0] i_pipeline_data,
    input  wire i_pipeline_read,
    input  wire i_pipeline_write,
    output wire [DATA_WIDTH-1:0] o_pipeline_data
  );

  // Señales internas:
  wire [DATA_WIDTH-1:0] rx_data, tx_data;
  wire rx_done, tx_start, tx_done;
  wire s_tick;
  wire rx_fifo_empty, tx_fifo_empty, rx_fifo_full, tx_fifo_full;

  //// Instanciación:
  // Baudrate Generator
  baudrate_generator #(.N(10), .M(652))
                     uut_baud_gen (
                       .i_clock(i_clock),
                       .i_reset(i_reset),
                       .o_flag_max_tick(s_tick)
                     );

  //! UART Receiver
  receiver #(.D_BIT(DATA_WIDTH))
           uut_uart_rx (
             .i_clock(i_clock),
             .i_reset(i_reset),
             .i_s_tick(s_tick),
             .i_rx(i_rx),
             .o_rx_done_tick(rx_done),
             .o_data(rx_data)
           );

  //! UART Transmitter
  transmitter #(.D_BIT(DATA_WIDTH))
              uut_uart_tx (
                .i_clock    (i_clock),
                .i_reset    (i_reset),
                .i_s_tick   (s_tick),
                .i_tx_start (tx_start),
                .i_data     (tx_data),
                .o_tx       (o_tx),
                .o_tx_done  (tx_done)

              );

  // UART FIFO Interface:
  interface_uart #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
                 uut_FIFO_interface (
                   .i_reset(i_reset),
                   .i_clock(i_clock),

                   // Receptor:
                   .i_rx_data      (rx_data),
                   .i_rx_write     (rx_done),
                   .i_rx_read      (i_pipeline_read),  // Lectura desde el pipeline
                   .o_rx_fifo_data (o_pipeline_data),  // Salida hacia el pipeline
                   .o_rx_empty     (rx_fifo_empty),
                   .o_rx_full      (rx_fifo_full),

                   // transmisor:
                   .i_tx_fifo_data (i_pipeline_data),  // Entrada desde el pipeline
                   .i_tx_write     (i_pipeline_write), // Escritura desde el pipeline
                   .i_tx_read      (tx_done),          // Lectura para transmisión
                   .o_tx_data      (tx_data),          // Salida hacia el UART Tx
                   .o_tx_empty     (tx_fifo_empty),
                   .o_tx_full      (tx_fifo_full)
                 );


  // Lógica para controlar el inicio de la transmisión (basada en el FIFO vacío):
  assign tx_start = !tx_fifo_empty;


endmodule
