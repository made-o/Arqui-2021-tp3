`timescale 1ns / 1ps

module tb_IF_sumadorAuto();
    
    //entradas
    reg [31:0] i_PC;
    
    //salidas
    wire [31:0] o_PC_4;

    sumador
    u_sumador(
        .i_PC(i_PC),
        .o_PC_4(o_PC_4)
    );
    
    initial begin
        #20
        i_PC = 32'h0;
        
        #20
        i_PC = 32'h27;
        
        #20
        i_PC = 32'hf;
        
        #20
        i_PC = 32'hff;
        
        #100
        $display("######    Test sumadorMasUno RIGHT   ######");
        $finish();
    end
    
    always @(*) 
    begin: sumadorMasUno
       if(o_PC_4 != i_PC + 1)
       begin
            $display("######    Test sumadorMasUno ERROR   ######");
            $finish();
       end
    end
endmodule
