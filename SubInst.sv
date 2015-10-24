
package SubInst;

import Utilities::*;

`define R0  (patch_base(ins.operand0))
`define RX0 (patch_index(ins.operand0))
`define R1  (patch_base(ins.operand1))
`define RX1 (patch_index(ins.operand1))

function automatic reg_id_t patch_base(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
        return opd.base_reg == RNIL ? RV0 : opd.base_reg;
endfunction

function automatic reg_id_t patch_index(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
        return opd.index_reg == RNIL ? RV0 : opd.index_reg;
endfunction

function automatic alu_inp_t make_sub_inst(sub_opcode_t opc, reg_id_t src0, reg_id_t src1, reg_id_t dst);
	alu_inp_t sub_inst = 0;
	sub_inst.opcode = opc;
	sub_inst.src0_id = src0;
	sub_inst.src1_id = src1;
	sub_inst.dst_id = dst;
	return sub_inst;
endfunction

function automatic int crack_opd0_opd1_out_opd0_RFLAGS(
	input sub_opcode_t sub_instcode, 
	/* verilator lint_off UNUSED */
	input inst_info_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output alu_inp_t[0:6-1] sub_insts
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(sub_instcode, `R0, `R1, `R0); 
		sub_insts[1] = make_sub_inst(MOVE, `R0, RNIL, RFLAGS); 
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		sub_insts[0] = make_sub_inst(LEA, `R1, `RX1, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(sub_instcode, `R0, RHA, `R0); 
		sub_insts[3] = make_sub_inst(MOVE, `R0, RNIL, RFLAGS); 
		return 4;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHB);
		sub_insts[2] = make_sub_inst(sub_instcode, RHB, `R1, RFLAGS); 
		sub_insts[3] = make_sub_inst(STORE, RFLAGS, RHA, RNIL);
		return 4;
	end 
	$display("ERROR: crack_opd0_opd1_out_opd0_RFLAGS: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	return 0;
endfunction

function automatic int crack_opd0_opd1_out_opd0_maybe_RFLAGS(
	input sub_opcode_t sub_instcode, 
	/* verilator lint_off UNUSED */
	input inst_info_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output alu_inp_t[0:6-1] sub_insts
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(MOVE_F, `R0, RFLAGS, `R0); 
		sub_insts[1] = make_sub_inst(sub_instcode, `R0, `R1, `R0); 
		sub_insts[2] = make_sub_inst(MOVE, `R0, RNIL, RFLAGS); 
		return 3;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		sub_insts[0] = make_sub_inst(LEA, `R1, `RX1, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(MOVE_F, `R0, RFLAGS, `R0); 
		sub_insts[3] = make_sub_inst(sub_instcode, `R0, RHA, `R0); 
		sub_insts[4] = make_sub_inst(MOVE, `R0, RNIL, RFLAGS); 
		return 5;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHB);
		sub_insts[2] = make_sub_inst(MOVE_F, RHB, RFLAGS, RHB); 
		sub_insts[3] = make_sub_inst(sub_instcode, RHB, `R1, RFLAGS); 
		sub_insts[4] = make_sub_inst(STORE, RFLAGS, RHA, RNIL);
		return 5;
	end 
	$display("ERROR: crack_opd0_opd1_out_opd0_maybe_RFLAGS: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	return 0;
endfunction

function automatic int crack_opd0_opd1_out_RFLAGS(
	input sub_opcode_t sub_instcode, 
	/* verilator lint_off UNUSED */
	input inst_info_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output alu_inp_t[0:6-1] sub_insts
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(sub_instcode, `R0, `R1, RFLAGS); 
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		sub_insts[0] = make_sub_inst(LEA, `R1, `RX1, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(sub_instcode, `R0, RHA, RFLAGS); 
		return 3;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(sub_instcode, RHA, `R1, RFLAGS); 
		return 3;
	end 
	$display("ERROR: crack_opd0_opd1_out_flags: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	return 0;
endfunction

function automatic int crack_imul1(
	/* verilator lint_off UNUSED */
	input inst_info_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output alu_inp_t[0:6-1] sub_insts
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(IMUL_L, RAX, `R0, RHA);
		sub_insts[1] = make_sub_inst(IMUL_H, RAX, `R0, RDX);
		sub_insts[2] = make_sub_inst(MOVE, RHA, RNIL, RAX);
		sub_insts[3] = make_sub_inst(MOVE, RDX, RNIL, RFLAGS);
		return 4;
	end
	if (ins.operand0.opd_type == opdt_memory) begin 
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(IMUL_L, RAX, RHA, RHB);
		sub_insts[3] = make_sub_inst(IMUL_H, RAX, RHA, RDX);
		sub_insts[4] = make_sub_inst(MOVE, RHB, RNIL, RAX);
		sub_insts[5] = make_sub_inst(MOVE, RDX, RNIL, RFLAGS);
		return 6;
	end
	$display("ERROR: crack_imul1: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
endfunction

function automatic int crack_jcc(
	input sub_opcode_t sub_instcode, 
	/* verilator lint_off UNUSED */
	input inst_info_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output alu_inp_t[0:6-1] sub_insts
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && `R0 == RIMM) begin // rip offset
		sub_insts[0] = make_sub_inst(ADD, RIP, RIMM, RHA);
		sub_insts[1] = make_sub_inst(sub_instcode, RHA, RFLAGS, RNIL);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		sub_insts[0] = make_sub_inst(sub_instcode, `R0, RFLAGS, RNIL);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(sub_instcode, RHA, RFLAGS, RNIL);
		return 3;
	end
	$display("ERROR: crack_jcc: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
endfunction


/*** macros for entry points ***/
`define SUBINSTFUN(fun) \
function automatic int ins_``fun( \
	/* verilator lint_off UNUSED */ \
	input inst_info_t ins, \
	/* verilator lint_on UNUSED */ \
	/* verilator lint_off UNDRIVEN */ \
	output alu_inp_t[0:6-1] sub_insts \
	/* verilator lint_on UNDRIVEN */ \
);

`define ENDSUBINSTFUN   endfunction

/*** begin of entry points ***/
`SUBINSTFUN(nop)
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(lea)
	sub_insts[0] = make_sub_inst(LEA, `R1, `RX1, `R0);
	return 1;
`ENDSUBINSTFUN

`SUBINSTFUN(syscall)
	sub_insts[0] = make_sub_inst(MNOP, RNIL, RNIL, RHC);
	sub_insts[1] = make_sub_inst(MOVE, RSYSCALL, RNIL, RAX);
	return 2;
	// sub_insts[0] = make_sub_inst(MOVE, rsyscall, RNIL, RAX);
	// return 1;
`ENDSUBINSTFUN

`SUBINSTFUN(add)
	return crack_opd0_opd1_out_opd0_RFLAGS(ADD, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(and)
	return crack_opd0_opd1_out_opd0_RFLAGS(AND, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(or)
	return crack_opd0_opd1_out_opd0_RFLAGS(OR, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(sub)
	return crack_opd0_opd1_out_opd0_RFLAGS(SUB, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(xor)
	return crack_opd0_opd1_out_opd0_RFLAGS(XOR, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(shl)
	return crack_opd0_opd1_out_opd0_maybe_RFLAGS(SHL, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(shr)
	return crack_opd0_opd1_out_opd0_maybe_RFLAGS(SHR, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(cmp)
	return crack_opd0_opd1_out_RFLAGS(SUB, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(test)
	return crack_opd0_opd1_out_RFLAGS(AND, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(imul)
	if (ins.opcode_struct.opcode == 24'hF7) begin
		// one operand
		return crack_imul1(ins, sub_insts);
	end else if (ins.opcode_struct.opcode == 24'h0FAF) begin
		// two operands
		return crack_opd0_opd1_out_opd0_RFLAGS(IMUL_L, ins, sub_insts);
	end else begin
		// three operands
		$display("ERROR: imul: 3-operand imul not supported yet"); 
		return 0;
	end
`ENDSUBINSTFUN

`SUBINSTFUN(jb)
	return crack_jcc(JB, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jnb)
	return crack_jcc(JNB, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jz)
	return crack_jcc(JZ, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jnz)
	return crack_jcc(JNZ, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jl)
	return crack_jcc(JL, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jnl)
	return crack_jcc(JNL, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jle)
	return crack_jcc(JLE, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jnle)
	return crack_jcc(JNLE, ins, sub_insts);
`ENDSUBINSTFUN

`SUBINSTFUN(jmp)
	if (ins.operand0.opd_type == opdt_register && `R0 == RIMM) begin // rip offset
		sub_insts[0] = make_sub_inst(ADD, RIP, RIMM, RHA);
		sub_insts[1] = make_sub_inst(JMP, RHA, RNIL, RNIL);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		sub_insts[0] = make_sub_inst(JMP, `R0, RNIL, RNIL);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[2] = make_sub_inst(JMP, RHA, RNIL, RNIL);
		return 3;
	end
	$display("ERROR: jmp: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(mov)
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(MOVE, `R1, RNIL, `R0); 
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		sub_insts[0] = make_sub_inst(LEA, `R1, `RX1, RHA);
		sub_insts[1] = make_sub_inst(LOAD, RHA, RNIL, `R0);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[1] = make_sub_inst(STORE, `R1, RHA, RNIL);
		return 2;
	end 
	$display("ERROR: mov: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(clflush)
	sub_insts[0] = make_sub_inst(LEA, `R0, `RX0, RHA);
	sub_insts[1] = make_sub_inst(CLFLUSH, RHA, RNIL, RNIL);
	return 2;
`ENDSUBINSTFUN

`SUBINSTFUN(pop)
	if (ins.operand0.opd_type == opdt_register) begin
		sub_insts[0] = make_sub_inst(LOAD, RSP, RNIL, `R0);
		sub_insts[1] = make_sub_inst(ADD, RSP, RV8, RSP);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		sub_insts[0] = make_sub_inst(LOAD, RSP, RNIL, RHA);
		sub_insts[1] = make_sub_inst(LEA, `R0, `RX0, RHB);
		sub_insts[2] = make_sub_inst(STORE, RHA, RHB, RNIL);
		sub_insts[3] = make_sub_inst(ADD, RSP, RV8, RSP);
		return 4;
	end
	$display("ERROR: pop: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(push)
	sub_insts[0] = make_sub_inst(SUB, RSP, RV8, RSP);
	if (ins.operand0.opd_type == opdt_register) begin
		sub_insts[1] = make_sub_inst(STORE, `R0, RSP, RNIL);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		sub_insts[1] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[2] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[3] = make_sub_inst(STORE, RHA, RSP, RNIL);
		return 4;
	end
	$display("ERROR: push: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(call)
	// push rip
	sub_insts[0] = make_sub_inst(SUB, RSP, RV8, RSP);
	sub_insts[1] = make_sub_inst(STORE, RIP, RSP, RNIL);
	// jmp
	if (ins.operand0.opd_type == opdt_register && `R0 == RIMM) begin // rip offset
		sub_insts[2] = make_sub_inst(ADD, RIP, RIMM, RHA);
		sub_insts[3] = make_sub_inst(JMP, RHA, RNIL, RNIL);
		return 4;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		sub_insts[2] = make_sub_inst(JMP, `R0, RNIL, RNIL);
		return 3;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		sub_insts[2] = make_sub_inst(LEA, `R0, `RX0, RHA);
		sub_insts[3] = make_sub_inst(LOAD, RHA, RNIL, RHA);
		sub_insts[4] = make_sub_inst(JMP, RHA, RNIL, RNIL);
		return 5;
	end
	$display("ERROR: call: invalid operand type: %x", ins.operand0.opd_type); 
	return 0;
`ENDSUBINSTFUN

`SUBINSTFUN(retq)
	// pop rip to RHA
	sub_insts[0] = make_sub_inst(LOAD, RSP, RNIL, RHA);
	sub_insts[1] = make_sub_inst(ADD, RSP, RV8, RSP);
	// jmp
	sub_insts[2] = make_sub_inst(JMP, RHA, RNIL, RNIL);
	return 3;
`ENDSUBINSTFUN


`define SUBINST(name) "name" : cnt = ins_``name(ins, sub_insts);

function automatic int inst_to_alu_input(inst_info_t ins, output logic [0:$bits(alu_inp_t)*6-1] sub_insts_bits);

	int cnt = 0;
	int i = 0;
	alu_inp_t[0:6-1] sub_insts = 0;

	case (ins.opcode_struct.name)
		`SUBINST(nop)
		`SUBINST(lea)
		`SUBINST(syscall)
		`SUBINST(add)
		`SUBINST(and)
		`SUBINST(or)
		`SUBINST(shl)
		`SUBINST(shr)
		`SUBINST(sub)
		`SUBINST(xor)
		`SUBINST(cmp)
		`SUBINST(test)
		`SUBINST(imul)
		`SUBINST(jb)
		`SUBINST(jnb)
		`SUBINST(jz)
		`SUBINST(jnz)
		`SUBINST(jl)
		`SUBINST(jnl)
		`SUBINST(jle)
		`SUBINST(jnle)
		`SUBINST(jmp)
		`SUBINST(mov)
		`SUBINST(clflush)
		`SUBINST(pop)
		`SUBINST(push)
		`SUBINST(call)
		`SUBINST(retq)
		default : begin
			$display("ERROR: instruction not supported: %s", ins.opcode_struct.name);
			return 0;
		end
	endcase

	for (i = 0; i < 6; i++) begin
		sub_insts[i].rip_val = ins.rip_val;
		sub_insts[i].scale = ins.scale;
		sub_insts[i].disp = ins.disp;
		sub_insts[i].immediate = ins.immediate;
	end

	for (i = 0; i < 6; i++) begin
		`get_block(sub_insts_bits, i, $bits(alu_inp_t)) = sub_insts[i];
	end

	return cnt;
endfunction

endpackage
