module MemPipeline (input logic reset,
                    input logic clk,
                    input logic mem_in_ready,
                    input Utilities::alu_inp_t input_inst,
                    output logic busy,
                    output logic mem_out_ready,
                    output Utilities::alu_inp_t out_struct,
                    output CACHE::req_type cache_req_type,
                    output logic[63:0] req_addr,
                    output logic[63:0] req_data,
                    input logic mem_respcyc,
                    input logic[63:0] resp_data );

  import CACHE::*;
  import Utilities::*;

  logic mem_running_ff, mem_returns_ff;
  alu_inp_t input_inst_ff;
  alu_inp_t mem_out_ff, mem_out_cb;
  logic pipe_moving;

  assign pipe_moving = mem_respcyc || cache_req_type == IDLE;

  always_ff @ (posedge clk)
  begin
     if (reset)
     begin
        mem_running_ff <= 0;
     end
     else
     begin
        mem_running_ff <= mem_in_ready || !pipe_moving;
     end

     if (mem_in_ready && pipe_moving)
     begin
        input_inst_ff <= input_inst;
     end
  end
 
  always_ff @ (posedge clk)
  begin
     if (reset)
     begin
        mem_returns_ff <= 0;
     end
     else
     begin
        mem_returns_ff <= mem_respcyc || (mem_running_ff && cache_req_type == IDLE);
     end
     mem_out_ff <= mem_out_cb;
  end 

  always_comb
  begin
     if(mem_running_ff)
     begin 
         case(input_inst_ff.opcode)
              LOAD    :  cache_req_type = READ;
              STORE   :  cache_req_type = WRITE;
              CLFLUSH :  cache_req_type = FLUSH;
              MNOP    :  cache_req_type = IDLE;
              default :  cache_req_type = IDLE;
         endcase
     end
     else
     begin
         cache_req_type = IDLE;
     end

     if(input_inst_ff.opcode == STORE)
     begin
        req_data = Utilities::val_to_le_8bytes(input_inst_ff.src0_val.val); 
        req_addr = input_inst_ff.src1_val.val;
     end
     else
     begin
        req_data = 0;
        req_addr = input_inst_ff.src0_val.val;
     end
  end

  always_comb
  begin
     mem_out_cb = input_inst_ff  ;  
     mem_out_cb.dst_val.val = Utilities::le_8bytes_to_val(resp_data);  
  end

  assign mem_out_ready = mem_returns_ff;
  assign out_struct = mem_out_ff;
  assign busy = !pipe_moving;

endmodule 
