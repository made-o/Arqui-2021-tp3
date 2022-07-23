module dataMemory #(
   // Parameters:
   parameter RAM_WIDTH = 32, // ancho de datos de la mem RAM
   parameter RAM_DEPTH = 128 // profundidad de la RAM (cant.de entradas)
)
(  // Inputs & Outputs:
   input  i_valid,
   input  i_clk,  // clock
   input  i_read_enable, //memRead
   input  i_write_enable, //memWrite
   
   input  [RAM_WIDTH-1:0] i_address, // address bus
   input  [RAM_WIDTH-1:0] i_write_data, // datos de entrada a la RAM
   
   
   output reg [RAM_WIDTH-1:0] o_read_data // datos de salida de la RAM
);
   
   // Variables internas:
   reg [RAM_WIDTH-1:0] memoryArray [RAM_DEPTH-1:0];
   
   
   ////////////////////////////////////////////////////
   // Start-code:
   // Initialization:
   initial begin
      memoryArray[0]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0000; // Data 0
      memoryArray[1]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0001;
      memoryArray[2]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0010;
      memoryArray[3]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0011;
      memoryArray[4]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0100;
      memoryArray[5]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0101;
      memoryArray[6]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0110;
      memoryArray[7]  <= 32'b0000_0000_0000_0000_0000_0000_0000_0111;
      memoryArray[8]  <= 32'b0000_0000_0000_0000_0000_0000_0000_1000;
      memoryArray[9]  <= 32'b0000_0000_0000_0000_0000_0000_0000_1001;
      memoryArray[10] <= 32'b0000_0000_0000_0000_0000_0000_0000_1010;
   end
   
   //---------------------------------------------------
   // LECTURA: (get data from the specified address)
   always @(posedge i_clk) begin: lectura
      if(i_valid && i_read_enable)
        o_read_data <= memoryArray[i_address];
   end
   
   // ESCRITURA: (write data to the specified address)
   always @(negedge i_clk) begin: escritura
      if(i_valid && i_write_enable)
         o_read_data <= memoryArray[i_address];
   end
   
   
endmodule