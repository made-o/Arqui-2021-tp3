module dataMemory #(
   // Parameters:
   parameter RAM_WIDTH = 32, // ancho de datos de la mem RAM
   parameter RAM_DEPTH = 128 // profundidad de la RAM (cant.de entradas)
)
(  // Inputs & Outputs:
   //localparam ADDR_WIDTH = $clog2(RAM_DEPTH),
   //input  i_valid,
   input  i_clk,  // clock
   input  i_read_enable, //memRead
   input  i_write_enable, //memWrite
   
   input  [$clog2(RAM_DEPTH)-1:0] i_address, // address bus
   input  [RAM_WIDTH-1:0] i_write_data, // datos de entrada a la RAM
   
   input  [$clog2(RAM_DEPTH)-1:0] i_addr_tx,

   output [RAM_WIDTH-1:0] o_data_send_tx,
   output [RAM_WIDTH-1:0] o_read_data // datos de salida de la RAM
);
   
   // Variables internas:
   reg [RAM_WIDTH-1:0] memoryArray [0:RAM_DEPTH-1];
   reg [RAM_WIDTH-1:0] data_send_tx;
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

   // ESCRITURA: (write data to the specified address)
   always @(posedge i_clk) begin: escritura
      if(i_write_enable)
         memoryArray[i_address] <= i_write_data;
   end

   always@(posedge i_clk)
   begin: send_data_uart
      begin
         data_send_tx <= memoryArray[i_addr_tx];
      end
   end

   // LECTURA: (get data from the specified address)
   assign o_data_send_tx = data_send_tx;
   //assign o_read_data    = memoryArray[i_address];
   assign o_read_data = i_read_enable ? memoryArray[i_address] : 32'h0;
   
endmodule