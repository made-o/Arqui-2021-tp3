`timescale 1ns / 1ps

module tb_int_mem();

    //declaro entradas:
    reg [31:0] i_PC;
    reg [31:0] i_address;
    reg [31:0] instruccion;
    reg PCWrite;
    
    reg i_clk, i_reset, i_valid;

    //declaro salidas:
    wire [31:0] o_data;
    wire o_haltSignal;
    
    // registros auxiliares
    
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
       i_reset = 0;
       
       #100
       
       i_address = 32'h2;
       
       #20
       select = 1;
       #20
       select = 0;
       #20
       
       select = 1;
       #20
       select = 0;
       #20
       
       select = 1;
       #20
       select = 0;
       
       #40
       
       flag_test_sum = 1;
       
       //finalizo:
       #100
       $display("######    Test sin sumador fue correcto   ######");
       $finish();
          
   end 
    
    
endmodule
