`timescale 1ns / 1ps

module tb_IF_sum();


//declaro entradas:
reg [31:0] i_PC;

//declaro salidas:
wire [31:0] o_PC_4;

//instancio módulo de testing:
sumador
   u_sumador(
      .i_PC(i_PC),
      
      .o_PC_4(o_PC_4)
   );

////////////////////////////////////////////////////////
//testing code:
initial begin
   //inicializo entradas:
   #20
   i_PC = 32'h0;
   
   #20          
   i_PC = 32'hA;
   
   #20          
   i_PC = 32'hF;
   
   #20          
   i_PC = 32'h8;
   
   //finalizo:
   #100 $finish;

end

endmodule