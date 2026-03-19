`timescale 1ns / 1ps

//==============================================================================
// TESTBENCH COMPLETO - MIPS Top Module con Debug Manager
//==============================================================================
module TB_Risc;
    //==========================================================================
    // Parámetros
    //==========================================================================
    parameter N_BITS = 8;
    parameter N_BITS_REG = 5;
    parameter N_BITS_INST = 32;
    parameter HALT_INSTRUCTION = 32'hFFFFFFFF;
    
    parameter CLK_PERIOD = 10;  // 100MHz → 10ns
    parameter UART_BIT_PERIOD = 8680;  // 115200 baud → ~8.68us
    
    //==========================================================================
    // Señales del DUT
    //==========================================================================
    reg i_reset_button;
    reg i_reset_clock;
    reg i_clk_100MHz;
    reg i_rx_B18;
    reg i_flag_edge;
    wire o_tx_A18;
    wire [N_BITS-1:0] o_rx_data;
    wire [3:0] o_an;
    wire [6:0] o_seg_bus;
    wire [7:0] o_instruction_8;
    // wire o_done;  // ← ELIMINADO (señal interna)
    
    //==========================================================================
    // Variables de control del testbench
    //==========================================================================
    integer i, j;
    reg [31:0] test_instructions [0:31];
    integer num_instructions;
    reg [1:0] prev_state;  // Para detectar cambios de estado
    
    //==========================================================================
    // Instancia del DUT
    //==========================================================================
    Risc_Top #(
        .N_BITS(N_BITS),
        .N_BITS_REG(N_BITS_REG),
        .N_BITS_INST(N_BITS_INST),
        .HALT_INSTRUCTION(HALT_INSTRUCTION)
    ) DUT (
        .i_clk_crudo(i_clk_100MHz),
        .i_reset_button(i_reset_button),
        .i_reset_clock(i_reset_clock),
        .i_rx_B18(i_rx_B18),
        .i_flag_edge(i_flag_edge),
        
        .o_tx_A18(o_tx_A18),
        .o_rx_data(o_rx_data),
        .o_an(o_an),
        .o_seg_bus(o_seg_bus),
        .o_instruction_8(o_instruction_8)
    );
    
    //==========================================================================
    // Generación de reloj
    //==========================================================================
    initial begin
        i_clk_100MHz = 0;
        forever #(CLK_PERIOD/2) i_clk_100MHz = ~i_clk_100MHz;
    end
    
    //==========================================================================
    // Monitor de estados y detección de transiciones
    //==========================================================================
    initial begin
        prev_state = 2'b11;  // IDLE inicial
    end
    
    always @(o_seg_bus) begin
        case (o_seg_bus)
            7'b0000001: $display("[%0t] Estado: IDLE", $time);
            7'b1001111: $display("[%0t] Estado: WAIT_CMD (Definiendo modo de ejecucion)", $time);
            7'b0010010: $display("[%0t] Estado: REC (Recibiendo)", $time);
            7'b0000110: $display("[%0t] Estado: WAIT_HALT (Modo Continuo)", $time);
            7'b1001100: $display("[%0t] Estado: EXEC_STEP (Esperando RISC)", $time);
            7'b0100100: $display("[%0t] Estado: SEND (Enviando)", $time);
            default: $display("[%0t] Estado: DESCONOCIDO", $time);
        endcase
        
        // Detectar transición SEND → IDLE (equivale a DONE)
        if (prev_state == 7'b0100100 && o_seg_bus == 7'b0000001) begin
            $display("[%0t] *** Transición SEND→IDLE detectada (proceso completo) ***", $time);
        end
        
        prev_state = o_seg_bus;
    end
    
    //==========================================================================
    // Tarea: Enviar byte por UART
    //==========================================================================
    task send_uart_byte;
        input [7:0] data;
        integer bit_idx;
        begin
            $display("[%0t] Enviando byte UART: 0x%02h", $time, data);
            
            // Start bit
            i_rx_B18 = 0;
            #UART_BIT_PERIOD;
            
            // Data bits (LSB first)
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                i_rx_B18 = data[bit_idx];
                #UART_BIT_PERIOD;
            end
            
            // Stop bit
            i_rx_B18 = 1;
            #UART_BIT_PERIOD;
        end
    endtask

    //==========================================================================
    // Tarea: Enviar el modo de ejecucion (1 bytes)
    //==========================================================================
    task send_modo;
        input [7:0] instruction;
        begin
            $display("[%0t] === Enviando modo: 0x%08h ===", $time, instruction);
            send_uart_byte(instruction[7:0]);
            $display("[%0t] Envio completado", $time);
        end
    endtask 

    //==========================================================================
    // Tarea: Enviar instrucción completa (4 bytes)
    //==========================================================================
    task send_instruction;
        input [31:0] instruction;
        begin
            $display("[%0t] === Enviando instrucción: 0x%08h ===", $time, instruction);
            send_uart_byte(instruction[7:0]);    // Byte 0 (LSB)
            send_uart_byte(instruction[15:8]);   // Byte 1
            send_uart_byte(instruction[23:16]);  // Byte 2
            send_uart_byte(instruction[31:24]);  // Byte 3 (MSB)
            $display("[%0t] Instrucción enviada completamente", $time);
        end
    endtask
    
    //==========================================================================
    // Tarea: Esperar que termine el envío (sin usar o_done)
    //==========================================================================
    task wait_send_complete;
        input integer timeout_cycles;
        integer count;
        reg send_detected;
        begin
            count = 0;
            send_detected = 0;
            
            // Primero asegurarse de estar en SEND
            while (o_seg_bus != 7'b0100100 && count < timeout_cycles) begin
                @(posedge i_clk_100MHz);
                count = count + 1;
            end
            
            if (count >= timeout_cycles) begin
                $display("[%0t] ERROR: Nunca entró en SEND", $time);
                $stop;
            end
            
            send_detected = 1;
            $display("[%0t] Estado SEND detectado, esperando retorno a IDLE...", $time);
            
            // Ahora esperar retorno a IDLE
            count = 0;
            while (o_seg_bus != 7'b0000001 && count < timeout_cycles) begin
                @(posedge i_clk_100MHz);
                count = count + 1;
            end
            
            if (count >= timeout_cycles) begin
                $display("[%0t] ERROR: Timeout esperando retorno a IDLE", $time);
                $stop;
            end
            
            $display("[%0t] Envío completado (retorno a IDLE)", $time);
        end
    endtask
    
    //==========================================================================
    // Tarea: Reset del sistema
    //==========================================================================
    task system_reset;
        begin
            $display("\n[%0t] ========================================", $time);
            $display("[%0t] Iniciando RESET del sistema", $time);
            $display("[%0t] ========================================\n", $time);
            
            i_reset_button = 1;
            i_reset_clock = 1;
            i_rx_B18 = 1;  // Idle state
            i_flag_edge = 0;
            
            repeat(10) @(posedge i_clk_100MHz);
            
            i_reset_clock = 0;
            repeat(10) @(posedge i_clk_100MHz);
            
            i_reset_button = 0;
            repeat(10) @(posedge i_clk_100MHz);
            #2000;
            i_flag_edge = 1;
            repeat(10) @(posedge i_clk_100MHz);
            i_flag_edge = 0;

            $display("[%0t] Reset completado\n", $time);
        end
    endtask
    
    //==========================================================================
    // TEST 1: Enviar 3 instrucciones normales + HALT
    //==========================================================================
    task test_infinito_stall;
        begin
            $display("\n[%0t] ╔════════════════════════════════════════╗", $time);
            $display("[%0t] ║  TEST 1: 3 Infinito Stall      ║", $time);
            $display("[%0t] ╚════════════════════════════════════════╝\n", $time);
            
            system_reset();

            // Definiendo modo
            send_modo(8'h1E);

            // Preparar instrucciones
            test_instructions[0] = 32'b001000_00010_00001_0111111111111111; //ADDI
            test_instructions[1] = 32'b000000_00100_00001_01000_00000_100100; // AND
            test_instructions[2] = 32'b000000_00010_00001_10000_00000_100101; //OR
            test_instructions[3] = 32'hFFFFFFFF;  // HALT
            num_instructions = 4;
            
            // Enviar instrucciones
            $display("[%0t] Enviando %0d instrucciones...\n", $time, num_instructions);
            for (i = 0; i < num_instructions; i = i + 1) begin
                send_instruction(test_instructions[i]);
                #1000;  // Pequeña pausa entre instrucciones
            end
            
            // Esperar transición a SEND y completar
            $display("\n[%0t] Esperando que complete el proceso...", $time);
            wait_send_complete(10000000);  // 1M ciclos de timeout
            
            $display("\n[%0t] ✓ TEST 1 COMPLETADO\n", $time);
        end
    endtask
    
    //==========================================================================
    // TEST 2: Enviar exactamente 31 instrucciones (límite sin HALT)
    //==========================================================================
    task test_normal_instructions;
        begin
            $display("\n[%0t] ╔════════════════════════════════════════╗", $time);
            $display("[%0t] ║  TEST 2: Ejecicopm normal   ║", $time);
            $display("[%0t] ╚════════════════════════════════════════╝\n", $time);
            
            system_reset();
            
            // Definiendo modo
            send_modo(8'h1E);
            
            // Preparar instrucciones
            //test_instructions[0] = 32'b001000_00010_00001_0111111111111111; //ADDI   20417FFF
            //test_instructions[1] = 32'b000000_00010_00001_01000_00000_100100; // AND 00414024
            //test_instructions[2] = 32'b000000_00011_00001_10000_00000_100101; //OR   00618025
            //test_instructions[3] = 32'hFFFFFFFF;  // HALT
            //num_instructions = 4;
            // Preparar instrucciones en RISC-V
            test_instructions[0] = 32'b011111111111__00001_000_00010_0010011; //ADDI rd, rs1, 7ff: 7F F0 81 13
            test_instructions[1] = 32'b0000000_00001_00010_111_01000_0110011; //AND  rd, rs1, rs2: 00 11 74 33 
            test_instructions[2] = 32'b0000000_00001_00011_110_10000_0110011; //OR   rd, rs1, rs2: 00 11 E8 33
            test_instructions[3] = 32'hFFFFFFFF; // HALT (Personalizado)
            num_instructions = 4;
            
            // Enviar instrucciones
            $display("[%0t] Enviando %0d instrucciones...\n", $time, num_instructions);
            for (i = 0; i < num_instructions; i = i + 1) begin
                send_instruction(test_instructions[i]);
                #1000;  // Pequeña pausa entre instrucciones
            end
            
            // Esperar transición a SEND y completar
            $display("\n[%0t] Esperando que complete el proceso...", $time);
            wait_send_complete(10000000);  // 1M ciclos de timeout
            
            $display("\n[%0t] ✓ TEST 1 COMPLETADO\n", $time);
        end
    endtask
    
    //==========================================================================
    // TEST 3: Una sola instrucción (HALT inmediato)
    //==========================================================================
    task test_single_halt;
        begin
            $display("\n[%0t] ╔════════════════════════════════════════╗", $time);
            $display("[%0t] ║  TEST 3: Solo HALT                    ║", $time);
            $display("[%0t] ╚════════════════════════════════════════╝\n", $time);
            
            system_reset();
            
            // Solo HALT
            test_instructions[0] = 32'hFFFFFFFF;
            num_instructions = 1;
            
            $display("[%0t] Enviando HALT...\n", $time);
            send_instruction(test_instructions[0]);
            #1000;
            
            wait_send_complete(10000000);
            
            $display("\n[%0t] ✓ TEST 3 COMPLETADO\n", $time);
        end
    endtask
    
    //==========================================================================
    // TEST 4: Verificar detección de HALT en posición intermedia
    //==========================================================================
    task test_halt_middle;
        begin
            $display("\n[%0t] ╔════════════════════════════════════════╗", $time);
            $display("[%0t] ║  TEST 4: HALT en posición 5          ║", $time);
            $display("[%0t] ╚════════════════════════════════════════╝\n", $time);
            
            system_reset();
            
            // 5 instrucciones normales + HALT
            for (i = 0; i < 5; i = i + 1) begin
                test_instructions[i] = 32'hA0000000 + (i << 8);
            end
            test_instructions[5] = 32'hFFFFFFFF;  // HALT en posición 5
            num_instructions = 6;
            
            $display("[%0t] Enviando %0d instrucciones (HALT en posición 5)...\n", 
                     $time, num_instructions);
            
            for (i = 0; i < num_instructions; i = i + 1) begin
                send_instruction(test_instructions[i]);
                #800;
            end
            
            wait_send_complete(10000000);
            
            $display("\n[%0t] ✓ TEST 4 COMPLETADO\n", $time);
        end
    endtask
    
    //==========================================================================
    // Secuencia principal de tests
    //==========================================================================
    initial begin
        $display("\n");
        $display("╔═══════════════════════════════════════════════════════════╗");
        $display("║                                                           ║");
        $display("║     TESTBENCH - MIPS Top Module con Debug Manager        ║");
        $display("║                                                           ║");
        $display("╚═══════════════════════════════════════════════════════════╝");
        $display("\n");
        
        // Ejecutar tests
        //test_infinito_stall();
        test_normal_instructions();
        #50000;
        
        test_infinito_stall();
        #50000;
        
        //test_single_halt();
        //#50000;
        
        //test_halt_middle();
        //#50000;
        
        // Resumen final
        $display("\n");
        $display("╔═══════════════════════════════════════════════════════════╗");
        $display("║                                                           ║");
        $display("║               ✓ TODOS LOS TESTS PASARON                  ║");
        $display("║                                                           ║");
        $display("╚═══════════════════════════════════════════════════════════╝");
        $display("\n");
        
        #10000;
        $finish;
    end
    
    //==========================================================================
    // Timeout global
    //==========================================================================
    initial begin
        #500000000;  // 500ms timeout
        $display("\n[%0t] ERROR: TIMEOUT GLOBAL - Simulación demasiado larga", $time);
        $finish;
    end
    
    //==========================================================================
    // Dump para GTKWave (opcional)
    //==========================================================================
    initial begin
        $dumpfile("tb_MIPS_Top_Module.vcd");
        $dumpvars(0, TB_Risc);
    end

endmodule