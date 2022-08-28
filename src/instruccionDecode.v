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
    input  wire [N_BITS-1:0]         i_pc_4,
    input  wire                      i_clk, 
    input  wire                      i_reset,
     
    //Unidad de deteccion de errores
    input  wire [N_REG_BITS-1:0] i_ID_EX_rt,
    input  wire [N_REG_BITS-1:0] i_ID_EX_MemRead,
    
    //selectores
    input  wire              i_regWrite,
    
    input  wire                  i_control_M_memRead_ID_EX,
    input  wire                  i_control_WB_regWrite_ex,
    input  wire                  i_control_WB_regWrite_mem,
    input  wire [N_BITS-1:0]     i_dato_salida_ALU,
    input  wire [N_BITS-1:0]     i_dato_salida_mem,
    input  wire [N_REG_BITS-1:0] i_Alu_rt,
    input  wire [N_REG_BITS-1:0] i_Mem_rt,
    
    //Señales de Salida
    // generales
    output wire [N_BITS-1:0] o_dato_leido1,
    output wire [N_BITS-1:0] o_dato_leido2,
    output wire [N_REG_BITS-1:0] o_rs,
    output reg  [N_REG_BITS-1:0] o_rd_or_rt,
    output wire [N_BITS-1:0] o_dato_ex_signo,
    //output reg [N_BITS-1:0] o_DstSalto,
    
    // Control
    output wire              o_control_WB_memtoReg,
    output wire              o_control_WB_regWrite,
    output wire [1:0]        o_control_M_branch,
    output wire              o_control_M_memWrite,
    output wire              o_control_M_memRead,
    output wire              o_control_EX_ALUSrc,
    output wire [1:0]        o_control_EX_ALUOp,
    
    // unidad de deteccion de riesgos
    //output reg              o_IF_ID_MemRead,
    //output reg              o_PCWrite, 
         
    output wire [N_BITS-1:0] o_sign_extension,
    
    output wire [N_BITS-1:0] o_jump_direction,
    
    output wire              o_flush,
    output wire              o_halt
);
    wire [N_BITS-1:0] jump_direction;
    
    reg              i_oEnable;
    reg              i_WriteEnable;
    reg [N_BITS-1:0] dato_a_escribir;
    
    wire              control_EX_regDst;
    
    reg i_ReadEnable;
    
    reg valid;
    
    assign o_rs = i_instruccion[25:21];
    
    always @(*)begin:multiplexor_rd_rt
        if(control_EX_regDst)//rt
            o_rd_or_rt = i_instruccion[20:16];
        else//rd
            o_rd_or_rt =i_instruccion[15:11];
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
            .i_reset(i_reset),
            
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
        
        .o_control_WB_memtoReg(o_control_WB_memtoReg),
        .o_control_WB_regWrite(o_control_WB_regWrite),
        .o_control_M_branch(o_control_M_branch),
        .o_control_M_memWrite(o_control_M_memWrite),
        .o_control_M_memRead(o_control_M_memRead),
        .o_control_EX_ALUSrc(o_control_EX_ALUSrc),
        .o_control_EX_ALUOp(o_control_EX_ALUOp),
        .o_control_EX_regDst(control_EX_regDst)
    ); 
    
    pc_jump#(
        .N_BITS_DW   (32),
        .N_BITS_W    (16),
        .N_BITS_REG  (5)
    ) extension_and_jump_addr(
        .i_sign_extension (i_instruccion[15:0]),
        .pc               (i_pc_4),
        
        .o_jump_direction (jump_direction),
        .o_sign_extension (o_sign_extension)
    );
    
     hazard_detector#(
        .N_BITS      (32),
        .N_BITS_REG  (5)
    ) hazard_d(
        .i_control_WB_regWrite_ex   (i_control_WB_regWrite_ex),
        .i_control_WB_regWrite_mem  (i_control_WB_regWrite_mem),
        .i_control_M_memRead_ID_EX  (i_control_M_memRead_ID_EX),
        .i_branch                   (o_control_M_branch),
        .i_rs                       (i_instruccion[25:21]),
        .i_rt                       (i_instruccion[20:16]),
        .i_Alu_rt                   (i_Alu_rt),
        .i_Mem_rt                   (i_Mem_rt),
        .i_ID_EX_rt                 (i_Alu_rt),
    
        .i_jump_direction           (jump_direction),
        .i_PC                       (i_pc_4),
        .i_dato_leido_1             (o_dato_leido1),
        .i_dato_leido_2             (o_dato_leido2),
        .i_dato_salida_ALU          (i_dato_salida_ALU),
        .i_dato_salida_mem          (i_dato_salida_mem),
        .o_flush                    (o_flush),
        .o_halt                     (o_halt),
        .o_jump_direction           (o_jump_direction)
    );
    
endmodule

