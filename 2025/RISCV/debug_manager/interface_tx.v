`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.01.2025 00:56:51
// Design Name: 
// Module Name: interface_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module interface_tx
#
(
    parameter N_BITS_INST = 32,
    parameter N_REG = 5,
    parameter N_BITS_UART  = 8,
    parameter N_BITS_REG   = 5
)
(
    input wire i_clk, i_reset,
    
    input wire i_exec_mode, //si es continuo o paso a paso
    input wire i_step,      //ejecutar un paso
    
    //Valores para enviar al UART
    //input wire [N_BITS_INSTR-1:0]              i_pc,
    //input wire [N_BITS_INSTR-1:0]              instruccion,
    
    // Etapa IF
    input [N_BITS_INST-1:0]  i_pc,
    input [N_BITS_INST-1:0]  i_instruction,

    // Etapa ID
    input [N_BITS_INST-1:0] i_D_reg_send, //el envio de la memoria de registros tiene su etapa aparte
    
    input [N_BITS_INST-1:0] i_D_dato_leido1,//32
    input [N_BITS_INST-1:0] i_D_dato_leido2,//32
    input [9-1:0]           i_D_control_bits,//9
    input [N_BITS_REG-1:0]  i_D_rs,//5
    input [N_BITS_REG-1:0]  i_D_rd_or_rt,//5
    input [N_BITS_INST-1:0] i_D_sign_extension,//32
    input [N_BITS_INST-1:0] i_D_jump_direction,//32
    input                   i_D_flush,//1

    // Etapa EX
    input [N_BITS_INST-1:0] i_EX_aluResult,
    input [N_BITS_INST-1:0] i_EX_datoLeido2,
    input [N_BITS_REG-1:0]  i_EX_rd_data_EX,
    input [N_BITS_REG-1:0]  i_EX_rt_OR_rd_EX,
    input [7-1 : 0]         i_EX_control_bits_EX,

    // Etapa MEM
    input [N_BITS_INST-1:0] i_MEM_data_mem_send, //el envio de la memoria de registros tiene su etapa aparte

    input [N_BITS_INST-1:0] i_MEM_aluResult,
    input [N_BITS_INST-1:0] i_MEM_readDataMEM,
    input [N_BITS_REG-1:0]  i_MEM_rd_data,
    input [N_BITS_REG-1:0]  i_MEM_rt_OR_rd,
    input [2-1 : 0]         i_MEM_control_bits,

    // Etapa WB
    input [N_BITS_INST-1:0]         i_WB_writeData, 
    input [N_BITS_REG-1:0]          i_rt_OR_rd, 
    input [N_BITS_REG-1:0]          i_rd_MEM_WB, 
    input                           i_WB_regWrite, 

    input wire i_halt,
    input wire i_tx_done,
    
    output reg                      o_tx_start,
    output reg                      o_done,
    output wire [N_BITS_UART-1:0]   o_data_to_send,
    
    output wire [N_BITS_REG-1:0]    o_data_addr_ID,
    output wire [7-1:0]             o_data_addr_MEM
);
	//declaracion de los estados
	localparam [3:0] IDLE           = 4'b0000;
	localparam [3:0] IF_INIT        = 4'b0001;
	localparam [3:0] IF_SEND        = 4'b0010;
	localparam [3:0] ID_INIT        = 4'b0011;
    localparam [3:0] ID_SEND        = 4'b0100;
	localparam [3:0] INDEX_RESET    = 4'b0101;
	localparam [3:0] REG            = 4'b0110;
	localparam [3:0] MEM            = 4'b0111;
	localparam [3:0] CNTR           = 4'b1000;
    localparam [3:0] EX_INIT        = 4'b1001;
    localparam [3:0] EX_SEND        = 4'b1010;
    localparam [3:0] MEM_INIT       = 4'b1011;
    localparam [3:0] MEM_SEND       = 4'b1100;
    localparam [3:0] WB_INIT        = 4'b1101;
    localparam [3:0] WB_SEND        = 4'b1110;

	localparam [1:0] IF_ARRAY_DEPTH   = 2'b10;
	localparam [2:0] ID_ARRAY_DEPTH   = 3'b101;
	localparam [2:0] EX_ARRAY_DEPTH   = 2'b11;
	localparam [2:0] MEM_ARRAY_DEPTH  = 2'b11;
	localparam [2:0] WB_ARRAY_DEPTH   = 2'b10;

    reg [2:0] array_ptr;
	reg       o_mem_done;
	reg [N_BITS_REG-1:0] data_add_ID;
	reg [7-1:0] data_add_MEM;
	
	reg [3-1:0]   index_8_bit;
	(* keep = "true" *)reg [N_BITS_REG-1:0]   reg_num = 5'b0;
	reg [3:0]              current_state;
	reg [3:0]              next_state;
    reg [N_BITS_INST-1:0] data;
    
    wire [N_BITS_INST-1 : 0] IF_array [0 : IF_ARRAY_DEPTH-1];
    wire [N_BITS_INST-1 : 0] ID_array [0 : ID_ARRAY_DEPTH-1];
    wire [N_BITS_INST-1 : 0] EX_array [0 : EX_ARRAY_DEPTH-1];
    wire [N_BITS_INST-1 : 0] MEM_array [0 : MEM_ARRAY_DEPTH-1];
    wire [N_BITS_INST-1 : 0] WB_array [0 : WB_ARRAY_DEPTH-1];

    reg [2:0] reset_index_flag;

    reg [N_BITS_INST-1 : 0] IF_array_data;
    reg [N_BITS_INST-1 : 0] ID_array_data;
    reg [N_BITS_INST-1 : 0] EX_array_data;
    reg [N_BITS_INST-1 : 0] MEM_array_data;
    reg [N_BITS_INST-1 : 0] WB_array_data;

    assign IF_array[0] = i_pc;
    assign IF_array[1] = i_instruction;

    assign ID_array[0] = {i_D_control_bits, i_D_rs, i_D_rd_or_rt, i_D_flush, 12'b0};
    assign ID_array[1] = i_D_dato_leido1;
    assign ID_array[2] = i_D_dato_leido2;
    assign ID_array[3] = i_D_sign_extension;
    assign ID_array[4] = i_D_jump_direction;

    assign EX_array[0] = i_EX_aluResult;
    assign EX_array[1] = i_EX_datoLeido2;
    assign EX_array[2] = {i_EX_rd_data_EX, i_EX_rt_OR_rd_EX, i_EX_control_bits_EX, 15'b0};
    
    assign MEM_array[0] = i_MEM_aluResult;
    assign MEM_array[1] = i_MEM_readDataMEM;
    assign MEM_array[2] = {i_MEM_rd_data, i_MEM_rt_OR_rd, i_MEM_control_bits, 20'b0};

    assign WB_array[0] = i_WB_writeData;
    assign WB_array[1] = {i_rd_MEM_WB, i_rt_OR_rd, i_WB_regWrite, 21'b0};

    //reg                    tx_done;
    
    //integer carga_reg = 0;
    
    //reg index_reset_flag = 0;
	//cambios de estado
	
    always @(posedge i_clk) begin: state_update
        if (i_reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(posedge i_clk) begin: reg_update_logic
        if (i_reset) begin
            index_8_bit <= 3'b0;
            reg_num <= 5'b0;
            o_done <= 1'b0;
            o_mem_done <= 1'b0;
            o_tx_start <= 1'b0;
            data <= 32'b0;
            array_ptr <= 3'b0;
            reset_index_flag <= 3'b000;

        end else begin
            case (current_state)
                IDLE: begin
                    index_8_bit <= 3'b0;
                    reg_num <= 5'b0;
                    o_done <= 1'b0;
                    o_mem_done <= 1'b0;
                    o_tx_start <= 1'b0;
                    //data <= IF_array[0];
                    data_add_ID <= 5'b0;
                    data_add_MEM <= 5'b0;
                    array_ptr <= 3'b0;
                    reset_index_flag <= 3'b000;
                end

                IF_INIT: begin
                    IF_array_data <= IF_array[array_ptr];
                    data <= IF_array[array_ptr];
                end
                
                IF_SEND: begin
                    //data = IF_array_data;
                    o_tx_start <= 1'b1;
                    
                    // Cuando termina transmisión de un byte
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            o_tx_start <= 1'b0;
                            index_8_bit <= 3'd0;
                            if (array_ptr < IF_ARRAY_DEPTH - 1) begin
                                array_ptr <= array_ptr + 1'b1;
                                //IF_array_data <= IF_array[array_ptr + 1'b1];
                            end
                            else begin
                                // YA SE ENVIÓ TODA LA MATRIZ
                                //o_tx_start <= 1'b0;
                                array_ptr <= 5'd0; // Opcional: resetear para la próxima vez
                                // Aquí podrías cambiar de estado: next_state = DONE;
                            end
                        end
                    end
                end

                ID_INIT: begin
                    ID_array_data <= ID_array[array_ptr];
                    data <= ID_array[array_ptr];
                end

                ID_SEND: begin
                    o_tx_start <= 1'b1;
                    reset_index_flag <= 3'b001;
                    //data = ID_array_data;
                    
                    // Cuando termina transmisión de un byte
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            o_tx_start <= 1'b0;
                            
                            index_8_bit <= 3'd0;
                            if (array_ptr < ID_ARRAY_DEPTH - 1) begin
                                array_ptr <= array_ptr + 1'b1;
                                //ID_array_data <= ID_array[array_ptr + 1'b1];
                            end
                            else begin
                                // YA SE ENVIÓ TODA LA MATRIZ
                                //o_tx_start <= 1'b0;
                                array_ptr <= 5'd0; // Opcional: resetear para la próxima vez
                                // Aquí podrías cambiar de estado: next_state = DONE;
                            end
                        end
                    end
                end
                
                EX_INIT: begin
                    EX_array_data <= EX_array[array_ptr];
                    data <= EX_array[array_ptr];
                end

                EX_SEND: begin
                    o_tx_start <= 1'b1;
                    reset_index_flag <= 3'b010;
                    //data = ID_array_data;
                    
                    // Cuando termina transmisión de un byte
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            o_tx_start <= 1'b0;
                            
                            index_8_bit <= 3'd0;
                            if (array_ptr < EX_ARRAY_DEPTH - 1) begin
                                array_ptr <= array_ptr + 1'b1;
                                //ID_array_data <= ID_array[array_ptr + 1'b1];
                            end
                            else begin
                                // YA SE ENVIÓ TODA LA MATRIZ
                                //o_tx_start <= 1'b0;
                                array_ptr <= 5'd0; // Opcional: resetear para la próxima vez
                                // Aquí podrías cambiar de estado: next_state = DONE;
                            end
                        end
                    end
                end

                MEM_INIT: begin
                    MEM_array_data <= MEM_array[array_ptr];
                    data <= MEM_array[array_ptr];
                end

                MEM_SEND: begin
                    o_tx_start <= 1'b1;
                    reset_index_flag <= 3'b011;
                    //data = ID_array_data;
                    
                    // Cuando termina transmisión de un byte
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            o_tx_start <= 1'b0;
                            
                            index_8_bit <= 3'd0;
                            if (array_ptr < MEM_ARRAY_DEPTH - 1) begin
                                array_ptr <= array_ptr + 1'b1;
                                //ID_array_data <= ID_array[array_ptr + 1'b1];
                            end
                            else begin
                                // YA SE ENVIÓ TODA LA MATRIZ
                                //o_tx_start <= 1'b0;
                                array_ptr <= 5'd0; // Opcional: resetear para la próxima vez
                                // Aquí podrías cambiar de estado: next_state = DONE;
                            end
                        end
                    end
                end

                WB_INIT: begin
                    WB_array_data <= WB_array[array_ptr];
                    data <= WB_array[array_ptr];
                end

                WB_SEND: begin
                    o_tx_start <= 1'b1;
                    reset_index_flag <= 3'b100;
                    //data = ID_array_data;
                    
                    // Cuando termina transmisión de un byte
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            o_tx_start <= 1'b0;
                            
                            index_8_bit <= 3'd0;
                            if (array_ptr < WB_ARRAY_DEPTH - 1) begin
                                array_ptr <= array_ptr + 1'b1;
                                //ID_array_data <= ID_array[array_ptr + 1'b1];
                            end
                            else begin
                                // YA SE ENVIÓ TODA LA MATRIZ
                                //o_tx_start <= 1'b0;
                                array_ptr <= 5'd0; // Opcional: resetear para la próxima vez
                                // Aquí podrías cambiar de estado: next_state = DONE;
                            end
                        end
                    end
                end
                
                INDEX_RESET: begin
                    index_8_bit <= 3'b0;
                    o_tx_start <= 1'b0;
                    data <= ID_array[0];
                end
                
                REG: begin
                    o_mem_done <= 1'b0;
                    data <= i_D_reg_send; // data <= i_instruction;
                    if(o_done == 1'b0)
                        o_tx_start <= 1'b1;
                    
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            // Continuar con siguiente byte de la instrucción actual
                            index_8_bit <= index_8_bit + 1'b1;
                            if(index_8_bit == 3'd2 && reg_num < N_REG - 1)
                                data_add_ID <= reg_num + 1'b1;
                        end else begin
                            // Terminó de enviar lo s 4 bytes de esta instrucción
                            index_8_bit <= 3'b0;
                            
                            o_tx_start <= 1'b0;
                            
                            if (reg_num < N_REG - 1) begin
                                // Hay más registros por enviar
                                reg_num <= reg_num + 1'b1;
                            end else begin
                                // Terminó de enviar todos los registros
                                reg_num <= 5'b0;
                                o_done <= 1'b1;
                            end
                        end
                    end
                end

                MEM: begin
                    data <= i_MEM_data_mem_send;
                    if(o_done == 1'b0)
                        o_tx_start <= 1'b1;
                    
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            // Continuar con siguiente byte de la instrucción actual
                            index_8_bit <= index_8_bit + 1'b1;
                            if(index_8_bit == 3'd2 && reg_num < N_REG - 1)
                                data_add_MEM <= reg_num + 1'b1;
                        end else begin
                            // Terminó de enviar lo s 4 bytes de esta instrucción
                            index_8_bit <= 3'b0;
                            
                            o_tx_start <= 1'b0;
                            
                            if (reg_num < N_REG - 1) begin
                                // Hay más registros por enviar
                                reg_num <= reg_num + 1'b1;
                            end else begin
                                // Terminó de enviar todos los registros
                                reg_num <= 5'b0;
                                o_mem_done <= 1'b1;
                            end
                        end
                    end
                end

                /*
                CNTR: begin
                    // Para cuando implementes contador de ciclos
                    data <= 32'b0; // i_ciclos
                    o_tx_start <= 1'b1;
                    
                    if (i_tx_done) begin
                        if (index_8_bit < 3'd3) begin
                            index_8_bit <= index_8_bit + 1'b1;
                        end else begin
                            index_8_bit <= 3'b0;
                            o_done <= 1'b1;
                            o_tx_start <= 1'b0;
                        end
                    end
                end
                */
                default: begin
                    index_8_bit <= 3'b0;
                    reg_num <= 5'b0;
                    o_done <= 1'b0;
                    o_tx_start <= 1'b0;
                    data <= 32'b0;
                end
            endcase
        end
    end
    
    always @(*) begin: next_state_logic
        // Valor por defecto
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (i_halt || (i_exec_mode && i_step)) begin
                    next_state = IF_INIT;
                end
            end
            
            IF_INIT: begin
                next_state = IF_SEND;
            end
            IF_SEND: begin
                // Esperar a que termine de enviar los datos de IF,
                // aunque espera a que index_8_bit sea 2 y no 3 que es el ultimo ya que
                // para entoncesya se estaria enviando el ultimo byte y debo pasar a la siguiente
                // etapa.
                if (i_tx_done && index_8_bit == 3'd3) begin
                    if(array_ptr == IF_ARRAY_DEPTH - 1)
                        next_state = INDEX_RESET;
                    else
                        next_state = IF_INIT;
                end
            end
             /*                 
            INDEX_RESET: begin
                // Estado transitorio de un ciclo para resetear índice
                if(reset_index_flag == 1'b0) begin
                    next_state = ID_INIT;
                end else
                    next_state = REG;
            end*/
            
            INDEX_RESET: begin
                // Estado transitorio de un ciclo para resetear índice
                case(reset_index_flag)
                    3'b000:  next_state = ID_INIT;
                    3'b001:  next_state = EX_INIT;
                    3'b010:  next_state = MEM_INIT;
                    3'b011:  next_state = WB_INIT;
                    3'b100:  next_state = MEM;
                endcase
            end

            ID_INIT: begin
                next_state = ID_SEND;
            end
            ID_SEND: begin
                // Esperar a que termine de enviar los datos de ID,
                // aunque espera a que index_8_bit sea 2 y no 3 que es el ultimo ya que
                // para entoncesya se estaria enviando el ultimo byte y debo pasar a la siguiente
                // etapa.
                if (i_tx_done && index_8_bit == 3'd3) begin
                    if(array_ptr == ID_ARRAY_DEPTH - 1)
                        next_state = INDEX_RESET;
                    else
                        next_state = ID_INIT;
                end
            end
            
            REG: begin
                // Esperar a que termine de enviar todos los registros
                if (o_done) begin
                    next_state = IDLE;
                end
                // Si quieres ir a MEM después:
                // if (o_done) begin
                //     next_state = MEM;
                // end
            end
            
            MEM: begin
                // Esperar a que termine de enviar todos los registros
                if (o_mem_done) begin
                    next_state = REG;
                end
                // Si quieres ir a MEM después:
                // if (o_done) begin
                //     next_state = MEM;
                // end
            end

            EX_INIT: begin
                next_state = EX_SEND;
            end
            EX_SEND: begin
                // Esperar a que termine de enviar los datos de ID,
                // aunque espera a que index_8_bit sea 2 y no 3 que es el ultimo ya que
                // para entoncesya se estaria enviando el ultimo byte y debo pasar a la siguiente
                // etapa.
                if (i_tx_done && index_8_bit == 3'd3) begin
                    if(array_ptr == EX_ARRAY_DEPTH - 1)
                        next_state = INDEX_RESET;
                    else
                        next_state = EX_INIT;
                end
            end

            MEM_INIT: begin
                next_state = MEM_SEND;
            end
            MEM_SEND: begin
                // Esperar a que termine de enviar los datos de ID,
                // aunque espera a que index_8_bit sea 2 y no 3 que es el ultimo ya que
                // para entoncesya se estaria enviando el ultimo byte y debo pasar a la siguiente
                // etapa.
                if (i_tx_done && index_8_bit == 3'd3) begin
                    if(array_ptr == MEM_ARRAY_DEPTH - 1)
                        next_state = INDEX_RESET;
                    else
                        next_state = MEM_INIT;
                end
            end

            WB_INIT: begin
                next_state = WB_SEND;
            end
            WB_SEND: begin
                // Esperar a que termine de enviar los datos de ID,
                // aunque espera a que index_8_bit sea 2 y no 3 que es el ultimo ya que
                // para entoncesya se estaria enviando el ultimo byte y debo pasar a la siguiente
                // etapa.
                if (i_tx_done && index_8_bit == 3'd3) begin
                    if(array_ptr == WB_ARRAY_DEPTH - 1)
                        next_state = INDEX_RESET;
                    else
                        next_state = WB_INIT;
                end
            end

            /*
            MEM: begin
                if (i_tx_done && index_8_bit == 3'd3) begin
                    next_state = CNTR;
                end
            end
            
            CNTR: begin
                if (o_done) begin
                    next_state = IDLE;
                end
            end
            */
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    /*
	always@(posedge i_clk) begin:check_state
		if(i_reset)
		begin
            state_reg  <= IDLE;
            o_done <= 0;
            //next_state <= IDLE;
        end
		else
		begin
			state_reg <= next_state;
			
			if(state_reg == IDLE)
            begin
                o_done <= 0;
                index_8_bit <= 5'b0;
            end
            
            if(tx_done && state_reg == PC)
            begin                
                index_8_bit <= index_8_bit + 1;
                index_reset_flag <= 0;
            end   
                     
            if(state_reg == INDEX_RESET)
            begin                
                index_8_bit <= 5'b0;
                index_reset_flag <= 1;
            end
            
            if (state_reg == REG) 
            begin
                if (tx_done && !carga_reg) 
                begin
                    index_8_bit <= index_8_bit + 1;
                    if (index_8_bit == 3) 
                    begin
                        index_8_bit <= 5'b0;
                        //o_tx_start <= 0;
                        if (reg_num == N_REG-1) 
                        begin
                            o_done <= 1;
                            reg_num <= 5'b0;
                        end 
                        else 
                        begin
                            reg_num <= reg_num + 1;
                            carga_reg <= 1;
                        end
                    end
                end 
                else 
                begin
                    carga_reg <= 0;
                end
            end
        end           
	end//check_state

    always@(*)begin:next
        next_state = state_reg;
        
        case(state_reg)
            IDLE: // O se hizo el step.
            begin
                data       = 32'b0;
                o_tx_start = 1'b0;
                //o_done     = 1'b0;
                
                if(i_halt || (i_exec_mode == 1'b1 && i_step))//
                begin
                    next_state = PC;
                end
                else
                begin
                    next_state = IDLE;
                end
            end
            PC:
            begin
                data = i_pc;
                o_tx_start = 1'b1;
                
                if(tx_done && index_8_bit == 3)
                begin
                    next_state = INDEX_RESET;
                    o_tx_start = 1'b0;
                end
                else
                begin                
                    next_state = PC;
                    o_tx_start = 1'b1;
                end
            end
            
            INDEX_RESET:
            begin
                if(index_reset_flag)
                begin
                    next_state = REG;
                end
                else 
                begin
                    next_state = INDEX_RESET;
                end
            end
            
            REG://manda los regs uno por uno sin usar un for,
                //Pero como solo tengo el IF voy a enviar las istrucciones para testear el procedimiento 
            begin
                data = instruccion;
                if (index_8_bit < 4) begin
                    o_tx_start = 1; // Mantener transmisión activa
                end
                if (o_done) begin
                    next_state = IDLE; // Salir de REG cuando termine
                end
            end
            
            MEM: // aun no lo necestio por que no tengo memoria
            begin
                data = i_memoria;
                o_tx_start = 1'b1;
                
                if(tx_done)
                begin
                    i = i + 1;
                    
                    if(i == 4)
                    begin
                        i = 5'b0;
                        next_state = CNTR;
                        o_tx_start = 1'b0;
                    end
                end
            end
            */
            /*
            CNTR:
            begin
                data = i_ciclos;
                o_tx_start = 1'b1;
                
                if(tx_done)
                begin
                    i = i + 1;
                    
                    if(i == 4)
                    begin
                        i = 5'b0;
                        next_state = IDLE;
                        o_done     = 1'b1;
                    end
                end
            end*//*            
            default:
            begin
                next_state = IDLE;
            end
        endcase       
    end
    
    always@(posedge i_clk)begin:tx_done_logic        
        // aca setea el tx_done
        if(i_tx_done == 1'b1)
            tx_done <= 1'b1;
        else
            tx_done <= 1'b0;
    end
    */
    
    assign o_data_to_send = data[(N_BITS_UART*index_8_bit)+:N_BITS_UART];
    assign o_data_addr_ID = data_add_ID;
    assign o_data_addr_MEM = data_add_MEM;
endmodule
