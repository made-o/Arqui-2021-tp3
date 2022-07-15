module dataMemory #(
   // Parameters:
   parameter RAM_WIDTH = 32, // ancho de datos de la mem RAM
   parameter RAM_DEPTH = 1024 // profundidad de la RAM (cant.de entradas)
)
(  // Inputs & Outputs:
   input  wire [RAM_WIDTH-1:0] i_address, // address bus
   input  wire [RAM_WIDTH-1:0] i_write_data, // datos de entrada a la RAM
   input  wire i_valid,
   input  wire i_clk,  // clock
   input  wire i_read_enable,
   input  wire i_write_enable,
   
   output wire [RAM_WIDTH-1:0] o_read_data // datos de salida de la RAM
);

   // Internal Variables:
   wire enable = 1'b1; // sirve para deshabilitar el puerto cuando o está en uso
   wire reset  = 1'b0; // output reset
   wire reg_enable = 1'b0;
   
   reg [RAM_WIDTH-1:0] d_ram [RAM_DEPTH-1:0];
   reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};
   
   
   // Carga de datos en la memoria:
   generate
      reg [RAM_WIDTH-1:0] ram_index;
      initial begin
         for(ram_index = 0;ram_index < RAM_DEPTH;ram_index = ram_index + 1) begin
             d_ram[ram_index] = 3;
         end // end_for
      end
   endgenerate
   
   // LECTURA:
   always @(*) begin: lectura
      if(i_valid && i_read_enable)
         ram_data <= d_ram[i_address];
   end
   
   // ESCRITURA:
   always @(negedge i_clk) begin: escritura
      if(i_valid && i_write_enable)
         d_ram[i_address] <= i_write_data;
   end
   
   
   assign o_read_data = ram_data;
   
endmodule