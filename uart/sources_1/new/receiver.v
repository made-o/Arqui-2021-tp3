module receiver
#( parameter D_BIT    = 8 , // # data bits
             SB_TICK  = 16  // # ticks for 'stop' bits
 )
 ( input  wire i_clock, 
   input  wire i_reset,
   input  wire i_s_tick,
   input  wire i_rx, 
   
   output reg  o_rx_done_tick,
   output wire [D_BIT-1:0] o_data
 );

   // symbolic state declaration:
   localparam [1:0]  idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;

   // signal declaration:
   reg [1:0] state_reg, state_next;
   reg [3:0] s_reg, s_next;
   reg [2:0] n_reg, n_next;
   reg [D_BIT-1:0] b_reg, b_next;
   
// body:
// FSMD state & data registers:
   always @(posedge i_clock)
     if(i_reset) begin
        state_reg <= idle;
        s_reg <= 0;
        n_reg <= 0;
        b_reg <='d0;
     end //end_if
     else begin
        state_reg <= state_next;
        s_reg <= s_next;
        n_reg <= n_next;
        b_reg <= b_next;
     end //end_else

// FSMD next-state logic:
   always @(*) begin :FSMD
     state_next = state_reg;
     o_rx_done_tick = 1'b0;
     s_next = s_reg;
     n_next = n_reg;
     b_next = b_reg;
     
     case (state_reg)
        idle: if(~i_rx) begin
                state_next = start;
                s_next = 0;
              end

        start: if(i_s_tick)
                 if(s_reg == 7) begin
                   state_next = data;
                   s_next = 0;
                   n_next = 0;
                 end
                 else
                   s_next = s_reg+1;

        data: if(i_s_tick)
                if(s_reg == 15) begin
                   s_next = 0;
                   b_next = {i_rx, b_reg[7:1]};
                   if(n_reg == (D_BIT-1))
                      state_next = stop;
                   else
                      n_next = n_reg+1;
                end
                else
                   s_next = s_reg+1;

        stop: if(i_s_tick)
                 if(s_reg == (SB_TICK-1)) begin
                   state_next = idle;
                   o_rx_done_tick = 1'b1;
                 end
                 else
                   s_next = s_reg+1;
     endcase
   end //end_always

// output:
   assign o_data = b_reg;

endmodule