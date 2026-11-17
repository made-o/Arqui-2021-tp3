`timescale 1ns / 100ps
module dataMemory #(
   // Parameters:
   parameter RAM_WIDTH = 32,  // ancho de datos de la mem RAM
   parameter RAM_DEPTH = 128, // profundidad de la RAM (cant.de entradas)
   parameter FILE_DATA = "../memory/memData.mem"
)
(  // Inputs & Outputs:
   input  i_clk,  // clock
   input  i_read_enable, //memRead
   input  i_write_enable, //memWrite
   
   input  [$clog2(RAM_DEPTH)-1:0] i_address, // address bus
   input  [RAM_WIDTH-1:0] i_write_data, // datos de entrada a la RAM
   
   input  [$clog2(RAM_DEPTH)-1:0] i_addr_tx,
   input  [1:0]                   i_mem_size,
   input                          i_mem_unsigned,
   
   input  i_exec_mode,
   input  i_step,

   output [RAM_WIDTH-1:0] o_data_send_tx,
   output [RAM_WIDTH-1:0] o_read_data // datos de salida de la RAM
);
   
   // Variables internas:
   reg [RAM_WIDTH-1:0] memoryArray [0:RAM_DEPTH-1];
   reg [RAM_WIDTH-1:0] data_send_tx;
   
   reg [RAM_WIDTH-1:0] r_read_data;
   ////////////////////////////////////////////////////
   // Start-code:
   // Initialization:    initial
   initial begin
      if(FILE_DATA != 0)begin
         $readmemb(FILE_DATA, memoryArray, 0, RAM_DEPTH-1);
      end
   end

   // ESCRITURA: (write data to the specified address)
   always @(posedge i_clk) begin: escritura
      if(i_write_enable && (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
      begin
         case(i_mem_size)
            2'b00: // SB
            begin
               
               case(i_address[1:0])
                  2'b00: memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][7:0]     <= i_write_data[7:0];
                  2'b01: memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][15:8]    <= i_write_data[7:0];
                  2'b10: memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][23:16]   <= i_write_data[7:0];
                  2'b11: memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][31:24]   <= i_write_data[7:0];
               endcase
               
            end
            2'b01: // SH
            begin
               
               if(i_address[1])
                  memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][31:16] <= i_write_data[15:0];
               else
                  memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]][15:0] <= i_write_data[15:0];
               
            end
            2'b10: // SW
            begin
               memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]] <= i_write_data;
            end
         endcase
      end
   end

   always@(posedge i_clk)
   begin: send_data_uart
      
      data_send_tx <= memoryArray[i_addr_tx];
      
   end

   // LECTURA: (get data from the specified address)
   assign o_data_send_tx = data_send_tx;

   always @(*) begin: lectura
      reg [31:0] full_word;
      r_read_data = 32'h0;
      full_word = memoryArray[i_address[$clog2(RAM_DEPTH)-1:2]];
      case(i_mem_size)
         2'b00: // LB o LBU
         begin
            if(i_read_enable && (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
            begin
               if(!i_mem_unsigned)
               begin
                  case(i_address[1:0])
                     2'b00: r_read_data = {{24{full_word[7]}}, full_word[7:0]};
                     2'b01: r_read_data = {{24{full_word[15]}},full_word[15:8]};
                     2'b10: r_read_data = {{24{full_word[23]}},full_word[23:16]};
                     2'b11: r_read_data = {{24{full_word[31]}},full_word[31:24]};
                  endcase
               end
               else
               begin
                  case(i_address[1:0])
                     2'b00: r_read_data = {{24{1'b0}},full_word[7:0]};
                     2'b01: r_read_data = {{24{1'b0}},full_word[15:8]};
                     2'b10: r_read_data = {{24{1'b0}},full_word[23:16]};
                     2'b11: r_read_data = {{24{1'b0}},full_word[31:24]};
                  endcase
               end

            end
         end
         2'b01: // LH o LHU
         begin
            if(i_read_enable && (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
            begin
               if(!i_mem_unsigned)
               begin
                  if(i_address[1])
                     r_read_data = {{16{full_word[31]}},full_word[31:16]};
                  else
                     r_read_data = {{16{full_word[15]}},full_word[15:0]};
               end
               else
               begin
                  if(i_address[1])
                     r_read_data = {{16{1'b0}},full_word[31:16]};
                  else
                     r_read_data = {{16{1'b0}},full_word[15:0]};
               end
            end
         end
         2'b10: // LW
         begin
            if(i_read_enable && (i_exec_mode == 1'b0 || (i_exec_mode && i_step)))
               r_read_data = full_word;
         end
      endcase
   end
   
   assign o_read_data = r_read_data;
   
endmodule