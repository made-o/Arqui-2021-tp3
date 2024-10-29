`timescale 1ns / 1ps

module tb_instruction_mem();

  // Par�metros para facilitar los cambios
  localparam ADDR_WIDTH = 7;
  localparam DATA_WIDTH = 32;

  reg  clk;
  reg  valid;
  reg  [ADDR_WIDTH-1:0] address;
  wire [DATA_WIDTH-1:0] data_out;
  wire halt_signal;

  // Instancia del m�dulo de instruction memory
  instruction_mem uut (
                    .i_clk(clk),
                    .i_valid(valid),
                    .i_address(address),
                    .o_data(data_out),
                    .o_haltSignal(halt_signal)
                  );

  // Clock generator
  always #5 clk = ~clk;

  initial
  begin
    // Inicializar se�ales
    clk = 0;
    valid = 0;
    address = 0;

    // Empezar la simulaci�n
    #10 valid = 1;

    // Probar varias direcciones:
    #10 address = 0; // LW r1 , 1(r0)
    #5 if (data_out !== 32'b100011_00000_00001_0000_0000_0000_0001)
       $display("Test failed at address 0");
    else
      $display("Test passed at address 0");

    #20 address = 1; // LW r2 , 2(r0)
    #10 if (data_out !== 32'b100011_00000_00010_0000_0000_0000_0010)
       //  8C01 0001
       $display("Test failed at address 1");
    else
      $display("Test passed at address 1");

    #20 address = 5; // ADD r1, r1, r2
    #10 if (data_out !== 32'b000000_00001_00010_00001_00000_100000)
       $display("Test failed at address 5");
    else
    begin
      $display("Test passed at address 5");
      $display("Instruction: %h",data_out);
    end

    #20 address = 20; // Verificar HALT en la direcci�n correcta
    #10 if (data_out === 32'hFC000000)
       $display("Halt test passed at address 20");
    else
    begin
      $display("Halt test failed at address 20. Expected HALT signal to be 1 and instruction to be FC000000");
      $display("Instruction: %h",data_out);
    end


    #50 $finish;

  end


endmodule
