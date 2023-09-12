`timescale 1ns / 1ps

module deco_tb();

    localparam N_BITS  = 32;
    localparam N_REG_BITS = 5;
    
 
    reg [N_BITS-1:0]     i_instruccion;
    reg [N_REG_BITS-1:0] i_dato_a_escribir_addr = 5'b00100;
    reg [N_BITS-1:0]     i_WB_data_to_w = 32'b00000000000000000001000011110011;
    reg [N_BITS-1:0]     i_pc_4 = 32'b00000000000000000000000000000100;
    reg                  i_clk;
    reg                  i_reset;
    reg                  i_regWrite;
    
    wire [N_BITS-1:0] o_dato_leido1;
    wire [N_BITS-1:0] o_dato_leido2;
    wire [N_REG_BITS-1:0] o_rs;
    wire [N_REG_BITS-1:0] o_rd_or_rt;
    wire [N_BITS-1:0] o_dato_ex_signo;
    wire [N_BITS-1:0] o_DstSalto;
    
    // Control
    wire              o_control_WB_memtoReg;
    wire              o_control_WB_regWrite;
    wire [1:0]        o_control_M_branch;
    wire              o_control_M_memWrite;
    wire              o_control_M_memRead;
    wire              o_control_EX_ALUSrc;
    wire [1:0]        o_control_EX_ALUOp;
    
    // unidad de deteccion de riesgos
    wire [N_BITS-1:0] o_sign_extension;
    
    wire [N_BITS-1:0] o_jump_direction;      
    
    wire              o_flush;
    
    wire              o_halt;
    
    reg [N_BITS-1:0] i_instruccion_array [29-1:0];
    integer index_instruccion;
    integer leng_inst_arry;
    reg  test_start;
    
    initial begin
    i_reset = 0;
    i_reset = 1;
    #100000
    i_reset = 0;
    index_instruccion = 0;
    leng_inst_arry = 29;
    test_start = 1'b0;
    i_clk = 1'b0; 
    // rt                        op       rs    rt    rd  des    func  
    i_instruccion_array[0] = 32'b00000000001000100001100000100100; // and
    i_instruccion_array[1] = 32'b00000000001000100001100000100101; // or
    i_instruccion_array[2] = 32'b00000000001000100001100000100001; // ADDU
    i_instruccion_array[3] = 32'b00000000001000100001100000100111; // NOR
    i_instruccion_array[4] = 32'b00000000001000100001100000100110; // XOR
    i_instruccion_array[5] = 32'b00000000000000100001100010000000; // SLL
    i_instruccion_array[6] = 32'b00000000000000100001100010000010; // SRL
    i_instruccion_array[7] = 32'b00000000000000100001100010000011; // SRA
    i_instruccion_array[8] = 32'b00000000001000100001100000000100; // SLLV
    i_instruccion_array[9] = 32'b00000000001000100001100000000110; // SRLV
    i_instruccion_array[10] = 32'b00000000001000100001100000000111; // SRAV
    i_instruccion_array[11] = 32'b00000000001000100001100000100011; // SUBU
    i_instruccion_array[12] = 32'b00000000001000100001100000100010; // SUB
    i_instruccion_array[13] = 32'b00000000001000100001100000101010; // SLT
    // carga y guardado           op       base    rt    offset 
    i_instruccion_array[14] = 32'b10000000011000110000000000000001; // 
    i_instruccion_array[15] = 32'b10000100011000110000000000000010; // 
    i_instruccion_array[16] = 32'b10001100011000110000000000000011; // 
    i_instruccion_array[17] = 32'b10010000011000110000000000000100; // 
    i_instruccion_array[18] = 32'b10010100011000110000000000000101; // 
    i_instruccion_array[19] = 32'b10011100011000110000000000000110; // 
    i_instruccion_array[20] = 32'b10100000001000110000000000000111; // 
    i_instruccion_array[21] = 32'b10100100001000110000000000001000; // 
    i_instruccion_array[22] = 32'b10101100001000110000000000001001; //
    // inmediata                   op       rs    rt    inmediato   
    i_instruccion_array[23] = 32'b00111100000000110000000000001000; // 
    i_instruccion_array[24] = 32'b00100000001000110000000000001000; // 
    i_instruccion_array[25] = 32'b00110000001000110000000101001010; // 
    i_instruccion_array[26] = 32'b00110100001000110000000101001010; // 
    i_instruccion_array[27] = 32'b00111000001000110000000101001010; // 
    i_instruccion_array[28] = 32'b00101000001000110000000000000010; //
    
    $dumpfile("dump.vcd"); 
    $dumpvars;
    
    #100
    
    test_start = 1'b1;
    
    #1000000;
    $finish();
    end
    
    
    always begin
      #10
      i_clk = ~i_clk;
    end
    
    always @(posedge i_clk) begin
      i_instruccion = i_instruccion_array[index_instruccion];
      
      if(index_instruccion == leng_inst_arry-1)
            index_instruccion = 0; 
      else
            index_instruccion = index_instruccion + 1;
    end
       
    instructionDecode 
    #(
       .N_BITS  (N_BITS),
       .N_REG_BITS (N_REG_BITS)    
    ) 
    instructionDecode 
    (
        .i_instruccion          (i_instruccion),
        .i_WB_data_to_w         ({32{1'b0}}),
        .i_dato_a_escribir_addr ({5{1'b0}}),
        .i_pc_4                 (i_pc_4),
        .i_clk                  (i_clk), 
        .i_reset                (i_reset),
        
        .i_ID_EX_rt             ({5{1'b0}}),
        .i_ID_EX_MemRead        ({5{1'b0}}),
        
        .i_regWrite             (1'b0), 
    
        
        .i_control_M_memRead_ID_EX  (1'b0),
        .i_control_WB_regWrite_ex   (1'b0),
        .i_control_WB_regWrite_mem  (1'b0),
        .i_dato_salida_ALU          ({32{1'b0}}),
        .i_dato_salida_mem          ({32{1'b0}}),
        .i_Alu_rt                   ({5{1'b0}}),
        .i_Mem_rt                   ({5{1'b0}}),
        //Señales de Salida
        // generales
        .o_dato_leido1          (o_dato_leido1),
        .o_dato_leido2          (o_dato_leido2),
        .o_rs                   (o_rs),
        .o_rd_or_rt             (o_rd_or_rt),
        .o_dato_ex_signo        (o_dato_ex_signo),
        //.o_DstSalto             (o_DstSalto),
        
        // Control
        .o_control_WB_memtoReg  (o_control_WB_memtoReg),
        .o_control_WB_regWrite  (o_control_WB_regWrite),
        .o_control_M_branch     (o_control_M_branch),
        .o_control_M_memWrite   (o_control_M_memWrite),
        .o_control_M_memRead    (o_control_M_memRead),
        .o_control_EX_ALUSrc    (o_control_EX_ALUSrc),
        .o_control_EX_ALUOp     (o_control_EX_ALUOp),
        
        // unidad de deteccion de riesgos
        
        .o_sign_extension       (o_sign_extension),
         
        .o_jump_direction       (o_jump_direction),
         
        .o_flush                (o_flush),      
        
        
        .o_halt                 (o_halt)
    );
    
endmodule
