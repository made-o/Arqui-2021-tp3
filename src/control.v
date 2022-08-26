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
	
	always@(*)begin:control
		if(i_reset || i_halt)
		begin
			o_control_EX_regDst 	 = 1'b0;
			o_control_M_branch 	     = 1'b00;
			o_control_M_memRead 	 = 1'b0;
			o_control_WB_memtoReg    = 1'b0;
			o_control_EX_ALUOp 	     = 2'b0;
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
                o_control_M_branch 	     = 1'b00;
                o_control_M_memRead 	 = 1'b0;
                o_control_WB_memtoReg    = 1'b0;
                o_control_EX_ALUOp 	     = 1'b0;
                o_control_M_memWrite     = 1'b0;
                o_control_EX_ALUSrc 	 = 1'b0;
                o_control_WB_regWrite    = 1'b1;
            end
				
			//tipo I
			6'b001xxx://addi
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 1'b00;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b10;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b1;
				o_control_WB_regWrite  = 1'b1;
			end
			
			//tipo beq
			6'b0001xx:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 1'b01;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b01;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b0;
				o_control_WB_regWrite  = 1'b0;
			end
			
			//tipo J
			6'b00001x:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 1'b10;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 1'b0;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc 	 = 1'b0;
				o_control_WB_regWrite  = 1'b0;
			end
	
			//tipo sw
			6'b101xxx:
			begin
				o_control_EX_regDst 	 = 1'b0;
				o_control_M_branch 	 = 1'b00;
				o_control_M_memRead 	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp 	 = 2'b10;
				o_control_M_memWrite  = 1'b0;
				o_control_EX_ALUSrc  	 = 1'b1;
				o_control_WB_regWrite  = 1'b1;
			end
			
			//lw
			6'b100xxx:
			begin 
				o_control_EX_regDst	 = 1'b0;
				o_control_M_branch 	 = 1'b00;
				o_control_M_memRead	 = 1'b1;
				o_control_WB_memtoReg = 1'b1;
				o_control_EX_ALUOp	 = 2'b0;
				o_control_M_memWrite	 = 1'b0;
				o_control_EX_ALUSrc	 = 1'b1;
				o_control_WB_regWrite	 = 1'b1;
			end
				
			default: //halt o no valida
			begin
			    o_control_EX_regDst	 = 1'b0;
				o_control_M_branch 	 = 1'b00;
				o_control_M_memRead	 = 1'b0;
				o_control_WB_memtoReg = 1'b0;
				o_control_EX_ALUOp	 = 2'b0;
				o_control_M_memWrite	 = 1'b0;
				o_control_EX_ALUSrc	 = 1'b0;
				o_control_WB_regWrite	 = 1'b0;
		    end
			endcase
		end
	end
endmodule
