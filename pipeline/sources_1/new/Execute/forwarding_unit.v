`timescale 1ns / 1ps

module forwarding_unit #(
    // Parameters:
    parameter N_BITS_REG = 5 //! Cantidad de bits de los registros
  )
  (  // Inputs de la etapa ID/EX:
    input  [N_BITS_REG-1:0] i_rt_ID,     //! Registro destino (target) de la instrucción actual
    input  [N_BITS_REG-1:0] i_rs_ID,     //! Segundo operando (source) de la instrucción actual

    // Inputs de la etapa EX/MEM:
    input  [N_BITS_REG-1:0] i_rd_EX_MEM, //! Registro destino de la instrucción en EX/MEM
    input  i_regWrite_EX_MEM,            //! Señal de escritura en registro EX/MEM

    // Inputs de la etapa MEM/WB:
    input  [N_BITS_REG-1:0] i_rd_MEM_WB, //! Registro destino de la instrucción en MEM/WB
    input  i_regWrite_MEM_WB,            //! Señal de escritura en registro MEM/WB

    output reg [1:0] o_forward_A, //! Bits para el RS
    output reg [1:0] o_forward_B  //! Bits para el RT
  );

  // Registros temporales para concatenar las señales de detección de riesgos (hazards):
  reg [2:0] temp1_EX;  //! hazard_check_EX_1 (3 bits)
  reg [2:0] temp2_EX;  //! hazard_check_EX_2 (3 bits)
  reg [3:0] temp1_MEM; //! hazard_check_MEM_1 (4 bits)
  reg [3:0] temp2_MEM; //! hazard_check_MEM_2 (4 bits)


  ////////////////////////////////////////////////////
  // Bloque combinacional para detectar riesgos y reenviar datos:
  always @(*)
  begin : hazards
    // Inicialización de las salidas para evitar estados indefinidos:
    o_forward_A = 2'b00;
    o_forward_B = 2'b00;

    // Concatenación de inputs para riesgos de EX:
    // Verifica si hay una coincidencia entre los registros en EX/MEM y los operandos RS/RT
    temp1_EX = {i_regWrite_EX_MEM,
                (i_rd_EX_MEM != 0),
                (i_rd_EX_MEM == i_rs_ID)};
    temp2_EX = {i_regWrite_EX_MEM,
                (i_rd_EX_MEM != 0),
                (i_rd_EX_MEM == i_rt_ID)};
    // Si hay una coincidencia completa (3'b111), reenviar el dato desde EX/MEM:
    if(temp1_EX == 3'b111)
      o_forward_A = 2'b10; // Señal para reenviar datos desde EX/MEM para [mux_3_1_a]
    if(temp2_EX == 3'b111)
      o_forward_B = 2'b10; // Señal para reenviar datos desde EX/MEM para [mux_3_1_b]


    // Concatenación de inputs para riesgos de MEM:
    // Se verifica si hay coincidencia entre los registros en MEM/WB y los operandos RS/RT
    //(también se asegura que no se esté escribiendo en el mismo registro desde EX/MEM)
    temp1_MEM = {i_regWrite_MEM_WB,
                 (i_rd_MEM_WB != 0),
                 ~(i_regWrite_EX_MEM && (i_rd_EX_MEM != 0) && (i_rd_EX_MEM != i_rs_ID)),
                 (i_rd_MEM_WB == i_rs_ID)};
    temp2_MEM = {i_regWrite_MEM_WB,
                 (i_rd_MEM_WB != 0),
                 ~(i_regWrite_EX_MEM && (i_rd_EX_MEM != 0) && (i_rd_EX_MEM != i_rt_ID)),
                 (i_rd_MEM_WB == i_rt_ID)};
    // Si hay una coincidencia completa (4'b1111), reenviar el dato desde MEM/WB:
    if(temp1_MEM == 4'b1111)
      o_forward_A = 2'b10; // Señal para reenviar datos desde MEM/WB para [mux_3_1_a]
    if(temp2_MEM == 4'b1111)
      o_forward_B = 2'b10; // Señal para reenviar datos desde MEM/WB para [mux_3_1_b]

  end
endmodule
