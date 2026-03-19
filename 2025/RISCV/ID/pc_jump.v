`timescale 1ns / 1ps

module pc_jump#
(
	N_BITS_DW  = 32,
	N_BITS_W   = 16,
    N_BITS_REG = 5
)
(  
    input  wire [12-1:0]         i_sign_extension1,
    input  wire [5-1:0]          i_sign_extension2,
    input  wire [8-1:0]          i_sign_extension3,
    input  wire [7-1:0]          i_opcode,
    input  wire [N_BITS_DW-1:0]  i_pc,
    input  wire [N_BITS_DW-1:0]  i_rs1,
    
    output reg  [N_BITS_DW-1:0]  o_jump_direction,
    output reg  [N_BITS_DW-1:0]  o_sign_extension
 ); 
    localparam [6:0] Tipo_L     = 7'b0000011; 
    localparam [6:0] Tipo_S     = 7'b0100011;
    localparam [6:0] Tipo_I     = 7'b0010011;
    localparam [6:0] Tipo_Jarl  = 7'b1100111;
    localparam [6:0] Tipo_B     = 7'b1100011; 
    localparam [6:0] Tipo_Jal   = 7'b1101111;
    localparam [6:0] Tipo_Lui   = 7'b0110111;

    always @(*) begin: extension_de_signo
        o_sign_extension = 32'b0;
        o_jump_direction = 32'b0;
        case(i_opcode)
            Tipo_L, Tipo_I, Tipo_Jarl:
            begin
                o_sign_extension = {{20{i_sign_extension1[11]}},i_sign_extension1};
                o_jump_direction = {(i_rs1[31:1] + o_sign_extension[31:1]), 1'b0};
            end
            Tipo_S:
            begin
                o_sign_extension = {{20{i_sign_extension1[11]}},i_sign_extension1[11:5],i_sign_extension2};
                
            end
            Tipo_B:
            begin
                o_sign_extension = {{20{i_sign_extension1[11]}},i_sign_extension2[0],i_sign_extension1[10:5],i_sign_extension2[4:1], 1'b0};
                o_jump_direction = i_pc + o_sign_extension;
            end            
            Tipo_Jal:
            begin
                o_sign_extension = {{12{i_sign_extension1[11]}},i_sign_extension3,i_sign_extension1[0],i_sign_extension1[10:1],1'b0};
                o_jump_direction = i_pc + o_sign_extension;
            end
            Tipo_Lui:
            begin
                o_sign_extension = {i_sign_extension1, i_sign_extension3, 12'b0};
                
            end
        endcase
    end
    /*
    always @(*) begin: jump_direction
        o_jump_direction = 32'b0;
        case(opcode)
        Tipo_Jarl:
        begin
            o_jump_direction = {(rs1 + {{20{i_sign_extension1[11]}},i_sign_extension1})[31:1], 1'b0};
        end
        Tipo_B:
        begin
            o_jump_direction = pc + {{20{i_sign_extension1[11]}},i_sign_extension2[0],i_sign_extension1[10:5],i_sign_extension2[4:1], 0};
        end
        Tipo_Jal:
        begin
            o_jump_direction = pc + {{12{i_sign_extension1[11]}},i_sign_extension3,i_sign_extension1[0],i_sign_extension1[10:1],0};
        end

    end
    */
    //assign o_sign_extension = {{(N_BITS_W){i_sign_extension[15]}},i_sign_extension};
    //assign o_jump_direction = pc + ({{(N_BITS_W){i_sign_extension[15]}},i_sign_extension}<<2);
endmodule
