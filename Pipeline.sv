
module Pipeline ( input[63:0] entry,
                  input reset,
                  input clk,
                  /* verilator lint_off UNDRIVEN */
                  /* verilator lint_off UNUSED */
                  Mybus.Top bus
                  /* verilator lint_on UNUSED */
                  /* verilator lint_on UNDRIVEN */ );

   //import "DPI-C" function longint syscall_cs505(input longint rax, input longint rdi, input longint rsi, input longint rdx, input longint r10, input longint r8, input longint r9);

import CACHE::*;    
import Utilities::*;
import SubInst::inst_to_alu_input;

   parameter SCALE = 2;
   parameter DQ_INP_SIZE = $bits(alu_inp_t) * 6 * SCALE;
   parameter DQ_OUT_SIZE = $bits(alu_inp_t) * SCALE;
   parameter DQ_WIDTH = DQ_INP_SIZE * 2;

   //logic sim_begun;

   logic fetch_reqcyc_ff, fetch_respcyc;
   logic [63:0] fetch_addr;
   logic [0:64*8-1] fetched_inst;

   logic true_reset, jump_reset;
   logic[63:0] true_entry, jump_entry;

   logic[63:0] fetch_addr_ff, pc_ff;

   logic fetch_enq, fetch_deq;
   logic[0: 64*8-1] fetch_in_data;
   logic[0:15*8*SCALE-1] fetch_out_data;
   int fetch_in_count;
   int fetch_out_count;
   int fetch_used_count;
   int fetch_empty_count;

   logic decode_enq, decode_deq;
   logic [0: DQ_INP_SIZE-1] decode_in_data;
   logic [0: DQ_OUT_SIZE-1] decode_out_data;
   int decode_in_count;
   int decode_out_count;
   int decode_used_count;
   int decode_empty_count;
   
   /* verilator lint_off UNDRIVEN */  
   Mybus ibus, dbus;
   /* verilator lint_on UNDRIVEN */

   int bytes_decoded_this_cycle;
   //int no_subinst_this_cycle;
   logic [0: DQ_INP_SIZE -1] sub_inst_bits;
   //logic can_decode ;
   //int decode_return ;
   
   /* Take care of branching */
   always_comb
   begin
      true_reset = reset ? 1 : jump_reset;
      true_entry = reset ? entry : jump_entry;
   end

   /* Shradha 1 */
   MemoryBusMux idbusmux(reset, 
                         clk,
                         dbus,
                         ibus,
                         bus); 

   /* Fetch instructions from instruction cache and populate them in queue */   
   /* Shradha 2 */
   cacheINway inst_reader(clk,
                          reset,
                          fetch_addr,
                          fetched_inst,
                          fetch_reqcyc_ff,
                          fetch_respcyc,
                          ibus); 
   
   /* Shradha 3 */                       
   Queue #(64*8, 15*8*SCALE, 64*8*2) fetch_queue (true_reset,
                                                  clk,
                                                  fetch_enq,
                                                  fetch_in_count,
                                                  fetch_in_data,
                                                  fetch_deq,
                                                  fetch_out_count,
                                                  fetch_out_data,
                                                  fetch_used_count,
                                                  fetch_empty_count);

   /* Shradha 4 */
   always_ff @ (posedge clk)
   begin
      if(true_reset)
      begin
         fetch_addr_ff <= true_entry;
         fetch_reqcyc_ff <= 0;
         pc_ff <= true_entry;
      end
      else
      begin
         //$display("fetch_respcyc = %x\n", fetch_respcyc); 
         if (fetch_respcyc)
         begin
            fetch_addr_ff <= (fetch_addr_ff & ~63) + 64;
         end
         if (fetch_respcyc)
         begin
            fetch_reqcyc_ff <= fetch_empty_count >= 128*8;
         end
         else
         begin
            fetch_reqcyc_ff <= fetch_empty_count >= 64 * 8;
         end
 
         pc_ff <= pc_ff + { 32'b0, bytes_decoded_this_cycle };
         //$display("fetch_reqcyc_ff = %x\n", fetch_reqcyc_ff);
         //$display("pc_ff = %x\n", pc_ff);
         //$display("fetched_inst = %x\n", fetched_inst); 
      end
  end

  assign fetch_addr = fetch_addr_ff & ~63;

  /* Shradha 5 */  
  always_comb 
  begin
     fetch_enq = fetch_respcyc;
     fetch_in_count = 64*8 - (fetch_addr_ff[5:0] * 8);
     fetch_in_data = fetched_inst << (fetch_addr_ff[5:0] * 8);
  end
        
  /* Decode and prepare queue for Dispatch stage */

  /* Shradha 6 */
  Queue #(DQ_INP_SIZE, DQ_OUT_SIZE, DQ_WIDTH) decode_queue(true_reset,
                                                           clk,
                                                           decode_enq,
                                                           decode_in_count,
                                                           decode_in_data,
                                                           decode_deq,
                                                           decode_out_count,
                                                           decode_out_data,
                                                           decode_used_count,
                                                           decode_empty_count);
           
  /* Decoder decoder ( can_decode,
                    fetch_out_data[bytes_decoded_this_cycle*8 +: 15*8],
                    pc_ff + {32'b0 , bytes_decoded_this_cycle},
                    inst_info,
                    decode_return); */

  /* Shradha 7 */ 
  always_comb 
  begin

      int no_subinst_this_cycle = 0;
      bytes_decoded_this_cycle = 0;
      sub_inst_bits = 0;

      if (decode_empty_count >= DQ_INP_SIZE)
      begin
         int i = 0;

         for (i=0; i<SCALE ; i++) 
         begin
            int decode_return = 0;
            inst_info_t inst_info = 0;
            //can_decode = 0;

            if ((fetch_used_count - bytes_decoded_this_cycle * 8) < (15*8))
             break;
           
             /* Shradha 8 */
             $display("To Decode = %x\n", fetch_out_data[bytes_decoded_this_cycle*8 +: 15*8]); 
             decode_return = Decoder::decoder(fetch_out_data[bytes_decoded_this_cycle*8 +: 15*8],
                                                 pc_ff + {32'b0 , bytes_decoded_this_cycle},
                                                 inst_info
                                                 );
             //$display("decode_return\n = %d", decode_return);
 
            if (decode_return > 0)
            begin
               int subinst_ret = 0;
               logic [0: 6 * $bits(alu_inp_t)-1] sub_inst_this_loop;  
               bytes_decoded_this_cycle = bytes_decoded_this_cycle + decode_return;
               subinst_ret = SubInst::inst_to_alu_input(inst_info, sub_inst_this_loop);  // Shradha - implement this
               sub_inst_bits[no_subinst_this_cycle * $bits(alu_inp_t) +: 6*$bits(alu_inp_t)] = sub_inst_this_loop;
               no_subinst_this_cycle = no_subinst_this_cycle + subinst_ret;
            end
            else
            begin
               bytes_decoded_this_cycle = bytes_decoded_this_cycle + 1;
            end
            //$display("bytes_decoded_this_cycle\n = %d", bytes_decoded_this_cycle);
         end
       end

       fetch_deq = bytes_decoded_this_cycle > 0;
       fetch_out_count = bytes_decoded_this_cycle * 8;

       decode_enq = no_subinst_this_cycle > 0;
       decode_in_count = no_subinst_this_cycle * $bits(alu_inp_t);
       decode_in_data = sub_inst_bits;

       //sim_begun = 1;
   end   
                
   reg_val_t[0: REG_FILE_SIZE-1] reg_file_ff;
   
   logic[0: REG_FILE_SIZE-1] sb_ff, new_sb;
   logic[0: REG_FILE_SIZE-1] sb_clear_mask;

   /* Shradha 9 */
   always_ff @ (posedge clk)
   begin
      if (reset)
      begin
         sb_ff <= 0;
      end
      else
      begin
         sb_ff <= new_sb ^ sb_clear_mask ;
      end
   end

   /* Dispath to Execution Unit and Memory Unit */

   /* Shradha 10 */
   logic[SCALE-1 : 0] apipe_in_ready, apipe_out_ready;

   alu_inp_t[SCALE-1 :0] apipe_inp_data;
   alu_inp_t[SCALE-1 :0] apipe_out_data;

   alu_inp_t mpipe_inp_data;
   alu_inp_t mpipe_out_data;

   logic mpipe_in_ready,mpipe_out_ready, mpipe_busy; 

   CACHE::req_type dcache_req_type;
   logic dcache_respcyc;
   logic [63:0] dcache_req_addr, dcache_req_data, dcache_resp_data;

   /* Shradha 11 */ 
   AluPipeline apipe[SCALE-1 :0] (reset,
                                  clk,
                                  apipe_in_ready,
                                  apipe_inp_data,
                                  apipe_out_ready,
                                  apipe_out_data);
   /* Shradha 12 */ 
   cacheNway dcache(clk, 
                    reset,
                    dcache_req_addr,
                    dcache_resp_data,
                    dcache_req_data,
                    dcache_respcyc,
                    dcache_req_type,
                    dbus);

   /* Shradha 13 */
   MemPipeline mpipe (reset,
                      clk,
                      mpipe_in_ready,
                      mpipe_inp_data,
                      mpipe_busy,
                      mpipe_out_ready,
                      mpipe_out_data,
                      dcache_req_type,
                      dcache_req_addr,
                      dcache_req_data,
                      dcache_respcyc,
                      dcache_resp_data);

   always_comb
   begin

      int i = 0;
      alu_inp_t sub_inst = 0;
      jump_reset = 0;
      jump_entry = 0;
      decode_out_count = 0;
      new_sb = sb_ff ;

      apipe_in_ready = 0;
      apipe_inp_data = 0;
      mpipe_in_ready = 0;
      mpipe_inp_data = 0;
  
      for (i = 0; i< SCALE; i++)
      begin
         sub_inst = decode_out_data[i*$bits(alu_inp_t) +: 1*$bits(alu_inp_t)];
         //print_sub_instructions(sub_inst);
         if (decode_used_count < $bits(alu_inp_t) * (i+1))
            break;
         if (!score_board_check(new_sb, sub_inst))
            break;

         load_reg_vals(reg_file_ff, sub_inst);
 
         if(is_sub_inst_branch(sub_inst.opcode))
         begin
            if(will_sub_inst_branch(sub_inst))
            begin
               if (fetch_reqcyc_ff == 0 || fetch_respcyc)
               begin
                  jump_reset = 1;
                  jump_entry = sub_inst.src0_val.val;
               end
               break;
            end
         end
         else if (is_sub_inst_mem(sub_inst.opcode))
         begin
            if (mpipe_in_ready)
               break;
            if (mpipe_busy)
               break;
            mpipe_in_ready = 1;
            mpipe_inp_data = sub_inst;
         end
         else
         begin
            apipe_in_ready[i] = 1;
            apipe_inp_data[i] = sub_inst;
            //print_sub_instructions(sub_inst);
         end

         decode_out_count = decode_out_count + $bits(alu_inp_t);
         new_sb = new_sb ^ make_sb_mask(sub_inst.dst_id);
      end
    
      decode_deq = 1;
   end
         
   /* Register Write Back */

   always_ff @ (posedge clk) 
   begin
      if (reset)
      begin
         reg_file_ff[reg_num(RSP)].val <= 64'h7c00;
      end
      else
      begin
         int i = 0;
         /* verilator lint_off UNUSED */
         alu_inp_t sub_inst = 0;
         /* verilator lint_on UNUSED */
         for (i=0 ; i< SCALE; i++)
         begin
            sub_inst = apipe_out_data[i];
            if (apipe_out_ready[i] && reg_in_file(sub_inst.dst_id))
            begin
                reg_file_ff[reg_num(sub_inst.dst_id)] <= sub_inst.dst_val;
            end
         end
         sub_inst = mpipe_out_data;
         if (mpipe_out_ready && reg_in_file(sub_inst.dst_id)) 
         begin
            reg_file_ff[reg_num(sub_inst.dst_id)] <= sub_inst.dst_val;
         end
      end
   end

   always_comb
   begin
      int i;
      sb_clear_mask = 0;
      for (i = 0; i < SCALE; i++)
      begin
         if (apipe_out_ready[i])
         begin
            sb_clear_mask = sb_clear_mask ^ make_sb_mask(apipe_out_data[i].dst_id);
         end
      end
      if (mpipe_out_ready)
      begin
         sb_clear_mask = sb_clear_mask ^ make_sb_mask(mpipe_out_data.dst_id);
      end
   end

   logic[0: 15*8*2-1] fetch_out_data_ff;
   logic[1:0] apipe_in_ready_ff;
   //logic mpipe_out_ready_ff;
   //logic[1:0] apipe_out_ready_ff; 
   /* always_comb
   begin
        fetch_out_data_ff = fetch_out_data;
        apipe_out_ready_ff = apipe_out_ready;
        mpipe_out_ready_ff = mpipe_out_ready;
        //apipe_out_ready_ff <= apipe_out_ready;
        if (((fetch_out_data_ff != 0) || (apipe_out_ready_ff != 2'b00) || (mpipe_out_ready_ff != 0)) || sim_begun == 0) 
           ;
        else
           $finish;
   end */

   always_ff @(posedge clk)
   begin
      fetch_out_data_ff <= fetch_out_data;
      apipe_in_ready_ff <= apipe_in_ready; 
      if ((fetch_out_data_ff == 0) && (apipe_in_ready_ff == 2'b11))
         $finish; 
   end 

   final begin
       $display("\n End of Execution \n");
       $display("RAX = %x", reg_file_ff[0].val);
       $display("RCX = %x", reg_file_ff[1].val);
       $display("RDX = %x", reg_file_ff[2].val);
       $display("RBX = %x", reg_file_ff[3].val);
       $display("RSP = %x", reg_file_ff[4].val);
       $display("RBP = %x", reg_file_ff[5].val);
       $display("RSI = %x", reg_file_ff[6].val);
       $display("RDI = %x", reg_file_ff[7].val);
       $display("R8 = %x", reg_file_ff[8].val);
       $display("R9 = %x", reg_file_ff[9].val);
       $display("R10 = %x", reg_file_ff[10].val);
       $display("R11 = %x", reg_file_ff[11].val);
       $display("R12 = %x", reg_file_ff[12].val);
       $display("R13 = %x", reg_file_ff[13].val);
       $display("R14 = %x", reg_file_ff[14].val);
       $display("R15 = %x", reg_file_ff[15].val);

   end

endmodule  
