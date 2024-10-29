module mux_3_1 #(
    parameter NBITS = 32
  ) (
    input  [NBITS-1:0] i_dataRead, //! Entrada del dato de lectura de la etapa ID
    input  [NBITS-1:0] i_data_MEM, //! Entrada del dato de la etapa MEM
    input  [NBITS-1:0] i_data_WB,  //! Entrada del dato de la etapa WB
    input  select, //! Selector

    output [NBITS-1:0] o_out  //! Salida de acuerdo a la elección del selector
  );

  always @(*)
  begin
    case (select)
      2'b00 :
        o_out = i_dataRead;
      2'b01 :
        o_out = i_data_MEM;
      2'b10 :
        o_out = i_data_WB;
      default:
        o_out = 0;
    endcase

  end


endmodule
