`timescale 1ns / 1ps

module hazard_detector#
(
	N_BITS	   = 32,
    N_BITS_REG = 5
)
(
    //input  wire                  i_PCSrc_ID,
    //input  wire                  i_PCSrc_EX,
    input  wire                  i_control_M_memRead_ID_EX,
    //input  wire [N_BITS_REG-1:0] i_ID_EX_memRead,
    
    input  wire [1:0]            i_branch,
    
    input  wire [N_BITS_REG-1:0] i_rs,
    input  wire [N_BITS_REG-1:0] i_rt,
    
    input  wire [N_BITS_REG-1:0] i_Alu_rt,
    input  wire [N_BITS_REG-1:0] i_Mem_rt,
    input  wire                  i_control_WB_regWrite_ex,
    input  wire                  i_control_WB_regWrite_mem,
    input  wire [N_BITS_REG-1:0] i_ID_EX_rt,
    
    input  wire [N_BITS-1:0]     i_jump_direction,
    input  wire [N_BITS-1:0]     i_PC,
    input  wire [N_BITS-1:0]     i_dato_leido_1,
    input  wire [N_BITS-1:0]     i_dato_leido_2,
    input  wire [N_BITS-1:0]     i_dato_salida_ALU,
    input  wire [N_BITS-1:0]     i_dato_salida_mem,
    
    //output reg                   o_PCSrc,
    output reg                   o_flush,
    output reg                   o_halt,
    output reg [N_BITS-1:0]      o_jump_direction
 );
    reg  [N_BITS-1:0] dato_comparacion_1;
    reg  [N_BITS-1:0] dato_comparacion_2;
    
    always@(*)begin:data_hazard
        if(i_control_M_memRead_ID_EX && ((i_rs == i_ID_EX_rt) || (i_rt == i_ID_EX_rt)))
            o_halt = 1'b1;
        else
            o_halt = 1'b0;
    end
    
    always@(*)begin:mux_data1
        if(i_rs == i_Alu_rt && i_control_WB_regWrite_ex == 1)
            dato_comparacion_1 = i_dato_salida_ALU;
        else
            dato_comparacion_1 = i_dato_leido_1;
    end
    
    always@(*)begin:mux_data2
        if(i_rs == i_Mem_rt && i_control_WB_regWrite_mem == 1)
            dato_comparacion_2 = i_dato_salida_mem;
        else
            dato_comparacion_2 = i_dato_leido_2;
    end
    
    always@(*)begin:control_hazard
        if(i_branch == 2'b01)
        begin
            if(dato_comparacion_1 == dato_comparacion_2)
            begin
                o_halt  = 1;
                o_flush = 1;
                o_jump_direction = i_jump_direction;
            end
            else
            begin
                o_halt  = 0;
                o_flush = 0;
                o_jump_direction = i_PC;
            end
        end
        else if(i_branch == 2'b10)
        begin
            o_halt  = 1;
            o_flush = 1;
            o_jump_direction = i_jump_direction;
        end
        else
        begin
            o_halt  = 0;
            o_flush = 0;
            o_jump_direction = i_PC;
        end
    end
 
endmodule