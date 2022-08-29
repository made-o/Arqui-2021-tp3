`timescale 1ns / 1ps

module tb_IF_mem();

//declaro entradas:
reg i_clk, i_valid;
reg [31:0] i_address;

//declaro salidas:
wire [31:0] o_data;
wire o_haltSignal;

//declaro el contador de ciclos del clock:
//reg [4:0] clk_cycle;

//instancio módulo de testing:
instructionMemory 
    u_instr_mem (
        .i_clk(i_clk),
        .i_valid(i_valid),
        .i_address(i_address),
        .o_data(o_data),
        .o_haltSignal(o_haltSignal)
    );

initial begin
   //inicializo entradas:
   i_clk = 0;
   i_valid = 1;
   i_address = 32'h2;
   
   //finalizo:
   #220 $finish;
      
end   
   
//clock:
initial begin	
   forever begin
      #10 i_clk = ~i_clk;
   end
end  

endmodule