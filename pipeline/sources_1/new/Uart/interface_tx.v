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
    parameter N_BITS_INSTR = 32,
    parameter N_BITS_UART  = 8,
    parameter N_BITS_REG   = 5
)
(
    input wire i_clk, i_reset,
    
    input wire i_exec_mode, //si es continuo o paso a paso
    input wire i_step,      //ejecutar un paso
    
    //Valores para enviar al UART
    input wire [N_BITS_INSTR-1:0]              i_pc,
    input wire [N_BITS_INSTR-1:0]              instruccion,
    input wire [N_BITS_INSTR-1:0]              i_memoria,
    input wire [N_BITS_INSTR-1:0]              i_ciclos,
    
    input wire i_halt,
    input wire i_tx_done,
    
    output reg                    o_tx_start,
    output reg                    o_done,
    output wire [N_BITS_UART-1:0] o_data_to_send,
    
    output wire [N_BITS_REG-1:0] o_data_add
);
	//declaracion de los estados
	localparam [2:0] IDLE = 3'b000;
	localparam [2:0] PC   = 3'b001;
	localparam [2:0] REG  = 3'b010;
	localparam [2:0] MEM  = 3'b011;
	localparam [2:0] CNTR = 3'b100;
	
	reg [N_BITS_REG-1:0]   index_8_bit = 5'b0;
	reg [N_BITS_REG-1:0]   reg_num = 5'b0;
	reg [2:0]              state_reg;
	reg [2:0]              next_state;
    reg [N_BITS_INSTR-1:0] data;
    reg                    tx_done;
    integer carga_reg = 0;
	//cambios de estado
	always@(posedge i_clk) begin:check_state
		if(i_reset)
		begin
            state_reg  <= IDLE;
            next_state <= IDLE;
        end
		else
			state_reg <= next_state;			
	end//check_state

    always@(*)begin:next
        //next_state = state_reg;
        
        case(state_reg)
        IDLE: // O se hizo el step.
        begin
            data       = 32'b0;
            o_tx_start = 1'b0;
            o_done     = 1'b0;
            
            if(i_halt || (i_exec_mode == 1'b1 && i_step))//detectar la instruccion HALT
            begin
            #10
                next_state = PC;
            end
        end
        PC:
        begin
            data = i_pc;
            o_tx_start = 1'b1;
            
            if(tx_done)
            begin
                index_8_bit = index_8_bit + 1;
                
                if(index_8_bit == 4)
                begin
                    index_8_bit = 5'b0;
                    next_state = REG;
                    o_tx_start = 1'b0;
                end
            end
        end
        REG: //manda los regs uno por uno sin usar un for,
             //Pero como solo tengo el IF voy a enviar las istrucciones para testear el procedimiento
        begin            
            data = instruccion;
            o_tx_start = 1'b1;
            
            if(tx_done && !carga_reg)
            begin
                index_8_bit = index_8_bit + 1;
                
                if(index_8_bit == 4)
                begin
                    index_8_bit = 5'b00000;
                    o_tx_start = 1'b0;           
                                        
                    if(reg_num == N_BITS_INSTR-1)
                    begin                 
                        o_done     = 1'b1;       
                        reg_num = 5'b0;
                        next_state = 3'b000;
                    end
                    else
                        reg_num = reg_num + 1;
                        carga_reg = 1;
                end
            end
            else
            begin
                carga_reg = 0;
            end
        end
        /*
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
        end*/
        endcase       
    end
    
    always@(posedge i_clk)begin:tx_done_logic        
        /* aca setea el tx_done */
        if(i_tx_done == 1'b1)
            tx_done <= 1'b1;
        else
            tx_done <= 1'b0;
    end

    assign o_data_to_send = data[(N_BITS_UART*index_8_bit)+:N_BITS_UART];
    assign o_data_add = reg_num;
endmodule
