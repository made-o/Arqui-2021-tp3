`timescale 1ns / 1ps

module regMemory #(
     // Parameters:
    parameter DATA_WIDTH = 32,   // Specify RAM data width
    parameter ADDR_WIDTH = 5,    // Specify Address width
    parameter RAM_DEPTH  = 1 << ADDR_WIDTH,  // 2^5 = 32
    parameter P_REG_WIDTH  = 5 
)
    //Input and outputs:
(  
    input wire                   i_clk,
    input wire                   i_reset ,
            
    input wire [P_REG_WIDTH-1:0] i_reg_lectura1, //rs
    input wire [P_REG_WIDTH-1:0] i_reg_lectura2, //rt
    input wire [P_REG_WIDTH-1:0] i_regWrite_addr,
    input wire [DATA_WIDTH-1:0]  i_dato_a_escribir,
    
    input wire                   i_oEnable,
    input wire                   i_WriteEnable ,
    input wire                   i_ReadEnable ,
    
    output wire [DATA_WIDTH-1:0] o_data1,
    output wire [DATA_WIDTH-1:0] o_data2

);
    // Internal Variables:
    // Variable to hold the registered read address:
    reg [DATA_WIDTH-1:0] data1_out;
    reg [DATA_WIDTH-1:0] data2_out;
    // Declare the RAM variable:
    reg [DATA_WIDTH-1:0] memBlock [0:RAM_DEPTH-1];
    reg oe_r;
    
    integer index;
    ////////////////////////////////////////////////////
        
    // Tri-State Buffer control:
    // output: When i_w_Enable = 0, i_oEnable = 1
    assign o_data1 = (i_oEnable && !i_ReadEnable) ? data1_out: {DATA_WIDTH{1'bz}};
    assign o_data2 = (i_oEnable && !i_ReadEnable) ? data2_out: {DATA_WIDTH{1'bz}};
    
    always@*
    begin
        if(i_reset)
        begin
            memBlock[0] = {DATA_WIDTH{1'b0}};
            for(index = 0;index < RAM_DEPTH; index = index+1)
            begin
                memBlock[index] = {32{1'b0}}; 
            end
        end
    end
    // Memory Write Block:
    // Write Operation: When i_w_Enable = 1 and i_r_Enable = 0
    always @(posedge i_clk) begin: memWrite
       if(i_WriteEnable && !i_ReadEnable && (i_regWrite_addr != 0)) begin 
          memBlock[i_regWrite_addr] <= i_dato_a_escribir;
       end//end_if
    end//end_always
    
    
    // Memory Read Block:
    // Read Operation: When i_w_Enable = 0, i_r_Enable =1 and i_oEnable = 1
    always @(negedge i_clk) begin: memRead
       if(!i_WriteEnable && i_ReadEnable && i_oEnable) begin
          data1_out <= memBlock[i_reg_lectura1];
          data2_out <= memBlock[i_reg_lectura2];
          oe_r <= 1;
       end//end_if
       else begin
          oe_r <= 0;
       end//end_Else
    end//end_always

endmodule
