package ALU;

import Utilities::*;

function automatic reg_val_t alu_lea(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     res.val = alu_in.src0_val.val + (alu_in.src1_val.val << alu_in.scale) + alu_in.disp;
     return res;
endfunction

function automatic reg_val_t alu_move(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     res = alu_in.src0_val;
     return res;
endfunction

function automatic reg_val_t alu_move_f(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     res = alu_in.src1_val;
     res.val = alu_in.src0_val.val;
     return res;
endfunction

function automatic logic parity(logic[7:0] ibyte);
     logic result;
     result = ~(ibyte[7] ^ ibyte[6] ^ ibyte[5] ^ ibyte[4] ^ ibyte[3] ^ ibyte[2] ^ ibyte[1] ^ ibyte[0]);
     return result;
endfunction

function automatic reg_val_t alu_add(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [63:0] v0 = alu_in.src0_val.val;
     logic [63:0] v1 = alu_in.src1_val.val;
     logic [64:0] unsigned_res = {1'b0, v0} + {1'b0, v1};
     /*verilator lint_off UNUSED*/
     logic [64:0] signed_res = {v0[63], v0} + {v1[63], v1};
     logic [4:0]  bcd_res = {1'b0, v0[3:0]} + {1'b0, v1[3:0]};
     /*verilator lint_on UNUSED*/
     res.cf  = unsigned_res[64];
     res.af  = bcd_res[4];
     res.of  = signed_res[64] != signed_res[63];
     res.val = unsigned_res[63:0];
     res.zf  = res.val == 0;
     res.sf  = res.val[63];
     res.pf  = parity(res.val[7:0]);
     return res;
endfunction

function automatic reg_val_t alu_sub(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [63:0] v0 = alu_in.src0_val.val;
     logic [63:0] v1 = alu_in.src1_val.val;
     logic [64:0] unsigned_res = {1'b0, v0} - {1'b0, v1};
     /*verilator lint_off UNUSED*/
     logic [64:0] signed_res = {v0[63], v0} - {v1[63], v1};
     logic [4:0]  bcd_res = {1'b0, v0[3:0]} - {1'b0, v1[3:0]};
     /*verilator lint_on UNUSED*/
     res.cf  = unsigned_res[64];
     res.af  = bcd_res[4];
     res.of  = signed_res[64] != signed_res[63];
     res.val = unsigned_res[63:0];
     res.zf  = res.val == 0;
     res.sf  = res.val[63];
     res.pf  = parity(res.val[7:0]);
     return res;
endfunction

function automatic reg_val_t alu_and(/*verilator lint_off UNUSED*/ 
                                     alu_inp_t alu_in
                                     /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [63:0] result = alu_in.src0_val.val & alu_in.src1_val.val;
     res.val = result;
     res.cf = 0;
     res.zf = result == 0;
     res.sf = result[63];
     res.pf = parity(result[7:0]);
     res.af = 0;
     res.of = 0;
     return res;
endfunction

function automatic reg_val_t alu_or(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [63:0] result = alu_in.src0_val.val | alu_in.src1_val.val;
     res.val = result;
     res.cf = 0;
     res.zf = result == 0;
     res.sf = result[63];
     res.pf = parity(result[7:0]);
     res.af = 0;
     res.of = 0;
     return res;
endfunction

function automatic reg_val_t alu_xor(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [63:0] result = alu_in.src0_val.val ^ alu_in.src1_val.val;
     res.val = result;
     res.cf = 0;
     res.zf = result == 0;
     res.sf = result[63];
     res.pf = parity(result[7:0]);
     res.af = 0;
     res.of = 0;
     return res;
endfunction

function automatic reg_val_t alu_shl(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     /*verilator lint_off WIDTH */
     logic[5:0] count = alu_in.src1_val.val;
     /*verilator lint_on WIDTH */
     if (count == 0)
     begin
         res = alu_in.src0_val;
     end 
     else
     begin
         logic[64:0] result = {1'b0, alu_in.src0_val.val} << count;
         res.val = result[63:0];
         res.cf = result[64];
         res.zf  = res.val == 0;
         res.sf  = res.val[63];
         res.pf  = parity(res.val[7:0]);
         res.af  = 0;
         res.of  = count == 1 ? res.val[63] ^ res.cf : 0;
     end
     return res;
endfunction

function automatic reg_val_t alu_shr(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     /*verilator lint_off WIDTH */
     logic[5:0] count = alu_in.src1_val.val;
     /*verilator lint_on WIDTH */
     if (count == 0)
         res = alu_in.src0_val;
     else
     begin
         logic [64:0] result = {alu_in.src0_val.val, 1'b0} >> count;
         res.val = result[64:1];
         res.cf = result[0];
         res.zf  = res.val == 0;
         res.sf  = res.val[63];
         res.pf  = parity(res.val[7:0]);
         res.af  = 0;
         /*verilator lint_off WIDTH */
         res.of  = count == 1 ? alu_in.src0_val.val : 0;
         /*verilator lint_on WIDTH */
     end
     return res;
endfunction

function automatic logic[127:0] signed_mul(logic[63:0] inp0, logic[63:0] inp1);
     logic[63:0] zeroes = 64'h0;
     logic[63:0] ones = ~zeroes;
     logic signed [127:0] op0;
     logic signed [127:0] op1;
     logic signed [127:0] result;

     if (inp0[63] == 0) 
        op0 = {zeroes, inp0}; 
     else
        op0 =  {ones, inp0};

     if (inp1[63] == 0)
        op1 = {zeroes, inp1};
     else
        op1 =  {ones, inp1};
 
     result = op0 * op1;

     return result;

endfunction

function automatic logic carry(/*verilator lint_off UNUSED*/ logic[127:0] inp /*verilator lint_on UNUSED*/);
     logic[63:0] zeroes = 64'h0;
     logic[63:0] ones = ~zeroes;
     if (inp[127:64] != zeroes && inp[127:64] != ones)
        return 1;
     if (inp[127:64] == zeroes && inp[63] == 1)
        return 1;
     if (inp[127:64] == ones && inp[63] == 0)
        return 1;
     return 0;
endfunction

function automatic reg_val_t alu_imul_l(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [127:0] result = signed_mul(alu_in.src0_val.val, alu_in.src1_val.val) ;
     res.val = result[63:0];
     res.cf = carry(result);
     res.zf = 0;
     res.sf = 0;
     res.pf = 0;
     res.af = 0;
     res.of = res.cf;
     return res;
endfunction

function automatic reg_val_t alu_imul_h(/*verilator lint_off UNUSED*/ alu_inp_t alu_in /*verilator lint_on UNUSED*/);
     reg_val_t res = 0;
     logic [127:0] result = signed_mul(alu_in.src0_val.val, alu_in.src1_val.val) ;
     res.val = result[127:64];
     res.cf = carry(result);
     res.zf = 0;
     res.sf = 0;
     res.pf = 0;
     res.af = 0;
     res.of = res.cf;
     return res;
endfunction

/* Main task for arithmetic and logical calculations */
function automatic alu_inp_t alu_main (/*verilator lint_off UNUSED*/ alu_inp_t  alu_in /*verilator lint_off UNUSED*/);
    alu_inp_t res_alu_in = alu_in;
  
    case(alu_in.opcode)
        LEA     : res_alu_in.dst_val = alu_lea(alu_in);
        MOVE    : res_alu_in.dst_val = alu_move(alu_in); 
        MOVE_F  : res_alu_in.dst_val = alu_move_f(alu_in);
        ADD     : res_alu_in.dst_val = alu_add(alu_in);
        AND     : res_alu_in.dst_val = alu_and(alu_in);
        OR      : res_alu_in.dst_val = alu_or(alu_in);
        SHL     : res_alu_in.dst_val = alu_shl(alu_in);
        SHR     : res_alu_in.dst_val = alu_shr(alu_in);
        SUB     : res_alu_in.dst_val = alu_sub(alu_in);
        XOR     : res_alu_in.dst_val = alu_xor(alu_in);
        IMUL_L  : res_alu_in.dst_val = alu_imul_l(alu_in);
        IMUL_H  : res_alu_in.dst_val = alu_imul_h(alu_in);
        default : ;
    endcase

    //print_sub_instructions(alu_in);
   
    return res_alu_in;

endfunction

endpackage

