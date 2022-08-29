`timescale 1ns / 1ps

module tb_IF_pc();

//declaro entradas:
reg i_clk, i_reset, i_enable;
reg i_halt, i_stall;
reg [31:0] i_PC;

//declaro salidas:
wire [31:0] o_newPC;

//instancio módulo de testing:
p_counter
   u_pCounter(
      .i_clk(i_clk),
      .i_reset(i_reset),
      .i_enable(i_enable),
      .i_halt(i_halt),
      .i_stall(i_stall),
      .i_PC(i_PC),
      
      .o_newPC(o_newPC)   
   );

////////////////////////////////////////////////////////
//testing code:
initial begin
   //inicializo entradas:
   i_clk = 0;
   i_enable = 1;
   i_halt = 0;
   i_stall = 0;
   
   #10 
   i_PC = 32'h2;
   
   #20
   i_reset = 1;
   
   #20
   i_reset = 0;
   i_PC = 32'hf;
   
   #20
   i_enable = 1;
   i_halt = 1;
   i_PC = 32'h4;
   

   //finalizo:
   #200 $finish;

end


//clock:
initial begin	
   forever begin
      #10 i_clk = ~i_clk;
   end
end  


endmodule