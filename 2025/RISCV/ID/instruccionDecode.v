`timescale 1ns / 1ps

module instructionDecode#(
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
    input                            i_exec_mode,
    input                            i_step,

    input wire              i_halt,
    
    input [N_REG_BITS-1:0] i_addr_tx_ID,
     
    //Unidad de deteccion de errores
    input  wire [N_REG_BITS-1:0] i_ID_EX_rt,
    //input  wire [N_REG_BITS-1:0] i_ID_EX_MemRead,
    
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
    output reg [N_BITS-1:0] o_instruccion,
    output [N_BITS-1:0] o_data_send_tx_ID,
        
    // generales
    output wire [N_BITS-1:0] o_dato_leido1,
    output wire [N_BITS-1:0] o_dato_leido2,
    output reg [N_REG_BITS-1:0] o_rs,
    output reg [N_REG_BITS-1:0] o_rt,
    output reg  [N_REG_BITS-1:0] o_rd_or_rt,

    output reg [N_REG_BITS-1:0] o_rd, //--- no se si lo necesito----
    //output wire [N_BITS-1:0] o_dato_ex_signo,
    //output reg [N_BITS-1:0] o_DstSalto,
    
    // Control
    output reg              o_control_WB_memtoReg,
    output reg              o_control_WB_regWrite,
    output reg [1:0]        o_control_M_branch,
    output reg              o_control_M_memWrite,
    output reg              o_control_M_memRead,
    output reg              o_control_EX_ALUSrc,
    output reg [1:0]        o_control_EX_ALUOp,
    
    // unidad de deteccion de riesgos
    //output reg              o_IF_ID_MemRead,
    //output reg              o_PCWrite, 
         
    output reg  [N_BITS-1:0] o_sign_extension,
    
    output wire [N_BITS-1:0] o_jump_direction,

    //output o_cpu_finished,
    
    output wire              o_flush,
    output reg               o_halt,
    output wire              o_stall
);
    wire              w_control_WB_memtoReg;
    wire              w_control_WB_regWrite;
    wire [1:0]        w_control_M_branch;
    wire              w_control_M_memWrite;
    wire              w_control_M_memRead;
    wire              w_control_EX_ALUSrc;
    wire [1:0]        w_control_EX_ALUOp;
    wire [N_BITS:0]   w_sign_extension;

    wire [N_BITS-1:0] jump_direction;
    
    reg [N_REG_BITS-1:0] w_rd_or_rt;
    //reg              i_oEnable;
    reg              i_WriteEnable;
    reg [N_BITS-1:0] dato_a_escribir;
    
    wire              control_EX_regDst;
    
    //reg i_ReadEnable;
    
    //reg valid;

    //  ¡¡Final de ejecucion!!
    //assign o_cpu_finished = i_halt;

    always @(*)begin:multiplexor_rd_rt
        if(control_EX_regDst)//rt
            w_rd_or_rt = i_instruccion[15:11];
        else//rd
            w_rd_or_rt = i_instruccion[20:16];
    end
    
    always @(posedge i_clk) begin: memWrite
            i_WriteEnable <= i_regWrite;
            //i_ReadEnable <= 1;
            //i_oEnable <= 1;
            //valid <= 1;
    end//end_always
    
    /*
    always @(negedge i_clk) begin: memRead
        i_WriteEnable = 0;
        i_ReadEnable = 1;
        i_oEnable = 1;
        valid = 0;
    end//end_always
    */
    
    regMemory 
        u_reg_mem (
            .i_clk(i_clk),
            //.i_reset(i_reset),
            
            .i_reg_lectura1(i_instruccion[25:21]), //rs
            .i_reg_lectura2(i_instruccion[20:16]), //rt
            .i_regWrite_addr(i_dato_a_escribir_addr),
            .i_dato_a_escribir(i_WB_data_to_w),
            
            //.i_oEnable(i_oEnable),
            .i_WriteEnable (i_WriteEnable),
            //.i_ReadEnable (i_ReadEnable),
            
            .i_addr_tx(i_addr_tx_ID),
            
            .o_data_send_tx(o_data_send_tx_ID),
            .o_data1(o_dato_leido1),
            .o_data2(o_dato_leido2)
        );
        
    control#(
        .N_BITS           (32),
        .N_BITS_OP        (6),
        .N_BITS_FUNC      (6)
    )   
    u_control(
        //.i_clk(i_clk),
        .i_instruccion(i_instruccion[31:26]),
        .i_reset(i_reset),
        .i_valid(!i_reset),
        .i_stall(o_stall),
        .i_flush(o_flush),
        //.i_halt(i_halt),
        
        .o_control_WB_memtoReg(w_control_WB_memtoReg),
        .o_control_WB_regWrite(w_control_WB_regWrite),
        .o_control_M_branch(w_control_M_branch),
        .o_control_M_memWrite(w_control_M_memWrite),
        .o_control_M_memRead(w_control_M_memRead),
        .o_control_EX_ALUSrc(w_control_EX_ALUSrc),
        .o_control_EX_ALUOp(w_control_EX_ALUOp),
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
        .o_sign_extension (w_sign_extension)
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
        .i_ID_EX_rt                 (i_ID_EX_rt),
    
        .i_jump_direction           (jump_direction),
        .i_PC                       (i_pc_4),
        .i_dato_leido_1             (o_dato_leido1),
        .i_dato_leido_2             (o_dato_leido2),
        .i_dato_salida_ALU          (i_dato_salida_ALU),
        .i_dato_salida_mem          (i_dato_salida_mem),
        .o_flush                    (o_flush),
        .o_stall                     (o_stall),
        .o_jump_direction           (o_jump_direction)
    );
    always @(posedge i_clk) begin: ID_EX
        if((i_exec_mode == 1'b0 || (i_exec_mode && i_step)))begin
            o_control_WB_memtoReg   <= w_control_WB_memtoReg;
            o_control_WB_regWrite   <= w_control_WB_regWrite;
            o_control_M_branch      <= w_control_M_branch;
            o_control_M_memWrite    <= w_control_M_memWrite;
            o_control_M_memRead     <= w_control_M_memRead;
            o_control_EX_ALUSrc     <= w_control_EX_ALUSrc;
            o_control_EX_ALUOp      <= w_control_EX_ALUOp;
            o_instruccion           <= i_instruccion;
            o_sign_extension        <= w_sign_extension;
            o_rs                    <= i_instruccion[25:21];
            o_rt                    <= i_instruccion[20:16];
            o_rd_or_rt              <= w_rd_or_rt;

            o_rd                    <= i_instruccion[15:11];
            o_halt                  <= i_halt;
        end    
    end
endmodule
