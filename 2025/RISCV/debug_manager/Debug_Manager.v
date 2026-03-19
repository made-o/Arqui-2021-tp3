module debug_manager #(
    parameter N_BITS = 8,
    parameter N_BITS_INST = 32,
    parameter N_BITS_REG = 5,
    parameter HALT_INSTRUCTION = 32'hFFFFFFFF,
    parameter MAX_INSTRUCTIONS = 32
)(
    input i_clk,
    input i_reset,

    input [N_BITS-1:0] i_rx_data,
    input i_rx_done,
    input i_flag_edge,

    input i_tx_done,
    
    // Datos provenientes de I_fetch
    input [N_BITS_INST-1:0] i_F_pc,
    input [N_BITS_INST-1:0] i_F_instruction,

    // Datos provenientes de I_Deco
    input       [N_BITS_INST-1:0]   i_D_reg_send, 
    output wire [N_BITS_REG-1:0]    o_addr_to_send_ID,
    output wire [7-1:0]             o_addr_to_send_MEM,
    input       [N_BITS_INST - 1:0] i_D_dato_leido1,
    input       [N_BITS_INST - 1:0] i_D_dato_leido2,
    input       [9-1:0]             i_D_control_bits,
    input       [N_BITS_REG-1 : 0]  i_D_rs,
    input       [N_BITS_REG-1 : 0]  i_D_rd_or_rt,
    input       [N_BITS_INST - 1:0] i_D_sign_extension,
    input       [N_BITS_INST - 1:0] i_D_jump_direction,
    input                           i_D_flush,

    input i_halt_risc,

    // Datos porventeintes de EX
    input [N_BITS_INST-1 : 0]       i_EX_aluResult,
    input [N_BITS_INST-1 : 0]       i_EX_datoLeido2,
    input [N_BITS_REG-1 : 0]        i_EX_rd_data_EX,
    input [N_BITS_REG-1 : 0]        i_EX_rt_OR_rd_EX,
    input [6-1 : 0]                 i_EX_control_bits_EX,
    input                           i_EX_ceroSignal,
    
    // Datos provenientes de MEM
    input [N_BITS_INST-1:0]         i_MEM_data_mem_send, 
    input [N_BITS_INST-1 : 0]       i_MEM_aluResult,
    input [N_BITS_INST-1 : 0]       i_MEM_readDataMEM,
    input [N_BITS_REG-1 : 0]        i_MEM_rd_data,
    input [N_BITS_REG-1 : 0]        i_MEM_rt_OR_rd,
    input [2-1 : 0]                 i_MEM_control_bits,

    // Datos provenientes de WB
    input [N_BITS_INST-1:0]         i_WB_writeData, 
    input [N_BITS_REG-1:0]          i_rt_OR_rd_WB, 
    input [N_BITS_REG-1:0]          i_rd_WB, 
    input                           i_WB_regWrite, 


    output o_tx_start,
    output [N_BITS-1:0] o_byte_to_send,

    output reg [N_BITS_INST-1:0] o_instruction,
    output [N_BITS_REG-1:0] o_addr_carga,
    output reg o_write_enable,
    
    output reg o_exec_mode,
    output reg o_step,

    output o_inicializando,

    output [2:0] o_state             // Ampliado a 3 bits
);

    //==========================================================================
    // Estados de la FSM (3 bits)
    //==========================================================================
    localparam [2:0] IDLE      = 3'b000; // Nuevo: Espera 1E o 0E
    localparam [2:0] WAIT_CMD  = 3'b001; // Nuevo: Espera 1E o 0E
    localparam [2:0] REC       = 3'b010; // Recibir instrucciones
    localparam [2:0] WAIT_HALT = 3'b011; // Nuevo: Esperar Halt (Modo 0)
    localparam [2:0] EXEC_STEP = 3'b100; // Nuevo: Pulsar Step (Modo 1)
    localparam [2:0] SEND      = 3'b101; // Enviar por UART

    reg [2:0] current_state, next_state;

    reg halt_detected;
    
    wire done;

    reg [2:0] byte_counter;
    reg [23:0] instruccion_temp;
    reg [N_BITS_REG-1:0] current_addr;

    assign o_addr_carga = current_addr - 1'b1;

    //reg send_started;

    //reg [1:0] halt_step_count; // Contador para los 3 ciclos extra
    reg halt_has_come;
    
    reg inicializando;

    // Instancia de interface_tx (sin cambios mayores)
    interface_tx u_interface_tx (
        .i_clk(i_clk), 
        .i_reset(i_reset),

        // Etapa PC
        .i_pc(i_F_pc),
        .i_instruction(i_F_instruction), 

        // Etapa REG
        .i_D_reg_send (i_D_reg_send),
        .i_D_dato_leido1(i_D_dato_leido1),//32
        .i_D_dato_leido2(i_D_dato_leido2),//32
        .i_D_control_bits(i_D_control_bits),//9
        .i_D_rs(i_D_rs),//5
        .i_D_rd_or_rt(i_D_rd_or_rt),//5
        .i_D_sign_extension(i_D_sign_extension),//32
        .i_D_jump_direction(i_D_jump_direction),//32
        .i_D_flush(i_D_flush),//1
        
        // Etapa EX
        .i_EX_aluResult(i_EX_aluResult),
        .i_EX_datoLeido2(i_EX_datoLeido2),
        .i_EX_rd_data_EX(i_EX_rd_data_EX),
        .i_EX_rt_OR_rd_EX(i_EX_rt_OR_rd_EX),
        .i_EX_control_bits_EX(i_EX_control_bits_EX),
        .i_EX_ceroSignal(i_EX_ceroSignal),
        
        // Etapa MEM
        .i_MEM_data_mem_send(i_MEM_data_mem_send),
        .i_MEM_aluResult(i_MEM_aluResult),
        .i_MEM_readDataMEM(i_MEM_readDataMEM),
        .i_MEM_rd_data(i_MEM_rd_data),
        .i_MEM_rt_OR_rd(i_MEM_rt_OR_rd),
        .i_MEM_control_bits(i_MEM_control_bits),

        // Etapa WB
        .i_WB_writeData(i_WB_writeData), 
        .i_rt_OR_rd(i_rt_OR_rd_WB), 
        .i_rd_MEM_WB(i_rd_WB), 
        .i_WB_regWrite(i_WB_regWrite), 

        .i_halt(1'b0), 
        .i_tx_done(i_tx_done),
        
        .i_exec_mode(o_exec_mode), 
        .i_step(o_step),
        
        .o_tx_start(o_tx_start), 
        .o_data_to_send(o_byte_to_send),
        .o_data_addr_ID(o_addr_to_send_ID),
        .o_data_addr_MEM(o_addr_to_send_MEM),
        .o_done(done)
    );

    // Actualización de estado
    always @(posedge i_clk) begin
        if (i_reset) 
            current_state <= WAIT_CMD;
        else 
            current_state <= next_state;
    end

    // Lógica de registros
    always @(posedge i_clk) begin
        if (i_reset) begin
            byte_counter <= 3'd0;
            current_addr <= 5'd0;
            instruccion_temp <= {(N_BITS_INST - N_BITS){1'b0}};
            o_instruction <= 32'b0;
            o_exec_mode <= 1'b0;
            o_step <= 1'b0;
            //send_started <= 1'b0;
            o_write_enable <= 1'b0;
            halt_detected <= 1'b0;
            //halt_step_count <= 2'd0;
            halt_has_come <= 1'b0;
            inicializando <= 1'b1;

        end else begin
            case (current_state)

                IDLE: begin
                    byte_counter <= 3'd0;
                    current_addr <= {N_BITS_REG{1'b0}};
                    //send_started <= 1'b0;
                    //o_addr_to_send <= {N_BITS_REG{1'b0}};
                    o_exec_mode <= 1'b0;
                    o_step <= 1'b0;
                    o_write_enable <= 1'b0;
                    halt_detected <= 1'b0;

                    //halt_step_count <= 2'd0;
                    halt_has_come <= 1'b0;
                    inicializando <= 1'b1;
                    //instruction_count <= {N_BITS_REG{1'b0}};
                end

                WAIT_CMD: begin
                    o_step <= 1'b0;
                    //send_started <= 1'b0;
                    if (i_rx_done) begin
                        if (i_rx_data == 8'h1E) o_exec_mode <= 1'b1;
                        else if (i_rx_data == 8'h0E) o_exec_mode <= 1'b0;
                    end
                end

                REC: begin
                    if (i_rx_done) begin
                        case (byte_counter)
                            3'd0: begin
                                instruccion_temp[7:0] <= i_rx_data;
                                byte_counter <= 3'd1;
                                o_write_enable <= 1'b0;
                            end
                            3'd1: begin
                                instruccion_temp[15:8] <= i_rx_data;
                                byte_counter <= 3'd2;
                                o_write_enable <= 1'b0; 
                            end 
                            3'd2: begin 
                                instruccion_temp[23:16] <= i_rx_data; 
                                byte_counter <= 3'd3;
                                o_write_enable <= 1'b0;
                            end
                            3'd3: begin
                                o_instruction <= {i_rx_data, instruccion_temp}; 
                                o_write_enable <= 1'b1;

                                if ({i_rx_data, instruccion_temp} == HALT_INSTRUCTION) begin
                                    halt_detected <= 1'b1;
                                end

                                byte_counter <= 3'd0;
                                current_addr <= current_addr + 1'b1;
                            end
                        endcase
                    end else o_write_enable <= 1'b0;
                end

                EXEC_STEP: begin
                    o_step <= 1'b1; // Pulso de ejecución 
                    inicializando <= 1'b0;
                    //send_started <= 1'b0;
                    /*
                    if (halt_has_come) begin
                        halt_step_count <= halt_step_count + 1'b1;
                    end
                    */
                end

                SEND: begin
                    o_step <= 1'b0;
                    //send_started <= 1'b1;
                    if (i_halt_risc) begin
                        halt_has_come <= 1'b1;
                    end
                end
                
                WAIT_HALT: begin
                    inicializando <= 1'b0;
                    o_step <= 1'b0;
                end
            endcase
        end
    end

    // Lógica de próximo estado
    always @(*) begin
        next_state = current_state;
        case (current_state)

            IDLE: begin
                if (i_flag_edge) begin
                    next_state = WAIT_CMD;
                end
            end

            WAIT_CMD: begin
                if (i_rx_done && (i_rx_data == 8'h1E || i_rx_data == 8'h0E)) begin
                    next_state = REC;
                end
            end

            REC: begin
                if ((byte_counter == 3'd3 && i_rx_done && (current_addr + 1'b1) == MAX_INSTRUCTIONS) || halt_detected) begin
                    if(o_exec_mode) begin
                        next_state = EXEC_STEP;
                    end else begin
                        next_state = WAIT_HALT;
                    end
                end
            end

            EXEC_STEP: begin
                next_state = SEND; // Pasa a enviar tras el pulso de step
            end

            WAIT_HALT: begin
                if (i_halt_risc) next_state = SEND; // Espera señal física de Halt
            end

            SEND: begin
                if (done) begin
                    if (o_exec_mode == 1'b1) begin //deberia poner un flag para cunado se ejecute la ultima instruccion.
                        if (halt_has_come) begin // && halt_step_count == 2'd3) begin
                            next_state = IDLE;
                        end else begin
                            next_state = EXEC_STEP; // Continuar bucle
                        end
                    end else begin
                        next_state = IDLE;
                    end
                end
            end

            //default: next_state = IDLE;
        endcase
    end
    
    assign o_inicializando = inicializando;
    assign o_state = current_state;
endmodule