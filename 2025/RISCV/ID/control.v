`timescale 1ns / 1ps

module control#
(
	parameter	N_BITS		  = 32,
	parameter 	N_BITS_OP	  = 7,
	parameter 	N_BITS_FUNC_3 = 3
)
(
    //input  wire       			 i_clk,
    input  wire     		     	i_reset,
    input  wire       		 	 	i_valid,
    input  wire       		 	 	i_stall,
    input  wire       		 	 	i_flush,
	//input  wire					 i_halt,
	input  wire [N_BITS_OP-1:0]	 	i_opcode,
	input  wire [N_BITS_FUNC_3-1:0]	i_func3,
    
	//EX  - se?ales de control para ejecuci?n
	output reg [1:0] o_control_EX_ALUOp,
	output reg [1:0] o_control_EX_ALUSrc,
	//output reg  	 o_control_EX_regDst,	
	
	//MEM - se?ales de control para acceso a memoria
	output reg [1:0] o_control_M_branch,
	output reg 	 	 o_control_M_memRead,
	output reg 	 	 o_control_M_memWrite,
	
	//WB  - se?ales de control para write-back
    output reg [1:0] o_control_WB_memtoReg,
	output reg 		 o_control_WB_regWrite
);
	
	reg [N_BITS_OP-1:0]   opcode;
	//reg [N_BITS_FUNC-1:0] funcion;	
	
	always@*
	begin:control
		if(i_reset || i_stall || i_flush)// || i_halt)
		begin
			//o_control_EX_regDst 	 = 1'b0;
			o_control_WB_memtoReg    = 1'b00;
			o_control_WB_regWrite    = 1'b0;
			o_control_M_branch 	     = 2'b00;
			o_control_M_memRead 	 = 1'b0;
			o_control_M_memWrite     = 1'b0;
			o_control_EX_ALUOp 	     = 2'b00;
			o_control_EX_ALUSrc 	 = 2'b00;
		end
		else if(i_valid)
		begin
		    opcode  = i_opcode;
		
			case(opcode)
			//tipo R
			7'b0110011:
            begin
                //o_control_EX_regDst 	 = 1'b1;
                o_control_WB_memtoReg    = 2'b00;//dato de la alu
                o_control_WB_regWrite    = 1'b1;
                o_control_M_branch 	     = 2'b00;
                o_control_M_memRead 	 = 1'b0;
                o_control_M_memWrite     = 1'b0;
                o_control_EX_ALUOp 	     = 2'b10;
                o_control_EX_ALUSrc 	 = 2'b00;
            end
				
			//tipo I
			7'b0010011 ://addi
			begin
				//o_control_EX_regDst 	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b00;//dato de la alu
				o_control_WB_regWrite  	= 1'b1;
				o_control_M_branch 	 	= 2'b00;
				o_control_M_memRead 	= 1'b0;
				o_control_M_memWrite 	= 1'b0;
				o_control_EX_ALUOp 	 	= 2'b11;
				o_control_EX_ALUSrc 	= 2'b01;
				if(i_func3 == 3'b001 && i_func3 == 3'b101)
				begin
					o_control_EX_ALUSrc = 2'b10;
				end
			end

			//tipo beq
			7'b1100011:
			begin
				o_control_WB_memtoReg 	= 2'b00;
				o_control_WB_regWrite  	= 1'b0;
				o_control_M_branch 	 	= 2'b11;

				if(i_func3 == 3'b000)
				begin
					o_control_M_branch 	= 2'b01;
				end

				o_control_M_memRead 	= 1'b0;
				o_control_M_memWrite  	= 1'b0;
				o_control_EX_ALUOp 	 	= 2'b01;
                o_control_EX_ALUSrc 	= 2'b00;
			end
			
			//tipo J
			7'b1101111, 7'b1100111:
			begin
				//o_control_EX_regDst 	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b00;
				o_control_WB_regWrite  	= 1'b0;
				o_control_M_branch 	 	= 2'b10;
				o_control_M_memRead 	= 1'b0;
				o_control_M_memWrite  	= 1'b0;
				o_control_EX_ALUOp 	 	= 2'b01;
				o_control_EX_ALUSrc 	= 1'b0;
			end
	
			//tipo sw
			7'b0100011:
			begin
				//o_control_EX_regDst 	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b00;
				o_control_WB_regWrite  	= 1'b0;
				o_control_M_branch 	 	= 2'b00;
				o_control_M_memRead 	= 1'b0;
				o_control_M_memWrite  	= 1'b1;
				o_control_EX_ALUOp 	 	= 2'b00;
                o_control_EX_ALUSrc 	= 2'b01;
			end
			
			//lw
			7'b0000011:
			begin 
				//o_control_EX_regDst	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b01;//dato leido de la memoria
				o_control_WB_regWrite	= 1'b1;
				o_control_M_branch 	 	= 2'b00;
				o_control_M_memRead	 	= 1'b1;
				o_control_M_memWrite	= 1'b0;
				o_control_EX_ALUOp	 	= 2'b00;
                o_control_EX_ALUSrc 	= 2'b01;
			end
			//LUI
			7'b0110111:
			begin 
				//o_control_EX_regDst	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b10;//dato de la extension de signo
				o_control_WB_regWrite	= 1'b1;
				o_control_M_branch 	 	= 2'b00;
				o_control_M_memRead	 	= 1'b0;
				o_control_M_memWrite	= 1'b0;
				o_control_EX_ALUOp	 	= 2'b01;
                o_control_EX_ALUSrc 	= 2'b00;
			end
			default: //halt o no valida
			begin
			    //o_control_EX_regDst	 = 1'b0;
				o_control_WB_memtoReg 	= 2'b00;
				o_control_WB_regWrite	= 1'b0;
				o_control_M_branch 	 	= 2'b00;
				o_control_M_memRead	 	= 1'b0;
				o_control_M_memWrite	= 1'b0;
				o_control_EX_ALUOp	 	= 2'b00;
                o_control_EX_ALUSrc 	= 2'b00;
		    end
			endcase
		end
		else
		begin
			//o_control_EX_regDst 	 = 1'b0;
			o_control_WB_memtoReg    = 2'b00;
			o_control_WB_regWrite    = 1'b0;
			o_control_M_branch 	     = 2'b00;
			o_control_M_memRead 	 = 1'b0;
			o_control_M_memWrite     = 1'b0;
			o_control_EX_ALUOp 	     = 2'b00;
            o_control_EX_ALUSrc 	 = 2'b00;
		end
	end
endmodule
