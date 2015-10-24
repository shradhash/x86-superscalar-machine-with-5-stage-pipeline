/**********************************************************************************
 *
 **********************************************************************************/

module MemoryWriter ( input reset,
                      input clk,
                      /* verilator lint_off UNUSED */
                      Mybus.Top bus,
                      input logic reqcyc,
                      input logic[63:0] addr,
                      output logic respcyc,
                      input logic[0:64*8-1] data
                      /* verilator lint_on UNUSED */ );

   enum { IDLE,
          WRITING }  state_ff, new_state;

   int offset_ff;

   logic first_ack_ff;

   always_ff @(posedge clk)
   begin
     if (reset)
     begin
        state_ff <= IDLE;
        offset_ff <= 0;
        first_ack_ff <= 0;
     end
     else
     begin
        state_ff <= new_state;
        if (first_ack_ff == 1'b1)
           offset_ff <= offset_ff + 64;
        if (bus.reqack) 
           first_ack_ff <= 1;
        if (new_state == IDLE)
        begin
           offset_ff <= 0;
           first_ack_ff <= 0;
        end
     end
  end

  always_comb 
  begin
     new_state = state_ff;
     case (state_ff)
         IDLE     :  if (reqcyc)
                        new_state = WRITING;
         WRITING  :  if (offset_ff == 512)
                        new_state = IDLE;
     endcase

     bus.bid = 0;
     bus.reqcyc = 0;
     bus.reqtag = 0;
     bus.req = 0;
     bus.respack = 0;
     
     respcyc = 0;

     if (state_ff == WRITING)
         bus.bid = 1;

     if (state_ff == WRITING && !first_ack_ff)
     begin
        bus.reqcyc = 1;
        bus.reqtag = MYBUS::WRITE_MEM_TAG;
        bus.req = addr;
     end

     if (state_ff == WRITING && first_ack_ff && offset_ff < 512)
     begin
        bus.reqcyc = 1;
        bus.reqtag = MYBUS::WRITE_MEM_TAG;
        bus.req = data[offset_ff +: 64];
     end

     if (offset_ff == 512)
     begin
        respcyc = 1;
     end

  end

endmodule

  
