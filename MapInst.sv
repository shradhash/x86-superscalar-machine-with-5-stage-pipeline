/*************************************************************************
 *  Map Instructions to Opcode                                           *
 ************************************************************************/

`define Mainmap(c, n, m) 'h``c: begin res.name = "n"; res.mode = "m"; end

`define GroupInst(c, g, m) 'h``c: begin res.name = 0; res.mode = "m"; res.group = 'h``g; end

`define MAP_BEGIN(name) \
     function automatic opcode_struct_t name(logic[7:0] key); \
	opcode_struct_t res = 0; \
    	   case (key)

`define MAP_END \
     	   endcase \
   	return res; \
     endfunction

package MapInst;

import Utilities::*;

/* Use _ to represent an empty mode */
/* Mapping one byte opcode first */

`MAP_BEGIN(opcode_map1)

   `Mainmap(01, add, Ev_Gv)
   `Mainmap(03, add, Gv_Ev)
   `Mainmap(05, add, rax_Iz)
   `Mainmap(09, or,  Ev_Gv)
   `Mainmap(0B, or,  Gv_Ev)
   `Mainmap(0D, or,  rax_Iz)

   `Mainmap(11, adc, Ev_Gv)
   `Mainmap(13, adc, Gv_Ev)
   `Mainmap(15, adc, rax_Iz)
   `Mainmap(19, sbb, Gv_Ev)
   `Mainmap(1B, sbb, Gv_Ev)
   `Mainmap(1D, sbb, rax_Iz)

   `Mainmap(21, and, Ev_Gv)
   `Mainmap(23, and, Gv_Ev)
   `Mainmap(25, and, rax_Iz)
   `Mainmap(29, sub, Ev_Gv)
   `Mainmap(2B, sub, Gv_Ev)
   `Mainmap(2D, sub, rax_Iz)

   `Mainmap(31, xor, Ev_Gv)
   `Mainmap(33, xor, Gv_Ev)
   `Mainmap(35, xor, rax_Iz)
   `Mainmap(39, cmp, Ev_Gv)
   `Mainmap(3B, cmp, Gv_Ev)
   `Mainmap(3D, cmp, rax_Iz)

   `Mainmap(50, push, rax$r8)
   `Mainmap(51, push, rcx$r9)
   `Mainmap(52, push, rdx$r10)
   `Mainmap(53, push, rbx$r11)
   `Mainmap(54, push, rsp$r12)
   `Mainmap(55, push, rbp$r13)
   `Mainmap(56, push, rsi$r14)
   `Mainmap(57, push, rdi$r15)
   `Mainmap(58, pop, rax$r8)
   `Mainmap(59, pop, rcx$r9)
   `Mainmap(5A, pop, rdx$r10)
   `Mainmap(5B, pop, rbx$r11)
   `Mainmap(5C, pop, rsp$r12)
   `Mainmap(5D, pop, rbp$r13)
   `Mainmap(5E, pop, rsi$r14)
   `Mainmap(5F, pop, rdi$r15)

   `Mainmap(68, push, Iz)
   `Mainmap(69, imul, Gv_Ev_Iz)
   `Mainmap(6A, push, Ib)
   `Mainmap(6B, imul, Gv_Ev_Ib)

   `Mainmap(70, jo, Jb)
   `Mainmap(71, jno, Jb)
   `Mainmap(72, jb, Jb)
   `Mainmap(73, jnb, Jb)
   `Mainmap(74, jz, Jb)
   `Mainmap(75, jnz, Jb)
   `Mainmap(76, jbe, Jb)
   `Mainmap(77, jnbe, Jb)
   `Mainmap(78, js, Jb)
   `Mainmap(79, jns, Jb)
   `Mainmap(7A, jp, Jb)
   `Mainmap(7B, jnp, Jb)
   `Mainmap(7C, jl, Jb)
   `Mainmap(7D, jnl, Jb)
   `Mainmap(7E, jle, Jb)
   `Mainmap(7F, jnle, Jb)

   `GroupInst(81, 1, Ev_Iz)
   `GroupInst(83, 1, Ev_Ib)
   `Mainmap(85, test, Ev_Gv)
   `Mainmap(87, xchg, Ev_Gv)
   `Mainmap(89, mov, Ev_Gv)
   `Mainmap(8B, mov, Gv_Ev)
   `Mainmap(8D, lea, Gv_M)
   `GroupInst(8F, 1A, Ev)

   `Mainmap(90, nop, _)

   `Mainmap(B8, mov, rax$r8_Iv)
   `Mainmap(B9, mov, rcx$r9_Iv)
   `Mainmap(BA, mov, rdx$r10_Iv)
   `Mainmap(BB, mov, rbx$r11_Iv)
   `Mainmap(BC, mov, rsp$r12_Iv)
   `Mainmap(BD, mov, rbp$r13_Iv)
   `Mainmap(BE, mov, rsi$r14_Iv)
   `Mainmap(BF, mov, rdi$r15_Iv)

   `GroupInst(C1, 2, Ev_Ib)
   `Mainmap(C3, retq, _)
   `GroupInst(C7, 11, Ev_Iz)

   `GroupInst(D1, 2, Ev_1)
   `GroupInst(D3, 2, Ev_CL)

   `Mainmap(E8, call, Jz)
   `Mainmap(E9, jmp, Jz)
   `Mainmap(EB, jmp, Jb)

   `GroupInst(F7, 3, Ev)
   `GroupInst(FF, 5, _)

`MAP_END

/* Mapping 2 byte opcode - first byte will be 0F */
`MAP_BEGIN(opcode_map2)

   `Mainmap(05, syscall, _)

   `Mainmap(80, jo, Jz)
   `Mainmap(81, jno, Jz)
   `Mainmap(82, jb, Jz)
   `Mainmap(83, jnb, Jz)
   `Mainmap(84, jz, Jz)
   `Mainmap(85, jnz, Jz)
   `Mainmap(86, jbe, Jz)
   `Mainmap(87, jnbe, Jz)
   `Mainmap(88, js, Jz)
   `Mainmap(89, jns, Jz)
   `Mainmap(8A, jp, Jz)
   `Mainmap(8B, jnp, Jz)
   `Mainmap(8C, jl, Jz)
   `Mainmap(8D, jnl, Jz)
   `Mainmap(8E, jle, Jz)
   `Mainmap(8F, jnle, Jz)

   `GroupInst(AE, 15, _)
   `Mainmap(AF, imul, Gv_Ev)

`MAP_END

`MAP_BEGIN(opcode_map3)
`MAP_END

`MAP_BEGIN(opcode_map4)
`MAP_END

`define GMC(g, k, c, n, m) {32'h``g, 8'b``k, 24'h``c}: begin res.name = "n"; res.mode = "m"; end
`define GroupMap(g, k, n, m) `GMC(g, k, ?, n, m)

function automatic opcode_struct_t group_opcode_map(int group, logic[7:0] key, logic [0:3*8-1] opcode);
	opcode_struct_t res = 0;
	casez ({group, key, opcode})

	/* within the same group, patterns with more ?'s should appear before patterns with less ?'s */

   `GroupMap(1, ??000???, add, _)
   `GroupMap(1, ??001???, or, _)
   `GroupMap(1, ??010???, adc, _)
   `GroupMap(1, ??011???, sbb, _)
   `GroupMap(1, ??100???, and, _)
   `GroupMap(1, ??101???, sub, _)
   `GroupMap(1, ??110???, xor, _)
   `GroupMap(1, ??111???, cmp, _)

   `GroupMap(1A, ??000???, pop, _)

   `GroupMap(2, ??000???, rol, _)
   `GroupMap(2, ??001???, ror, _)
   `GroupMap(2, ??010???, rcl, _)
   `GroupMap(2, ??011???, rcr, _)
   `GroupMap(2, ??100???, shl, _)
   `GroupMap(2, ??101???, shr, _)
   `GroupMap(2, ??111???, sar, _)

   `GMC(3, ??000???, F7, test, Ev_Iz)
   `GroupMap(3, ??010???, not, _)
   `GroupMap(3, ??011???, neg, _)
   `GMC(3, ??100???, F7, mul, Ev)
   `GMC(3, ??101???, F7, imul, Ev)
   `GMC(3, ??110???, F7, div, Ev)
   `GMC(3, ??111???, F7, idiv, Ev)

   `GroupMap(5, ??000???, inc, Ev)
   `GroupMap(5, ??001???, dec, Ev)
   `GroupMap(5, ??010???, call, Ev)
   `GroupMap(5, ??011???, call, Ep)
   `GroupMap(5, ??100???, jmp, Ev)
   `GroupMap(5, ??101???, jmp, Mp)
   `GroupMap(5, ??110???, push, Ev)

   `GMC(11, ??000???, C7, mov, Ev_Iz)

   `GroupMap(15, 11111???, sfence, _)
   `GroupMap(15, ??111???, clflush, M)

  endcase
  return res;
endfunction

/* op_struct.name will be zero when something goes wrong */
/* returns the number of bytes in opcode, excluding ModRM, even if it's used */
function automatic int fill_opcode_struct(logic[0:4*8-1] op_bytes,
                                          output opcode_struct_t op_struct);

    int idx = 0;
    logic[7:0] modrm = 0;
    /* verilator lint_off UNUSED */
    opcode_struct_t tmp = 0;
    /* verilator lint_on UNUSED */

    op_struct = 0;

        if (`get_byte(op_bytes, 0) == 'h0F) 
        begin
	    if (`get_byte(op_bytes, 1) == 'h3A) 
            begin
		op_struct = opcode_map4(`get_byte(op_bytes, 2));
		`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
		idx = 3;
	    end 
            else if (`get_byte(op_bytes, 1) == 'h38)
            begin
	        op_struct = opcode_map3(`get_byte(op_bytes, 2));
		`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
		idx = 3;
	    end 
            else
            begin
		op_struct = opcode_map2(`get_byte(op_bytes, 1));
		`eget_bytes(op_struct.opcode, 1, 3) = `eget_bytes(op_bytes, 0, 2);
		idx = 2;
	    end
       end 
       else
       begin
    	  op_struct = opcode_map1(`get_byte(op_bytes, 0));
	  `eget_bytes(op_struct.opcode, 2, 3) = `eget_bytes(op_bytes, 0, 1);
	  idx = 1;
       end

       if (op_struct.group != 0)
       begin
	 modrm = `get_byte(op_bytes, idx);
	 tmp = group_opcode_map(op_struct.group, modrm, op_struct.opcode);
	 op_struct.name = tmp.name;
	 /* group-map mode overrides opcode-map mode */
	 if (tmp.mode != "_")
         begin
	    op_struct.mode = tmp.mode;
	end
     end

     return idx;

endfunction

endpackage;
