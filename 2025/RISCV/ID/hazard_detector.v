`timescale 1ns / 1ps

module hazard_detector#
(
	N_BITS	   = 32,
    N_BITS_REG = 5
)
(
    //input  wire                  i_PCSrc_ID,
    //input  wire                  i_PCSrc_EX,
    //input  wire [N_BITS_REG-1:0] i_ID_EX_memRead,
    
    input  wire [1:0]            i_branch,
    
    input  wire [N_BITS_REG-1:0] i_rs1,
    input  wire [N_BITS_REG-1:0] i_rs2,
    
    //input  wire [N_BITS_REG-1:0] i_Alu_rt,
    
    input  wire [N_BITS-1:0]     i_jump_direction,
    input  wire [N_BITS-1:0]     i_PC,
    input  wire [N_BITS-1:0]     i_dato_leido_1,
    input  wire [N_BITS-1:0]     i_dato_leido_2,

    input wire  [7-1:0]          i_opcode,

    //Vienen de ID_EX
    input  wire [N_BITS_REG-1:0] i_ID_EX_rt,
    input  wire                  i_control_WB_regWrite_ID_EX,
    input  wire                  i_control_M_memRead_ID_EX,

    //Vienen de EX_MEM
    input  wire [N_BITS_REG-1:0] i_EX_MEM_rt,
    input  wire                  i_control_M_memRead_EX_MEM,
    input  wire                  i_control_WB_regWrite_EX_MEM,
    input  wire [N_BITS-1:0]     i_dato_salida_ALU,
    
    //output reg                   o_PCSrc,
    output reg                   o_flush,
    output reg                   o_stall,
    output reg [N_BITS-1:0]      o_jump_direction
 );
    reg  [N_BITS-1:0] dato_comparacion_1;
    reg  [N_BITS-1:0] dato_comparacion_2;

    wire is_branch_condicional = (i_opcode == 7'b1100011); // BEQ, BNE
    wire is_jalr               = (i_opcode == 7'b1100111); // JALR

    wire use_rs1 = (i_opcode != 7'b0110111) && 
                   (i_opcode != 7'b1101111); // LUI y JAL NO lo usan
    wire use_rs2 = (i_opcode == 7'b0110011) || 
                   (i_opcode == 7'b0100011) || 
                   (is_branch_condicional); // BNQ, BEQ, tipo sabe y tipo R SI lo usan
    
    always@(*)
    begin: calculo_stall 
        o_stall = 0;

        if((i_control_M_memRead_ID_EX == 1'b1) && 
           (((i_rs1 == i_ID_EX_rt) && use_rs1) || ((i_rs2 == i_ID_EX_rt) && use_rs2)) && 
           (i_ID_EX_rt != 5'd0)) begin: normal_data_hazard_or_type_load_1_EX
            o_stall = 1;
        end

        if (is_branch_condicional || is_jalr) begin: branch_data_hazard

            if (i_control_M_memRead_EX_MEM && 
                     ((i_rs1 == i_EX_MEM_rt) || ((i_rs2 == i_EX_MEM_rt) && is_branch_condicional)) && 
                     (i_EX_MEM_rt != 5'd0)) begin: type_Load_2_MEM
                o_stall = 1;
            end
            
            else if (i_control_WB_regWrite_ID_EX && 
                     ((i_rs1 == i_ID_EX_rt) || ((i_rs2 == i_ID_EX_rt) && is_branch_condicional)) && 
                     (i_ID_EX_rt != 5'd0)) begin: type_R_EX
                o_stall = 1;
            end
        end
    end
    //WARNING: parece un forwardin pero le faltan condiciones
    always@(*)
    begin: mux_data1
        if((i_rs1 == i_EX_MEM_rt && i_control_WB_regWrite_EX_MEM == 1) && 
            (i_EX_MEM_rt != 5'd0) && use_rs1)
            dato_comparacion_1 = i_dato_salida_ALU;
        else
            dato_comparacion_1 = i_dato_leido_1;
    end
    
    always@(*)
    begin: mux_data2
        if((i_rs2 == i_EX_MEM_rt && i_control_WB_regWrite_EX_MEM == 1) && 
            (i_EX_MEM_rt != 5'd0) && use_rs2)
            dato_comparacion_2 = i_dato_salida_ALU;
        else
            dato_comparacion_2 = i_dato_leido_2;
    end
    
    always@(*)begin:control_hazard
        o_flush = 0;
        o_jump_direction = i_PC;
        case(i_branch)
            2'b01:begin
                if(dato_comparacion_1 == dato_comparacion_2)
                begin
                    o_flush = 1;
                    o_jump_direction = i_jump_direction;
                end
            end            
            2'b11:begin
                if(dato_comparacion_1 != dato_comparacion_2)
                begin
                    o_flush = 1;
                    o_jump_direction = i_jump_direction;
                end
            end
            2'b10:begin
                o_flush = 1;
                o_jump_direction = i_jump_direction;
            end
        endcase
    end
 
endmodule
