`timescale 1ns / 1ps

module hazard_detector#
(
	N_BITS	   = 32,
    N_BITS_REG = 5
)
(
    input  wire                  i_PCSrc_ID,
    input  wire                  i_PCSrc_EX,
    input  wire                  i_control_M_memRead_ID_EX,
    input  wire [N_BITS_REG-1:0] i_ID_EX_rt,
    input  wire [N_BITS_REG-1:0] i_EX_M_rt,
    input  wire [N_BITS_REG-1:0] i_ID_EX_memRead,
    input  wire [N_BITS_REG-1:0] i_rs,
    input  wire [N_BITS_REG-1:0] i_rt,
    input  wire [N_BITS-1:0] i_jump_direction_ID,
    input  wire [N_BITS-1:0] i_jump_direction_EX,
    
    output reg                   o_PCSrc,
    output reg                   o_flush,
    output reg                   o_halt,
    output reg [N_BITS-1:0]      o_jump_direction
 );
 
    always@(*)begin:data_hazard
        if(i_control_M_memRead_ID_EX && ((i_rs == i_ID_EX_rt) || (i_rt == i_ID_EX_rt)))
            o_halt = 1'b1;
        else
            o_halt = 1'b0;
    end
     
    always@(*)begin:control_hazard
        if(i_PCSrc_ID && (i_rt != i_ID_EX_rt && i_rs != i_ID_EX_rt && i_rt != i_EX_M_rt && i_rs != i_EX_M_rt ))
            begin
                o_flush = 1'b1;
                o_jump_direction = i_jump_direction_ID;
                o_PCSrc = i_PCSrc_ID;
            end
        else if(i_PCSrc_EX)
            begin
                o_flush = 1'b1;
                o_jump_direction = i_jump_direction_EX;
                o_PCSrc = i_PCSrc_EX;
            end
        else
            begin
                o_flush = 1'b0;
                o_PCSrc = 0;
            end
    end
 
endmodule