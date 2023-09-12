`timescale 1ns / 1ps

module tb_IF_muxPCAuto();
    
    //declaro entradas:
    reg [31:0] in_A;
    reg [31:0] in_B;
    reg select;
    
    reg i_clk, i_reset, i_enable;
    reg i_halt, i_stall;
    reg [31:0] i_PC;
    reg i_valid;
    reg [31:0] i_address;

    //declaro salidas:
    wire [31:0] out;
    
    wire [31:0] o_newPC;

    wire [31:0] o_data;
    wire o_haltSignal;
    wire [31:0] o_PC_4;
    
    // registros auxiliares
    reg flag_test_sum;
    reg [31:0] PC_pre_halt;
    
    
    //instancio módulo de testing:
    mux
       u_mux (
          .in_A(o_PC_4),
          .in_B(in_B),
          .select(select),
          
          .out(out)
       );
       
     p_counter
       u_pCounter(
          .i_clk(i_clk),
          .i_reset(i_reset),
          .i_enable(i_enable),
          .i_halt(i_halt),
          .i_stall(i_stall),
          .i_PC(out),
          
          .o_newPC(o_newPC)   
       );
       
      instructionMemory 
        u_instr_mem (
            .i_clk(i_clk),
            .i_valid(i_valid),
            .i_address(o_newPC),
            .o_data(o_data),
            .o_haltSignal(o_haltSignal)
        );
        sumador
        u_sumador(
            .i_PC(o_newPC),
            .o_PC_4(o_PC_4)
        );
  initial begin
       //inicializo entradas:
       i_clk = 0;
       i_enable = 1;
       i_reset = 0;
       i_halt = 1;
       i_stall = 0;
       flag_test_sum = 0;
       
       i_address = 32'h2;
       
       in_A = 32'h1;
       in_B = 32'h2;
       select = 0;
       
       i_valid = 1;
       
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
   
   // simulacion de clock
   initial begin	
       forever begin
           if(i_valid == 1)
              #10 i_clk = ~i_clk;
       end
    end
    
    always @(posedge i_clk) 
    begin: Test
       if((select == 1 && out != in_B) || (select == 0 && out != in_A))
       begin: testMux
            $display("######    Test Mux ERROR   ######");
            $finish();
       end
       
       if(flag_test_sum == 1)
       begin: testSumador
           if((o_PC_4 != o_newPC + 1))
           begin
                $display("######    Test testSumador ERROR   ######");
                $finish();
           end
       end
           
    end
    always @(posedge i_clk) begin: testIntructionMem
       
       if(((select == 1 && o_data != 32'hFC000000) || (select == 0 && o_data != 32'h496023)))
       begin
            $display("######    Test testIntructionMem ERROR   ######");
            $finish();
       end
      
    end
        
endmodule
