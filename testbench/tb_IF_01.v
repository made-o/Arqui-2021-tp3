`timescale 1ns / 1ps

module tb_IF_01();

//declaro entradas:
reg i_clk, i_enable, i_reset;
reg i_PCWrite, i_PCSource, i_stall;
//reg i_flush;
reg [31:0] i_PC_MEM;
//reg i_instruction, i_address;

//declaro salidas:
wire o_stall;
wire [31:0] o_PC_4;
wire [31:0] o_instruction;


//instancio módulo de testing:
IFetch
   u_IFetch (
      .i_clk(i_clk),
      .i_enable(i_enable),
      .i_reset(i_reset),
      .i_PCWrite(i_PCWrite),
      .i_PCSource(i_PCSource),
      .i_stall(i_stall),
      .i_PC_MEM(i_PC_MEM),
      //.i_flush(i_flush),
      //.i_instruction(i_instruction),
      //.i_address(i_address),
      
      .o_stall(o_stall),
      .o_PC_4(o_PC_4),
      .o_instruction(o_instruction)
);


initial begin
   i_clk = 0;
   i_enable = 1;
   i_reset = 0;
   //i_PCWrite = 1;
   i_PCSource = 0; // elijo el valor del pc
   i_stall = 0;
   i_PCWrite = 1;
   
   i_PC_MEM = 32'h2;
   
   
   
   //finalizo:
   #100 $finish;
   
end

//clock:
initial begin	
   forever begin
      #10 i_clk = ~i_clk;
   end
end


endmodule
