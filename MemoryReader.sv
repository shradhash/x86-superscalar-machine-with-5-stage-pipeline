module MemoryReader (input reset,
                     input clk,
                     /* verilator lint_off UNUSED */
                     Mybus.Top bus,
                     input logic reqcyc,
                     input logic [63:0] addr,
                     output logic respcyc,
                     output logic [0:64*8-1] data
                     /* verilator lint_on UNUSED */);

  enum { IDLE,
         READING } state_ff, new_state;

  logic reqack_ff;

  logic [0:64*8-1] databuf_ff;

  int offset_ff;

  always_ff @ (posedge clk)
  begin
     if (reset)
     begin
        state_ff <= IDLE;
        offset_ff <= 0;
        reqack_ff <= 0;
     end
     else
     begin
        //$display("Inside always_ff of mem reader");
        state_ff <= new_state;
        if (bus.respcyc)
        begin
           //$display("bus.respcyc is true"); 
           databuf_ff[offset_ff +: 64] <= bus.resp;
           offset_ff <= offset_ff + 64;
        end
        if (bus.reqack)
        begin
           //$display("bus.reqack is true");
           reqack_ff <= 1;
        end
        if (new_state == IDLE)
        begin
           //$display("inside new_state");
           offset_ff <= 0;
           reqack_ff <= 0;
        end
     end
  end

  always_comb
  begin

     new_state = state_ff ;

     case(state_ff)
        IDLE    : if (reqcyc)
                      new_state = READING;
        READING : if (offset_ff == 512)
                      new_state = IDLE;
     endcase

     //$display("new state inside memory reader = %d  ",new_state);
     //$display("Offset = %d  ", offset_ff);

     bus.bid = 0;
     bus.reqcyc = 0;
     bus.reqtag = MYBUS::READ_MEM_TAG;
     bus.req = addr;
     bus.respack = bus.respcyc;

     respcyc = 0;
     data = 0;

     if (state_ff == READING)
        bus.bid = 1;

     if (state_ff == READING && !reqack_ff)
        bus.reqcyc = 1;

     if (offset_ff == 512)
     begin
        respcyc = 1;
        data = databuf_ff;
     end
  end

endmodule


