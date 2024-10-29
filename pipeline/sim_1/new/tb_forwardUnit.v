`timescale 1ns / 1ps

module tb_forwarding_unit;

  // Parámetro para definir el número de bits de los registros
  localparam N_BITS_REG = 6;

  // entradas:
  reg [N_BITS_REG-1:0] i_rt_ID;
  reg [N_BITS_REG-1:0] i_rs_ID;
  reg [N_BITS_REG-1:0] i_rd_EX_MEM;
  reg i_regWrite_EX_MEM;
  reg [N_BITS_REG-1:0] i_rd_MEM_WB;
  reg i_regWrite_MEM_WB;

  // salidas:
  wire [1:0] o_forward_A;
  wire [1:0] o_forward_B;

  // Instanciación del módulo forwarding_unit:
  forwarding_unit #(.N_BITS_REG(N_BITS_REG)) uut (
                    .i_rt_ID(i_rt_ID),
                    .i_rs_ID(i_rs_ID),
                    .i_rd_EX_MEM(i_rd_EX_MEM),
                    .i_regWrite_EX_MEM(i_regWrite_EX_MEM),
                    .i_rd_MEM_WB(i_rd_MEM_WB),
                    .i_regWrite_MEM_WB(i_regWrite_MEM_WB),
                    .o_forward_A(o_forward_A),
                    .o_forward_B(o_forward_B)
                  );

  initial 
  begin
    // Caso 1: Sin riesgo, sin forward:
    i_rs_ID = 5'b00001;     // rs
    i_rt_ID = 5'b00010;     // rt
    i_rd_EX_MEM = 5'd0; // No se escribe a ningún registro en EX/MEM
    i_regWrite_EX_MEM = 1'b0;
    i_rd_MEM_WB = 5'd0; // No se escribe a ningún registro en MEM/WB
    i_regWrite_MEM_WB = 1'b0;
    #10;  // Esperar 10 unidades de tiempo
    $display("Caso 1 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);


    // Caso 2: Riesgo en EX/MEM para rs, se debe reenviar desde EX/MEM
    i_rs_ID = 5'b00001;     // rs coincide con rd_EX_MEM
    i_rt_ID = 5'b00010;
    i_rd_EX_MEM = 5'b00001; // Registro de destino EX/MEM es 1
    i_regWrite_EX_MEM = 1'b1; // Se escribe en EX/MEM
    i_rd_MEM_WB = 5'd0; // No se escribe en MEM/WB
    i_regWrite_MEM_WB = 1'b0;
    #10;
    $display("Caso 2 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);

    // Caso 3: Riesgo en EX/MEM para rt, se debe reenviar desde EX/MEM
    i_rs_ID = 5'b00001;
    i_rt_ID = 5'b00010;     // rt coincide con rd_EX_MEM
    i_rd_EX_MEM = 5'b00010; // Registro de destino EX/MEM es 2
    i_regWrite_EX_MEM = 1'b1;
    i_rd_MEM_WB = 5'd0; // No se escribe en MEM/WB
    i_regWrite_MEM_WB = 1'b0;
    #10;
    $display("Caso 3 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);

    // Caso 4: Riesgo en MEM/WB para rs, se debe reenviar desde MEM/WB
    i_rs_ID = 5'b00011;     // rs coincide con rd_MEM_WB
    i_rt_ID = 5'b00100;
    i_rd_EX_MEM = 5'd0; // No se escribe en EX/MEM
    i_regWrite_EX_MEM = 1'b0;
    i_rd_MEM_WB = 5'b00011; // Registro de destino MEM/WB es 3
    i_regWrite_MEM_WB = 1'b1; // Se escribe en MEM/WB
    #10;
    $display("Caso 4 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);

    // Caso 5: Riesgo en MEM/WB para rt, se debe reenviar desde MEM/WB
    i_rs_ID = 5'b00011;
    i_rt_ID = 5'b00100;     // rt coincide con rd_MEM_WB
    i_rd_EX_MEM = 5'd0; // No se escribe en EX/MEM
    i_regWrite_EX_MEM = 1'b0;
    i_rd_MEM_WB = 5'b00100; // Registro de destino MEM/WB es 4
    i_regWrite_MEM_WB = 1'b1;
    #10;
    $display("Caso 5 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);

    // Caso 6: Riesgo en EX/MEM y MEM/WB simultáneamente
    i_rs_ID = 5'b00101;     // rs coincide con ambos EX/MEM y MEM/WB
    i_rt_ID = 5'b00110;
    i_rd_EX_MEM = 5'b00101; // Registro de destino EX/MEM es 5
    i_regWrite_EX_MEM = 1'b1;
    i_rd_MEM_WB = 5'b00101; // Registro de destino MEM/WB es 5
    i_regWrite_MEM_WB = 1'b1;
    #10;
    $display("Caso 6 -> o_forward_A: %b, o_forward_B: %b", o_forward_A, o_forward_B);

    // Finalizar la simulación
    $stop;


  end



endmodule
