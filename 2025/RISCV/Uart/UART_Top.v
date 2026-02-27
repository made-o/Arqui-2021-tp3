`timescale 1ns / 1ps

module UART_Top
#
(
    // --- Parámetros de Frecuencia y Velocidad ---
    parameter CLK_FREQ   = 50_000_000, // Frecuencia del reloj del sistema (50 MHz)
    parameter BAUD_RATE  = 115_200,    // Velocidad de comunicación estándar (115200 bps)
    
    // --- Parámetros de Formato UART ---
    parameter D_BIT      = 8,          // Cantidad de bits de datos (8 bits)
    parameter SB_TICK    = 16          // Ticks por bit (normalmente 16)
)
(
    // Puertos de control y reloj
    input  wire i_clk,
    input  wire i_reset,
    
    // Puertos físicos (conectados al pin)
    input  wire i_rx_data,
    output wire o_tx_data,
    
    // Puertos de Handshake (conectan al Debug_Manager)
    input  wire i_tx_start,
    input  wire [D_BIT-1:0] i_data_to_send, // Ancho de datos paramétrico
    output wire o_rx_done,
    output wire o_tx_done,
    output wire [D_BIT-1:0] o_received_data // Ancho de datos paramétrico
);

    // --- 1. Cálculo del Divisor de Baudrate (M) ---
    
    // El módulo baudrate_generator usa M como divisor.
    // M = CLK_FREQ / (BAUD_RATE * SB_TICK)
    // Se calcula usando $ceil() y $rtoi() en herramientas como Vivado,
    // pero en Verilog estándar, usamos la división entera:
    localparam real real_divisor = (1.0 * CLK_FREQ)/ (BAUD_RATE * SB_TICK); 
    localparam M_DIVISOR = $rtoi($ceil(real_divisor));
    
    // Asegúrate de que el contador del baudrate_generator (N) sea lo suficientemente grande
    // para contar hasta M_DIVISOR.
    localparam N_BITS_M  = M_DIVISOR > 0 ? $clog2(M_DIVISOR) : 1;
    
    // --- 2. Señales Internas ---
    
    wire w_s_tick; // Tick de Baudrate

    // A. INSTANCIAR BAUD RATE GENERATOR
    baudrate_generator 
    #(.N(N_BITS_M), .M(M_DIVISOR)) // Usa los valores paramétricos calculados
    u_baudrate_gen (
        .i_clk (i_clk),
        .i_reset (i_reset),
        .o_flag_max_tick (w_s_tick)
    );

    // B. INSTANCIAR RECEIVER
    receiver 
    #(.D_BIT(D_BIT), .SB_TICK(SB_TICK)) // Usa los parámetros de formato
    u_receiver (
        .i_clock (i_clk),
        .i_reset (i_reset),

        .i_s_tick (w_s_tick),
        .i_rx (i_rx_data), // viene desde fuera, desde la pc a traves de la UART fisica
        
        .o_rx_done_tick (o_rx_done), // debe ir al debug_manager
        .o_data (o_received_data) // debe ir al debug_manager
    );

    // C. INSTANCIAR TRANSMITTER
    transmitter 
    #(.D_BIT(D_BIT), .SB_TICK(SB_TICK)) // Usa los parámetros de formato
    u_transmitter (
        .i_clock (i_clk),
        .i_reset (i_reset),
        .i_s_tick (w_s_tick),
        .i_tx_start (i_tx_start), // debe venir desde interface_tx dentro del debug_manager
        .i_data (i_data_to_send), // debe venir desde interface_tx dentro del debug_manager
        
        .o_tx (o_tx_data), // viene desde fuera del sistema a traves de la UART fisica
        .o_tx_done (o_tx_done) // debe ir a interface_tx dentro del debug_manager
    );

endmodule