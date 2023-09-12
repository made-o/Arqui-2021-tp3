`timescale 1ns / 1ps

module tb_int_mem();

    //declaro entradas:
    reg [31:0] i_PC;
    reg [31:0] i_address;
    reg [31:0] instruccion;
    reg PCWrite;
    
    reg i_clk, i_reset, i_pcWrite;

    //declaro salidas:
    wire [31:0] o_data;
    wire o_haltSignal;
    
    // registros auxiliares
    reg flag_test_mem;
    reg [32-1:0] memAux [3-1:0];
    
    //instancio módulo de testing:
    instructionMemory 
        u_instr_mem (
            .i_clk(i_clk),
            .i_pcWrite(i_pcWrite),
            .i_pc(i_PC),
            .i_instruction(instruccion),
            .i_address(i_address),
            .o_data(o_data),
            .o_haltSignal(o_haltSignal)
        );

    initial begin
       //inicializo entradas:
       i_clk = 0;
       i_pcWrite = 1;
       i_reset = 0;
       i_PC = 32'h0;
       flag_test_mem = 0;
       
       memAux[0] = 32'b10001100001000100000000000000100;
       memAux[1] = 32'b00000000010010010110000000100011;
       memAux[2] = 32'b11111100000000000000000000000000;
       
       #100
       
       i_address = 32'h0;
       instruccion = memAux[0];
       
       #20       
       i_address = 32'h1;
       instruccion = memAux[1];
       #20       
       i_address = 32'h2;
       instruccion = memAux[2];
       
       #20
       
       i_pcWrite = 0;
       
       #15
       
       flag_test_mem = 1;
       
       //finalizo:
       #1000
        $display("######    Test memoria de instrucciones fue correcto   ######");
       $finish();
          
   end 
   
    initial begin	
       forever begin
          #10 i_clk = ~i_clk;
       end
    end
    
    always @(posedge i_clk) 
    begin: Test
       if(flag_test_mem == 1)
           begin
               if(memAux[i_PC] != o_data)
                   begin
                        $display("######    Test Mem ERROR   ######");
                        $finish();
                   end
               if(i_PC < 32'h2)
                    i_PC = i_PC + 1;
            end
              
    end
    
    
endmodule
