`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2024 21:10:54
// Design Name: 
// Module Name: tb_EX
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


module tb_EX();

    localparam N_BITS  = 32;
    localparam N_BITS_REG = 5;
    
    // entradas
    reg [N_BITS-1:0]     i_data_A =  32'b1;
    reg [N_BITS-1:0]     i_data_B =  32'b11;
    
    reg [N_BITS-1:0]     i_data_from_WB =  32'b101;
    reg [N_BITS-1:0]     i_data_from_ME =  32'b110;
    
    reg [N_BITS-1:0]     i_data_extension_signo = 32'b0000000000100010000110000010000;
    
    reg [N_BITS-1:0]     i_instruccion = 32'b00000000001000100001100000100001;
    
    reg                  i_clk;
    reg                  i_reset;
    reg                  i_enable;
    
    // entradas de control  
    reg [1:0]            i_alu_op = 2'b10;
    reg                  i_alu_src = 1'b0;
    
    // Se�ales de control de la EX:
    reg i_regDst = 5'b00001;
   
    reg [N_BITS_REG-1:0] i_rt_id = 5'b00000; // 5-bits
    reg [N_BITS_REG-1:0] i_rd_id = 5'b00000; // 5-bits
    reg [N_BITS_REG-1:0] i_rt_OR_rd = 5'b00000; // 5-bits
   
    // Se�al de entrada al m�dulo de control de la ALU
    reg [N_BITS_REG:0]   i_opcode; // 6bits
   
    // Se�ales extras que entran a la unidad de cortocircuito:
    reg [N_BITS_REG-1:0] i_rd_EX_MEM = 5'b00000; //6-bits
    reg [N_BITS_REG-1:0] i_rd_MEM_WB = 5'b00000; //6-bits
    reg [N_BITS_REG-1:0] i_rs_id = 5'b00000;     //6-bits
   
    // Se�ales que vienen de la etapa ID o de etapas siguientes:
    reg i_memToReg = 1'b0;
    reg i_regWrite_EX_MEM = 1'b0;
    reg i_regWrite_MEM_WB = 1'b0;
    reg [1:0] i_branch = 2'b00;
    reg i_memWrite = 1'b0;
    reg i_memRead = 1'b0;
    
    // coneccion entre modulos
    reg [2-1:0]         con_forwarding_a = 2'b00;
    reg [2-1:0]         con_forwarding_b = 2'b00;
    
    // salida 
    wire [N_BITS-1:0]       o_data_B;
    wire [N_BITS-1:0]       o_resultado;
    wire [N_BITS_REG-1:0]   o_rs;
    wire [N_BITS_REG-1:0]   o_rd_or_rt;
    wire [N_BITS-1:0]       o_dato_ex_signo;
    wire [N_BITS-1:0]       o_DstSalto;
    
    // salida Control
    wire                    o_control_WB_memtoReg;
    wire                    o_control_WB_regWrite;
    wire [1:0]              o_control_M_branch;
    wire                    o_control_M_memWrite;
    wire                    o_control_M_memRead;
   
    wire                    o_ceroSignal;
    wire                    o_memToReg;
    wire                    o_regWrite_EX_MEM;
    wire                    o_regWrite_MEM_WB;
    wire                    o_branch;
    wire                    o_memWrite;
    wire                    o_memRead;
    
    reg test_start = 1'b0;
    initial begin
    i_reset = 0;
    i_reset = 1;
    i_clk = 0;
    #100000
    i_reset = 0;
   
    $dumpfile("dump.vcd"); 
    $dumpvars;
    
    #100
    
    test_start = 1'b1;
    
    //i_data_A =  32'b1;
    //i_data_B =  32'b11;
    
    //i_data_from_WB =  32'b101;
    //i_data_from_ME =  32'b110;
    
    //i_data_extension_signo =  32'b0000000000100010000110000010000;
    
    //i_instruccion = 32'b00000000001000100001100000100001;
    
    // entradas de control  
    //i_alu_op = 2'b10;
    //i_alu_src = 1'b0;
    
    // Se�ales de control de la EX:
    //i_regDst = ;
   
    //i_rt_id = 5'b00000; // 5-bits
    //i_rd_id = 5'b00000; // 5-bits
    //i_rt_OR_rd = 5'b00000; // 5-bits
   
    // Se�ales extras que entran a la unidad de cortocircuito:
    //i_rd_EX_MEM = 5'b00000; //5-bits
    //i_rd_MEM_WB = 5'b00000; //5-bits
    //i_rs_id = 5'b00000;     //5-bits
   
    // Se�ales que vienen de la etapa ID o de etapas siguientes:
    //i_memToReg = 1'b0;
    //i_regWrite_EX_MEM = 1'b0;
    //i_regWrite_MEM_WB = 1'b0;
    //i_branch = 2'b00;
    //i_memWrite = 1'b0;
    //i_memRead = 1'b0;
    
    //con_forwarding_a = 2'b00;
    //con_forwarding_b = 2'b00;
    
    
    #1000000;
    $finish();
    end
    
    always begin
      #200
      i_clk = ~i_clk;
    end
       
    execute 
    #(
       .N_BITS  (N_BITS),
       .N_REG_BITS (N_BITS_REG)
    ) 
    execute 
    (
        .i_instruccion          (i_instruccion),
        .i_aluOP                (i_alu_op),
        .i_aluSrc               (i_alu_src),
        .i_regDst               (i_regDst),
        
        .i_datoLeido1           (i_data_A),
        .i_datoLeido2           (i_data_B),
        .i_datoExtSigno         (i_data_extension_signo),
        .i_rt_id                (i_rt_id),
        .i_rd_id                (i_rd_id),
        .i_rt_OR_rd             (i_rt_OR_rd),
        .i_opcode               (i_opcode),
        .i_rd_EX_MEM            (i_rd_EX_MEM),
        .i_rd_MEM_WB            (i_rd_MEM_WB),
        .i_rs_id                (i_rs_id),
        
        .i_wbData               (i_data_from_WB),
        .i_memData              (i_data_from_ME),
        .i_memToReg             (i_memToReg),
        
        .i_regWrite_EX_MEM      (i_regWrite_EX_MEM),
        .i_regWrite_MEM_WB      (i_regWrite_MEM_WB),
        .i_branch               (i_branch),
        .i_memWrite             (i_memWrite),
        .i_memRead              (i_memRead),
        
        .i_forwardA             (con_forwarding_a),
        .i_forwardB             (con_forwarding_b),
        
        //Se�ales de Salida
        // generales
        .o_ceroSignal           (o_ceroSignal),
        .o_aluResult            (o_resultado),
        .o_datoLeido2           (o_data_B),
        .o_rd_data              (o_rs),
        .o_rt_OR_rd             (o_rt_OR_rd),
        .o_memToReg             (o_memToReg),
        .o_regWrite_EX_MEM      (o_regWrite_EX_MEM),
        .o_regWrite_MEM_WB      (o_regWrite_MEM_WB),
        .o_branch               (o_branch),
        .o_memWrite             (o_memWrite),
        .o_memRead              (o_memRead)

    );
endmodule
