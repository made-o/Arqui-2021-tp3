`timescale 1ns / 1ps

module tb_pc_jmp();

reg [15:0] i_sign_extension;
reg [31:0] pc;

wire [31:0] o_jump_direction;
wire [31:0] o_sign_extension;

pc_jump u_pc_jump (
    .i_sign_extension(i_sign_extension),
    .pc(pc),
    
    .o_jump_direction(o_jump_direction),
    .o_sign_extension(o_sign_extension)
);
initial begin
       //inicializo entradas:
       #10
       i_sign_extension = 16'b1000000000000000;
       pc = 32'h1200;
       #10
       if(o_sign_extension != 32'b11111111111111111000000000000000)
       begin
            $display("######    Test Extension de signo con 1 ERROR   ######");
            $finish();
       end
       
       if(o_jump_direction != pc + ({{(16){i_sign_extension[15]}},i_sign_extension}<<2))
       begin
            $display("######    Test Set Direccion de salto(beq) ERROR   ######");
            $finish();
       end
       
       #10
       i_sign_extension = 16'b0100000000000000;
       pc = 32'h1200;
       #10
       if(o_sign_extension != 32'b00000000000000000100000000000000)
       begin
            $display("######    Test Extension de signo con 0 ERROR   ######");
            $finish();
       end
       
       #100
       $display("######    Test sin sumador fue correcto   ######");
       $finish();
          
   end  

 
endmodule
