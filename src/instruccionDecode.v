`timescale 1ns / 1ps
module instruccionDecode#(
    // Parametros:
    parameter N_BITS = 32,
    parameter N_REG_BITS = 5
)
// Entradas y salidas:
(   
    //Señales De Entrada
    //de el modulo Deco
    input  wire [N_BITS-1:0]         i_instruccion,
    input  wire [N_BITS-1:0]         i_WB_data_to_w,
    input  wire [N_REG_BITS-1:0]     i_dato_a_escribir_addr,
    input  wire                      i_pc_4,
    input  wire                      i_clk, 
    input  wire                      i_reset,
     
    //Unidad de deteccion de errores
    input  wire [N_REG_BITS-1:0] i_ID_EX_rt,
    input  wire [N_REG_BITS-1:0] i_ID_EX_MemRead,
    
    //selectores
    input  wire             i_regWrite, 
    
    
    //Señales de Salida
    // generales
    output reg [N_BITS-1:0] o_dato_leido1,
    output reg [N_BITS-1:0] o_dato_leido2,
    output wire             o_rs,
    output reg              o_rd_or_rt,
    output reg [N_BITS-1:0] o_dato_ex_signo,
    output reg [N_BITS-1:0] o_DstSalto,
    
    // Control
    output reg              o_control_WB_memtoReg,
    output reg              o_control_WB_regWrite,
    output reg              o_control_M_branch,
    output reg              o_control_M_memWrite,
    output reg              o_control_M_memRead,
    output reg              o_control_EX_ALUSrc,
    output reg [1:0]        o_control_EX_ALUOp,
    
    // unidad de deteccion de riesgos
    output reg              o_IF_ID_MemRead,
    output reg              o_PCWrite,      
    
    
    output reg              o_halt
);

    reg              i_oEnable;
    reg              i_WriteEnable;
    reg [N_BITS-1:0] dato_a_escribir;
    
    reg              control_EX_regDst;
    
    reg i_ReadEnable;
    
    reg valid;
    
    assign o_rs = i_instruccion[21:25];
    
    always @(*)begin:multiplexor_rd_rt
        if(control_EX_regDst)//rt
            o_rd_or_rt = i_instruccion[16:20];
        else//rd
            o_rd_or_rt =i_instruccion[11:15];
    end
    
    always @(posedge i_clk) begin: memWrite
        i_WriteEnable = i_regWrite;
        i_ReadEnable = 0;
        valid = 1;
    end//end_always
    
    always @(negedge i_clk) begin: memRead
        i_WriteEnable = 0;
        i_ReadEnable = 1;
        i_oEnable = 1;
        valid = 0;
    end//end_always

    regMemory 
        u_reg_mem (
            .i_clk(i_clk),
            
            .i_reg_lectura1(i_instruccion[25:21]), //rs
            .i_reg_lectura2(i_instruccion[20:16]), //rt
            .i_regWrite_addr(i_dato_a_escribir_addr),
            .i_dato_a_escribir(i_WB_data_to_w),
            
            .i_oEnable(i_oEnable),
            .i_WriteEnable (i_WriteEnable),
            .i_ReadEnable (i_ReadEnable),
            
            .o_data1(o_dato_leido1),
            .o_data2(o_dato_leido2)
        );
        
    control#(
        .N_BITS           (32),
        .N_BITS_OP        (6),
        .N_BITS_FUNC      (6)
    )   
    u_control(
        .i_clk(i_clk),
        .i_instruccion(i_instruccion),
        .i_reset(i_reset),
        .i_valid(valid),
        .i_halt(o_halt),
        
        .o_RegWrite(o_dato_leido1),
        .o_RegDst(o_dato_leido1),
        
        .o_memtoReg(o_control_WB_memtoReg),
        .o_regWrite(o_control_WB_regWrite),
        .o_branch(o_control_M_branch),
        .o_memWrite(o_control_M_memWrite),
        .o_memRead(o_control_M_memRead),
        .o_ALUSrc(o_control_EX_ALUSrc),
        .o_ALUOp(o_control_EX_ALUOp),
        .o_regDst(control_EX_regDst)
    ); 


	
    
    pc_jump#(
        .N_BITS_DW   (32),
        .N_BITS_W    (16),
        .N_BITS_REG  (5)
    ) extension_and_jump_addr(
        .i_sign_extension (0),
        .pc               (0),
        .o_jump_direction (0),
        .o_sign_extension (0)
    );
    
     hazard_detector#(
        .N_BITS_DW   (32),
        .N_BITS_W    (16),
        .N_BITS_REG  (5)
    ) hazard_d(
        .i_PCSrc_ID                 (0),
        .i_PCSrc_EX                 (0),
        .i_control_M_memRead_ID_EX  (0),
        .i_ID_EX_rt                 (0),
        .i_EX_M_rt                  (0),
        .i_ID_EX_memRead            (0),
        .i_rs                       (0),
        .i_rt                       (0),
        .i_jump_direction_ID        (0),
        .i_jump_direction_EX        (0),
        
        .o_PCSrc                    (0),
        .o_flush                    (0),
        .o_halt                     (0),
        .o_jump_direction           (0)
    );
    
endmodule

