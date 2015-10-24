module MemoryBusMux (input reset,
                     input clk,
                     /* verilator lint_off UNDRIVEN */
                     /* verilator lint_off UNUSED */
                     Mybus.Bottom bottom0,
                     Mybus.Bottom bottom1,
                     Mybus.Top top
                     /* verilator lint_on UNUSED */
                     /* verilator lint_off UNDRIVEN */ );

  enum { IDLE,
         BUSY }  state_ff, new_state;

  int user_ff, new_user;

  always_ff @(posedge clk)
  begin
     if (reset)
     begin
        state_ff <= IDLE;
        user_ff <= 0;
     end
     else
     begin
        state_ff <= new_state;
        user_ff <= new_user;
     end
   end

   always_comb
   begin
      new_state = state_ff ;
      new_user = user_ff ;
      case(state_ff)
           IDLE  :  begin
                       if(bottom0.bid)
                       begin
                          new_state = BUSY;
                          new_user = 0;
                       end
                       else if(bottom1.bid)
                       begin
                          new_state = BUSY;
                          new_user = 1;
                       end
                   end
           BUSY  : begin
                      if ((user_ff == 0 && !bottom0.bid) || (user_ff == 1 && !bottom1.bid))
                      begin
                         new_state = IDLE;
                      end
                   end
      endcase
   end

   always_comb
   begin
      top.bid  = 0;
      top.reqcyc = 0;
      top.reqtag = 0;
      top.req = 0;
      if (new_user == 0 && new_state == BUSY)
      begin
         top.bid = bottom0.bid;
         top.reqcyc = bottom0.reqcyc;
         top.reqtag = bottom0.reqtag;
         top.req = bottom0.req;
      end
      else if (new_user == 1 && new_state == BUSY)
      begin
         top.bid = bottom1.bid;
         top.reqcyc = bottom1.reqcyc;
         top.reqtag = bottom1.reqtag;
         top.req = bottom1.req;
      end
   end

   always_comb
   begin
      top.respack = 0;
      if (new_user == 0 && new_state == BUSY)
         top.respack = bottom0.respack;
      else if (new_user == 1 && new_state == BUSY)
         top.respack = bottom1.respack;
   end

   always_comb
   begin
      bottom0.respcyc = 0;
      bottom0.resp = 0;
      bottom0.reqack = 0;
      if (new_user == 0 && new_state == BUSY)
      begin
         bottom0.respcyc = top.respcyc;
         bottom0.resp = top.resp;
         bottom0.reqack = top.reqack;
      end
   end

   always_comb
   begin
      bottom1.respcyc = 0;
      bottom1.resp = 0;
      bottom1.reqack = 0;
      if (new_user == 1 && new_state == BUSY)
      begin
         bottom1.respcyc = top.respcyc;
         bottom1.resp = top.resp;
         bottom1.reqack = top.reqack;
      end
   end

endmodule

