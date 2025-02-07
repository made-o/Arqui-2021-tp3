module transmitter
  #( parameter D_BIT    = 8,// number of data bits
     parameter SB_TICK  = 16 //number of ticks needed for the stop bit
   )
   ( input  wire i_clock,
     input  wire i_reset,
     input  wire i_s_tick,
     input  wire i_tx_start,
     input  wire [D_BIT-1:0] i_data,


     output reg  o_tx_done,
     output wire o_tx
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
  reg tx_reg, tx_next;

  // body:
  // FSMD state & data registers:
  always @(posedge i_clock, posedge i_reset)
    if(i_reset)
    begin
      state_reg <= idle;
      s_reg <= 0;
      n_reg <= 0;
      b_reg <= 0;
      tx_reg <= 1'b1;
    end //end_if
    else
    begin
      state_reg <= state_next;
      s_reg <= s_next;
      n_reg <= n_next;
      b_reg <= b_next;
      tx_reg <= tx_next;
    end //end_else

  // FSMD next-state logic & functional units:
  always @(*)
  begin
    state_next = state_reg;
    o_tx_done = 1'b0;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;
    tx_next = tx_reg;

    case(state_reg)
      idle:
      begin
        tx_next = 1'b1;
        if(i_tx_start)
        begin
          state_next = start;
          s_next = 0;
          b_next = i_data;
        end //end_if
      end //end_idle

      start:
      begin
        tx_next = 1'b0;
        if(i_s_tick)
          if(s_reg == 15)
          begin
            state_next = data;
            s_next = 0;
            n_next = 0;
          end //end_if
          else
            s_next = s_reg+1;
      end // end_start

      data:
      begin
        tx_next = b_reg[0];
        if(i_s_tick)
          if(s_reg == 15)
          begin
            s_next = 0;
            b_next = b_reg >> 1;
            if(n_reg == (D_BIT-1))
              state_next = stop;
            else
              n_next = n_reg+1;
          end // end_if
          else
            s_next = s_reg+1;
      end // end_data

      stop:
      begin
        tx_next = 1'b1;
        if(i_s_tick)
          if(s_reg == (SB_TICK-1))
          begin
            state_next = idle;
            o_tx_done = 1'b1;
          end //end_if
          else
            s_next = s_reg+1;
      end //end_stop
    endcase
  end //end_always

  // output:
  assign o_tx = tx_reg;

endmodule
