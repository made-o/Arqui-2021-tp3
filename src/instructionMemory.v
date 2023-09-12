`timescale 1ns / 1ps

module instructionMemory #(
    // Parameters:
    parameter DATA_WIDTH = 32, // Specify RAM data width
    parameter DATA_DEPTH  = 128,
    parameter FILE_DATA = "D:/FACULTAD/VivadoFiles/memIF.mem"
)
    //Input and outputs:
(   input  i_clk, // Clock
    input  i_valid,
    input  [DATA_WIDTH-1:0] i_address, // Address bus
    
    output wire [DATA_WIDTH-1:0] o_data, // RAM output data
    output reg  o_haltSignal
);
    // Internal Variables:
    wire enable = 1;
    //wire reset = 0;
    //reg loadDone = 1'b0;
    reg [DATA_WIDTH-1:0] memBlock [DATA_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] ram_data = {DATA_WIDTH{1'b0}};
        
    ////////////////////////////////////////////////////
    // Start-code:
    // Initialize memory:
    always @(*) begin: loadFile
       if(i_valid) begin
          if(FILE_DATA != "") begin
              $readmemb(FILE_DATA, memBlock, 0, DATA_DEPTH-1);
              //loadDone = 1'b1;
          end
       end
    end
   
    // Assign the contents at the requested memory address to data:
    always @(posedge i_clk) begin
       if(enable && !i_valid) begin
          ram_data <= memBlock[i_address];
       end
    end
  
    always @(negedge i_clk) begin
       if(o_data[31:26] == 6'b111111) begin //Check if instruction is HALT
          o_haltSignal = 1'b1;
       end
       else begin
          o_haltSignal = 1'b0;
       end
    end
    
    assign o_data = ram_data;
    
endmodule
