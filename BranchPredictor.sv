module BranchPredictor(input clk,
                       input reset,
                       input logic[63:0] pc_ff,
                       input logic[63:0] target_inp,
                       output logic[63:0] target_out, 
                       input logic is_taken_input,
                       output logic is_taken_output,
                       output logic respcyc_ff,
                       input logic mode);

/* Implementing a Branch Predictor using 1 bit saturating counter */
   parameter BTB_INP_SIZE = 64;
   parameter BTB_TRGT_SIZE = 64;
   parameter BTB_DIR_SIZE = 1
   parameter BTB_DEPTH = 32;
   parameter indexbits = 5;

   logic [indexbits-1:0] read_index;
   logic [indexbits-1:0] write_index;

   `define btb_width BTB_INP_SIZE + BTB_TRGT_SIZE + BTB_DIR_SIZE

   logic [`btb_width-1 :0] read_data;

   assign index = pc_ff[indexbits-1 : 0];

   enum { IDLE,
          READBTB,
          WRITEBTB } state_ff , btb_state;

   logic btb_respcyc;
       
   SRAM #(.width(`btb_width),
          .logdepth(BTB_DEPTH),
          .wordsize(`btb_width)) bpredictor (clk,
                                             reset,
                                             read_index,
                                             read_data,
                                             write_index,
                                             write_data,
                                             write_enable);
   
   always_ff @(posedge clk)
   begin
        if(reset)
        begin
             state_ff <= IDLE;
        end
        else
        begin
             state_ff <= btb_state;
             respcyc_ff <= btb_respcyc;
             if(state_ff == IDLE)
             begin
                  case(mode)
                     1'b0  : state_ff <= READBTB;
                     1'b1  : state_ff <= WRITEBTB;
                     default: state_ff <= IDLE;
                  endcase
            end
       end
   end
             
   always_comb
   begin
       btb_state = state_ff;
      
       case(state_ff)
           READBTB   :   begin
                             if (pc_ff == read_data[index][128:65])
                             begin
                                target_out = read_data[index][64:1] ;
                                is_taken_output = read_data[0];
                             end
                             else
                                is_taken_output = 1'b0;
                             end
                             if (respcyc_ff == 1'b0)
                                 btb_respcyc = 1'b1;
                             else
                             begin
                                 btb_state = IDLE;
                                 btb_respcyc = 1'b0;
                             end
                          end
          WRITEBTB    :   begin
                             write_data = {pc_ff, target_inp, is_taken_input};
                             if (respcyc_ff == 1'b0)
                             begin
                                 writeenable = 1'b1;
                                 btb_respcyc = 1'b1;
                             end
                             else
                                 btb_state = IDLE;
                                 btb_respcyc = 1'b0;
                             end
                         end
           default     :  ;
      endcase

   end

endmodule   
                                 
