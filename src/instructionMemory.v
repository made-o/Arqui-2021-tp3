`timescale 1ns / 1ps

module instructionMemory #(
    // Parameters:
    parameter DATA_WIDTH = 32,   // Specify RAM data width
    parameter ADDR_WIDTH = 4,    // Specify Address width
    parameter RAM_DEPTH  = 1 << ADDR_WIDTH  // 2^4 = 16
)
    //Input and outputs:
(   input  wire [ADDR_WIDTH-1:0] i_address, // Address bus
    input  i_clk,        // Clock
    input  i_w_Enable,   // Write Enable
    input  i_r_Enable,   // Read Enable
    input  i_oEnable,    // Output Enable
    
    inout wire [DATA_WIDTH-1:0] io_data // RAM input/output data

);
    // Internal Variables:
    // Variable to hold the registered read address:
    reg [DATA_WIDTH-1:0] data_out;
    // Declare the RAM variable:
    reg [DATA_WIDTH-1:0] memBlock [0:RAM_DEPTH-1];
    reg oe_r; // Output Enable Read
    
    ////////////////////////////////////////////////////
    
    // Tri-State Buffer control:
    // output: When i_w_Enable = 0, i_oEnable = 1
    // if(condition) --> io_data = data_out; else io_data = io_data{DATA_WIDTH{1'bz}};
    assign io_data = (i_oEnable && !i_w_Enable) ? data_out : {DATA_WIDTH{1'bz}};
    
    
    // Memory Write Block:
    // Write Operation: When i_w_Enable = 1 and i_r_Enable = 0
    always @(posedge i_clk) begin: memWrite
       if(i_w_Enable && !i_r_Enable) begin
          memBlock[i_address] <= io_data;
       end//end_if
    end//end_always
    
    
    // Memory Read Block:
    // Read Operation: When i_w_Enable = 0, i_r_Enable = 1 and i_oEnable = 1
    always @(posedge i_clk) begin: memRead
       if(!i_w_Enable && i_r_Enable && i_oEnable) begin
          data_out <= memBlock[i_address];
          oe_r <= 1;
       end//end_if
       else begin
          oe_r <= 0;
       end//end_Else
    end//end_always
    

endmodule