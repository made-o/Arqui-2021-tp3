`timescale 1ns / 1ps

module TB_UART_4_Instruction;

    // ----------------------------------------------------
    // 1. Declaración de Señales de Simulación (Wires/Regs)
    // ----------------------------------------------------
    // Entradas del DUT (Device Under Test)
    reg  i_clk_50MHz = 1'b0; 
    reg  i_reset_button = 1'b1;
    reg  i_rx_B18 = 1'b1; // Señal RX (Inicialmente Alta/Idle)
    reg  flag_edge_tb = 1'b0; // ¡NUEVO! Señal de control para salir de IDLE

    // Salidas del DUT (Conexión para monitoreo)
    wire o_tx_A18;
    wire i_rx_done; // o_rx_done_tick del receiver
    wire o_instruction_byte; // byte recibido
    //wire [31:0]o_data_carga;
    wire tx_start;
    wire write_enable;
    wire [1:0] o_led_state_scan;
    
    // Señales internas para monitoreo
    wire s_tick; // Tick del Baudrate Generator

    // Definición de Instrucciones de Prueba
    localparam NOP = 32'h00000000;
    localparam HALT = 32'hFFEEDDCC; // Usando tu HALT de ejemplo
    localparam INST1 = 32'h10010001; 
    localparam INST2 = 32'h20020002;
    localparam INST3 = 32'h30030003;
    
    // Variables de control de simulación
    integer byte_index;

    // ----------------------------------------------------
    // 2. Instancia del Módulo Principal (DUT)
    // ----------------------------------------------------
    Uart_test_FPGA #(.N_BITS(8)) uut_top (
        .i_reset_button(i_reset_button),
        .i_reset_clock(1'b0), // Dummy
        .i_clk_50MHz(i_clk_50MHz), 
        
        .i_rx_B18(i_rx_B18), // La señal que enviamos
        
        .o_tx_A18(o_tx_A18), // TX saliente (monitoreo)
        
        .o_led_state_scan(o_led_state_scan), // Estado FSM
        .flag_edge(flag_edge_tb), // Dummy
        
        .o_instruction(o_instruction_byte), // Byte recibido
        //.o_writeEnable (write_enable),
        //.o_data_carga(o_data_carga),
        .done() // Dummy
    );

    // ----------------------------------------------------
    // 3. Generación de Reloj
    // ----------------------------------------------------
    always #5 i_clk_50MHz = ~i_clk_50MHz; // Clock de 50 MHz (Periodo 20 ns)

    // ----------------------------------------------------
    // 4. Tarea para Generar la Señal RX (Simular la UART)
    // ----------------------------------------------------
    task send_byte;
        input [7:0] data_in;
        begin
            // Bajar la línea (bit de START)
            i_rx_B18 = 1'b0;
            @(posedge i_clk_50MHz); // Esperar el primer flanco (aproximadamente la mitad de un tick de muestreo)

            // Esperar 16 ticks (1/2 bit time + 16 ticks del Baudrate_generator).
            // NOTA: Para simulación, simular la duración de un bit es M * 16 * 20ns.
            // En tu diseño: M=434, 16 ticks por bit, 50MHz clock. 
            // Usaremos una aproximación simple de 16 ticks de s_tick por bit (27 * 16 = 432 ciclos de 50MHz).
            // Aquí, usaremos la señal s_tick para sincronizar el envío:

            // 1. Bit de START: Esperar 16 ticks de s_tick (1 bit de duración)
            repeat (16) @(posedge s_tick);

            // 2. 8 Bits de DATA (LSB primero)
            for (byte_index = 0; byte_index < 8; byte_index = byte_index + 1) begin
                i_rx_B18 = data_in[byte_index];
                repeat (16) @(posedge s_tick);
            end

            // 3. Bit de STOP
            i_rx_B18 = 1'b1;
            repeat (16) @(posedge s_tick); 
            
            // 4. Línea IDLE (un tick extra para asegurar el i_rx_done)
            repeat (16) @(posedge s_tick);
        end
    endtask

    // ----------------------------------------------------
    // 5. Secuencia de Inicialización y Prueba
    // ----------------------------------------------------
    initial begin
        // a) Reset Inicial
        #1000;
        i_reset_button = 1'b1;
        flag_edge_tb = 1'b0; // Aseguramos que la FSM permanezca en IDLE
        #100;
        
        // b) Fin de Reset (FSM está en IDLE)
        i_reset_button = 1'b0;
        #20;
        
        // c) ACTIVACIÓN DEL INICIO DE CARGA (IDLE -> REC)
        $display("Activando flag_edge para iniciar la carga (IDLE -> REC)...");
        flag_edge_tb = 1'b1;
        
        // Esperamos unos ciclos para asegurar la transición de estado
        repeat (5) @(posedge i_clk_50MHz);
        
        $display("--- INICIO DE CARGA DE INSTRUCCIONES ---");
        
        // d) Desactivamos flag_edge una vez que ya se hizo la transición
        flag_edge_tb = 1'b0;
        
        // Instruccion 1: 0x00010001 (4 bytes)
        $display("Cargando Instruccion 1 (0x%h) en addr 0", INST1);
        send_byte(INST1[7:0]);   // B0
        send_byte(INST1[15:8]);  // B1
        send_byte(INST1[23:16]); // B2
        send_byte(INST1[31:24]); // B3 (Check Combinacional de HALT o limite)
        
        // Instruccion 2: 0x00020002 (4 bytes)
        $display("Cargando Instruccion 2 (0x%h) en addr 1", INST2);
        send_byte(INST2[7:0]);   // B0
        send_byte(INST2[15:8]);  // B1
        send_byte(INST2[23:16]); // B2
        send_byte(INST2[31:24]); // B3
        
        // Instruccion 3: HALT (2 bytes)
        $display("Cargando Instruccion 3 (HALT: 0x%h) en addr 2. ¡Debe terminar aqui!", HALT);
        send_byte(HALT[7:0]);   // B0
        send_byte(HALT[15:8]);  // B1
        send_byte(HALT[23:16]); // B2
        send_byte(HALT[31:24]); // B3 (Check Combinacional de HALT -> next_state = IDLE)

        #1000;
        $display("--- FIN DE CARGA ---");

        // Verificar el estado de la FSM (debería ser IDLE)
        #50;
        $display("Estado final de FSM: %d (0=IDLE, 1=REC, 2=SEND)", uut_top.o_led_state_scan);
        
        #1000;
        $finish;
    end
    
    // ----------------------------------------------------
    // 6. Conexión de Monitoreo (Necesitas acceder a s_tick)
    // ----------------------------------------------------
    // Nota: La señal s_tick no está expuesta en Uart_test_FPGA.v. 
    // Para que la simulación funcione, necesitamos conectarla desde el baudrate_generator interno.
    // Esto se hace accediendo a la jerarquía del módulo (si tu simulador lo permite).
    
    // (Esta línea depende del simulador, y asume que 'uut_top' es la instancia del Uart_test_FPGA)
    // Suponemos que el baudrate_generator dentro de Uart_test_FPGA se llama uut_baudrate_generator.
    assign s_tick = uut_top.uut_baud_gen.o_flag_max_tick;
    
endmodule
