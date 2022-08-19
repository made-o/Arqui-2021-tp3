`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.07.2022 16:50:34
// Design Name: 
// Module Name: pc_jump
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


module pc_jump#
(
	N_BITS_DW  = 32,
	N_BITS_W   = 16,
    N_BITS_REG = 5
)
(
    input  wire [N_BITS_W-1:0]   i_sign_extension,
    input  wire [N_BITS_DW-1:0]  pc,
    
    output wire  [N_BITS_DW-1:0]  o_jump_direction,
    output wire  [N_BITS_DW-1:0]  o_sign_extension
 );
 
 assign o_sign_extension = {{(N_BITS_W){i_sign_extension[15]}},i_sign_extension};
 assign o_jump_direction = pc + (o_sign_extension<<2);
 
endmodule
