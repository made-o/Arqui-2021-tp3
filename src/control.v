`timescale 1ns / 1ps

module control#
(
	parameter	N_BITS		= 32,
	parameter 	N_BITS_OP	= 6,
	parameter 	N_BITS_FUNC = 6
)
(
    input  wire       			 i_clk,
    input  wire     		     i_reset,
    input  wire       		 	 i_valid,
    input  wire       		 	 i_halt,
	input  wire [N_BITS-1:0]	 i_instruccion,
    
	//EX  - se?ales de control para ejecuci?n
	output reg [1:0] o_control_EX_ALUOp,
	output reg 		 o_control_EX_ALUSrc,
	output reg  	 o_control_EX_regDst,	
	
	//MEM - se?ales de control para acceso a memoria
	output reg [1:0] o_control_M_branch,
	output reg 	 	 o_control_M_memRead,
	output reg 	 	 o_control_M_memWrite,
	
	//WB  - se?ales de control para write-back
    output reg 	  	 o_control_WB_memtoReg,
	output reg 		 o_control_WB_regWrite
);
	
	reg [N_BITS_OP-1:0]   opcode;
	reg [N_BITS_FUNC-1:0] funcion;	
	
	always@*
	begin:control
		if(i_reset || i_halt)
		begin
			o_control_EX_regDst 	 = 1'b0;
			o_control_M_branch 	     = 2'b00;
			o_control_M_memRead 	 = 1'b0;
			o_control_WB_memtoReg    = 1'b0;
			o_control_EX_ALUOp 	     = 2'b00;
			o_control_M_memWrite     = 1'b0;
			o_control_EX_ALUSrc 	 = 1'b0;
			o_control_WB_regWrite    = 1'b0;
		end
		else if(i_valid)
		begin
		    opcode  = i_instruccion[31:26];
		
			case(opcode)
			//tipo R
			6'b000000:
            begin
                o_control_EX_regDst 	 = 1'b1;
                o_control_M_branch 	     = 2'b00;
                o_control_M_memRead 	 = 1'b0;
                o_control_WB_memtoReg    = 1'b0;
                o_control_EX_ALUOp 	     = 2'b00;
                o_control_M_memWrite     = 1'b0;
                o_control_EX_ALUSrc 	 = 1'b0;
                o_control_WB_regWrite    = 1'b1;
            end
				
			//tipo I
			6'b001111, 6'b001000, 6'b001100, 6'b001101, 6'b001110, 6'b001010://addi
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 2'b00;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b10;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b1;
				o_control_WB_regWrite  = 1'b1;
			end
			
			//tipo beq
			6'b000100, 6'b000101:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 2'b01;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b01;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b0;
				o_control_WB_regWrite  = 1'b0;
			end
			
			//tipo J
			6'b000010, 6'b000011:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 2'b10;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b00;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b0;
				o_control_WB_regWrite  = 1'b0;
			end
	
			//tipo sw
			6'b101000, 6'b101001, 6'b101011:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 2'b00;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b10;
				o_control_M_memWrite  = 1'b1;
				o_control_EX_ALUSrc  	 = 1'b1;
				o_control_WB_regWrite  = 1'b0;
			end
			
			//lw
			6'b100000, 6'b100001, 6'b100011, 6'b100100, 6'b100101, 6'b100111:
			begin 
				o_control_EX_regDst	 = 1'b0;
				o_control_M_branch 	 = 2'b00;
				o_control_M_memRead	 = 1'b1;
				o_control_WB_memtoReg = 1'b1;
				o_control_EX_ALUOp	 = 2'b00;
				o_control_M_memWrite	 = 1'b0;
				o_control_EX_ALUSrc	 = 1'b1;
				o_control_WB_regWrite	 = 1'b1;
			end
				
			default: //halt o no valida
			begin
			    o_control_EX_regDst	 = 1'b0;
				o_control_M_branch 	 = 2'b00;
				o_control_M_memRead	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp	 = 2'b00;
				o_control_M_memWrite	 = 1'b0;
				o_control_EX_ALUSrc	 = 1'b0;
				o_control_WB_regWrite	 = 1'b0;
		    end
			endcase
		end
		else
		begin
			o_control_EX_regDst 	 = 1'b0;
			o_control_M_branch 	     = 2'b00;
			o_control_M_memRead 	 = 1'b0;
			o_control_WB_memtoReg    = 1'b0;
			o_control_EX_ALUOp 	     = 2'b00;
			o_control_M_memWrite     = 1'b0;
			o_control_EX_ALUSrc 	 = 1'b0;
			o_control_WB_regWrite    = 1'b0;
		end
	end
endmodule
