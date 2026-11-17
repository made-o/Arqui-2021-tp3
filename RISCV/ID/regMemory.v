`timescale 1ns / 100ps

module regMemory #(
     // Parameters:
    parameter DATA_WIDTH = 32,   // Specify RAM data width
    parameter ADDR_WIDTH = 5,    // Specify Address width
    parameter RAM_DEPTH  = 1 << ADDR_WIDTH,  // 2^5 = 32
    parameter FILE_DATA = "/home/nikaro/Documents/Arqui2025Nikaro/Riscv_IF_ID_EX_MEM_WB/memory/memReg.mem", //"../memory/memReg.mem",
    parameter P_REG_WIDTH  = 5 
)
    //Input and outputs:
(  
    input wire                   i_clk,
            
    input wire [P_REG_WIDTH-1:0] i_reg_lectura1, //rs1
    input wire [P_REG_WIDTH-1:0] i_reg_lectura2, //rs2
    input wire [P_REG_WIDTH-1:0] i_regWrite_addr,
    input wire [DATA_WIDTH-1:0]  i_dato_a_escribir,
    
    input wire                   i_WriteEnable ,
    
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
        if(FILE_DATA != 0)begin
            $readmemb(FILE_DATA, memBlock, 0, RAM_DEPTH-1);
        end
    end


    // Memory Write Block:
    // Write Operation: When i_w_Enable = 1 and i_r_Enable = 0
    always @(posedge i_clk) begin: memWrite
       if(i_WriteEnable && (i_regWrite_addr != 0)) begin 
          memBlock[i_regWrite_addr]  <= i_dato_a_escribir;
       end//end_if
    end//end_always
    
    always@(posedge i_clk)
      begin: send_data_uart
        begin
            data_send_tx <= memBlock[i_addr_tx];
        end
      end
    always @(posedge i_clk) begin
        if (i_WriteEnable && i_regWrite_addr != 0)
            $display("WRITE: x%0d <= %h", i_regWrite_addr, i_dato_a_escribir);
    end
    
    assign o_data_send_tx = data_send_tx;
    assign o_data1 = (i_WriteEnable && i_regWrite_addr != 0 && i_regWrite_addr == i_reg_lectura1)
                 ? i_dato_a_escribir : memBlock[i_reg_lectura1];
    assign o_data2 = (i_WriteEnable && i_regWrite_addr != 0 && i_regWrite_addr == i_reg_lectura2)
                 ? i_dato_a_escribir : memBlock[i_reg_lectura2];
    
endmodule
