`timescale 1ns / 1ps

module regMemory #(
     // Parameters:
    parameter DATA_WIDTH = 32,   // Specify RAM data width
    parameter ADDR_WIDTH = 5,    // Specify Address width
    parameter RAM_DEPTH  = 1 << ADDR_WIDTH,  // 2^5 = 32
    parameter FILE_DATA = "D:/FACULTAD/VivadoFiles/memInitFile.mem",
    parameter P_REG_WIDTH  = 5 
)
    //Input and outputs:
(  
    input wire                   i_clk,
    //input wire                   i_reset ,
            
    input wire [P_REG_WIDTH-1:0] i_reg_lectura1, //rs
    input wire [P_REG_WIDTH-1:0] i_reg_lectura2, //rt
    input wire [P_REG_WIDTH-1:0] i_regWrite_addr,
    input wire [DATA_WIDTH-1:0]  i_dato_a_escribir,
    
    //input wire                   i_oEnable,
    input wire                   i_WriteEnable ,
    //input wire                   i_ReadEnable ,
    
    //input       [ADDR_WIDTH-1:0] i_addr_tx,
    input       [$clog2(RAM_DEPTH)-1:0] i_addr_tx,
    
    output wire [DATA_WIDTH-1:0] o_data_send_tx,

    (* keep = "true" *) output wire [DATA_WIDTH-1:0] o_data1,
    (* keep = "true" *) output wire [DATA_WIDTH-1:0] o_data2

);
    // Internal Variables:
    reg [DATA_WIDTH-1:0] data_send_tx; //! Registro temporal que guarda la instrucción leída desde la memoria
    // Variable to hold the registered read address:
    reg [DATA_WIDTH-1:0] data1_out;
    reg [DATA_WIDTH-1:0] data2_out;
    // Declare the RAM variable:
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] memBlock [0:RAM_DEPTH-1];
    reg oe_r;
    
    integer index;
    ////////////////////////////////////////////////////
    initial
    begin
        memBlock[0] <= 32'b0000_0000_0000_0000_0000_0000_0000_1001;
        memBlock[1] <= 32'b0000_0000_0000_0000_0000_0000_1001_0000;
        memBlock[2] <= 32'b0000_0000_0000_0000_0000_1010_0000_0001;
        memBlock[3] <= 32'b0000_0000_0000_0000_1100_0000_0000_0000;
        memBlock[4] <= 32'b0000_0000_0000_1011_0000_0000_0000_0001;
        memBlock[5] <= 32'b0000_0000_1110_0000_0000_0000_0000_0000;
        memBlock[6] <= 32'b0000_1111_0000_0000_0000_0000_0000_0001;
        memBlock[7] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[8] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[9] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[10] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[11] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[12] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[13] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[14] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[15] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[16] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[17] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[18] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[19] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[20] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[21] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[22] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[23] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[24] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[25] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[26] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[27] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[28] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[29] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[30] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        memBlock[31] <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        //memBlock  <= 1024'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;  // LW r1 , 1(r0)
    end
    // Tri-State Buffer control:
    // output: When i_w_Enable = 0, i_oEnable = 1


    // Memory Write Block:
    // Write Operation: When i_w_Enable = 1 and i_r_Enable = 0
    always @(posedge i_clk) begin: memWrite
       /*if(i_reset)
       begin
            memBlock[0] <= {DATA_WIDTH{1'b0}};
            for(index = 0;index < RAM_DEPTH; index = index+1)
            begin
                if(index != 2)
                    memBlock[index] <= {32{1'b0}}; 
                else
                    memBlock[index] <= 32'd27;
            end
       end*/
       if(i_WriteEnable && (i_regWrite_addr != 0)) begin 
          memBlock[i_regWrite_addr] <= i_dato_a_escribir;
       end//end_if
    end//end_always
    
    always@(posedge i_clk)
      begin: send_data_uart
        begin
            data_send_tx <= memBlock[i_addr_tx];
        end
      end
    
    
    // Memory Read Block:
    // Read Operation: When i_w_Enable = 0, i_r_Enable =1 and i_oEnable = 1
    /*always @(negedge i_clk) begin: memRead
       if(!i_WriteEnable && i_ReadEnable && i_oEnable) begin
          data1_out <= memBlock[i_reg_lectura1];
          data2_out <= memBlock[i_reg_lectura2];
          oe_r <= 1;
       end//end_if
       else begin
          oe_r <= 0;
       end//end_Else
    end//end_always
    */
    assign o_data_send_tx = data_send_tx;
    assign o_data1 = memBlock[i_reg_lectura1];
    assign o_data2 = memBlock[i_reg_lectura2];
    
    
endmodule
