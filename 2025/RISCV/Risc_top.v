`timescale 1ns / 1ps

module Risc_Top #(
    parameter N_BITS = 8,
    parameter N_BITS_REG = 5,
    parameter N_BITS_MEM = 7,
    parameter N_BITS_INST = 32,
    parameter HALT_INSTRUCTION = 32'hFFFFFFFF
)(
    // Puertos físicos (de la FPGA o del Testbench)
    input  wire i_clk_crudo,       // Clock de entrada, ej: 100 MHz
    input  wire i_reset_button,    // Botón de Reset manual (Activo Alto)
    input  wire i_reset_clock,
    input  wire i_rx_B18,         // Línea de datos RX (desde PC)
    input  wire i_flag_edge,

    output wire o_tx_A18,         // Línea de datos TX (hacia PC)
    output wire [N_BITS-1:0] o_rx_data,
    //output wire [2:0] o_led_state,  // Indicador de Estado (opcional)
    output [3:0] o_an,
    output [6:0] o_seg_bus,
    output [N_BITS-1: 0]o_instruction_8
);

    // --- 1. Declaración de Señales de Sistema ---
    
    wire [2:0] w_led_state;

    // Señales del Clock Wizard
    wire w_clk_50MHz;       // Clock limpio y dividido (50 MHz)
    wire w_clk_locked;      // Señal de estabilidad del PLL/MMCM
    
    // Reset sincronizado y estable (para el sistema)
    reg r_reset_system = 1'b1;

    // --- 2. Señales de Conexión entre Bloques (Handshake y Datos) ---

    // UART <--> Debug Manager
    wire w_rx_done;
    wire w_tx_start;
    wire w_tx_done;
    wire [N_BITS-1:0] w_byte_to_send;
    
    // Debug Manager <--> I_Fetch (Carga de Instrucciones)
    wire w_inst_write_en;
    wire [N_BITS_REG - 1:0] w_inst_addr_carga; // ADDR_WIDTH = 5 (según I_Fetch.v)
    wire [N_BITS_INST - 1:0] w_inst_data_carga; // NBITS = 32 (según I_Fetch.v)
    //wire [N_BITS_INST-1:0] w_pc_current;

    // Deco <--> Debug Manager (Datos del procesador)
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_D_reg_to_send; // Registro leída de la memoria (para TX/Debug)
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_MEM_mem_to_send; // Registro leída de la memoria (para TX/Debug)
    //(*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_MEM_data_mem_send;
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_dato_leido1;
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_dato_leido2;
    
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_REG-1 : 0] w_rs_id;
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_REG-1 : 0] w_rt_id;
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_REG-1 : 0] w_rt_OR_rd_ID;

    //---- creo que no lo necesito ----
    (*KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_REG-1 : 0] w_rd_id; 
    
    (* KEEP = "true", MARK_DEBUG = "true" *)wire [9-1:0] w_control_bits_ID;
    (* KEEP = "true", MARK_DEBUG = "true" *)wire [7-1:0] w_control_bits_EX;
    (* KEEP = "true", MARK_DEBUG = "true" *)wire [2-1:0] w_control_bits_MEM;
    
    (* KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_sign_extension;
    (* KEEP = "true", MARK_DEBUG = "true" *)wire [N_BITS_INST - 1:0] w_jump_direction;
    wire w_flush;
    (*KEEP = "true", MARK_DEBUG = "true" *) wire w_stall;
    
    // Otras señales
    wire w_halt_IF;             // Señal HALT detectada en I_Fetch
    wire w_halt_ID;
    wire w_halt_EX;
    wire w_halt_MEM;
    wire w_cpu_finished;

    (*KEEP = "true", MARK_DEBUG = "true" *) wire w_exec_mode;
    (*KEEP = "true", MARK_DEBUG = "true" *) wire w_step;

    (*KEEP = "true", MARK_DEBUG = "true" *) wire [N_BITS_INST - 1:0] pc_out;

    (*KEEP = "true", MARK_DEBUG = "true" *) wire w_inicializando;

    wire [N_BITS_REG - 1:0] w_addr_to_send_ID;
    wire [N_BITS_MEM - 1:0] w_addr_to_send_MEM;
    
    
    // aun no se usan
    //wire [N_BITS_INST-1: 0] i_jump_address;
    (*KEEP = "true", MARK_DEBUG = "true" *) wire [N_BITS_INST-1: 0] w_instruction_IF;
    (*KEEP = "true", MARK_DEBUG = "true" *) wire [N_BITS_INST-1: 0] w_instruction_ID;
    (*KEEP = "true", MARK_DEBUG = "true" *) wire [N_BITS_INST-1: 0] w_instruction_EX;
    
    assign o_instruction_8 = w_instruction_IF[N_BITS-1 : 0];   

    //Salidas de la etapa EX
    wire [N_BITS_INST-1:0]  w_aluResult_EX;
    wire [N_BITS_INST-1:0]  w_aluResult_MEM;
    wire [N_BITS_INST-1:0]  w_datoLeido2_EX;
    wire [N_BITS_REG-1:0]   w_rd_data_EX;
    wire [N_BITS_REG-1:0]   w_rt_OR_rd_EX;
    wire                    w_regWrite_EX_MEM;
    wire                    w_regWrite_MEM_WB;

    //Salidas de la etapa MEM
    wire [N_BITS_REG-1:0]   w_rt_OR_rd_MEM;
    wire [N_BITS_REG-1:0]   w_rd_data_MEM;
    wire [N_BITS_INST-1:0]  w_readData;

    //Salidas de la etapa WB  
    wire [N_BITS_INST-1:0] w_WB_writeData;
    wire [N_BITS_REG-1:0]  w_rt_OR_rd_WB; 
    wire [N_BITS_REG-1:0]  w_rd_WB; 
    wire                   w_WB_regWrite;

    // --- 3. Lógica de Reset Sincronizado y Estabilidad ---
    
    // El reset del sistema está activo hasta que el Clock Wizard se bloquee Y el botón se libere
    always @(posedge w_clk_50MHz) begin
        if (i_reset_button) begin
            r_reset_system <= 1'b1;
        end else if (w_clk_locked) begin
            r_reset_system <= 1'b0; // Libera el reset solo cuando el reloj es estable
        end
    end


    // =======================================================
    // I N S T A N C I A C I O N E S
    // =======================================================
 
    // A. INSTANCIACIÓN DEL CLOCK WIZARD
    // NOTA: Debes generar el Clock_Wizard.v en Vivado y pegarlo aquí
    clk_wiz_0 u_clock_wizard (
        .clk_in1 (i_clk_crudo),    // Clock de entrada (ej. 100 MHz)
        .CLK_50MHz (w_clk_50MHz),   // Clock de sistema (ej. 50 MHz)
        .locked (w_clk_locked),    // Reset estable
        .reset (i_reset_clock)    // Reset al Wizard (para la simulación/FPGA)
    );

    // B. INSTANCIACIÓN DEL MÓDULO UART TOP
    UART_Top u_uart_system (
        .i_clk (w_clk_50MHz),
        .i_reset (r_reset_system),
        
        .i_rx_data (i_rx_B18),       // Pin de entrada RX
        .o_tx_data (o_tx_A18),       // Pin de salida TX
        
        .i_tx_start (w_tx_start),
        .i_data_to_send (w_byte_to_send),
        
        .o_rx_done (w_rx_done),
        .o_tx_done (w_tx_done),
        .o_received_data (o_rx_data)
    );

    // C. INSTANCIACIÓN DEL DEBUG MANAGER (FSM de Carga)
    debug_manager u_debug_manager (
        .i_clk (w_clk_50MHz),
        .i_reset (r_reset_system),
        
        .i_rx_done (w_rx_done),
        .i_rx_data (o_rx_data),
        .i_tx_done (w_tx_done),
        
        // Entradas de control (simuladas por ahora)
        .i_flag_edge (i_flag_edge), 

        // Datos provenientes de I_fetch
        .i_F_instruction(w_instruction_IF), //32
        .i_F_pc(pc_out), //32
        
        // Datos provenientes de I_Deco
        .i_D_reg_send(w_D_reg_to_send),
        .i_D_dato_leido1(w_dato_leido1),//32
        .i_D_dato_leido2(w_dato_leido2),//32
        .i_D_control_bits(w_control_bits_ID),//9
        .i_D_rs(w_rs_id),//5
        .i_D_rd_or_rt(w_rt_OR_rd_ID),//5
        .i_D_sign_extension(w_sign_extension),//32
        .i_D_jump_direction(w_jump_direction),//32
        .i_D_flush(w_flush),//
        
        .i_halt_risc(w_cpu_finished),

        // Datos provenientes de EX
        .i_EX_aluResult(w_aluResult_EX),
        .i_EX_datoLeido2(w_datoLeido2_EX),
        .i_EX_rd_data_EX(w_rd_data_EX),
        .i_EX_rt_OR_rd_EX(w_rt_OR_rd_EX),
        .i_EX_control_bits_EX(w_control_bits_EX),

        // Datos provenientes de MEM
        .i_MEM_data_mem_send(w_MEM_mem_to_send),
        .i_MEM_aluResult(w_aluResult_MEM),
        .i_MEM_readDataMEM(w_readData),
        .i_MEM_rd_data(w_rd_data_MEM),
        .i_MEM_rt_OR_rd(w_rt_OR_rd_MEM),
        .i_MEM_control_bits(w_control_bits_MEM),
        
        // Datos provenientes de WB
        .i_WB_writeData(w_WB_writeData), 
        .i_rt_OR_rd_WB(w_rt_OR_rd_WB), 
        .i_rd_WB(w_rd_WB), 
        .i_WB_regWrite(w_WB_regWrite), 
        
        // Salidas hacia UART (TX)
        .o_tx_start (w_tx_start),//
        .o_byte_to_send (w_byte_to_send),
        
        // Salidas hacia I_Fetch (Carga)
        .o_write_enable (w_inst_write_en),//
        .o_addr_carga (w_inst_addr_carga),//
        .o_instruction (w_inst_data_carga),//
        
        .o_exec_mode(w_exec_mode),//
        .o_step(w_step),//

        .o_addr_to_send_ID(w_addr_to_send_ID),//
        .o_addr_to_send_MEM(w_addr_to_send_MEM),//

        //.o_done(o_done),
        
        .o_inicializando(w_inicializando),
        
        .o_state (w_led_state)//
    );

    // D. INSTANCIACIÓN DEL I_FETCH
    (* keep = "true" *)I_Fetch #(
        .NBITS(N_BITS_INST),
        .ADDR_WIDTH(5)
    ) u_instruction_fetch (
        .i_clk(w_clk_50MHz),
        .i_reset(r_reset_system),
        .i_enable(!w_inicializando),  // Habilito pc y la memoria luego de la carga de la memoria(es redundante)
        //.i_halt(w_fetch_halt),
        .i_stall(w_stall),
        .i_inicializando(w_inicializando), // ver bien como usar este flag, se usa en el modulo pc
        .i_jump_address(w_jump_direction),
        .i_jump_select(w_flush),
        
        // Interface para carga de instrucciones
        .i_WriteEnable(w_inst_write_en),
        .i_addr_carga(w_inst_addr_carga),
        .i_data_carga(w_inst_data_carga),
        
        // Interface para TX - usa addr_to_send del Debug Manager
        //.i_addr_tx(),
        
        // Control de ejecución
        .i_exec_mode(w_exec_mode),
        .i_step(w_step),
        
        // Outputs
        .o_instruction(w_instruction_IF),
        .o_data_send_tx(),
        .o_halt_signal(w_halt_IF),
        //.o_pc_current(w_pc_current), 
        .o_pc(pc_out)
    );
    
    // D. INSTANCIACIÓN DEL I_DECODE
    (* keep = "true" *)instructionDecode #(
        .N_BITS(N_BITS_INST),
        .N_REG_BITS(N_BITS_REG)
    ) u_instruction_decode (
        .i_clk(w_clk_50MHz),
        .i_reset(r_reset_system),
        
        // Control de ejecución
        .i_exec_mode(w_exec_mode),
        .i_step(w_step),
        
        .i_instruccion(w_instruction_IF),
        .i_WB_data_to_w({N_BITS_INST{1'b0}}),
        .i_dato_a_escribir_addr({{4{1'b0}},1'b0}),
        .i_pc_4(pc_out),
        
        // Interface para TX - usa addr_to_send del Debug Manager
        .i_addr_tx_ID(w_addr_to_send_ID),
        
        .i_ID_EX_rt(5'b00100),
        //.i_ID_EX_MemRead({5{1'b0}}),
       
        .i_regWrite(1'b0),
        
        .i_control_M_memRead_ID_EX(1'b1),
        .i_control_WB_regWrite_ex(1'b0),
        .i_control_WB_regWrite_mem(1'b0),
        .i_dato_salida_ALU({N_BITS_INST{1'b0}}),
        .i_dato_salida_mem({N_BITS_INST{1'b0}}),
        .i_Alu_rt({5{1'b1}}),
        .i_Mem_rt({5{1'b1}}),
           
        .i_halt(w_halt_IF),

        .o_instruccion(w_instruction_ID),

        // Outputs
        .o_data_send_tx_ID(w_D_reg_to_send), //Debug Manager
        
        .o_dato_leido1(w_dato_leido1),
        .o_dato_leido2(w_dato_leido2),
        .o_rs(w_rs_id),
        .o_rt(w_rt_id),
        .o_rd_or_rt(w_rt_OR_rd_ID),

        .o_rd(w_rd_id),
        //.o_dato_ex_signo(),

        .o_control_M_branch(w_control_bits_ID[1:0]),
        .o_control_M_memRead(w_control_bits_ID[2]),
        .o_control_WB_memtoReg(w_control_bits_ID[3]),
        .o_control_EX_ALUOp(w_control_bits_ID[5:4]),
        .o_control_M_memWrite(w_control_bits_ID[6]),
        .o_control_EX_ALUSrc(w_control_bits_ID[7]),
        .o_control_WB_regWrite(w_control_bits_ID[8]),
        /*Salidas del EX para comparar
        .o_branch(w_control_bits_EX[1:0]), //2bits
        .o_memRead(w_control_bits_EX[2]), //1bits
        .o_memToReg(w_control_bits_EX[3]), //1bits
        .o_memWrite(w_control_bits_EX[4]), //1bits
        .o_regWrite(w_control_bits_EX[5]), //1bits
        .o_ceroSignal(w_control_bits_EX[6]) //1bits
        */
        .o_sign_extension(w_sign_extension),
        
        .o_jump_direction(w_jump_direction),

        //.o_cpu_finished(w_cpu_finished),

        .o_halt(w_halt_ID),
        
        .o_flush(w_flush),
        
        .o_stall(w_stall)
    );

    /////////////////////////////----------------------EX
    
    (* keep = "true" *)IExecute #(
        .N_BITS(N_BITS_INST),
        .N_BITS_REG(N_BITS_REG)
    ) u_IExecute (
        .i_clk(w_clk_50MHz),
        .i_reset(r_reset_system),        
        
        // Control de ejecución
        .i_exec_mode(w_exec_mode),
        .i_step(w_step),
        .i_halt(w_halt_ID),

        .i_aluOP(w_control_bits_ID[5:4]),
        .i_aluSrc(w_control_bits_ID[7]),

        .i_datoLeido1(w_dato_leido1), 
        .i_datoLeido2(w_dato_leido2),
        .i_datoExtSigno(w_sign_extension),
        
        .i_instruccion(w_instruction_ID),
        .i_rt_id(w_rt_id), 
        .i_rd_id(w_rd_id), //-----creo que no lo necesito.----
        .i_rt_OR_rd(w_rt_OR_rd_ID),  

        // Se�al de entrada al m�dulo de control de la ALU
        //.i_opcode(), // 6bits
        
        // Se�ales extras que entran a la unidad de cortocircuito:
        .i_rd_EX_MEM(5'b01000), //5-bits
        .i_rd_MEM_WB(5'b10000), //5-bits
        .i_rs_id(w_rs_id),     //5-bits
        
        // Se�ales que vienen de las etapas WB y MEM (para usar en MUX)
        .i_wbData(32'hf000270f),
        .i_memData(32'hf072000f),
        
        // Se�ales que vienen de la etapa ID o de etapas siguientes:
        .i_regWrite_EX_MEM(1'b0),
        .i_regWrite_MEM_WB(1'b0),
        .i_branch(w_control_bits_ID[1:0]),
        .i_memRead(w_control_bits_ID[2]),
        .i_memToReg(w_control_bits_ID[3]),
        .i_memWrite(w_control_bits_ID[6]),
        .i_regWrite(w_control_bits_ID[8]),
        
        .o_instruccion(w_instruction_EX),
        .o_aluResult(w_aluResult_EX), //32bits
        .o_datoLeido2(w_datoLeido2_EX), //32bits
        .o_rd_data(w_rd_data_EX), //5bits 
        .o_rt_OR_rd(w_rt_OR_rd_EX), //5bits 
        //.o_regWrite_EX_MEM(w_regWrite_EX_MEM), 
        //.o_regWrite_MEM_WB(w_regWrite_MEM_WB),
        .o_branch(w_control_bits_EX[1:0]), //2bits
        .o_memRead(w_control_bits_EX[2]), //1bits
        .o_memToReg(w_control_bits_EX[3]), //1bits
        .o_memWrite(w_control_bits_EX[4]), //1bits
        .o_regWrite(w_control_bits_EX[5]), //1bits
        .o_ceroSignal(w_control_bits_EX[6]), //1bits

        .o_halt(w_halt_EX)
    );

    /////////////////////////////----------------------MEM
    
    (* keep = "true" *)memory #(
        .N_BITS(N_BITS_INST),
        .N_BITS_REG(N_BITS_REG)
    ) u_memory (
        .i_clk(w_clk_50MHz),
        .i_reset(r_reset_system),
        .i_halt(w_halt_EX),

        .i_memRead(w_control_bits_EX[2]),
        .i_memToReg(w_control_bits_EX[3]),
        .i_memWrite(w_control_bits_EX[4]),
        .i_regWrite(w_control_bits_EX[5]),
   
   
        .i_aluResult(w_aluResult_EX), // retorna para la etapa EX - (i_memData)
        .i_datoLeido2(w_datoLeido2_EX), 
        .i_rt_OR_rd(w_rt_OR_rd_EX),
        .i_rd_EX_MEM(w_rd_data_EX), // retorna para la etapa EX - bloque forwarding

        .i_exec_mode(w_exec_mode),
        .i_step(w_step),

        .i_addr_tx_MEM(w_addr_to_send_MEM),
   
        // OUTPUTS:
        .o_data_send_tx_MEM(w_MEM_mem_to_send), //Debug Manager
        
        .o_memToReg_MEM_WB(w_control_bits_MEM[0]),
        .o_regWrite_MEM_WB(w_control_bits_MEM[1]),

        .o_halt(w_halt_MEM),
   
        .o_readData(w_readData),
        .o_aluResult(w_aluResult_MEM),
        .o_rt_OR_rd(w_rt_OR_rd_MEM),
        .o_rd_MEM(w_rd_data_MEM)
    );
    
    (* keep = "true" *)writeBack #(
        .N_BITS(N_BITS_INST),
        .N_BITS_REG(N_BITS_REG)
    ) u_writeBack (
        .i_clk(w_clk_50MHz),
        .i_reset(r_reset_system),
        .i_halt(w_halt_MEM),

        .i_exec_mode(w_exec_mode),
        .i_step(w_step),
        
        //se�ales de control:
        .i_memToReg(w_control_bits_MEM[0]), 
        
        //entradas al mux:
        .i_datoLeido_MEM(w_readData),
        .i_AluResult(w_aluResult_MEM),
        
        //entradas que directamente salen:
        .i_regWrite(w_control_bits_MEM[1]), //habilita la escritura en la etapa ID
        .i_rd_MemToWb(w_rd_data_MEM),  //cortocircuito etapa EX
        .i_rt_OR_rd(w_rt_OR_rd_MEM), //registro a escribir en etapa ID
        
        
        .o_cpu_finished(w_cpu_finished),

        .o_WB_writeData(w_WB_writeData), //salida del multiplexor
        .o_rt_OR_rd(w_rt_OR_rd_WB), // reg a escribir en la etapa ID
        .o_rd_MEM_WB(w_rd_WB), // para el cortocircuito de la etapa EX
        .o_WB_regWrite(w_WB_regWrite) //se�al de escritura en etapa ID
    );

    assign o_an = 4'b1110;
    decode_7_Seg display_unit (
        .i_estado(w_led_state),
        .o_segmentos(o_seg_bus)
    );
    
    ila_0 ILA_Debug (
        .clk(w_clk_50MHz), // input wire clk
    
    
        .probe0(pc_out), // input wire [31:0]  probe0  
        .probe1(w_instruction_IF), // input wire [31:0]  probe1
        .probe2(w_inicializando), // input wire [32:0]  probe5 
        .probe3(w_stall), // input wire [32:0]  probe6 
        .probe4(w_step), // input wire [32:0]  probe6 
        .probe5(w_exec_mode)
    );

endmodule