`timescale 1ns / 1ps

module tb_IF_mux();

//declaro entradas:
reg [31:0] in_A;
reg [31:0] in_B;
reg select;

//declaro salidas:
wire [31:0] out;

//instancio módulo de testing:
mux
   u_mux (
      .in_A(in_A),
      .in_B(in_B),
      .select(select),
      
      .out(out)
   );

////////////////////////////////////////////////////////
//testing code:
initial begin
   //inicializo entradas:
   in_A = 32'h4;
   in_B = 32'hf;
   select = 1;
   
   #40
   in_A = 32'h4;
   in_B = 32'hf;
   select = 0;
   
   
   //finalizo:
   #100 $finish;

end

endmodule