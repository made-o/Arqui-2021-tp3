/*`timescale 1ns / 1ps


module test_concatenacion#
(
	BITS  = 3,
	DEPTH   = 4
)
(
    input wire  [BITS-1:0]  i_reset,
    
    output wire  [BITS-1:0]  o_reg_test,
    output wire  [BITS-1:0]  o_reg0,
    output wire  [BITS-1:0]  o_reg1,
    output wire  [BITS-1:0]  o_reg2,
    output wire  [BITS-1:0]  o_reg3
 );
 
 reg [BITS-1:0] memBlock [0:DEPTH-1];
 
 always@ *
 begin
    if(i_reset)
    begin
        memBlock[0] <= 3'b000;
        memBlock[1] <= 3'b001;
        memBlock[2] <= 3'b010;
        memBlock[3] <= 3'b011;
    end
 end
 
 assign o_reg_test = {3'b100,memBlock[0]};
 assign o_reg = {3'b100,memBlock}[1];
 assign o_reg = {3'b100,memBlock}[2];
 assign o_reg = {3'b100,memBlock}[3];
 assign o_reg = {3'b100,memBlock}[4];
 
endmodule*/

`timescale 1ns / 1ps

module instructionMemory #(
    // Parameters:
    parameter DATA_WIDTH = 32, // Specify RAM data width
    parameter DATA_DEPTH  = 128,
    parameter FILE_DATA = "D:/FACULTAD/VivadoFiles/memInitFile.mem"
)
    //Input and outputs:
(   input  i_clk, // Clock
    input  i_valid,
    input  [DATA_DEPTH-1:0] i_address, // Address bus
    
    output wire [DATA_WIDTH-1:0] o_data, // RAM output data
    output reg  o_haltSignal
);
    // Internal Variables:
    wire enable = 1;
    //wire reset = 0; 
    reg loadDone = 1'b0;
    reg [DATA_WIDTH-1:0] memBlock [DATA_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] ram_data = {DATA_WIDTH{1'b0}};
        
    ////////////////////////////////////////////////////
    // Start-code:
    // Initialize memory:
    always @(*) begin: loadFile
       if(i_valid) begin
          if(!loadDone && FILE_DATA != "") begin
              $readmemb(FILE_DATA, memBlock, 0, DATA_DEPTH-1);
              loadDone = 1'b1;
          end
       end
    end
   
    // Assign the contents at the requested memory address to data:
    always @(posedge i_clk) begin
       if(enable && i_valid && loadDone == 1'b1) begin
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

