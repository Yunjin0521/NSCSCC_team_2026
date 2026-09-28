//-----------------------------------------------------------------
//                         Biloong CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//                     Copyright 2019-2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------

module biloong_issue
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_DUAL_ISSUE = 1
    ,parameter SUPPORT_LOAD_BYPASS = 0
    ,parameter SUPPORT_MUL_BYPASS = 1
    ,parameter SUPPORT_REGFILE_XILINX = 0
    ,parameter SUPPORT_SLOT1_ALU = 1
    ,parameter SUPPORT_SLOT1_BRANCH = 1
    ,parameter SUPPORT_SLOT1_MUL = 1
    ,parameter SUPPORT_SLOT1_LOAD = 1
    ,parameter SUPPORT_SLOT1_STORE = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch0_valid_i
    ,input  [ 31:0]  fetch0_instr_i
    ,input  [ 31:0]  fetch0_pc_i
    ,input           fetch0_pred_branch_i
    ,input  [ 31:0]  fetch0_pred_pc_i
    ,input           fetch0_fault_fetch_i
    ,input           fetch0_fault_page_i
    ,input  [  5:0]  fetch0_fault_ecode_i
    ,input  [ 31:0]  fetch0_fault_addr_i
    ,input           fetch0_instr_exec_i
    ,input           fetch0_instr_lsu_i
    ,input           fetch0_instr_branch_i
    ,input           fetch0_instr_mul_i
    ,input           fetch0_instr_div_i
    ,input           fetch0_instr_csr_i
    ,input           fetch0_instr_rd_valid_i
    ,input           fetch0_instr_invalid_i
    ,input           fetch1_valid_i
    ,input  [ 31:0]  fetch1_instr_i
    ,input  [ 31:0]  fetch1_pc_i
    ,input           fetch1_pred_branch_i
    ,input  [ 31:0]  fetch1_pred_pc_i
    ,input           fetch1_fault_fetch_i
    ,input           fetch1_fault_page_i
    ,input  [  5:0]  fetch1_fault_ecode_i
    ,input  [ 31:0]  fetch1_fault_addr_i
    ,input           fetch1_instr_exec_i
    ,input           fetch1_instr_lsu_i
    ,input           fetch1_instr_branch_i
    ,input           fetch1_instr_mul_i
    ,input           fetch1_instr_div_i
    ,input           fetch1_instr_csr_i
    ,input           fetch1_instr_rd_valid_i
    ,input           fetch1_instr_invalid_i
    ,input           branch_exec0_request_i
    ,input           branch_exec0_is_taken_i
    ,input           branch_exec0_is_not_taken_i
    ,input  [ 31:0]  branch_exec0_source_i
    ,input           branch_exec0_is_call_i
    ,input           branch_exec0_is_ret_i
    ,input           branch_exec0_is_jmp_i
    ,input  [ 31:0]  branch_exec0_pc_i
    ,input           branch_d_exec0_request_i
    ,input  [ 31:0]  branch_d_exec0_pc_i
    ,input  [  1:0]  branch_d_exec0_priv_i
    ,input           branch_exec1_request_i
    ,input           branch_exec1_is_taken_i
    ,input           branch_exec1_is_not_taken_i
    ,input  [ 31:0]  branch_exec1_source_i
    ,input           branch_exec1_is_call_i
    ,input           branch_exec1_is_ret_i
    ,input           branch_exec1_is_jmp_i
    ,input  [ 31:0]  branch_exec1_pc_i
    ,input           branch_d_exec1_request_i
    ,input  [ 31:0]  branch_d_exec1_pc_i
    ,input  [  1:0]  branch_d_exec1_priv_i
    ,input           branch_csr_request_i
    ,input  [ 31:0]  branch_csr_pc_i
    ,input  [  1:0]  branch_csr_priv_i
    ,input  [ 31:0]  writeback_exec0_value_i
    ,input  [ 31:0]  writeback_exec1_value_i
    ,input           writeback_mem_valid_i
    ,input           writeback_mem_pipe1_i
    ,input  [ 31:0]  writeback_mem_value_i
    ,input  [  5:0]  writeback_mem_exception_i
    ,input  [  5:0]  writeback_mem_exception_ecode_i
    ,input           writeback_mul_valid_i
    ,input  [ 31:0]  writeback_mul_value_i
    ,input           writeback_div_valid_i
    ,input  [ 31:0]  writeback_div_value_i
    ,input  [ 31:0]  csr_result_e1_value_i
    ,input           csr_result_e1_write_i
    ,input  [ 31:0]  csr_result_e1_wdata_i
    ,input  [  5:0]  csr_result_e1_exception_i
    ,input           lsu_stall_i
    ,input           lsu_skid_ready_i
    ,input           take_interrupt_i
    ,input  [  1:0]  current_priv_i

    // Outputs
    ,output          fetch0_accept_o
    ,output          fetch1_accept_o
    ,output          branch_request_o
    ,output [ 31:0]  branch_pc_o
    ,output [  1:0]  branch_priv_o
    ,output          branch_info_request_o
    ,output          branch_info_is_taken_o
    ,output          branch_info_is_not_taken_o
    ,output [ 31:0]  branch_info_source_o
    ,output          branch_info_is_call_o
    ,output          branch_info_is_ret_o
    ,output          branch_info_is_jmp_o
    ,output [ 31:0]  branch_info_pc_o
    ,output          exec0_opcode_valid_o
    ,output          exec1_opcode_valid_o
    ,output          lsu_opcode_valid_o
    ,output          csr_opcode_valid_o
    ,output          mul_opcode_valid_o
    ,output          div_opcode_valid_o
    ,output [ 31:0]  opcode0_opcode_o
    ,output [ 31:0]  opcode0_pc_o
    ,output          opcode0_invalid_o
    ,output [  4:0]  opcode0_rd_idx_o
    ,output [  4:0]  opcode0_ra_idx_o
    ,output [  4:0]  opcode0_rb_idx_o
    ,output [  3:0]  opcode0_alu_func_o
    ,output [  1:0]  opcode0_alu_a_sel_o
    ,output [  1:0]  opcode0_alu_b_sel_o
    ,output [  3:0]  opcode0_direct_func_o
    ,output [  3:0]  opcode0_branch_func_o
    ,output [ 31:0]  opcode0_imm_o
    ,output [ 31:0]  opcode0_ra_operand_o
    ,output [ 31:0]  opcode0_rb_operand_o
    ,output [ 31:0]  opcode1_opcode_o
    ,output [ 31:0]  opcode1_pc_o
    ,output          opcode1_invalid_o
    ,output [  4:0]  opcode1_rd_idx_o
    ,output [  4:0]  opcode1_ra_idx_o
    ,output [  4:0]  opcode1_rb_idx_o
    ,output [  3:0]  opcode1_alu_func_o
    ,output [  1:0]  opcode1_alu_a_sel_o
    ,output [  1:0]  opcode1_alu_b_sel_o
    ,output [  3:0]  opcode1_direct_func_o
    ,output [  3:0]  opcode1_branch_func_o
    ,output [ 31:0]  opcode1_imm_o
    ,output [ 31:0]  opcode1_ra_operand_o
    ,output [ 31:0]  opcode1_rb_operand_o
    ,output [ 31:0]  lsu_opcode_opcode_o
    ,output [ 31:0]  lsu_opcode_pc_o
    ,output          lsu_opcode_invalid_o
    ,output [  4:0]  lsu_opcode_rd_idx_o
    ,output [  4:0]  lsu_opcode_ra_idx_o
    ,output [  4:0]  lsu_opcode_rb_idx_o
    ,output [ 31:0]  lsu_opcode_ra_operand_o
    ,output [ 31:0]  lsu_opcode_rb_operand_o
    ,output          lsu_opcode_pipe1_o
    ,output [ 31:0]  mul_opcode_opcode_o
    ,output [ 31:0]  mul_opcode_pc_o
    ,output          mul_opcode_invalid_o
    ,output [  4:0]  mul_opcode_rd_idx_o
    ,output [  4:0]  mul_opcode_ra_idx_o
    ,output [  4:0]  mul_opcode_rb_idx_o
    ,output [ 31:0]  mul_opcode_ra_operand_o
    ,output [ 31:0]  mul_opcode_rb_operand_o
    ,output [ 31:0]  csr_opcode_opcode_o
    ,output [ 31:0]  csr_opcode_pc_o
    ,output          csr_opcode_invalid_o
    ,output [  4:0]  csr_opcode_rd_idx_o
    ,output [  4:0]  csr_opcode_ra_idx_o
    ,output [  4:0]  csr_opcode_rb_idx_o
    ,output [ 31:0]  csr_opcode_ra_operand_o
    ,output [ 31:0]  csr_opcode_rb_operand_o
    ,output          csr_writeback_write_o
    ,output          csr_writeback_valid_o
    ,output [ 13:0]  csr_writeback_waddr_o
    ,output [ 31:0]  csr_writeback_wdata_o
    ,output [  5:0]  csr_writeback_exception_o
    ,output [  5:0]  csr_writeback_exception_ecode_o
    ,output [ 31:0]  csr_writeback_exception_pc_o
    ,output [ 31:0]  csr_writeback_exception_addr_o
    ,output          exec0_hold_o
    ,output          exec1_hold_o
    ,output          mul_hold_o
    ,output          interrupt_inhibit_o

`ifdef CPU_REAL_MDU
    ,input           writeback_mul_pipe1_i
    ,input           mul_accept_one_i
    ,input           mul_accept_two_i
    ,output          mul_opcode_pipe1_o
    ,output          mul_opcode1_valid_o
    ,output [ 31:0]  mul_opcode1_opcode_o
    ,output [ 31:0]  mul_opcode1_ra_operand_o
    ,output [ 31:0]  mul_opcode1_rb_operand_o
`endif
`ifdef BPU_PERF
    ,output          bpu_perf_valid_o
    ,output          bpu_perf_is_branch_o
    ,output          bpu_perf_is_jump_o
    ,output          bpu_perf_is_ret_jirl_o
    ,output          bpu_perf_is_indirect_jirl_o
    ,output [ 31:0]  bpu_perf_pc_o
    ,output          bpu_perf_pred_taken_o
    ,output          bpu_perf_actual_taken_o
    ,output          bpu_perf_correct_o
    ,output          bpu_perf_direction_miss_o
    ,output          bpu_perf_target_miss_o
    ,output          bpu_perf_exu_flush_o
`endif
`ifdef PERF_MONI
    ,output [  2:0]  perf_iq_count_o
    ,output          perf_stall_div_o
    ,output          perf_stall_mem_o
    ,output          perf_stall_mul_o
    ,output          perf_iq_empty_o
    ,output          perf_lsu_stall_o
    ,output          perf_single_issue_o
    ,output          perf_slot1_no_inst_o
    ,output          perf_slot1_type_block_o
    ,output          perf_slot1_dep_block_o
    ,output          perf_enq_dual_o
    ,output          perf_enq_single_taken_o
    ,output          perf_enq_single_upper_o
    ,output          perf_enq_single_no_fetch1_o
    ,output          perf_iq_empty_after_flush_o
    ,output          perf_iq_empty_steady_o
`endif
);



`include "biloong_defs.v"

function [0:0] la_is_3r;
    input [31:0] inst;
begin
    la_is_3r = (inst[`LA_OP_31_26_R] == 6'h00) &&
               (inst[`LA_OP_25_22_R] == 4'h0) &&
               (inst[`LA_OP_21_20_R] == 2'h1)||
               (inst[`LA_OP_31_15_R] == 17'b11111111111111111);
end
endfunction

function [0:0] la_is_div_3r;
    input [31:0] inst;
begin
    la_is_div_3r = (inst[`LA_OP_31_26_R] == 6'h00) &&
                   (inst[`LA_OP_25_22_R] == 4'h0) &&
                   (inst[`LA_OP_21_20_R] == 2'h2) &&
                   (inst[`LA_OP_19_15_R] <= 5'h03);
end
endfunction

function [0:0] la_is_shift_imm;
    input [31:0] inst;
begin
    la_is_shift_imm = (inst[`LA_OP_31_26_R] == 6'h00) &&
                      (inst[`LA_OP_25_22_R] == 4'h1) &&
                      (inst[`LA_OP_21_20_R] == 2'h0) &&
                      ((inst[`LA_OP_19_15_R] == 5'h01) ||
                       (inst[`LA_OP_19_15_R] == 5'h09) ||
                       (inst[`LA_OP_19_15_R] == 5'h11));
end
endfunction

function [0:0] la_is_alu_i12;
    input [31:0] inst;
begin
    la_is_alu_i12 = (inst[`LA_OP_31_26_R] == 6'h00) &&
                    ((inst[`LA_OP_25_22_R] == 4'h8) ||
                     (inst[`LA_OP_25_22_R] == 4'h9) ||
                     (inst[`LA_OP_25_22_R] == 4'ha) ||
                     (inst[`LA_OP_25_22_R] == 4'hd) ||
                     (inst[`LA_OP_25_22_R] == 4'he) ||
                     (inst[`LA_OP_25_22_R] == 4'hf));
end
endfunction

function [0:0] la_is_ll_w;
    input [31:0] inst;
begin
    la_is_ll_w = (inst[`LA_OP_31_26_R] == 6'h08) && !inst[25] && !inst[24];
end
endfunction

function [0:0] la_is_sc_w;
    input [31:0] inst;
begin
    la_is_sc_w = (inst[`LA_OP_31_26_R] == 6'h08) && !inst[25] && inst[24];
end
endfunction

function [0:0] la_is_load;
    input [31:0] inst;
begin
    la_is_load = la_is_ll_w(inst) ||
                 ((inst[`LA_OP_31_26_R] == 6'h0a) &&
                  ((inst[`LA_OP_25_22_R] == 4'h0) ||
                   (inst[`LA_OP_25_22_R] == 4'h1) ||
                   (inst[`LA_OP_25_22_R] == 4'h2) ||
                   (inst[`LA_OP_25_22_R] == 4'h8) ||
                   (inst[`LA_OP_25_22_R] == 4'h9)));
end
endfunction

function [0:0] la_is_store;
    input [31:0] inst;
begin
    la_is_store = la_is_sc_w(inst) ||
                  ((inst[`LA_OP_31_26_R] == 6'h0a) &&
                   ((inst[`LA_OP_25_22_R] == 4'h4) ||
                    (inst[`LA_OP_25_22_R] == 4'h5) ||
                    (inst[`LA_OP_25_22_R] == 4'h6)));
end
endfunction

function [0:0] la_is_preld;
    input [31:0] inst;
begin
    la_is_preld = (inst[`LA_OP_31_26_R] == 6'h0a) &&
                  (inst[`LA_OP_25_22_R] == 4'hb);
end
endfunction

function [0:0] la_is_cond_branch;
    input [31:0] inst;
begin
    la_is_cond_branch = (inst[`LA_OP_31_26_R] == 6'h16) ||
                        (inst[`LA_OP_31_26_R] == 6'h17) ||
                        (inst[`LA_OP_31_26_R] == 6'h18) ||
                        (inst[`LA_OP_31_26_R] == 6'h19) ||
                        (inst[`LA_OP_31_26_R] == 6'h1a) ||
                        (inst[`LA_OP_31_26_R] == 6'h1b);
end
endfunction

function [0:0] la_is_bl;
    input [31:0] inst;
begin
    la_is_bl = (inst[`LA_OP_31_26_R] == 6'h15);
end
endfunction

function [0:0] la_is_jirl;
    input [31:0] inst;
begin
    la_is_jirl = (inst[`LA_OP_31_26_R] == 6'h13);
end
endfunction

function [0:0] la_is_csr_reg;
    input [31:0] inst;
begin
    la_is_csr_reg = (inst[`LA_OP_31_26_R] == 6'h01) && !inst[25] && !inst[24];
end
endfunction

function [0:0] la_is_csrrd;
    input [31:0] inst;
begin
    la_is_csrrd = la_is_csr_reg(inst) && (inst[`LA_RJ_R] == 5'd0);
end
endfunction

function [0:0] la_is_csrwr;
    input [31:0] inst;
begin
    la_is_csrwr = la_is_csr_reg(inst) && (inst[`LA_RJ_R] == 5'd1);
end
endfunction

function [0:0] la_is_csrxchg;
    input [31:0] inst;
begin
    la_is_csrxchg = la_is_csr_reg(inst) &&
                    (inst[`LA_RJ_R] != 5'd0) &&
                    (inst[`LA_RJ_R] != 5'd1);
end
endfunction

function [0:0] la_is_cacop;
    input [31:0] inst;
begin
    la_is_cacop = (inst[`LA_OP_31_26_R] == 6'h01) &&
                  (inst[`LA_OP_25_22_R] == 4'h8);
end
endfunction

function [0:0] la_is_valid_cacop;
    input [31:0] inst;
begin
    la_is_valid_cacop = la_is_cacop(inst) &&
                        ((inst[2:0] == 3'b000) ||
                         (inst[2:0] == 3'b001)) &&
                        (inst[4:3] != 2'b11);
end
endfunction

function [0:0] la_is_ertn;
    input [31:0] inst;
begin
    la_is_ertn = (inst[`LA_OP_31_26_R] == 6'h01) &&
                 (inst[`LA_OP_25_22_R] == 4'h9) &&
                 (inst[`LA_OP_21_20_R] == 2'h0) &&
                 (inst[`LA_OP_19_15_R] == 5'h10) &&
                 (inst[`LA_RK_R] == 5'h0e) &&
                 (inst[`LA_RJ_R] == 5'd0) &&
                 (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_tlbsrch;
    input [31:0] inst;
begin
    la_is_tlbsrch = (inst[`LA_OP_31_26_R] == 6'h01) &&
                    (inst[`LA_OP_25_22_R] == 4'h9) &&
                    (inst[`LA_OP_21_20_R] == 2'h0) &&
                    (inst[`LA_OP_19_15_R] == 5'h10) &&
                    (inst[`LA_RK_R] == 5'h0a) &&
                    (inst[`LA_RJ_R] == 5'd0) &&
                    (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_tlbrd;
    input [31:0] inst;
begin
    la_is_tlbrd = (inst[`LA_OP_31_26_R] == 6'h01) &&
                  (inst[`LA_OP_25_22_R] == 4'h9) &&
                  (inst[`LA_OP_21_20_R] == 2'h0) &&
                  (inst[`LA_OP_19_15_R] == 5'h10) &&
                  (inst[`LA_RK_R] == 5'h0b) &&
                  (inst[`LA_RJ_R] == 5'd0) &&
                  (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_tlbwr;
    input [31:0] inst;
begin
    la_is_tlbwr = (inst[`LA_OP_31_26_R] == 6'h01) &&
                  (inst[`LA_OP_25_22_R] == 4'h9) &&
                  (inst[`LA_OP_21_20_R] == 2'h0) &&
                  (inst[`LA_OP_19_15_R] == 5'h10) &&
                  (inst[`LA_RK_R] == 5'h0c) &&
                  (inst[`LA_RJ_R] == 5'd0) &&
                  (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_tlbfill;
    input [31:0] inst;
begin
    la_is_tlbfill = (inst[`LA_OP_31_26_R] == 6'h01) &&
                    (inst[`LA_OP_25_22_R] == 4'h9) &&
                    (inst[`LA_OP_21_20_R] == 2'h0) &&
                    (inst[`LA_OP_19_15_R] == 5'h10) &&
                    (inst[`LA_RK_R] == 5'h0d) &&
                    (inst[`LA_RJ_R] == 5'd0) &&
                    (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_idle;
    input [31:0] inst;
begin
    la_is_idle = (inst[`LA_OP_31_26_R] == 6'h01) &&
                 (inst[`LA_OP_25_22_R] == 4'h9) &&
                 (inst[`LA_OP_21_20_R] == 2'h0) &&
                 (inst[`LA_OP_19_15_R] == 5'h11);
end
endfunction

function [0:0] la_is_rdcntid_w;
    input [31:0] inst;
begin
    la_is_rdcntid_w = (inst[`LA_OP_31_26_R] == 6'h00) &&
                      (inst[`LA_OP_25_22_R] == 4'h0) &&
                      (inst[`LA_OP_21_20_R] == 2'h0) &&
                      (inst[`LA_OP_19_15_R] == 5'h00) &&
                      (inst[`LA_RK_R] == 5'h18) &&
                      (inst[`LA_RD_R] == 5'd0);
end
endfunction

function [0:0] la_is_cpucfg;
    input [31:0] inst;
begin
    la_is_cpucfg = (inst[`LA_OP_31_26_R] == 6'h00) &&
                   (inst[`LA_OP_25_22_R] == 4'h0) &&
                   (inst[`LA_OP_21_20_R] == 2'h0) &&
                   (inst[`LA_OP_19_15_R] == 5'h00) &&
                   (inst[`LA_RK_R] == 5'h1b);
end
endfunction

function [0:0] la_is_invtlb;
    input [31:0] inst;
begin
    la_is_invtlb = (inst[`LA_OP_31_26_R] == 6'h01) &&
                   (inst[`LA_OP_25_22_R] == 4'h9) &&
                   (inst[`LA_OP_21_20_R] == 2'h0) &&
                   (inst[`LA_OP_19_15_R] == 5'h13) &&
                   (inst[`LA_RD_R] <= 5'd6);
end
endfunction

function [0:0] la_is_privileged;
    input [31:0] inst;
begin
    la_is_privileged = la_is_csrrd(inst) ||
                       la_is_csrwr(inst) ||
                       la_is_csrxchg(inst) ||
                       (la_is_valid_cacop(inst) && (inst[4:3] != 2'b10)) ||
                       la_is_tlbsrch(inst) ||
                       la_is_tlbrd(inst) ||
                       la_is_tlbwr(inst) ||
                       la_is_tlbfill(inst) ||
                       la_is_invtlb(inst) ||
                       la_is_ertn(inst) ||
                       la_is_idle(inst);
end
endfunction

function [0:0] la_uses_rj;
    input [31:0] inst;
begin
    la_uses_rj = la_is_3r(inst) ||
                 la_is_div_3r(inst) ||
                 la_is_shift_imm(inst) ||
                 la_is_alu_i12(inst) ||
                 la_is_load(inst) ||
                 la_is_store(inst) ||
                 la_is_preld(inst) ||
                 la_is_cond_branch(inst) ||
                 la_is_jirl(inst) ||
                 la_is_cpucfg(inst) ||
                 la_is_csrxchg(inst) ||
                 la_is_cacop(inst) ||
                 la_is_invtlb(inst);
end
endfunction

function [0:0] la_uses_rk;
    input [31:0] inst;
begin
    la_uses_rk = la_is_3r(inst) ||
                 la_is_div_3r(inst) ||
                 la_is_invtlb(inst);
end
endfunction

function [0:0] la_uses_rd_as_src;
    input [31:0] inst;
begin
    la_uses_rd_as_src = la_is_store(inst) ||
                        la_is_cond_branch(inst) ||
                        la_is_csrwr(inst) ||
                        la_is_csrxchg(inst);
end
endfunction

function [4:0] la_dest_idx;
    input [31:0] inst;
    input        rd_valid;
begin
    if (!rd_valid)
        la_dest_idx = 5'd0;
    else if (la_is_bl(inst))
        la_dest_idx = 5'd1;
    else if (la_is_rdcntid_w(inst))
        la_dest_idx = inst[`LA_RJ_R];
    else
        la_dest_idx = inst[`LA_RD_R];
end
endfunction

function [4:0] la_predecode_ra_idx;
    input [31:0] inst;
begin
    la_predecode_ra_idx = la_uses_rj(inst) ? inst[`LA_RJ_R] : 5'd0;
end
endfunction

function [4:0] la_predecode_rb_idx;
    input [31:0] inst;
begin
    la_predecode_rb_idx = la_uses_rk(inst) ? inst[`LA_RK_R] :
                          la_uses_rd_as_src(inst) ? inst[`LA_RD_R] : 5'd0;
end
endfunction

function [4:0] la_predecode_rd_idx;
    input [31:0] inst;
    input        rd_valid;
begin
    la_predecode_rd_idx = la_dest_idx(inst, rd_valid);
end
endfunction

function [`EXEC_INFO_W-1:0] la_predecode_exec_info;
    input [31:0] inst;
    reg [31:15] op_31_15;
    reg [5:0] op_31_26;
    reg [3:0] op_25_22;
    reg [1:0] op_21_20;
    reg [4:0] op_19_15;
    reg [3:0] alu_func;
    reg [1:0] alu_a_sel;
    reg [1:0] alu_b_sel;
    reg [3:0] direct_func;
    reg [3:0] branch_func;
    reg [31:0] imm;
begin
    op_31_15 = inst[`LA_OP_31_15_R];
    op_31_26 = inst[`LA_OP_31_26_R];
    op_25_22 = inst[`LA_OP_25_22_R];
    op_21_20 = inst[`LA_OP_21_20_R];
    op_19_15 = inst[`LA_OP_19_15_R];

    alu_func    = `ALU_NONE;
    alu_a_sel   = `EXEC_ALU_A_ZERO;
    alu_b_sel   = `EXEC_ALU_B_ZERO;
    direct_func = `EXEC_DIRECT_NONE;
    branch_func = `EXEC_BRANCH_NONE;
    imm         = 32'b0;

    if(op_31_15 == 17'b11111111111111111)
    begin
        alu_a_sel   = `EXEC_ALU_A_RA;
        alu_b_sel   = `EXEC_ALU_B_RB;
        direct_func = `EXEC_DIRECT_BDOT;
    end
    else if ((op_31_26 == 6'h00) && (op_25_22 == 4'h0) && (op_21_20 == 2'h1))
    begin
        alu_a_sel = `EXEC_ALU_A_RA;
        alu_b_sel = `EXEC_ALU_B_RB;
        case (op_19_15)
        5'h00: alu_func = `ALU_ADD;
        5'h02: alu_func = `ALU_SUB;
        5'h04: alu_func = `ALU_LESS_THAN_SIGNED;
        5'h05: alu_func = `ALU_LESS_THAN;
        5'h08: direct_func = `EXEC_DIRECT_NOR;
        5'h09: alu_func = `ALU_AND;
        5'h0a: alu_func = `ALU_OR;
        5'h0b: alu_func = `ALU_XOR;
        5'h0c: direct_func = `EXEC_DIRECT_ORN;
        5'h0d: direct_func = `EXEC_DIRECT_ANDN;
        5'h0e: alu_func = `ALU_SHIFTL;
        5'h0f: alu_func = `ALU_SHIFTR;
        5'h10: alu_func = `ALU_SHIFTR_ARITH;
        default: ;
        endcase
    end
    else if ((op_31_26 == 6'h00) && (op_25_22 == 4'h1) &&
             (op_21_20 == 2'h0))
    begin
        alu_a_sel = `EXEC_ALU_A_RA;
        alu_b_sel = `EXEC_ALU_B_IMM;
        imm       = {27'b0, inst[`LA_RK_R]};
        case (op_19_15)
        5'h01: alu_func = `ALU_SHIFTL;
        5'h09: alu_func = `ALU_SHIFTR;
        5'h11: alu_func = `ALU_SHIFTR_ARITH;
        default: ;
        endcase
    end
    else if ((op_31_26 == 6'h00) &&
             ((op_25_22 == 4'h8) || (op_25_22 == 4'h9) ||
              (op_25_22 == 4'ha) || (op_25_22 == 4'hd) ||
              (op_25_22 == 4'he) || (op_25_22 == 4'hf)))
    begin
        alu_a_sel = `EXEC_ALU_A_RA;
        alu_b_sel = `EXEC_ALU_B_IMM;
        imm       = ((op_25_22 == 4'hd) || (op_25_22 == 4'he) ||
                     (op_25_22 == 4'hf)) ? {20'd0, inst[21:10]} :
                                           {{20{inst[21]}}, inst[21:10]};
        case (op_25_22)
        4'h8: alu_func = `ALU_LESS_THAN_SIGNED;
        4'h9: alu_func = `ALU_LESS_THAN;
        4'ha: alu_func = `ALU_ADD;
        4'hd: alu_func = `ALU_AND;
        4'he: alu_func = `ALU_OR;
        4'hf: alu_func = `ALU_XOR;
        default: ;
        endcase
    end
    else if ((op_31_26 == 6'h05) && !inst[25])
    begin
        alu_a_sel   = `EXEC_ALU_A_IMM;
        direct_func = `EXEC_DIRECT_LU12;
        imm         = {inst[24:5], 12'b0};
    end
    else if ((op_31_26 == 6'h06) && !inst[25])
    begin
        alu_func  = `ALU_ADD;
        alu_a_sel = `EXEC_ALU_A_PC;
        alu_b_sel = `EXEC_ALU_B_IMM;
        imm       = {{10{inst[24]}}, inst[24:5], 2'b0};
    end
    else if ((op_31_26 == 6'h07) && !inst[25])
    begin
        alu_func  = `ALU_ADD;
        alu_a_sel = `EXEC_ALU_A_PC;
        alu_b_sel = `EXEC_ALU_B_IMM;
        imm       = {inst[24:5], 12'b0};
    end
    else if (op_31_26 == 6'h15)
    begin
        alu_func    = `ALU_ADD;
        alu_a_sel   = `EXEC_ALU_A_PC;
        alu_b_sel   = `EXEC_ALU_B_FOUR;
        branch_func = `EXEC_BRANCH_BL;
        imm         = {{4{inst[9]}}, inst[9:0], inst[25:10], 2'b0};
    end
    else if (op_31_26 == 6'h14)
    begin
        branch_func = `EXEC_BRANCH_B;
        imm         = {{4{inst[9]}}, inst[9:0], inst[25:10], 2'b0};
    end
    else if (op_31_26 == 6'h13)
    begin
        alu_func    = `ALU_ADD;
        alu_a_sel   = `EXEC_ALU_A_PC;
        alu_b_sel   = `EXEC_ALU_B_FOUR;
        branch_func = `EXEC_BRANCH_JIRL;
        imm         = {{14{inst[25]}}, inst[25:10], 2'b0};
    end
    
    else if ((op_31_26 >= 6'h16) && (op_31_26 <= 6'h1b))
    begin
        case (op_31_26)
        6'h16: branch_func = `EXEC_BRANCH_BEQ;
        6'h17: branch_func = `EXEC_BRANCH_BNE;
        6'h18: branch_func = `EXEC_BRANCH_BLT;
        6'h19: branch_func = `EXEC_BRANCH_BGE;
        6'h1a: branch_func = `EXEC_BRANCH_BLTU;
        6'h1b: branch_func = `EXEC_BRANCH_BGEU;
        default: ;
        endcase
        imm = {{14{inst[25]}}, inst[25:10], 2'b0};
    end
    

    la_predecode_exec_info = {alu_func, alu_a_sel, alu_b_sel,
                              direct_func, branch_func, imm};
end
endfunction

function [0:0] seq_after;
    input [15:0] a;
    input [15:0] b;
    reg   [15:0] diff;
begin
    diff = a - b;
    seq_after = (diff != 16'd0) && !diff[15];
end
endfunction

wire enable_dual_issue_w = SUPPORT_DUAL_ISSUE;
wire enable_muldiv_w     = SUPPORT_MULDIV;
wire enable_mul_bypass_w = SUPPORT_MUL_BYPASS;
wire enable_slot1_alu_w    = SUPPORT_SLOT1_ALU;
wire enable_slot1_branch_w = SUPPORT_SLOT1_BRANCH;
wire enable_slot1_mul_w    = SUPPORT_SLOT1_MUL;
wire enable_slot1_load_w   = SUPPORT_SLOT1_LOAD;
wire enable_slot1_store_w  = SUPPORT_SLOT1_STORE;

wire stall_w;
wire squash_w;
wire squash_now_w;
wire exception_issue_block_w;
reg  squash_issue_q;
reg [15:0] issue_seq_q;
wire [15:0] issue_pipe0_seq_w = issue_seq_q;
wire [15:0] issue_pipe1_seq_w = issue_seq_q + 16'd1;

//-------------------------------------------------------------
// Fetch-to-issue packet queue
//-------------------------------------------------------------
localparam ISSUE_QUEUE_DEPTH = 4;
localparam ISSUE_QUEUE_ADDR_W = 2;
localparam ISSUE_QUEUE_COUNT_W = ISSUE_QUEUE_ADDR_W + 1;
localparam [ISSUE_QUEUE_COUNT_W-1:0] ISSUE_QUEUE_DEPTH_C = ISSUE_QUEUE_DEPTH;
localparam ISSUE_INFO_BASE_W = 81;
localparam ISSUE_PREDECODE_W = 18 + `EXEC_INFO_W;
localparam ISSUE_INFO_W = ISSUE_INFO_BASE_W + ISSUE_PREDECODE_W;

wire        single_issue_w;
wire        dual_issue_w;
wire        branch_redirect_w;
wire        branch_redirect_raw_w;
wire        branch_redirect_blocked_by_exception_w;
wire [31:0] branch_redirect_pc_w;
wire [15:0] branch_redirect_seq_w;
wire        branch_mispredict_w;
wire        branch_taken_mispredict_w;
wire        branch_not_taken_mispredict_w;
reg  [31:0] pc_fetch_q;
reg   [1:0] priv_x_q;

(* ram_style = "distributed" *) reg [31:0] issue_instr0_q[ISSUE_QUEUE_DEPTH-1:0];
(* ram_style = "distributed" *) reg [31:0] issue_instr1_q[ISSUE_QUEUE_DEPTH-1:0];
(* ram_style = "distributed" *) reg [31:0] issue_pc0_q[ISSUE_QUEUE_DEPTH-1:0];
(* ram_style = "distributed" *) reg [31:0] issue_pc1_q[ISSUE_QUEUE_DEPTH-1:0];
(* ram_style = "distributed" *) reg [ISSUE_INFO_W-1:0] issue_info0_q[ISSUE_QUEUE_DEPTH-1:0];
(* ram_style = "distributed" *) reg [ISSUE_INFO_W-1:0] issue_info1_q[ISSUE_QUEUE_DEPTH-1:0];
reg        issue_valid0_q[ISSUE_QUEUE_DEPTH-1:0];
reg        issue_valid1_q[ISSUE_QUEUE_DEPTH-1:0];
reg [ISSUE_QUEUE_ADDR_W-1:0] issue_rd_ptr_q;
reg [ISSUE_QUEUE_ADDR_W-1:0] issue_wr_ptr_q;
reg [ISSUE_QUEUE_COUNT_W-1:0] issue_count_q;

reg [31:0] dispatch_instr0_q;
reg [31:0] dispatch_instr1_q;
reg [31:0] dispatch_pc0_q;
reg [31:0] dispatch_pc1_q;
reg [ISSUE_INFO_W-1:0] dispatch_info0_q;
// Pipe 1 dispatch metadata is consumed by decode, dependency, and exception
// logic.  Allow controlled register replication for the wide control bus.
(* max_fanout = 16 *) reg [ISSUE_INFO_W-1:0] dispatch_info1_q;
reg        dispatch_valid0_q;
reg        dispatch_valid1_q;
// Register-file indexes are consumed by scoreboard and RF-read logic. Keep
// them off the wide dispatch metadata bus so one metadata bit does not drive
// the entire issue/decode cone.
reg [4:0]  dispatch_ra_idx0_q;
reg [4:0]  dispatch_rb_idx0_q;
reg [4:0]  dispatch_rd_idx0_q;
reg [4:0]  dispatch_ra_idx1_q;
reg [4:0]  dispatch_rb_idx1_q;
reg [4:0]  dispatch_rd_idx1_q;

reg mispredicted_r;
reg fetch_enqueue0_r;
reg fetch_enqueue1_r;
reg [31:0] fetch_enqueue_instr0_r;
reg [31:0] fetch_enqueue_instr1_r;
reg [31:0] fetch_enqueue_pc0_r;
reg [31:0] fetch_enqueue_pc1_r;
reg [ISSUE_INFO_W-1:0] fetch_enqueue_info0_r;
reg [ISSUE_INFO_W-1:0] fetch_enqueue_info1_r;

wire issue_queue_head_valid_w = issue_count_q != {ISSUE_QUEUE_COUNT_W{1'b0}};
wire issue_queue_slot0_valid_w = issue_queue_head_valid_w && issue_valid0_q[issue_rd_ptr_q];
wire issue_queue_slot1_valid_w = issue_queue_head_valid_w && issue_valid1_q[issue_rd_ptr_q];
wire dispatch_valid_w          = dispatch_valid0_q || dispatch_valid1_q;
wire issue_slot0_valid_w      = dispatch_valid0_q;
wire issue_slot1_valid_w      = dispatch_valid1_q;
wire slot0_valid_r            = issue_slot0_valid_w;
wire slot1_valid_r            = 1'b0;

wire [31:0] issue_queue_instr0_w = issue_instr0_q[issue_rd_ptr_q];
wire [31:0] issue_queue_instr1_w = issue_instr1_q[issue_rd_ptr_q];
wire [31:0] issue_queue_pc0_w    = issue_pc0_q[issue_rd_ptr_q];
wire [31:0] issue_queue_pc1_w    = issue_pc1_q[issue_rd_ptr_q];
wire [ISSUE_INFO_W-1:0] issue_queue_info0_w = issue_info0_q[issue_rd_ptr_q];
wire [ISSUE_INFO_W-1:0] issue_queue_info1_w = issue_info1_q[issue_rd_ptr_q];
wire issue_queue_upper_only_w = issue_queue_slot1_valid_w && !issue_queue_slot0_valid_w;
wire issue_queue_valid0_norm_w = issue_queue_slot0_valid_w || issue_queue_slot1_valid_w;
wire issue_queue_valid1_norm_w = issue_queue_slot0_valid_w && issue_queue_slot1_valid_w;
wire [31:0] issue_queue_instr0_norm_w = issue_queue_upper_only_w ? issue_queue_instr1_w : issue_queue_instr0_w;
wire [31:0] issue_queue_instr1_norm_w = issue_queue_upper_only_w ? 32'b0 : issue_queue_instr1_w;
wire [31:0] issue_queue_pc0_norm_w = issue_queue_upper_only_w ? issue_queue_pc1_w : issue_queue_pc0_w;
wire [31:0] issue_queue_pc1_norm_w = issue_queue_upper_only_w ? 32'b0 : issue_queue_pc1_w;
wire [ISSUE_INFO_W-1:0] issue_queue_info0_norm_w = issue_queue_upper_only_w ? issue_queue_info1_w : issue_queue_info0_w;
wire [ISSUE_INFO_W-1:0] issue_queue_info1_norm_w = issue_queue_upper_only_w ? {ISSUE_INFO_W{1'b0}} : issue_queue_info1_w;

wire [31:0] issue_instr0_w = dispatch_instr0_q;
wire [31:0] issue_instr1_w = dispatch_instr1_q;
wire [31:0] issue_pc0_w    = dispatch_pc0_q;
wire [31:0] issue_pc1_w    = dispatch_pc1_q;
wire [ISSUE_INFO_W-1:0] issue_info0_w = dispatch_info0_q;
wire [ISSUE_INFO_W-1:0] issue_info1_w = dispatch_info1_q;

// RA/RB/RD occupy bits 65:51 in the packed issue metadata. They are copied
// into local sidebands at dispatch, leaving those high-fanout bits unused in
// the wide dispatch registers.
function [ISSUE_INFO_W-1:0] issue_info_without_reg_idx;
    input [ISSUE_INFO_W-1:0] info;
    begin
        issue_info_without_reg_idx = info;
        issue_info_without_reg_idx[65:51] = 15'b0;
    end
endfunction

wire [4:0] dispatch_ra_idx0_w = dispatch_ra_idx0_q;
wire [4:0] dispatch_rb_idx0_w = dispatch_rb_idx0_q;
wire [4:0] dispatch_rd_idx0_w = dispatch_rd_idx0_q;
wire [4:0] dispatch_ra_idx1_w = dispatch_ra_idx1_q;
wire [4:0] dispatch_rb_idx1_w = dispatch_rb_idx1_q;
wire [4:0] dispatch_rd_idx1_w = dispatch_rd_idx1_q;

wire issue0_pred_branch_w;
wire [31:0] issue0_pred_pc_w;
wire issue0_fault_fetch_w;
wire issue0_fault_page_w;
wire [5:0] issue0_fault_ecode_w;
wire [31:0] issue0_fault_addr_w;
wire issue0_instr_exec_w;
wire issue0_instr_lsu_w;
wire issue0_instr_branch_w;
wire issue0_instr_mul_w;
wire issue0_instr_div_w;
wire issue0_instr_csr_w;
wire issue0_instr_rd_valid_w;
wire issue0_instr_invalid_w;
wire [4:0] issue0_ra_idx_meta_w;
wire [4:0] issue0_rb_idx_meta_w;
wire [4:0] issue0_rd_idx_meta_w;
wire issue0_privileged_w;
wire issue0_load_w;
wire issue0_store_w;
wire [3:0] issue0_alu_func_w;
wire [1:0] issue0_alu_a_sel_w;
wire [1:0] issue0_alu_b_sel_w;
wire [3:0] issue0_direct_func_w;
wire [3:0] issue0_branch_func_w;
wire [31:0] issue0_imm_w;

wire issue1_pred_branch_w;
wire [31:0] issue1_pred_pc_w;
wire issue1_fault_fetch_w;
wire issue1_fault_page_w;
wire [5:0] issue1_fault_ecode_w;
wire [31:0] issue1_fault_addr_w;
wire issue1_instr_exec_w;
wire issue1_instr_lsu_w;
wire issue1_instr_branch_w;
wire issue1_instr_mul_w;
wire issue1_instr_div_w;
wire issue1_instr_csr_w;
wire issue1_instr_rd_valid_w;
wire issue1_instr_invalid_w;
wire [4:0] issue1_ra_idx_meta_w;
wire [4:0] issue1_rb_idx_meta_w;
wire [4:0] issue1_rd_idx_meta_w;
wire issue1_privileged_w;
wire issue1_load_w;
wire issue1_store_w;
wire [3:0] issue1_alu_func_w;
wire [1:0] issue1_alu_a_sel_w;
wire [1:0] issue1_alu_b_sel_w;
wire [3:0] issue1_direct_func_w;
wire [3:0] issue1_branch_func_w;
wire [31:0] issue1_imm_w;

assign {issue0_pred_branch_w, issue0_pred_pc_w, issue0_fault_fetch_w, issue0_fault_page_w,
        issue0_fault_ecode_w, issue0_fault_addr_w, issue0_instr_exec_w,
        issue0_instr_lsu_w, issue0_instr_branch_w, issue0_instr_mul_w,
        issue0_instr_div_w, issue0_instr_csr_w, issue0_instr_rd_valid_w,
        issue0_instr_invalid_w, issue0_ra_idx_meta_w, issue0_rb_idx_meta_w,
        issue0_rd_idx_meta_w, issue0_privileged_w, issue0_load_w,
        issue0_store_w, issue0_alu_func_w, issue0_alu_a_sel_w,
        issue0_alu_b_sel_w, issue0_direct_func_w, issue0_branch_func_w,
        issue0_imm_w} = issue_info0_w;

assign {issue1_pred_branch_w, issue1_pred_pc_w, issue1_fault_fetch_w, issue1_fault_page_w,
        issue1_fault_ecode_w, issue1_fault_addr_w, issue1_instr_exec_w,
        issue1_instr_lsu_w, issue1_instr_branch_w, issue1_instr_mul_w,
        issue1_instr_div_w, issue1_instr_csr_w, issue1_instr_rd_valid_w,
        issue1_instr_invalid_w, issue1_ra_idx_meta_w, issue1_rb_idx_meta_w,
        issue1_rd_idx_meta_w, issue1_privileged_w, issue1_load_w,
        issue1_store_w, issue1_alu_func_w, issue1_alu_a_sel_w,
        issue1_alu_b_sel_w, issue1_direct_func_w, issue1_branch_func_w,
        issue1_imm_w} = issue_info1_w;

wire [4:0] issue0_ra_idx_pre_w = dispatch_ra_idx0_w;
wire [4:0] issue0_rb_idx_pre_w = dispatch_rb_idx0_w;
wire [4:0] issue0_rd_idx_pre_w = dispatch_rd_idx0_w;
wire [4:0] issue1_ra_idx_pre_w = dispatch_ra_idx1_w;
wire [4:0] issue1_rb_idx_pre_w = dispatch_rb_idx1_w;
wire [4:0] issue1_rd_idx_pre_w = dispatch_rd_idx1_w;

wire fetch_enqueue_raw_w   = fetch_enqueue0_r | fetch_enqueue1_r;
wire fetch_enqueue_upper_only_w = fetch_enqueue1_r && !fetch_enqueue0_r;
wire fetch_irq_empty_enqueue_w = take_interrupt_i && !dispatch_valid_w &&
                                 !issue_queue_head_valid_w && fetch_enqueue_raw_w;
wire fetch_enqueue_w       = fetch_enqueue_raw_w &
                             (~take_interrupt_i | fetch_irq_empty_enqueue_w);
wire [31:0] fetch_enqueue_seq_pc_w = fetch_enqueue_upper_only_w ? (fetch_enqueue_pc1_r + 32'd4) :
                                     fetch_enqueue1_r           ? (fetch_enqueue_pc1_r + 32'd4) :
                                                                 (fetch_enqueue_pc0_r + 32'd4);
wire [31:0] fetch_enqueue_next_pc_w =
    (fetch_enqueue1_r && fetch1_pred_branch_i) ? fetch1_pred_pc_i :
    (fetch_enqueue0_r && fetch0_pred_branch_i) ? fetch0_pred_pc_i :
                                                  fetch_enqueue_seq_pc_w;
wire fetch_enqueue_valid0_norm_w = fetch_enqueue0_r || fetch_enqueue1_r;
wire fetch_enqueue_valid1_norm_w = fetch_enqueue0_r && fetch_enqueue1_r;
wire [31:0] fetch_enqueue_instr0_norm_w = fetch_enqueue_upper_only_w ? fetch_enqueue_instr1_r : fetch_enqueue_instr0_r;
wire [31:0] fetch_enqueue_instr1_norm_w = fetch_enqueue_upper_only_w ? 32'b0 : fetch_enqueue_instr1_r;
wire [31:0] fetch_enqueue_pc0_norm_w = fetch_enqueue_upper_only_w ? fetch_enqueue_pc1_r : fetch_enqueue_pc0_r;
wire [31:0] fetch_enqueue_pc1_norm_w = fetch_enqueue_upper_only_w ? 32'b0 : fetch_enqueue_pc1_r;
wire [ISSUE_INFO_W-1:0] fetch_enqueue_info0_norm_w = fetch_enqueue_upper_only_w ? fetch_enqueue_info1_r : fetch_enqueue_info0_r;
wire [ISSUE_INFO_W-1:0] fetch_enqueue_info1_norm_w = fetch_enqueue_upper_only_w ? {ISSUE_INFO_W{1'b0}} : fetch_enqueue_info1_r;
wire        branch_redirect_flush_w = branch_redirect_w;

reg         opcode_a_issue_r;
reg         opcode_a_accept_r;
reg         opcode_b_issue_r;
reg         opcode_b_accept_r;

wire        issue_pipe_release_w = !stall_w;
wire        opcode_a_issue_w     = opcode_a_issue_r  & issue_pipe_release_w;
wire        opcode_a_accept_w    = opcode_a_accept_r & issue_pipe_release_w;
wire        opcode_b_issue_w     = opcode_b_issue_r  & issue_pipe_release_w;
wire        opcode_b_accept_w    = opcode_b_accept_r & issue_pipe_release_w;
`ifdef CPU_REAL_MDU
wire        opcode_a_seq_accept_w = opcode_a_accept_w;
wire        opcode_b_seq_accept_w = opcode_b_accept_w;
`else
wire        opcode_a_seq_accept_w = opcode_a_accept_r;
wire        opcode_b_seq_accept_w = opcode_b_accept_r;
`endif

wire issue_pop0_w         = slot0_valid_r && opcode_a_accept_w && ~take_interrupt_i &&
                            !exception_issue_block_w;
wire issue_pop1_w         = ((slot1_valid_r && opcode_a_accept_w) || opcode_b_accept_w) &&
                            ~take_interrupt_i && !exception_issue_block_w;
wire issue_pop_complete_w = dispatch_valid_w &&
                            (((issue_pop0_w && !issue_slot1_valid_w) ||
                              (issue_pop1_w && !issue_slot0_valid_w) ||
                              (issue_pop0_w && issue_pop1_w)));
// Keep fetch enqueue independent of current-cycle issue pop. This avoids a long
// exception/issue-pop feedback path into the frontend PC tracking state.
wire issue_queue_accept_w  = issue_count_q != ISSUE_QUEUE_DEPTH_C;
wire dispatch_can_load_w   = !dispatch_valid_w || issue_pop_complete_w;
wire dispatch_load_queue_w = dispatch_can_load_w && issue_queue_head_valid_w;
wire dispatch_load_fetch_w = dispatch_can_load_w && !issue_queue_head_valid_w &&
                             fetch_enqueue_w;
wire issue_queue_enqueue_w = fetch_enqueue_w && !dispatch_load_fetch_w;
wire issue_queue_dequeue_w = dispatch_load_queue_w;

wire        issue_a_pred_branch_w = issue0_pred_branch_w;
wire [31:0] issue_a_pred_pc_w     = issue0_pred_pc_w;
wire        issue_b_pred_branch_w = issue1_pred_branch_w;
wire [31:0] issue_b_pred_pc_w     = issue1_pred_pc_w;

reg         pipe0_pred_branch_e1_q;
reg         pipe1_pred_branch_e1_q;
reg  [31:0] pipe0_pred_pc_e1_q;
reg  [31:0] pipe1_pred_pc_e1_q;

assign branch_taken_mispredict_w =
    (pipe1_branch_e1_w && branch_exec1_request_i && branch_exec1_is_taken_i &&
     (!pipe1_pred_branch_e1_q || (branch_exec1_pc_i != pipe1_pred_pc_e1_q))) ||
    (pipe0_branch_e1_w && branch_exec0_request_i && branch_exec0_is_taken_i &&
     (!pipe0_pred_branch_e1_q || (branch_exec0_pc_i != pipe0_pred_pc_e1_q)));

assign branch_not_taken_mispredict_w =
    (pipe1_branch_e1_w && branch_exec1_request_i && branch_exec1_is_not_taken_i && pipe1_pred_branch_e1_q) ||
    (pipe0_branch_e1_w && branch_exec0_request_i && branch_exec0_is_not_taken_i && pipe0_pred_branch_e1_q);
assign branch_redirect_raw_w = branch_taken_mispredict_w | branch_not_taken_mispredict_w;
assign branch_redirect_w     = branch_redirect_raw_w & ~branch_redirect_blocked_by_exception_w;
assign branch_redirect_pc_w = branch_taken_mispredict_w ?
                              ((pipe1_branch_e1_w && branch_exec1_request_i && branch_exec1_is_taken_i) ?
                               branch_exec1_pc_i : branch_exec0_pc_i) :
                              (pipe1_branch_e1_w && branch_exec1_request_i ? branch_exec1_pc_i : branch_exec0_pc_i);
assign branch_redirect_seq_w = (pipe1_branch_e1_w && branch_exec1_request_i) ? pipe1_seq_e1_w : pipe0_seq_e1_w;
assign branch_mispredict_w  = mispredicted_r | branch_redirect_w;
wire issue_flush_kill_w     = branch_csr_request_i | branch_redirect_w | squash_w;
wire issue_pipe0_valid_w;
wire issue_pipe1_valid_w;
wire issue_sideband_valid_w = ~issue_flush_kill_w & ~squash_now_w &
                              ~exception_issue_block_w;

// Branch request (CSR branch - ecall, xret, or branch misprediction)
// Note: Correctly predicted branches remain silent to the frontend.
assign branch_request_o = branch_csr_request_i | branch_mispredict_w;
assign branch_pc_o      = branch_csr_request_i ? branch_csr_pc_i :
                          branch_redirect_w ? branch_redirect_pc_w :
                                                    pc_fetch_q;
assign branch_priv_o    = branch_csr_request_i ? branch_csr_priv_i : priv_x_q;

integer issue_q_i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    pc_fetch_q <= 32'b0;
    priv_x_q <= `PRIV_MACHINE;
    pipe0_pred_branch_e1_q <= 1'b0;
    pipe1_pred_branch_e1_q <= 1'b0;
    pipe0_pred_pc_e1_q <= 32'b0;
    pipe1_pred_pc_e1_q <= 32'b0;
    issue_seq_q <= 16'b0;
    issue_rd_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_wr_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_count_q <= {ISSUE_QUEUE_COUNT_W{1'b0}};
    dispatch_instr0_q <= 32'b0;
    dispatch_instr1_q <= 32'b0;
    dispatch_pc0_q <= 32'b0;
    dispatch_pc1_q <= 32'b0;
    dispatch_info0_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_info1_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_ra_idx0_q <= 5'b0;
    dispatch_rb_idx0_q <= 5'b0;
    dispatch_rd_idx0_q <= 5'b0;
    dispatch_ra_idx1_q <= 5'b0;
    dispatch_rb_idx1_q <= 5'b0;
    dispatch_rd_idx1_q <= 5'b0;
    dispatch_valid0_q <= 1'b0;
    dispatch_valid1_q <= 1'b0;

    for (issue_q_i = 0; issue_q_i < ISSUE_QUEUE_DEPTH; issue_q_i = issue_q_i + 1)
    begin
        issue_instr0_q[issue_q_i] <= 32'b0;
        issue_instr1_q[issue_q_i] <= 32'b0;
        issue_pc0_q[issue_q_i] <= 32'b0;
        issue_pc1_q[issue_q_i] <= 32'b0;
        issue_info0_q[issue_q_i] <= {ISSUE_INFO_W{1'b0}};
        issue_info1_q[issue_q_i] <= {ISSUE_INFO_W{1'b0}};
        issue_valid0_q[issue_q_i] <= 1'b0;
        issue_valid1_q[issue_q_i] <= 1'b0;
    end
end
else if (branch_csr_request_i || branch_redirect_flush_w || squash_w)
begin
    pc_fetch_q <= branch_csr_request_i ? branch_csr_pc_i :
                  branch_redirect_flush_w ? branch_redirect_pc_w :
                                            pc_fetch_q;
    if (branch_csr_request_i)
        priv_x_q <= branch_csr_priv_i;
    pipe0_pred_branch_e1_q <= 1'b0;
    pipe1_pred_branch_e1_q <= 1'b0;
    pipe0_pred_pc_e1_q <= 32'b0;
    pipe1_pred_pc_e1_q <= 32'b0;
    issue_rd_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_wr_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_count_q <= {ISSUE_QUEUE_COUNT_W{1'b0}};
    dispatch_instr0_q <= 32'b0;
    dispatch_instr1_q <= 32'b0;
    dispatch_pc0_q <= 32'b0;
    dispatch_pc1_q <= 32'b0;
    dispatch_info0_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_info1_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_ra_idx0_q <= 5'b0;
    dispatch_rb_idx0_q <= 5'b0;
    dispatch_rd_idx0_q <= 5'b0;
    dispatch_ra_idx1_q <= 5'b0;
    dispatch_rb_idx1_q <= 5'b0;
    dispatch_rd_idx1_q <= 5'b0;
    dispatch_valid0_q <= 1'b0;
    dispatch_valid1_q <= 1'b0;

    for (issue_q_i = 0; issue_q_i < ISSUE_QUEUE_DEPTH; issue_q_i = issue_q_i + 1)
    begin
        issue_valid0_q[issue_q_i] <= 1'b0;
        issue_valid1_q[issue_q_i] <= 1'b0;
    end
end
else if (branch_mispredict_w)
begin
    pc_fetch_q <= pc_fetch_q;
    pipe0_pred_branch_e1_q <= 1'b0;
    pipe1_pred_branch_e1_q <= 1'b0;
    pipe0_pred_pc_e1_q <= 32'b0;
    pipe1_pred_pc_e1_q <= 32'b0;
    issue_rd_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_wr_ptr_q <= {ISSUE_QUEUE_ADDR_W{1'b0}};
    issue_count_q <= {ISSUE_QUEUE_COUNT_W{1'b0}};
    dispatch_instr0_q <= 32'b0;
    dispatch_instr1_q <= 32'b0;
    dispatch_pc0_q <= 32'b0;
    dispatch_pc1_q <= 32'b0;
    dispatch_info0_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_info1_q <= {ISSUE_INFO_W{1'b0}};
    dispatch_ra_idx0_q <= 5'b0;
    dispatch_rb_idx0_q <= 5'b0;
    dispatch_rd_idx0_q <= 5'b0;
    dispatch_ra_idx1_q <= 5'b0;
    dispatch_rb_idx1_q <= 5'b0;
    dispatch_rd_idx1_q <= 5'b0;
    dispatch_valid0_q <= 1'b0;
    dispatch_valid1_q <= 1'b0;

    for (issue_q_i = 0; issue_q_i < ISSUE_QUEUE_DEPTH; issue_q_i = issue_q_i + 1)
    begin
        issue_valid0_q[issue_q_i] <= 1'b0;
        issue_valid1_q[issue_q_i] <= 1'b0;
    end
end
else
begin
    if (!stall_w)
    begin
        pipe0_pred_branch_e1_q <= issue_pipe0_valid_w && issue_a_branch_w &&
                                   !issue_a_priv_fault_w && issue_a_pred_branch_w &&
                                   ~take_interrupt_i;
        pipe1_pred_branch_e1_q <= issue_pipe1_valid_w && issue_b_branch_w &&
                                   !issue_b_priv_fault_w && issue_b_pred_branch_w &&
                                   ~take_interrupt_i;
        pipe0_pred_pc_e1_q <= issue_pipe0_valid_w ? issue_a_pred_pc_w : 32'b0;
        pipe1_pred_pc_e1_q <= issue_pipe1_valid_w ? issue_b_pred_pc_w : 32'b0;
    end

    if (issue_pop0_w && !issue_pop1_w && issue_slot1_valid_w)
    begin
        dispatch_instr0_q <= dispatch_instr1_q;
        dispatch_pc0_q <= dispatch_pc1_q;
        dispatch_info0_q <= dispatch_info1_q;
        dispatch_ra_idx0_q <= dispatch_ra_idx1_q;
        dispatch_rb_idx0_q <= dispatch_rb_idx1_q;
        dispatch_rd_idx0_q <= dispatch_rd_idx1_q;
        dispatch_valid0_q <= 1'b1;
        dispatch_valid1_q <= 1'b0;
    end
    else
    begin
        if (issue_pop0_w)
            dispatch_valid0_q <= 1'b0;
        if (issue_pop1_w)
            dispatch_valid1_q <= 1'b0;

        if (dispatch_load_queue_w)
        begin
            dispatch_instr0_q <= issue_queue_instr0_norm_w;
            dispatch_instr1_q <= issue_queue_instr1_norm_w;
            dispatch_pc0_q <= issue_queue_pc0_norm_w;
            dispatch_pc1_q <= issue_queue_pc1_norm_w;
            dispatch_info0_q <= issue_info_without_reg_idx(issue_queue_info0_norm_w);
            dispatch_info1_q <= issue_info_without_reg_idx(issue_queue_info1_norm_w);
            dispatch_ra_idx0_q <= issue_queue_info0_norm_w[65:61];
            dispatch_rb_idx0_q <= issue_queue_info0_norm_w[60:56];
            dispatch_rd_idx0_q <= issue_queue_info0_norm_w[55:51];
            dispatch_ra_idx1_q <= issue_queue_info1_norm_w[65:61];
            dispatch_rb_idx1_q <= issue_queue_info1_norm_w[60:56];
            dispatch_rd_idx1_q <= issue_queue_info1_norm_w[55:51];
            dispatch_valid0_q <= issue_queue_valid0_norm_w;
            dispatch_valid1_q <= issue_queue_valid1_norm_w;
        end
        else if (dispatch_load_fetch_w)
        begin
            dispatch_instr0_q <= fetch_enqueue_instr0_norm_w;
            dispatch_instr1_q <= fetch_enqueue_instr1_norm_w;
            dispatch_pc0_q <= fetch_enqueue_pc0_norm_w;
            dispatch_pc1_q <= fetch_enqueue_pc1_norm_w;
            dispatch_info0_q <= issue_info_without_reg_idx(fetch_enqueue_info0_norm_w);
            dispatch_info1_q <= issue_info_without_reg_idx(fetch_enqueue_info1_norm_w);
            dispatch_ra_idx0_q <= fetch_enqueue_info0_norm_w[65:61];
            dispatch_rb_idx0_q <= fetch_enqueue_info0_norm_w[60:56];
            dispatch_rd_idx0_q <= fetch_enqueue_info0_norm_w[55:51];
            dispatch_ra_idx1_q <= fetch_enqueue_info1_norm_w[65:61];
            dispatch_rb_idx1_q <= fetch_enqueue_info1_norm_w[60:56];
            dispatch_rd_idx1_q <= fetch_enqueue_info1_norm_w[55:51];
            dispatch_valid0_q <= fetch_enqueue_valid0_norm_w;
            dispatch_valid1_q <= fetch_enqueue_valid1_norm_w;
        end
    end

    if (issue_queue_dequeue_w)
    begin
        issue_valid0_q[issue_rd_ptr_q] <= 1'b0;
        issue_valid1_q[issue_rd_ptr_q] <= 1'b0;
        issue_rd_ptr_q <= issue_rd_ptr_q + {{(ISSUE_QUEUE_ADDR_W-1){1'b0}}, 1'b1};
    end

    if (issue_queue_enqueue_w)
    begin
        issue_instr0_q[issue_wr_ptr_q] <= fetch_enqueue_instr0_norm_w;
        issue_instr1_q[issue_wr_ptr_q] <= fetch_enqueue_instr1_norm_w;
        issue_pc0_q[issue_wr_ptr_q] <= fetch_enqueue_pc0_norm_w;
        issue_pc1_q[issue_wr_ptr_q] <= fetch_enqueue_pc1_norm_w;
        issue_info0_q[issue_wr_ptr_q] <= fetch_enqueue_info0_norm_w;
        issue_info1_q[issue_wr_ptr_q] <= fetch_enqueue_info1_norm_w;
        issue_valid0_q[issue_wr_ptr_q] <= fetch_enqueue_valid0_norm_w;
        issue_valid1_q[issue_wr_ptr_q] <= fetch_enqueue_valid1_norm_w;
        issue_wr_ptr_q <= issue_wr_ptr_q + {{(ISSUE_QUEUE_ADDR_W-1){1'b0}}, 1'b1};
    end

    if (fetch_enqueue_w)
        pc_fetch_q <= fetch_enqueue_next_pc_w;

    if (issue_queue_enqueue_w && !issue_queue_dequeue_w)
        issue_count_q <= issue_count_q + {{ISSUE_QUEUE_ADDR_W{1'b0}}, 1'b1};
    else if (!issue_queue_enqueue_w && issue_queue_dequeue_w)
        issue_count_q <= issue_count_q - {{ISSUE_QUEUE_ADDR_W{1'b0}}, 1'b1};

    case ({opcode_b_seq_accept_w, opcode_a_seq_accept_w})
    2'b01: issue_seq_q <= issue_seq_q + 16'd1;
    2'b11: issue_seq_q <= issue_seq_q + 16'd2;
    default: ;
    endcase
end

always @ *
begin
    mispredicted_r = 1'b0;
    fetch_enqueue0_r = 1'b0;
    fetch_enqueue1_r = 1'b0;
    fetch_enqueue_instr0_r = 32'b0;
    fetch_enqueue_instr1_r = 32'b0;
    fetch_enqueue_pc0_r = 32'b0;
    fetch_enqueue_pc1_r = 32'b0;
    fetch_enqueue_info0_r = {ISSUE_INFO_W{1'b0}};
    fetch_enqueue_info1_r = {ISSUE_INFO_W{1'b0}};

    // Flush due to CSR branch
    if (branch_csr_request_i || branch_redirect_w || squash_w)
    begin
        ;
    end
    // Word 0 valid and expected PC (word 1 may also be valid)
    else if (fetch0_valid_i && {fetch0_pc_i[31:2], 2'b0} == {pc_fetch_q[31:2], 2'b0})
    begin
        fetch_enqueue0_r = issue_queue_accept_w;
        fetch_enqueue1_r = issue_queue_accept_w && fetch1_valid_i && !fetch0_pred_branch_i;
        fetch_enqueue_instr0_r = fetch0_instr_i;
        fetch_enqueue_instr1_r = fetch1_instr_i;
        fetch_enqueue_pc0_r = fetch0_pc_i;
        fetch_enqueue_pc1_r = fetch1_pc_i;
        fetch_enqueue_info0_r = {fetch0_pred_branch_i, fetch0_pred_pc_i, fetch0_fault_fetch_i, fetch0_fault_page_i,
                                 fetch0_fault_ecode_i, fetch0_fault_addr_i, fetch0_instr_exec_i,
                                 fetch0_instr_lsu_i, fetch0_instr_branch_i, fetch0_instr_mul_i,
                                 fetch0_instr_div_i, fetch0_instr_csr_i, fetch0_instr_rd_valid_i,
                                 fetch0_instr_invalid_i, la_predecode_ra_idx(fetch0_instr_i),
                                 la_predecode_rb_idx(fetch0_instr_i),
                                 la_predecode_rd_idx(fetch0_instr_i, fetch0_instr_rd_valid_i),
                                 la_is_privileged(fetch0_instr_i), la_is_load(fetch0_instr_i),
                                 la_is_store(fetch0_instr_i),
                                 la_predecode_exec_info(fetch0_instr_i)};
        fetch_enqueue_info1_r = {fetch1_pred_branch_i, fetch1_pred_pc_i, fetch1_fault_fetch_i, fetch1_fault_page_i,
                                 fetch1_fault_ecode_i, fetch1_fault_addr_i, fetch1_instr_exec_i,
                                 fetch1_instr_lsu_i, fetch1_instr_branch_i, fetch1_instr_mul_i,
                                 fetch1_instr_div_i, fetch1_instr_csr_i, fetch1_instr_rd_valid_i,
                                 fetch1_instr_invalid_i, la_predecode_ra_idx(fetch1_instr_i),
                                 la_predecode_rb_idx(fetch1_instr_i),
                                 la_predecode_rd_idx(fetch1_instr_i, fetch1_instr_rd_valid_i),
                                 la_is_privileged(fetch1_instr_i), la_is_load(fetch1_instr_i),
                                 la_is_store(fetch1_instr_i),
                                 la_predecode_exec_info(fetch1_instr_i)};
    end
    // Word 1 valid and expected PC
    else if (fetch1_valid_i && {fetch1_pc_i[31:2], 2'b0} == {pc_fetch_q[31:2], 2'b0})
    begin
        fetch_enqueue1_r = issue_queue_accept_w;
        fetch_enqueue_instr1_r = fetch1_instr_i;
        fetch_enqueue_pc1_r = fetch1_pc_i;
        fetch_enqueue_info1_r = {fetch1_pred_branch_i, fetch1_pred_pc_i, fetch1_fault_fetch_i, fetch1_fault_page_i,
                                 fetch1_fault_ecode_i, fetch1_fault_addr_i, fetch1_instr_exec_i,
                                 fetch1_instr_lsu_i, fetch1_instr_branch_i, fetch1_instr_mul_i,
                                 fetch1_instr_div_i, fetch1_instr_csr_i, fetch1_instr_rd_valid_i,
                                 fetch1_instr_invalid_i, la_predecode_ra_idx(fetch1_instr_i),
                                 la_predecode_rb_idx(fetch1_instr_i),
                                 la_predecode_rd_idx(fetch1_instr_i, fetch1_instr_rd_valid_i),
                                 la_is_privileged(fetch1_instr_i), la_is_load(fetch1_instr_i),
                                 la_is_store(fetch1_instr_i),
                                 la_predecode_exec_info(fetch1_instr_i)};
    end
    // Neither word is the expected PC - must be a branch misprediction
    else if (fetch0_valid_i || fetch1_valid_i)
        mispredicted_r = 1'b1;
end

//-------------------------------------------------------------
// Instruction Decoder
//-------------------------------------------------------------
reg        opcode_a_valid_r;
reg        opcode_b_valid_r;
reg [1:0]  opcode_a_fault_r;
reg [1:0]  opcode_b_fault_r;
reg [5:0]  opcode_a_fault_ecode_r;
reg [5:0]  opcode_b_fault_ecode_r;
reg [31:0] opcode_a_fault_addr_r;
reg [31:0] opcode_b_fault_addr_r;
reg [31:0] opcode_a_r;
reg [31:0] opcode_b_r;
reg [31:0] opcode_a_pc_r;
reg [31:0] opcode_b_pc_r;
`ifdef BPU_PERF
reg        opcode_a_pred_branch_r;
reg        opcode_b_pred_branch_r;
`endif

always @ *
begin
    opcode_a_r       = 32'b0;
    opcode_b_r       = 32'b0;
    opcode_a_valid_r = 1'b0;
    opcode_b_valid_r = 1'b0;
`ifdef BPU_PERF
    opcode_a_pred_branch_r = 1'b0;
    opcode_b_pred_branch_r = 1'b0;
`endif
    opcode_a_fault_r = 2'b0;
    opcode_b_fault_r = 2'b0;
    opcode_a_fault_ecode_r = 6'b0;
    opcode_b_fault_ecode_r = 6'b0;
    opcode_a_fault_addr_r = 32'b0;
    opcode_b_fault_addr_r = 32'b0;
    opcode_a_pc_r    = 32'b0;
    opcode_b_pc_r    = 32'b0;

    // Word 0 (and possibly slot 1) are valid instructions
    if (slot0_valid_r)
    begin
        opcode_a_valid_r = 1'b1;
        opcode_b_valid_r = issue_slot1_valid_w;
        opcode_a_r       = issue_instr0_w;
        opcode_a_pc_r    = issue_pc0_w;
`ifdef BPU_PERF
        opcode_a_pred_branch_r = issue0_pred_branch_w;
`endif
        opcode_a_fault_r = {issue0_fault_page_w, issue0_fault_fetch_w};
        opcode_a_fault_ecode_r = issue0_fault_ecode_w;
        opcode_a_fault_addr_r = issue0_fault_addr_w;
        opcode_b_r       = issue_instr1_w;
        opcode_b_pc_r    = issue_pc1_w;
`ifdef BPU_PERF
        opcode_b_pred_branch_r = issue1_pred_branch_w;
`endif
        opcode_b_fault_r = {issue1_fault_page_w, issue1_fault_fetch_w};
        opcode_b_fault_ecode_r = issue1_fault_ecode_w;
        opcode_b_fault_addr_r = issue1_fault_addr_w;
    end
end

wire       issue_a_sb_alloc_w = issue0_instr_rd_valid_w;
wire       issue_a_exec_w     = issue0_instr_exec_w;
wire       issue_a_lsu_w      = issue0_instr_lsu_w;
wire       issue_a_branch_w   = issue0_instr_branch_w;
wire       issue_a_mul_w      = issue0_instr_mul_w;
wire       issue_a_div_w      = issue0_instr_div_w;
wire       issue_a_csr_w      = issue0_instr_csr_w;
wire       issue_a_invalid_w  = issue0_instr_invalid_w;
wire       issue_a_fault_any_w = |opcode_a_fault_r;
wire       issue_a_priv_fault_w = opcode_a_valid_r && !issue_a_invalid_w &&
                                  !issue_a_fault_any_w &&
                                  (current_priv_i == 2'b11) &&
                                  issue0_privileged_w;
wire       issue_head_csr_w     = opcode_a_valid_r && issue_a_csr_w &&
                                  !issue_a_priv_fault_w && issue_sideband_valid_w;
wire       issue_head_csr_irq_hold_w = take_interrupt_i && issue_head_csr_w;
wire       issue_a_regs_valid_w = opcode_a_valid_r && !issue_a_invalid_w &&
                                  !issue_a_fault_any_w && !issue_a_priv_fault_w;
wire [4:0] issue_a_ra_idx_w   = issue_a_regs_valid_w ? issue0_ra_idx_pre_w : 5'd0;
wire [4:0] issue_a_rb_idx_w   = issue_a_regs_valid_w ? issue0_rb_idx_pre_w : 5'd0;
wire [4:0] issue_a_rd_idx_w   = issue_a_regs_valid_w ? issue0_rd_idx_pre_w : 5'd0;
// Raw RF read indexes: gated only by slot-valid, not by fault/invalid/priv.
// This shortens the timing cone into the regfile read mux. Architectural
// gating (scoreboard, forwarding, x0 force-zero, opcode*_ra_idx_o) still uses
// the fault-gated issue_*_idx_w above.
wire [4:0] issue_a_ra_idx_rf_w = opcode_a_valid_r ? issue0_ra_idx_pre_w : 5'd0;
wire [4:0] issue_a_rb_idx_rf_w = opcode_a_valid_r ? issue0_rb_idx_pre_w : 5'd0;


wire       issue_b_sb_alloc_w = issue1_instr_rd_valid_w;
wire       issue_b_exec_w     = issue1_instr_exec_w;
wire       issue_b_lsu_w      = issue1_instr_lsu_w;
wire       issue_b_branch_w   = issue1_instr_branch_w;
wire       issue_b_mul_w      = issue1_instr_mul_w;
wire       issue_b_div_w      = issue1_instr_div_w;
wire       issue_b_csr_w      = issue1_instr_csr_w;
wire       issue_b_invalid_w  = issue1_instr_invalid_w;
wire       issue_b_fault_any_w = |opcode_b_fault_r;
wire       issue_b_priv_fault_w = opcode_b_valid_r && !issue_b_invalid_w &&
                                  !issue_b_fault_any_w &&
                                  (current_priv_i == 2'b11) &&
                                  issue1_privileged_w;
wire       issue_b_regs_valid_w = opcode_b_valid_r && !issue_b_invalid_w &&
                                  !issue_b_fault_any_w && !issue_b_priv_fault_w;
wire [4:0] issue_b_ra_idx_w   = issue_b_regs_valid_w ? issue1_ra_idx_pre_w : 5'd0;
wire [4:0] issue_b_rb_idx_w   = issue_b_regs_valid_w ? issue1_rb_idx_pre_w : 5'd0;
wire [4:0] issue_b_rd_idx_w   = issue_b_regs_valid_w ? issue1_rd_idx_pre_w : 5'd0;
wire [4:0] issue_b_ra_idx_rf_w = opcode_b_valid_r ? issue1_ra_idx_pre_w : 5'd0;
wire [4:0] issue_b_rb_idx_rf_w = opcode_b_valid_r ? issue1_rb_idx_pre_w : 5'd0;

`ifdef CPU_REAL_MDU
wire       issue_a_pipe_mul_w = 1'b0;
wire       issue_b_pipe_mul_w = 1'b0;
wire       issue_a_real_mdu_detach_w = issue_a_mul_w &&
                                      !issue_a_priv_fault_w && !issue_a_invalid_w &&
                                      !issue_a_fault_any_w;
wire       issue_b_real_mdu_detach_w = issue_b_mul_w &&
                                      !issue_b_priv_fault_w && !issue_b_invalid_w &&
                                      !issue_b_fault_any_w;
`else
wire       issue_a_pipe_mul_w = issue_a_mul_w;
wire       issue_b_pipe_mul_w = issue_b_mul_w;
wire       issue_a_real_mdu_detach_w = 1'b0;
wire       issue_b_real_mdu_detach_w = 1'b0;
`endif

//-------------------------------------------------------------
// Pipe0 - Status tracking
//------------------------------------------------------------- 
wire        pipe0_squash_e1_e2_w;
wire        pipe1_squash_e1_e2_w;

wire        pipe0_stall_raw_w;

wire        pipe0_load_e1_w;
wire        pipe0_store_e1_w;
wire        pipe0_mul_e1_w;
wire        pipe0_branch_e1_w;
`ifdef BPU_PERF
wire        pipe0_pred_branch_e1_w;
`endif
wire [4:0]  pipe0_rd_e1_w;
wire        pipe0_complete_e1_w;
wire [15:0] pipe0_seq_e1_w;

wire [31:0] pipe0_pc_e1_w;
wire [31:0] pipe0_opcode_e1_w;
wire [31:0] pipe0_operand_ra_e1_w;
wire [31:0] pipe0_operand_rb_e1_w;

wire        pipe0_load_e2_w;
wire        pipe0_mul_e2_w;
wire [4:0]  pipe0_rd_e2_w;
wire [31:0] pipe0_result_e2_w;
// Load E2 forwarding can use the already-selected LSU return value directly.
// This removes the generic pipe-control result mux from the load-use path;
// non-load operations retain the original result bus.
wire [31:0] pipe0_result_e2_fwd_w =
            ((SUPPORT_LOAD_BYPASS != 0) && pipe0_load_e2_w) ? writeback_mem_value_i :
                                                               pipe0_result_e2_w;
wire        pipe0_complete_e2_w;
wire [15:0] pipe0_seq_e2_w;

wire        pipe0_valid_wb_raw_w;
wire        pipe0_csr_wb_raw_w;
wire [4:0]  pipe0_rd_wb_raw_w;
wire [15:0] pipe0_seq_wb_raw_w;
wire [31:0] pipe0_result_wb_raw_w;
wire [31:0] pipe0_pc_wb_raw_w;
wire [31:0] pipe0_opc_wb_raw_w;
wire [31:0] pipe0_ra_val_wb_raw_w;
wire [31:0] pipe0_rb_val_wb_raw_w;
wire [`EXCEPTION_W-1:0] pipe0_exception_wb_raw_w;
wire [5:0]  pipe0_exception_ecode_wb_raw_w;
wire        pipe0_complete_wb_w;
wire        pipe0_squash_to_pipe1_w;
wire        pipe1_squash_to_pipe0_w;
wire        writeback_mem_valid0_w = writeback_mem_valid_i && !writeback_mem_pipe1_i;
wire        writeback_mem_valid1_w = writeback_mem_valid_i &&  writeback_mem_pipe1_i;
`ifdef CPU_REAL_MDU
wire        writeback_mul_valid0_w = writeback_mul_valid_i && !writeback_mul_pipe1_i;
wire        writeback_mul_valid1_w = writeback_mul_valid_i &&  writeback_mul_pipe1_i;
`else
wire        writeback_mul_valid0_w = writeback_mul_valid_i;
wire        writeback_mul_valid1_w = writeback_mul_valid_i;
`endif

`ifdef CPU_REAL_MDU
wire        issue_pipe0_ctrl_valid_w = issue_pipe0_valid_w && !issue_a_real_mdu_detach_w;
wire        issue_pipe1_ctrl_valid_w = issue_pipe1_valid_w && !issue_b_real_mdu_detach_w;
wire        issue_a_ctrl_rd_valid_w  = issue_a_sb_alloc_w && !issue_a_real_mdu_detach_w;
wire        issue_b_ctrl_rd_valid_w  = issue_b_sb_alloc_w && !issue_b_real_mdu_detach_w;
`else
wire        issue_pipe0_ctrl_valid_w = issue_pipe0_valid_w;
wire        issue_pipe1_ctrl_valid_w = issue_pipe1_valid_w;
wire        issue_a_ctrl_rd_valid_w  = issue_a_sb_alloc_w;
wire        issue_b_ctrl_rd_valid_w  = issue_b_sb_alloc_w;
`endif

wire [`EXCEPTION_W-1:0] issue_a_fault_w = opcode_a_fault_r[0] ? `EXCEPTION_FAULT_FETCH:
                                          opcode_a_fault_r[1] ? `EXCEPTION_PAGE_FAULT_INST:
                                          issue_a_priv_fault_w ? `EXCEPTION_PRIVILEGED_INSTRUCTION:
                                          `EXCEPTION_W'b0;

biloong_pipe_ctrl
#( 
     .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
)
u_pipe0_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)    

    // Issue
    ,.issue_valid_i(issue_pipe0_ctrl_valid_w)
    ,.issue_accept_i(opcode_a_accept_w)
    ,.issue_stall_i(stall_w)
    ,.issue_lsu_i(issue_a_lsu_w && !issue_a_priv_fault_w)
    ,.issue_csr_i(issue_a_csr_w && !issue_a_priv_fault_w)
    ,.issue_div_i(issue_a_div_w && !issue_a_priv_fault_w)
    ,.issue_mul_i(issue_a_pipe_mul_w && !issue_a_priv_fault_w)
    ,.issue_branch_i(issue_a_branch_w && !issue_a_priv_fault_w)
`ifdef BPU_PERF
    ,.issue_pred_branch_i(opcode_a_pred_branch_r)
`endif
    ,.issue_rd_valid_i(issue_a_ctrl_rd_valid_w)
    ,.issue_rd_i(issue_a_rd_idx_w)
    ,.issue_seq_i(issue_pipe0_seq_w)
    ,.issue_exception_i(issue_a_fault_w)
    ,.issue_exception_ecode_i(opcode_a_fault_ecode_r)
    ,.issue_exception_addr_i(opcode_a_fault_addr_r)
    ,.issue_pc_i(opcode0_pc_o)
    ,.issue_opcode_i(opcode0_opcode_o)
    ,.issue_operand_ra_i(opcode0_ra_operand_o)
    ,.issue_operand_rb_i(opcode0_rb_operand_o)
    ,.issue_branch_taken_i(branch_d_exec0_request_i)
    ,.issue_branch_target_i(branch_d_exec0_pc_i)
    ,.take_interrupt_i(take_interrupt_i)

    // Execution stage 1: ALU result
    ,.alu_result_e1_i(writeback_exec0_value_i)
    ,.csr_result_value_e1_i(csr_result_e1_value_i)
    ,.csr_result_write_e1_i(csr_result_e1_write_i)
    ,.csr_result_wdata_e1_i(csr_result_e1_wdata_i)
    ,.csr_result_exception_e1_i(csr_result_e1_exception_i)

    // Execution stage 1
    ,.load_e1_o(pipe0_load_e1_w)
    ,.store_e1_o(pipe0_store_e1_w)
    ,.mul_e1_o(pipe0_mul_e1_w)
    ,.branch_e1_o(pipe0_branch_e1_w)
`ifdef BPU_PERF
    ,.pred_branch_e1_o(pipe0_pred_branch_e1_w)
`endif
    ,.rd_e1_o(pipe0_rd_e1_w)
    ,.pc_e1_o(pipe0_pc_e1_w)
    ,.opcode_e1_o(pipe0_opcode_e1_w)
    ,.operand_ra_e1_o(pipe0_operand_ra_e1_w)
    ,.operand_rb_e1_o(pipe0_operand_rb_e1_w)

    // Execution stage 2: Other results
    ,.mem_complete_i(writeback_mem_valid0_w)
    ,.mem_result_e2_i(writeback_mem_value_i)
    ,.mem_exception_e2_i(writeback_mem_exception_i)
    ,.mem_exception_ecode_e2_i(writeback_mem_exception_ecode_i)
    ,.mul_result_e2_i(writeback_mul_value_i)
    ,.mul_complete_i(writeback_mul_valid0_w)

    // Execution stage 2
    ,.load_e2_o(pipe0_load_e2_w)
    ,.mul_e2_o(pipe0_mul_e2_w)
    ,.rd_e2_o(pipe0_rd_e2_w)
    ,.result_e2_o(pipe0_result_e2_w)
    ,.complete_e1_o(pipe0_complete_e1_w)
    ,.seq_e1_o(pipe0_seq_e1_w)
    ,.complete_e2_o(pipe0_complete_e2_w)
    ,.seq_e2_o(pipe0_seq_e2_w)
    ,.complete_wb_o(pipe0_complete_wb_w)

    ,.stall_o(pipe0_stall_raw_w)
    ,.squash_e1_e2_o(pipe0_squash_e1_e2_w)
    ,.squash_e1_e2_i(pipe1_squash_to_pipe0_w)
    ,.squash_wb_i(1'b0)
`ifdef PERF_MONI
    ,.perf_stall_div_o(pipe0_perf_stall_div_w)
    ,.perf_stall_mem_o(pipe0_perf_stall_mem_w)
    ,.perf_stall_mul_o(pipe0_perf_stall_mul_w)
`endif

    // Out of pipe: Divide Result
    ,.div_complete_i(writeback_div_valid_i)
    ,.div_result_i(writeback_div_value_i)

    // Commit
    ,.valid_wb_o(pipe0_valid_wb_raw_w)
    ,.csr_wb_o(pipe0_csr_wb_raw_w)
    ,.rd_wb_o(pipe0_rd_wb_raw_w)
    ,.seq_wb_o(pipe0_seq_wb_raw_w)
    ,.result_wb_o(pipe0_result_wb_raw_w)
    ,.pc_wb_o(pipe0_pc_wb_raw_w)
    ,.opcode_wb_o(pipe0_opc_wb_raw_w)
    ,.operand_ra_wb_o(pipe0_ra_val_wb_raw_w)
    ,.operand_rb_wb_o(pipe0_rb_val_wb_raw_w)
    ,.exception_wb_o(pipe0_exception_wb_raw_w)
    ,.exception_ecode_wb_o(pipe0_exception_ecode_wb_raw_w)
    ,.csr_write_wb_o(csr_writeback_write_o)
    ,.csr_waddr_wb_o(csr_writeback_waddr_o)
    ,.csr_wdata_wb_o(csr_writeback_wdata_o)   
);

assign exec0_hold_o = stall_w;
assign mul_hold_o   = stall_w;

//-------------------------------------------------------------
// Pipe1 - Status tracking
//-------------------------------------------------------------
wire        pipe1_stall_raw_w;

wire        pipe1_load_e1_w;
wire        pipe1_store_e1_w;
wire        pipe1_mul_e1_w;
wire        pipe1_branch_e1_w;
`ifdef BPU_PERF
wire        pipe1_pred_branch_e1_w;
`endif
wire [4:0]  pipe1_rd_e1_w;
wire        pipe1_complete_e1_w;
wire [15:0] pipe1_seq_e1_w;

wire [31:0] pipe1_pc_e1_w;
wire [31:0] pipe1_opcode_e1_w;
wire [31:0] pipe1_operand_ra_e1_w;
wire [31:0] pipe1_operand_rb_e1_w;

wire        pipe1_load_e2_w;
wire        pipe1_mul_e2_w;
wire [4:0]  pipe1_rd_e2_w;
wire [31:0] pipe1_result_e2_w;
wire [31:0] pipe1_result_e2_fwd_w =
            ((SUPPORT_LOAD_BYPASS != 0) && pipe1_load_e2_w) ? writeback_mem_value_i :
                                                               pipe1_result_e2_w;
wire        pipe1_complete_e2_w;
wire [15:0] pipe1_seq_e2_w;

wire        pipe1_valid_wb_raw_w;
wire [4:0]  pipe1_rd_wb_raw_w;
wire [15:0] pipe1_seq_wb_raw_w;
wire [31:0] pipe1_result_wb_raw_w;
wire [31:0] pipe1_pc_wb_raw_w;
wire [31:0] pipe1_opc_wb_raw_w;
wire [31:0] pipe1_ra_val_wb_raw_w;
wire [31:0] pipe1_rb_val_wb_raw_w;
wire [`EXCEPTION_W-1:0] pipe1_exception_wb_raw_w;
wire [5:0]  pipe1_exception_ecode_wb_raw_w;
wire        pipe1_complete_wb_w;

wire [`EXCEPTION_W-1:0] issue_b_fault_w = opcode_b_fault_r[0] ? `EXCEPTION_FAULT_FETCH:
                                          opcode_b_fault_r[1] ? `EXCEPTION_PAGE_FAULT_INST:
                                          issue_b_priv_fault_w ? `EXCEPTION_PRIVILEGED_INSTRUCTION:
                                          `EXCEPTION_W'b0;

biloong_pipe_ctrl
#( 
     .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
)
u_pipe1_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Issue
    ,.issue_valid_i(issue_pipe1_ctrl_valid_w)
    ,.issue_accept_i(opcode_b_accept_w)
    ,.issue_stall_i(stall_w)
    ,.issue_lsu_i(issue_b_lsu_w && !issue_b_priv_fault_w)
    ,.issue_csr_i(1'b0)
    ,.issue_div_i(1'b0)
    ,.issue_mul_i(issue_b_pipe_mul_w && !issue_b_priv_fault_w)
    ,.issue_branch_i(issue_b_branch_w && !issue_b_priv_fault_w)
`ifdef BPU_PERF
    ,.issue_pred_branch_i(opcode_b_pred_branch_r)
`endif
    ,.issue_rd_valid_i(issue_b_ctrl_rd_valid_w)
    ,.issue_rd_i(issue_b_rd_idx_w)
    ,.issue_seq_i(issue_pipe1_seq_w)
    ,.issue_exception_i(issue_b_fault_w)
    ,.issue_exception_ecode_i(opcode_b_fault_ecode_r)
    ,.issue_exception_addr_i(opcode_b_fault_addr_r)
    ,.issue_pc_i(opcode1_pc_o)
    ,.issue_opcode_i(opcode1_opcode_o)
    ,.issue_operand_ra_i(opcode1_ra_operand_o)
    ,.issue_operand_rb_i(opcode1_rb_operand_o)
    ,.issue_branch_taken_i(branch_d_exec1_request_i)
    ,.issue_branch_target_i(branch_d_exec1_pc_i)
    ,.take_interrupt_i(take_interrupt_i)

    // Execution stage 1: ALU, CSR result
    ,.alu_result_e1_i(writeback_exec1_value_i)
    ,.csr_result_value_e1_i(csr_result_e1_value_i)
    ,.csr_result_write_e1_i(csr_result_e1_write_i)
    ,.csr_result_wdata_e1_i(csr_result_e1_wdata_i)
    ,.csr_result_exception_e1_i(csr_result_e1_exception_i)

    // Execution stage 1
    ,.load_e1_o(pipe1_load_e1_w)
    ,.store_e1_o(pipe1_store_e1_w)
    ,.mul_e1_o(pipe1_mul_e1_w)
    ,.branch_e1_o(pipe1_branch_e1_w)
`ifdef BPU_PERF
    ,.pred_branch_e1_o(pipe1_pred_branch_e1_w)
`endif
    ,.rd_e1_o(pipe1_rd_e1_w)
    ,.pc_e1_o(pipe1_pc_e1_w)
    ,.opcode_e1_o(pipe1_opcode_e1_w)
    ,.operand_ra_e1_o(pipe1_operand_ra_e1_w)
    ,.operand_rb_e1_o(pipe1_operand_rb_e1_w)

    // Execution stage 2: Other results
    ,.mem_complete_i(writeback_mem_valid1_w)
    ,.mem_result_e2_i(writeback_mem_value_i)
    ,.mem_exception_e2_i(writeback_mem_exception_i)
    ,.mem_exception_ecode_e2_i(writeback_mem_exception_ecode_i)
    ,.mul_result_e2_i(writeback_mul_value_i)
    ,.mul_complete_i(writeback_mul_valid1_w)

    // Execution stage 2
    ,.load_e2_o(pipe1_load_e2_w)
    ,.mul_e2_o(pipe1_mul_e2_w)
    ,.rd_e2_o(pipe1_rd_e2_w)
    ,.result_e2_o(pipe1_result_e2_w)
    ,.complete_e1_o(pipe1_complete_e1_w)
    ,.seq_e1_o(pipe1_seq_e1_w)
    ,.complete_e2_o(pipe1_complete_e2_w)
    ,.seq_e2_o(pipe1_seq_e2_w)
    ,.complete_wb_o(pipe1_complete_wb_w)

    ,.stall_o(pipe1_stall_raw_w)
    ,.squash_e1_e2_o(pipe1_squash_e1_e2_w)
    ,.squash_e1_e2_i(pipe0_squash_to_pipe1_w)
    ,.squash_wb_i(pipe0_squash_e1_e2_w)
`ifdef PERF_MONI
    ,.perf_stall_div_o(pipe1_perf_stall_div_w)
    ,.perf_stall_mem_o(pipe1_perf_stall_mem_w)
    ,.perf_stall_mul_o(pipe1_perf_stall_mul_w)
`endif

    // Out of pipe: Divide Result
    ,.div_complete_i(writeback_div_valid_i)
    ,.div_result_i(writeback_div_value_i)

    // Commit
    ,.valid_wb_o(pipe1_valid_wb_raw_w)
    ,.csr_wb_o()
    ,.rd_wb_o(pipe1_rd_wb_raw_w)
    ,.seq_wb_o(pipe1_seq_wb_raw_w)
    ,.result_wb_o(pipe1_result_wb_raw_w)
    ,.pc_wb_o(pipe1_pc_wb_raw_w)
    ,.opcode_wb_o(pipe1_opc_wb_raw_w)
    ,.operand_ra_wb_o(pipe1_ra_val_wb_raw_w)
    ,.operand_rb_wb_o(pipe1_rb_val_wb_raw_w)
    ,.exception_wb_o(pipe1_exception_wb_raw_w)
    ,.exception_ecode_wb_o(pipe1_exception_ecode_wb_raw_w)
    ,.csr_write_wb_o()
    ,.csr_waddr_wb_o()
    ,.csr_wdata_wb_o()
);

assign exec1_hold_o = stall_w;

wire        pipe0_exception_valid_raw_w = pipe0_exception_wb_raw_w != `EXCEPTION_W'b0;
wire        pipe1_exception_valid_raw_w = pipe1_exception_wb_raw_w != `EXCEPTION_W'b0;
wire        pipe1_exception_wait_pipe0_e1_w =
            pipe1_exception_valid_raw_w && pipe0_complete_e1_w &&
            seq_after(pipe1_seq_wb_raw_w, pipe0_seq_e1_w);
wire        pipe1_exception_wait_pipe0_e2_w =
            pipe1_exception_valid_raw_w && pipe0_complete_e2_w &&
            seq_after(pipe1_seq_wb_raw_w, pipe0_seq_e2_w);
// These sequence relations are used by multiple exception/squash predicates.
// Materialize each relation once so the subtract/compare cone is shared.
wire        seq_after_pipe1_pipe0_wb_w =
            seq_after(pipe1_seq_wb_raw_w, pipe0_seq_wb_raw_w);
wire        seq_after_pending_pipe0_wb_w =
            seq_after(pipe1_exception_seq_q, pipe0_seq_wb_raw_w);
wire        seq_pending_pipe0_wb_equal_w =
            pipe1_exception_seq_q == pipe0_seq_wb_raw_w;
// Outstanding instructions never span half the 16-bit sequence space, so the
// reverse relation is the non-equal complement of the forward comparison.
// Reusing it avoids a second 16-bit subtract/compare cone on this path.
wire        seq_after_pipe0_pending_wb_w =
            !seq_pending_pipe0_wb_equal_w && !seq_after_pending_pipe0_wb_w;
wire        pipe1_exception_wait_pipe0_wb_w =
            pipe1_exception_valid_raw_w && pipe0_complete_wb_w &&
            seq_after_pipe1_pipe0_wb_w;
wire        pipe1_exception_wait_older_pipe0_w =
            pipe1_exception_wait_pipe0_e1_w ||
            pipe1_exception_wait_pipe0_e2_w ||
            pipe1_exception_wait_pipe0_wb_w;
// Pending pipe 1 exceptions feed several release and squash predicates.
(* max_fanout = 16 *) reg         pipe1_exception_pending_q;
reg [4:0]   pipe1_exception_rd_q;
reg [15:0]  pipe1_exception_seq_q;
reg [31:0]  pipe1_exception_result_q;
reg [31:0]  pipe1_exception_pc_q;
reg [31:0]  pipe1_exception_opc_q;
reg [31:0]  pipe1_exception_ra_val_q;
reg [31:0]  pipe1_exception_rb_val_q;
reg [`EXCEPTION_W-1:0] pipe1_exception_q;
reg [5:0]   pipe1_exception_ecode_q;

wire        pipe1_exception_pending_ready_w =
            pipe1_exception_pending_q &&
            !(pipe0_complete_e1_w && seq_after(pipe1_exception_seq_q, pipe0_seq_e1_w)) &&
            !(pipe0_complete_e2_w && seq_after(pipe1_exception_seq_q, pipe0_seq_e2_w)) &&
            !(pipe0_complete_wb_w && seq_after_pending_pipe0_wb_w);
wire        pipe0_exception_older_than_pipe1_raw_w =
            pipe0_exception_valid_raw_w &&
            seq_after_pipe1_pipe0_wb_w;
wire        pipe1_exception_capture_w =
            pipe1_exception_valid_raw_w && pipe1_exception_wait_older_pipe0_w &&
            !pipe1_exception_pending_q &&
            !pipe0_exception_older_than_pipe1_raw_w;
wire        pipe0_exception_older_than_pending_w =
            pipe1_exception_pending_q && pipe0_exception_valid_raw_w &&
            seq_after_pending_pipe0_wb_w;
wire        pipe1_exception_replay_w =
            pipe1_exception_pending_ready_w && !pipe0_exception_older_than_pending_w;
wire        pipe1_exception_valid_w =
            (pipe1_exception_valid_raw_w && !pipe1_exception_wait_older_pipe0_w) ||
            pipe1_exception_replay_w;
assign pipe0_squash_to_pipe1_w = pipe0_squash_e1_e2_w;
assign pipe1_squash_to_pipe0_w = (pipe1_squash_e1_e2_w & ~pipe1_exception_wait_older_pipe0_w) |
                                  pipe1_exception_replay_w;
wire        pipe0_exception_valid_w = pipe0_exception_valid_raw_w;
wire [15:0] pipe1_exception_visible_seq_w =
            pipe1_exception_replay_w ? pipe1_exception_seq_q : pipe1_seq_wb_raw_w;
wire [15:0] active_exception_seq_w = pipe0_exception_valid_w ? pipe0_seq_wb_raw_w :
                                                                 pipe1_exception_visible_seq_w;
wire        active_exception_valid_w = pipe0_exception_valid_w || pipe1_exception_valid_w;
assign branch_redirect_blocked_by_exception_w =
            branch_redirect_raw_w &&
            ((active_exception_valid_w && seq_after(branch_redirect_seq_w, active_exception_seq_w)) ||
             (exception_commit_block_q && seq_after(branch_redirect_seq_w, exception_commit_seq_q)) ||
             (pipe1_exception_capture_w && seq_after(branch_redirect_seq_w, pipe1_seq_wb_raw_w)) ||
             (pipe1_exception_pending_q && seq_after(branch_redirect_seq_w, pipe1_exception_seq_q)) ||
             pipe1_exception_replay_w);
wire        branch_redirect_clears_pending_w =
            branch_redirect_w &&
            (!pipe1_exception_pending_q || seq_after(pipe1_exception_seq_q, branch_redirect_seq_w)) &&
            (!pipe1_exception_capture_w || seq_after(pipe1_seq_wb_raw_w, branch_redirect_seq_w)) &&
            (!active_exception_valid_w || seq_after(active_exception_seq_w, branch_redirect_seq_w));
wire        pipe0_younger_than_pending_exception_w =
            pipe1_exception_pending_q &&
            seq_after_pipe0_pending_wb_w;
wire        pipe0_squash_clears_pending_w =
            pipe0_exception_older_than_pending_w;
wire        pipe0_younger_than_exception_w =
            (pipe1_exception_valid_w && seq_after(pipe0_seq_wb_raw_w, pipe1_exception_visible_seq_w));
wire        pipe1_younger_than_exception_w =
            (pipe0_exception_valid_w && seq_after(pipe1_seq_wb_raw_w, pipe0_seq_wb_raw_w));
assign exception_issue_block_w = pipe1_exception_pending_q || pipe1_exception_capture_w ||
                                 pipe1_exception_replay_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    pipe1_exception_pending_q <= 1'b0;
    pipe1_exception_rd_q      <= 5'b0;
    pipe1_exception_seq_q     <= 16'b0;
    pipe1_exception_result_q  <= 32'b0;
    pipe1_exception_pc_q      <= 32'b0;
    pipe1_exception_opc_q     <= 32'b0;
    pipe1_exception_ra_val_q  <= 32'b0;
    pipe1_exception_rb_val_q  <= 32'b0;
    pipe1_exception_q         <= `EXCEPTION_W'b0;
    pipe1_exception_ecode_q   <= 6'b0;
end
else if (branch_csr_request_i || branch_redirect_clears_pending_w || pipe0_squash_clears_pending_w ||
         pipe1_exception_replay_w)
begin
    pipe1_exception_pending_q <= 1'b0;
    pipe1_exception_rd_q      <= 5'b0;
    pipe1_exception_seq_q     <= 16'b0;
    pipe1_exception_result_q  <= 32'b0;
    pipe1_exception_pc_q      <= 32'b0;
    pipe1_exception_opc_q     <= 32'b0;
    pipe1_exception_ra_val_q  <= 32'b0;
    pipe1_exception_rb_val_q  <= 32'b0;
    pipe1_exception_q         <= `EXCEPTION_W'b0;
    pipe1_exception_ecode_q   <= 6'b0;
end
else if (pipe1_exception_capture_w)
begin
    pipe1_exception_pending_q <= 1'b1;
    pipe1_exception_rd_q      <= pipe1_rd_wb_raw_w;
    pipe1_exception_seq_q     <= pipe1_seq_wb_raw_w;
    pipe1_exception_result_q  <= pipe1_result_wb_raw_w;
    pipe1_exception_pc_q      <= pipe1_pc_wb_raw_w;
    pipe1_exception_opc_q     <= pipe1_opc_wb_raw_w;
    pipe1_exception_ra_val_q  <= pipe1_ra_val_wb_raw_w;
    pipe1_exception_rb_val_q  <= pipe1_rb_val_wb_raw_w;
    pipe1_exception_q         <= pipe1_exception_wb_raw_w;
    pipe1_exception_ecode_q   <= pipe1_exception_ecode_wb_raw_w;
end

reg         exception_commit_block_q;
reg [15:0]  exception_commit_seq_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    exception_commit_block_q <= 1'b0;
    exception_commit_seq_q   <= 16'b0;
end
else if (pipe0_exception_valid_w || pipe1_exception_valid_w)
begin
    exception_commit_block_q <= 1'b1;
    exception_commit_seq_q   <= active_exception_seq_w;
end
else if (exception_commit_block_q && !squash_now_w)
begin
    exception_commit_block_q <= 1'b0;
    exception_commit_seq_q   <= 16'b0;
end

wire        pipe0_blocked_by_exception_w =
            pipe0_younger_than_pending_exception_w ||
            pipe0_younger_than_exception_w ||
            (exception_commit_block_q && seq_after(pipe0_seq_wb_raw_w, exception_commit_seq_q));
wire        pipe1_blocked_by_exception_raw_w =
            pipe1_younger_than_exception_w ||
            (exception_commit_block_q && seq_after(pipe1_seq_wb_raw_w, exception_commit_seq_q)) ||
            pipe1_exception_wait_older_pipe0_w;
wire        pipe1_blocked_by_exception_w =
            pipe1_exception_replay_w || pipe1_blocked_by_exception_raw_w;
wire        pipe0_wb_fwd_issue_valid_w = |pipe0_rd_wb_raw_w;
wire        pipe1_wb_fwd_issue_valid_w = |pipe1_rd_wb_raw_w;

`ifdef CPU_REAL_MDU
localparam REAL_MDU_Q_DEPTH = 8;
localparam REAL_MDU_Q_COUNT_W = 4;
localparam [REAL_MDU_Q_COUNT_W-1:0] REAL_MDU_Q_DEPTH_C = REAL_MDU_Q_DEPTH;

reg [REAL_MDU_Q_COUNT_W-1:0] real_mdu_count_q;
reg [REAL_MDU_Q_COUNT_W-1:0] real_mdu_count_r;
reg [15:0] real_mdu_seq_q[0:REAL_MDU_Q_DEPTH-1];
reg [15:0] real_mdu_seq_r[0:REAL_MDU_Q_DEPTH-1];
reg [4:0]  real_mdu_rd_q[0:REAL_MDU_Q_DEPTH-1];
reg [4:0]  real_mdu_rd_r[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_pc_q[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_pc_r[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_opc_q[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_opc_r[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_ra_q[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_ra_r[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_rb_q[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_rb_r[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_result_q[0:REAL_MDU_Q_DEPTH-1];
reg [31:0] real_mdu_result_r[0:REAL_MDU_Q_DEPTH-1];
reg        real_mdu_complete_q[0:REAL_MDU_Q_DEPTH-1];
reg        real_mdu_complete_r[0:REAL_MDU_Q_DEPTH-1];
reg        real_mdu_killed_q[0:REAL_MDU_Q_DEPTH-1];
reg        real_mdu_killed_r[0:REAL_MDU_Q_DEPTH-1];

integer real_mdu_i;
reg     real_mdu_result_marked_r;
reg [31:0] real_mdu_scoreboard_r;
reg        real_mdu_live_pending_r;
reg        real_mdu_fwd_a_ra_hit_r;
reg        real_mdu_fwd_a_rb_hit_r;
reg        real_mdu_fwd_b_ra_hit_r;
reg        real_mdu_fwd_b_rb_hit_r;
reg [31:0] real_mdu_fwd_a_ra_value_r;
reg [31:0] real_mdu_fwd_a_rb_value_r;
reg [31:0] real_mdu_fwd_b_ra_value_r;
reg [31:0] real_mdu_fwd_b_rb_value_r;

wire real_mdu_head_valid_w = real_mdu_count_q != {REAL_MDU_Q_COUNT_W{1'b0}};
wire pipe0_real_mdu_order_event_w =
            pipe0_complete_wb_w && !pipe0_blocked_by_exception_w;
wire pipe1_real_mdu_order_event_w =
            pipe1_complete_wb_w && !pipe1_blocked_by_exception_w;
wire real_mdu_pipe0_older_w =
            real_mdu_head_valid_w && pipe0_real_mdu_order_event_w &&
            seq_after(real_mdu_seq_q[0], pipe0_seq_wb_raw_w);
wire real_mdu_pipe1_older_w =
            real_mdu_head_valid_w && pipe1_real_mdu_order_event_w &&
            seq_after(real_mdu_seq_q[0], pipe1_seq_wb_raw_w);
wire real_mdu_pipe0_younger_w =
            real_mdu_head_valid_w && pipe0_real_mdu_order_event_w &&
            seq_after(pipe0_seq_wb_raw_w, real_mdu_seq_q[0]);
wire real_mdu_pipe1_younger_w =
            real_mdu_head_valid_w && pipe1_real_mdu_order_event_w &&
            seq_after(pipe1_seq_wb_raw_w, real_mdu_seq_q[0]);
wire real_mdu_raw_older_w = real_mdu_pipe0_older_w | real_mdu_pipe1_older_w;
wire real_mdu_raw_younger_w = real_mdu_pipe0_younger_w | real_mdu_pipe1_younger_w;
wire real_mdu_head_retire_ready_w =
            real_mdu_head_valid_w && real_mdu_complete_q[0] && !real_mdu_raw_older_w;
wire real_mdu_commit_w =
            real_mdu_head_retire_ready_w && !real_mdu_killed_q[0];
wire real_mdu_drop_w =
            real_mdu_head_retire_ready_w && real_mdu_killed_q[0];
wire real_mdu_retire_w = real_mdu_commit_w | real_mdu_drop_w;
wire real_mdu_commit_stall_w =
            real_mdu_head_valid_w && real_mdu_raw_younger_w && !real_mdu_raw_older_w;

wire real_mdu_mul0_enqueue_w = mul_opcode_valid_o;
wire real_mdu_mul1_enqueue_w = mul_opcode1_valid_o;
wire real_mdu_mul0_pipe1_w   = mul_opcode_pipe1_o;
wire [15:0] real_mdu_mul0_seq_w = real_mdu_mul0_pipe1_w ? issue_pipe1_seq_w : issue_pipe0_seq_w;
wire [4:0]  real_mdu_mul0_rd_w  = real_mdu_mul0_pipe1_w ? opcode1_rd_idx_o : opcode0_rd_idx_o;
wire [31:0] real_mdu_mul0_pc_w  = real_mdu_mul0_pipe1_w ? opcode1_pc_o : opcode0_pc_o;
wire [31:0] real_mdu_mul0_opc_w = real_mdu_mul0_pipe1_w ? opcode1_opcode_o : opcode0_opcode_o;
wire [31:0] real_mdu_mul0_ra_w  = real_mdu_mul0_pipe1_w ? opcode1_ra_operand_o : opcode0_ra_operand_o;
wire [31:0] real_mdu_mul0_rb_w  = real_mdu_mul0_pipe1_w ? opcode1_rb_operand_o : opcode0_rb_operand_o;

always @ *
begin
    real_mdu_count_r = real_mdu_count_q;
    real_mdu_result_marked_r = 1'b0;

    for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
    begin
        real_mdu_seq_r[real_mdu_i]      = real_mdu_seq_q[real_mdu_i];
        real_mdu_rd_r[real_mdu_i]       = real_mdu_rd_q[real_mdu_i];
        real_mdu_pc_r[real_mdu_i]       = real_mdu_pc_q[real_mdu_i];
        real_mdu_opc_r[real_mdu_i]      = real_mdu_opc_q[real_mdu_i];
        real_mdu_ra_r[real_mdu_i]       = real_mdu_ra_q[real_mdu_i];
        real_mdu_rb_r[real_mdu_i]       = real_mdu_rb_q[real_mdu_i];
        real_mdu_result_r[real_mdu_i]   = real_mdu_result_q[real_mdu_i];
        real_mdu_complete_r[real_mdu_i] = real_mdu_complete_q[real_mdu_i];
        real_mdu_killed_r[real_mdu_i]   = real_mdu_killed_q[real_mdu_i];
    end

    if (real_mdu_retire_w && (real_mdu_count_q != {REAL_MDU_Q_COUNT_W{1'b0}}))
    begin
        real_mdu_count_r = real_mdu_count_q - {{(REAL_MDU_Q_COUNT_W-1){1'b0}}, 1'b1};
        for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH-1; real_mdu_i = real_mdu_i + 1)
        begin
            real_mdu_seq_r[real_mdu_i]      = real_mdu_seq_q[real_mdu_i + 1];
            real_mdu_rd_r[real_mdu_i]       = real_mdu_rd_q[real_mdu_i + 1];
            real_mdu_pc_r[real_mdu_i]       = real_mdu_pc_q[real_mdu_i + 1];
            real_mdu_opc_r[real_mdu_i]      = real_mdu_opc_q[real_mdu_i + 1];
            real_mdu_ra_r[real_mdu_i]       = real_mdu_ra_q[real_mdu_i + 1];
            real_mdu_rb_r[real_mdu_i]       = real_mdu_rb_q[real_mdu_i + 1];
            real_mdu_result_r[real_mdu_i]   = real_mdu_result_q[real_mdu_i + 1];
            real_mdu_complete_r[real_mdu_i] = real_mdu_complete_q[real_mdu_i + 1];
            real_mdu_killed_r[real_mdu_i]   = real_mdu_killed_q[real_mdu_i + 1];
        end
        real_mdu_seq_r[REAL_MDU_Q_DEPTH-1]      = 16'b0;
        real_mdu_rd_r[REAL_MDU_Q_DEPTH-1]       = 5'b0;
        real_mdu_pc_r[REAL_MDU_Q_DEPTH-1]       = 32'b0;
        real_mdu_opc_r[REAL_MDU_Q_DEPTH-1]      = 32'b0;
        real_mdu_ra_r[REAL_MDU_Q_DEPTH-1]       = 32'b0;
        real_mdu_rb_r[REAL_MDU_Q_DEPTH-1]       = 32'b0;
        real_mdu_result_r[REAL_MDU_Q_DEPTH-1]   = 32'b0;
        real_mdu_complete_r[REAL_MDU_Q_DEPTH-1] = 1'b0;
        real_mdu_killed_r[REAL_MDU_Q_DEPTH-1]   = 1'b0;
    end

    for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
    begin
        if (real_mdu_i < real_mdu_count_r)
        begin
            if (branch_csr_request_i ||
                (branch_redirect_w && seq_after(real_mdu_seq_r[real_mdu_i], branch_redirect_seq_w)) ||
                (active_exception_valid_w && seq_after(real_mdu_seq_r[real_mdu_i], active_exception_seq_w)))
                real_mdu_killed_r[real_mdu_i] = 1'b1;
        end
    end

    if (writeback_mul_valid_i)
    begin
        for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
        begin
            if (!real_mdu_result_marked_r &&
                (real_mdu_i < real_mdu_count_r) &&
                !real_mdu_complete_r[real_mdu_i])
            begin
                real_mdu_complete_r[real_mdu_i] = 1'b1;
                real_mdu_result_r[real_mdu_i]   = writeback_mul_value_i;
                real_mdu_result_marked_r        = 1'b1;
            end
        end
    end

    if (real_mdu_mul0_enqueue_w && (real_mdu_count_r < REAL_MDU_Q_DEPTH_C))
    begin
        real_mdu_seq_r[real_mdu_count_r]      = real_mdu_mul0_seq_w;
        real_mdu_rd_r[real_mdu_count_r]       = real_mdu_mul0_rd_w;
        real_mdu_pc_r[real_mdu_count_r]       = real_mdu_mul0_pc_w;
        real_mdu_opc_r[real_mdu_count_r]      = real_mdu_mul0_opc_w;
        real_mdu_ra_r[real_mdu_count_r]       = real_mdu_mul0_ra_w;
        real_mdu_rb_r[real_mdu_count_r]       = real_mdu_mul0_rb_w;
        real_mdu_result_r[real_mdu_count_r]   = 32'b0;
        real_mdu_complete_r[real_mdu_count_r] = 1'b0;
        real_mdu_killed_r[real_mdu_count_r]   = 1'b0;
        real_mdu_count_r = real_mdu_count_r + {{(REAL_MDU_Q_COUNT_W-1){1'b0}}, 1'b1};
    end

    if (real_mdu_mul1_enqueue_w && (real_mdu_count_r < REAL_MDU_Q_DEPTH_C))
    begin
        real_mdu_seq_r[real_mdu_count_r]      = issue_pipe1_seq_w;
        real_mdu_rd_r[real_mdu_count_r]       = opcode1_rd_idx_o;
        real_mdu_pc_r[real_mdu_count_r]       = opcode1_pc_o;
        real_mdu_opc_r[real_mdu_count_r]      = opcode1_opcode_o;
        real_mdu_ra_r[real_mdu_count_r]       = opcode1_ra_operand_o;
        real_mdu_rb_r[real_mdu_count_r]       = opcode1_rb_operand_o;
        real_mdu_result_r[real_mdu_count_r]   = 32'b0;
        real_mdu_complete_r[real_mdu_count_r] = 1'b0;
        real_mdu_killed_r[real_mdu_count_r]   = 1'b0;
        real_mdu_count_r = real_mdu_count_r + {{(REAL_MDU_Q_COUNT_W-1){1'b0}}, 1'b1};
    end
end

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    real_mdu_count_q <= {REAL_MDU_Q_COUNT_W{1'b0}};
    for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
    begin
        real_mdu_seq_q[real_mdu_i]      <= 16'b0;
        real_mdu_rd_q[real_mdu_i]       <= 5'b0;
        real_mdu_pc_q[real_mdu_i]       <= 32'b0;
        real_mdu_opc_q[real_mdu_i]      <= 32'b0;
        real_mdu_ra_q[real_mdu_i]       <= 32'b0;
        real_mdu_rb_q[real_mdu_i]       <= 32'b0;
        real_mdu_result_q[real_mdu_i]   <= 32'b0;
        real_mdu_complete_q[real_mdu_i] <= 1'b0;
        real_mdu_killed_q[real_mdu_i]   <= 1'b0;
    end
end
else
begin
    real_mdu_count_q <= real_mdu_count_r;
    for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
    begin
        real_mdu_seq_q[real_mdu_i]      <= real_mdu_seq_r[real_mdu_i];
        real_mdu_rd_q[real_mdu_i]       <= real_mdu_rd_r[real_mdu_i];
        real_mdu_pc_q[real_mdu_i]       <= real_mdu_pc_r[real_mdu_i];
        real_mdu_opc_q[real_mdu_i]      <= real_mdu_opc_r[real_mdu_i];
        real_mdu_ra_q[real_mdu_i]       <= real_mdu_ra_r[real_mdu_i];
        real_mdu_rb_q[real_mdu_i]       <= real_mdu_rb_r[real_mdu_i];
        real_mdu_result_q[real_mdu_i]   <= real_mdu_result_r[real_mdu_i];
        real_mdu_complete_q[real_mdu_i] <= real_mdu_complete_r[real_mdu_i];
        real_mdu_killed_q[real_mdu_i]   <= real_mdu_killed_r[real_mdu_i];
    end
end

always @ *
begin
    real_mdu_scoreboard_r = 32'b0;
    real_mdu_live_pending_r = 1'b0;
    real_mdu_fwd_a_ra_hit_r = 1'b0;
    real_mdu_fwd_a_rb_hit_r = 1'b0;
    real_mdu_fwd_b_ra_hit_r = 1'b0;
    real_mdu_fwd_b_rb_hit_r = 1'b0;
    real_mdu_fwd_a_ra_value_r = 32'b0;
    real_mdu_fwd_a_rb_value_r = 32'b0;
    real_mdu_fwd_b_ra_value_r = 32'b0;
    real_mdu_fwd_b_rb_value_r = 32'b0;

    for (real_mdu_i = 0; real_mdu_i < REAL_MDU_Q_DEPTH; real_mdu_i = real_mdu_i + 1)
    begin
        if ((real_mdu_i < real_mdu_count_q) && !real_mdu_killed_q[real_mdu_i])
        begin
            real_mdu_live_pending_r = 1'b1;
            if ((|real_mdu_rd_q[real_mdu_i]) && !real_mdu_complete_q[real_mdu_i])
                real_mdu_scoreboard_r[real_mdu_rd_q[real_mdu_i]] = 1'b1;
            if ((|real_mdu_rd_q[real_mdu_i]) && real_mdu_complete_q[real_mdu_i])
            begin
                if (real_mdu_rd_q[real_mdu_i] == issue_a_ra_idx_rf_w)
                begin
                    real_mdu_fwd_a_ra_hit_r   = 1'b1;
                    real_mdu_fwd_a_ra_value_r = real_mdu_result_q[real_mdu_i];
                end
                if (real_mdu_rd_q[real_mdu_i] == issue_a_rb_idx_rf_w)
                begin
                    real_mdu_fwd_a_rb_hit_r   = 1'b1;
                    real_mdu_fwd_a_rb_value_r = real_mdu_result_q[real_mdu_i];
                end
                if (real_mdu_rd_q[real_mdu_i] == issue_b_ra_idx_rf_w)
                begin
                    real_mdu_fwd_b_ra_hit_r   = 1'b1;
                    real_mdu_fwd_b_ra_value_r = real_mdu_result_q[real_mdu_i];
                end
                if (real_mdu_rd_q[real_mdu_i] == issue_b_rb_idx_rf_w)
                begin
                    real_mdu_fwd_b_rb_hit_r   = 1'b1;
                    real_mdu_fwd_b_rb_value_r = real_mdu_result_q[real_mdu_i];
                end
            end
        end
    end
end

wire real_mdu_pending_w = real_mdu_count_q != {REAL_MDU_Q_COUNT_W{1'b0}};
wire real_mdu_live_pending_w = real_mdu_live_pending_r;
wire [31:0] real_mdu_scoreboard_w = real_mdu_scoreboard_r;
wire real_mdu_fwd_a_ra_hit_w = real_mdu_fwd_a_ra_hit_r;
wire real_mdu_fwd_a_rb_hit_w = real_mdu_fwd_a_rb_hit_r;
wire real_mdu_fwd_b_ra_hit_w = real_mdu_fwd_b_ra_hit_r;
wire real_mdu_fwd_b_rb_hit_w = real_mdu_fwd_b_rb_hit_r;
wire [31:0] real_mdu_fwd_a_ra_value_w = real_mdu_fwd_a_ra_value_r;
wire [31:0] real_mdu_fwd_a_rb_value_w = real_mdu_fwd_a_rb_value_r;
wire [31:0] real_mdu_fwd_b_ra_value_w = real_mdu_fwd_b_ra_value_r;
wire [31:0] real_mdu_fwd_b_rb_value_w = real_mdu_fwd_b_rb_value_r;
wire real_mdu_accept_one_w =
            (real_mdu_count_q <= (REAL_MDU_Q_DEPTH_C - {{(REAL_MDU_Q_COUNT_W-1){1'b0}}, 1'b1})) &&
            mul_accept_one_i;
wire real_mdu_accept_two_w =
            (real_mdu_count_q <= (REAL_MDU_Q_DEPTH_C - {{(REAL_MDU_Q_COUNT_W-2){1'b0}}, 2'd2})) &&
            mul_accept_two_i;
`else
wire real_mdu_pending_w = 1'b0;
wire real_mdu_live_pending_w = 1'b0;
wire [31:0] real_mdu_scoreboard_w = 32'b0;
wire real_mdu_fwd_a_ra_hit_w = 1'b0;
wire real_mdu_fwd_a_rb_hit_w = 1'b0;
wire real_mdu_fwd_b_ra_hit_w = 1'b0;
wire real_mdu_fwd_b_rb_hit_w = 1'b0;
wire [31:0] real_mdu_fwd_a_ra_value_w = 32'b0;
wire [31:0] real_mdu_fwd_a_rb_value_w = 32'b0;
wire [31:0] real_mdu_fwd_b_ra_value_w = 32'b0;
wire [31:0] real_mdu_fwd_b_rb_value_w = 32'b0;
wire real_mdu_accept_one_w = 1'b1;
wire real_mdu_accept_two_w = 1'b1;
wire real_mdu_commit_w = 1'b0;
wire real_mdu_drop_w = 1'b0;
wire real_mdu_commit_stall_w = 1'b0;
`endif

wire        pipe0_valid_wb_pipe_w = pipe0_valid_wb_raw_w & ~pipe0_blocked_by_exception_w;
wire        pipe0_csr_wb_pipe_w = pipe0_csr_wb_raw_w & ~pipe0_blocked_by_exception_w;
wire [4:0]  pipe0_rd_wb_pipe_w = pipe0_blocked_by_exception_w ? 5'b0 : pipe0_rd_wb_raw_w;
wire [15:0] pipe0_seq_wb_pipe_w = pipe0_seq_wb_raw_w;
wire [31:0] pipe0_result_wb_pipe_w = pipe0_result_wb_raw_w;
wire [31:0] pipe0_pc_wb_pipe_w = pipe0_pc_wb_raw_w;
wire [31:0] pipe0_opc_wb_pipe_w = pipe0_opc_wb_raw_w;
wire [31:0] pipe0_ra_val_wb_pipe_w = pipe0_ra_val_wb_raw_w;
wire [31:0] pipe0_rb_val_wb_pipe_w = pipe0_rb_val_wb_raw_w;
wire [`EXCEPTION_W-1:0] pipe0_exception_wb_pipe_w =
            pipe0_blocked_by_exception_w ? `EXCEPTION_W'b0 : pipe0_exception_wb_raw_w;
wire [5:0]  pipe0_exception_ecode_wb_pipe_w =
            pipe0_blocked_by_exception_w ? 6'b0 : pipe0_exception_ecode_wb_raw_w;

wire        pipe1_valid_wb_w = pipe1_exception_replay_w ? 1'b0 :
                               (pipe1_valid_wb_raw_w & ~pipe1_blocked_by_exception_w);
wire [4:0]  pipe1_rd_wb_w = pipe1_blocked_by_exception_w ? 5'b0 : pipe1_rd_wb_raw_w;
wire [15:0] pipe1_seq_wb_w = pipe1_exception_replay_w ? pipe1_exception_seq_q : pipe1_seq_wb_raw_w;
wire [31:0] pipe1_result_wb_w = pipe1_result_wb_raw_w;
wire [31:0] pipe1_exception_result_wb_w =
            pipe1_exception_replay_w ? pipe1_exception_result_q : pipe1_result_wb_raw_w;
wire [31:0] pipe1_pc_wb_w = pipe1_exception_replay_w ? pipe1_exception_pc_q : pipe1_pc_wb_raw_w;
wire [31:0] pipe1_opc_wb_w = pipe1_exception_replay_w ? pipe1_exception_opc_q : pipe1_opc_wb_raw_w;
wire [31:0] pipe1_ra_val_wb_w = pipe1_exception_replay_w ? pipe1_exception_ra_val_q : pipe1_ra_val_wb_raw_w;
wire [31:0] pipe1_rb_val_wb_w = pipe1_exception_replay_w ? pipe1_exception_rb_val_q : pipe1_rb_val_wb_raw_w;
wire [`EXCEPTION_W-1:0] pipe1_exception_wb_w =
            pipe1_exception_replay_w ? pipe1_exception_q :
            (pipe1_blocked_by_exception_w ? `EXCEPTION_W'b0 : pipe1_exception_wb_raw_w);
wire [5:0]  pipe1_exception_ecode_wb_w =
            pipe1_exception_replay_w ? pipe1_exception_ecode_q :
            (pipe1_blocked_by_exception_w ? 6'b0 : pipe1_exception_ecode_wb_raw_w);

`ifdef CPU_REAL_MDU
wire        pipe0_valid_wb_w = real_mdu_commit_w ? 1'b1 : pipe0_valid_wb_pipe_w;
wire        pipe0_csr_wb_w = real_mdu_commit_w ? 1'b0 : pipe0_csr_wb_pipe_w;
wire [4:0]  pipe0_rd_wb_w = real_mdu_commit_w ? real_mdu_rd_q[0] : pipe0_rd_wb_pipe_w;
wire [15:0] pipe0_seq_wb_w = real_mdu_commit_w ? real_mdu_seq_q[0] : pipe0_seq_wb_pipe_w;
wire [31:0] pipe0_result_wb_w = real_mdu_commit_w ? real_mdu_result_q[0] : pipe0_result_wb_pipe_w;
wire [31:0] pipe0_pc_wb_w = real_mdu_commit_w ? real_mdu_pc_q[0] : pipe0_pc_wb_pipe_w;
wire [31:0] pipe0_opc_wb_w = real_mdu_commit_w ? real_mdu_opc_q[0] : pipe0_opc_wb_pipe_w;
wire [31:0] pipe0_ra_val_wb_w = real_mdu_commit_w ? real_mdu_ra_q[0] : pipe0_ra_val_wb_pipe_w;
wire [31:0] pipe0_rb_val_wb_w = real_mdu_commit_w ? real_mdu_rb_q[0] : pipe0_rb_val_wb_pipe_w;
wire [`EXCEPTION_W-1:0] pipe0_exception_wb_w =
            real_mdu_commit_w ? `EXCEPTION_W'b0 : pipe0_exception_wb_pipe_w;
wire [5:0]  pipe0_exception_ecode_wb_w =
            real_mdu_commit_w ? 6'b0 : pipe0_exception_ecode_wb_pipe_w;
`else
wire        pipe0_valid_wb_w = pipe0_valid_wb_pipe_w;
wire        pipe0_csr_wb_w = pipe0_csr_wb_pipe_w;
wire [4:0]  pipe0_rd_wb_w = pipe0_rd_wb_pipe_w;
wire [15:0] pipe0_seq_wb_w = pipe0_seq_wb_pipe_w;
wire [31:0] pipe0_result_wb_w = pipe0_result_wb_pipe_w;
wire [31:0] pipe0_pc_wb_w = pipe0_pc_wb_pipe_w;
wire [31:0] pipe0_opc_wb_w = pipe0_opc_wb_pipe_w;
wire [31:0] pipe0_ra_val_wb_w = pipe0_ra_val_wb_pipe_w;
wire [31:0] pipe0_rb_val_wb_w = pipe0_rb_val_wb_pipe_w;
wire [`EXCEPTION_W-1:0] pipe0_exception_wb_w = pipe0_exception_wb_pipe_w;
wire [5:0]  pipe0_exception_ecode_wb_w = pipe0_exception_ecode_wb_pipe_w;
`endif

assign csr_writeback_exception_o      = pipe0_exception_wb_w | pipe1_exception_wb_w;
assign csr_writeback_exception_ecode_o = (|pipe0_exception_wb_w) ? pipe0_exception_ecode_wb_w :
                                         pipe1_exception_ecode_wb_w;
assign csr_writeback_valid_o          = pipe0_csr_wb_w;
wire pipe0_fetch_exception_w = (pipe0_exception_wb_w == `EXCEPTION_FAULT_FETCH) ||
                               (pipe0_exception_wb_w == `EXCEPTION_MISALIGNED_FETCH) ||
                               (pipe0_exception_wb_w == `EXCEPTION_PAGE_FAULT_INST);
wire pipe1_fetch_exception_w = (pipe1_exception_wb_w == `EXCEPTION_FAULT_FETCH) ||
                               (pipe1_exception_wb_w == `EXCEPTION_MISALIGNED_FETCH) ||
                               (pipe1_exception_wb_w == `EXCEPTION_PAGE_FAULT_INST);
assign csr_writeback_exception_pc_o   = (|pipe0_exception_wb_w) ?
                                        (pipe0_fetch_exception_w ? pipe0_result_wb_w : pipe0_pc_wb_w) :
                                        (pipe1_fetch_exception_w ? pipe1_exception_result_wb_w : pipe1_pc_wb_w);
assign csr_writeback_exception_addr_o = (|pipe0_exception_wb_w) ? pipe0_result_wb_w :
                                        pipe1_exception_result_wb_w;

//-------------------------------------------------------------
// Branch predictor info
//-------------------------------------------------------------
// This info is used to learn future prediction, and to correct 
// BTB, BHT, GShare, RAS indexes on mispredictions.
wire branch_info_pipe1_sel_w      = pipe1_branch_e1_w & branch_exec1_request_i;
wire branch_info_pipe0_sel_w      = pipe0_branch_e1_w & branch_exec0_request_i;
wire branch_info_resolve_valid_w  = branch_info_pipe1_sel_w | branch_info_pipe0_sel_w;

assign branch_info_request_o      = branch_info_resolve_valid_w &
                                    (mispredicted_r | branch_not_taken_mispredict_w |
                                     branch_taken_mispredict_w);
assign branch_info_is_taken_o     = (branch_info_pipe1_sel_w & branch_exec1_is_taken_i)     |
                                    (branch_info_pipe0_sel_w & branch_exec0_is_taken_i);
assign branch_info_is_not_taken_o = (branch_info_pipe1_sel_w & branch_exec1_is_not_taken_i) |
                                    (branch_info_pipe0_sel_w & branch_exec0_is_not_taken_i);
assign branch_info_is_call_o      = (branch_info_pipe1_sel_w & branch_exec1_is_call_i)      |
                                    (branch_info_pipe0_sel_w & branch_exec0_is_call_i);
assign branch_info_is_ret_o       = (branch_info_pipe1_sel_w & branch_exec1_is_ret_i)       |
                                    (branch_info_pipe0_sel_w & branch_exec0_is_ret_i);
assign branch_info_is_jmp_o       = (branch_info_pipe1_sel_w & branch_exec1_is_jmp_i)       |
                                    (branch_info_pipe0_sel_w & branch_exec0_is_jmp_i);
assign branch_info_source_o       = branch_info_pipe1_sel_w ? branch_exec1_source_i :
                                    branch_info_pipe0_sel_w ? branch_exec0_source_i :
                                                              32'b0;
assign branch_info_pc_o           = branch_info_pipe1_sel_w ? branch_exec1_pc_i :
                                    branch_info_pipe0_sel_w ? branch_exec0_pc_i :
                                                              32'b0;

`ifdef BPU_PERF
wire bpu_perf_pipe1_select_w = branch_info_pipe1_sel_w;
wire bpu_perf_actual_taken_w = bpu_perf_pipe1_select_w ? branch_exec1_is_taken_i :
                                                          branch_exec0_is_taken_i;
wire bpu_perf_pred_taken_w   = bpu_perf_pipe1_select_w ? pipe1_pred_branch_e1_w :
                                                          pipe0_pred_branch_e1_w;
wire [31:0] bpu_perf_opcode_w = bpu_perf_pipe1_select_w ? pipe1_opcode_e1_w :
                                                           pipe0_opcode_e1_w;
wire bpu_perf_inst_jirl_w    = bpu_perf_opcode_w[`LA_OP_31_26_R] == 6'h13;
wire bpu_perf_resolve_valid_w = branch_info_resolve_valid_w;
wire bpu_perf_is_jmp_w       = bpu_perf_pipe1_select_w ? branch_exec1_is_jmp_i :
                                                          branch_exec0_is_jmp_i;
wire bpu_perf_is_ret_w       = bpu_perf_pipe1_select_w ? branch_exec1_is_ret_i :
                                                          branch_exec0_is_ret_i;
wire bpu_perf_is_call_w      = bpu_perf_pipe1_select_w ? branch_exec1_is_call_i :
                                                          branch_exec0_is_call_i;
wire bpu_perf_direction_miss_w = bpu_perf_pred_taken_w ^ bpu_perf_actual_taken_w;
wire bpu_perf_target_miss_w  = bpu_perf_pred_taken_w & bpu_perf_actual_taken_w &
                               mispredicted_r;
wire bpu_perf_correct_w      = ~bpu_perf_direction_miss_w &
                               ~bpu_perf_target_miss_w;

assign bpu_perf_valid_o            = bpu_perf_resolve_valid_w;
assign bpu_perf_is_branch_o        = bpu_perf_resolve_valid_w & ~bpu_perf_is_jmp_w &
                                     ~bpu_perf_is_call_w & ~bpu_perf_is_ret_w;
assign bpu_perf_is_jump_o          = bpu_perf_resolve_valid_w &
                                     (bpu_perf_is_jmp_w | bpu_perf_is_call_w |
                                      bpu_perf_is_ret_w);
assign bpu_perf_is_ret_jirl_o      = bpu_perf_resolve_valid_w & bpu_perf_is_ret_w;
assign bpu_perf_is_indirect_jirl_o = bpu_perf_resolve_valid_w &
                                     bpu_perf_inst_jirl_w & bpu_perf_is_jmp_w;
assign bpu_perf_pc_o               = bpu_perf_pipe1_select_w ? branch_exec1_source_i :
                                                                branch_exec0_source_i;
assign bpu_perf_pred_taken_o       = bpu_perf_pred_taken_w;
assign bpu_perf_actual_taken_o     = bpu_perf_actual_taken_w;
assign bpu_perf_correct_o          = bpu_perf_correct_w;
assign bpu_perf_direction_miss_o   = bpu_perf_direction_miss_w;
assign bpu_perf_target_miss_o      = bpu_perf_target_miss_w;
assign bpu_perf_exu_flush_o        = bpu_perf_resolve_valid_w & mispredicted_r;
`endif
`ifdef PERF_MONI
wire pipe0_perf_stall_div_w;
wire pipe0_perf_stall_mem_w;
wire pipe0_perf_stall_mul_w;
wire pipe1_perf_stall_div_w;
wire pipe1_perf_stall_mem_w;
wire pipe1_perf_stall_mul_w;

assign perf_iq_count_o     = issue_count_q;
assign perf_stall_div_o    = pipe0_perf_stall_div_w | pipe1_perf_stall_div_w;
assign perf_stall_mem_o    = pipe0_perf_stall_mem_w | pipe1_perf_stall_mem_w;
assign perf_stall_mul_o    = pipe0_perf_stall_mul_w | pipe1_perf_stall_mul_w;
// "issue queue empty" really means dispatch slot has nothing to send. We use
// !opcode_a_valid_r so divider/csr-pending and lsu_stall don't pollute the count.
assign perf_iq_empty_o     = ~opcode_a_valid_r;
assign perf_lsu_stall_o    = lsu_stall_i;
// One slot issues, the other doesn't (slot1 starvation due to dual-issue conflict).
assign perf_single_issue_o = single_issue_w;
// Sub-categories of single_issue, mutually exclusive in priority order.
assign perf_slot1_no_inst_o    = single_issue_w & ~opcode_b_valid_r;
assign perf_slot1_type_block_o = single_issue_w &  opcode_b_valid_r & ~dual_issue_ok_w;
// Catch-all after the above two: dual-issue allowed, slot1 has inst, but issue logic refused.
// In practice this is the scoreboard (operand) hazard plus minor exception-issue blocks.
assign perf_slot1_dep_block_o  = single_issue_w &  opcode_b_valid_r &  dual_issue_ok_w & ~opcode_b_issue_r;
// IQ enqueue events. Mutually exclusive across {dual, single_*}; sum = total pushes.
//   dual              : both slots fetched, slot0 not a taken branch
//   single_taken      : slot0 enqueued but suppressed slot1 via predicted-taken branch
//   single_upper      : packet entered at upper (pc[2]=1), only slot1 valid; pushed as single slot0
//   single_no_fetch1  : lower-aligned packet but fetch1 invalid (e.g., upstream fault) and slot0 not branch
assign perf_enq_dual_o             = fetch_enqueue0_r &  fetch_enqueue1_r;
assign perf_enq_single_taken_o     = fetch_enqueue0_r & ~fetch_enqueue1_r &  fetch0_pred_branch_i;
assign perf_enq_single_upper_o     = fetch_enqueue_upper_only_w;
assign perf_enq_single_no_fetch1_o = fetch_enqueue0_r & ~fetch_enqueue1_r & ~fetch0_pred_branch_i;

// Flush-recovery window: loads N=12 on any flush event, counts down each cycle.
// Used to attribute iq_empty cycles to either "post-flush refill bubble" or
// "steady-state starvation" (e.g. ICache miss with no pending flush).
reg [3:0] flush_window_q;
wire any_flush_w = branch_redirect_flush_w | branch_csr_request_i | squash_w | mispredicted_r;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    flush_window_q <= 4'd0;
else if (any_flush_w)
    flush_window_q <= 4'd12;
else if (|flush_window_q)
    flush_window_q <= flush_window_q - 4'd1;

assign perf_iq_empty_after_flush_o = perf_iq_empty_o &  (|flush_window_q);
assign perf_iq_empty_steady_o      = perf_iq_empty_o & ~(|flush_window_q);
`endif

//-------------------------------------------------------------
// Blocking events (division, CSR unit access)
//-------------------------------------------------------------
reg div_pending_q;
reg [2:0] mul_pending_q;
reg csr_pending_q;
wire mul_pending_ret_w = (mul_pending_q != 3'b0) && writeback_mul_valid_i;

// Division operations take 2 - 34 cycles and stall
// the pipeline (complete out-of-pipe) until completed.
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    div_pending_q <= 1'b0;
else if (squash_now_w)
    div_pending_q <= 1'b0;
else if (div_opcode_valid_o && issue_a_div_w)
    div_pending_q <= 1'b1;
else if (writeback_div_valid_i)
    div_pending_q <= 1'b0;

// Legacy multiply pending counter is only used by the old in-pipe multiplier
// contract. CPU_REAL_MDU has its own ordered retire queue above.
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mul_pending_q <= 3'b0;
else if (squash_now_w)
    mul_pending_q <= 3'b0;
else
    mul_pending_q <= 3'b0;

// CSR operations are infrequent - avoid any complications of pipelining them.
// These only take a 2-3 cycles anyway and may result in a pipe flush (e.g. ecall, ebreak..).
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    csr_pending_q <= 1'b0;
else if (branch_csr_request_i)
    csr_pending_q <= 1'b0;
else if (csr_opcode_valid_o && issue_a_csr_w)
    csr_pending_q <= 1'b1;
else if (pipe0_csr_wb_w && (pipe0_exception_wb_w == `EXCEPTION_W'b0))
    csr_pending_q <= 1'b0;

assign squash_now_w = pipe0_squash_e1_e2_w || pipe1_squash_to_pipe0_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    squash_issue_q <= 1'b0;
else
    squash_issue_q <= squash_now_w;

assign squash_w = squash_issue_q;

//-------------------------------------------------------------
// Issue / scheduling logic
//-------------------------------------------------------------
reg [31:0] scoreboard_r;
reg        pipe1_mux_lsu_r;
reg        pipe1_mux_mul_r;
wire       issue_a_lsu_skiddable_w = !issue_a_priv_fault_w &&
                                     (issue0_load_w || issue0_store_w);
wire       issue_b_lsu_skiddable_w = !issue_b_priv_fault_w &&
                                     (issue1_load_w || issue1_store_w);
wire       issue_a_skid_safe_w     = issue_a_exec_w ||
                                     (issue_a_lsu_w && issue_a_lsu_skiddable_w);
wire       issue_b_skid_safe_w     = issue_b_exec_w ||
                                     (issue_b_lsu_w && issue_b_lsu_skiddable_w);
wire       issue_b_load_w          = issue_b_lsu_w && issue1_load_w;
wire       issue_b_store_w         = issue_b_lsu_w && issue1_store_w;
wire       issue_b_slot1_alu_ok_w  = issue_b_exec_w && enable_slot1_alu_w;
wire       issue_b_slot1_branch_ok_w = issue_b_branch_w && enable_slot1_branch_w;
`ifdef CPU_REAL_MDU
wire       issue_lsu_overlap_block_w =
	            pipe0_load_e1_w || pipe0_store_e1_w ||
	            pipe1_load_e1_w || pipe1_store_e1_w ||
	            lsu_stall_i;
wire       slot1_lsu_overlap_block_w = issue_lsu_overlap_block_w;
wire       issue_a_lsu_overlap_ok_w  = !issue_a_lsu_w || !issue_lsu_overlap_block_w;
`else
wire       issue_lsu_overlap_block_w = 1'b0;
wire       slot1_lsu_overlap_block_w = 1'b0;
wire       issue_a_lsu_overlap_ok_w  = 1'b1;
`endif
wire       issue_b_slot1_lsu_ok_w  = issue_b_lsu_w &&
                                     !slot1_lsu_overlap_block_w &&
                                     ((issue_b_load_w && enable_slot1_load_w) ||
                                      (issue_b_store_w && enable_slot1_store_w) ||
                                      (!issue_b_load_w && !issue_b_store_w && enable_slot1_load_w));
wire       issue_b_slot1_mul_ok_w  = issue_b_mul_w && enable_slot1_mul_w;
wire       issue_a_real_mdu_mul_w  = issue_a_real_mdu_detach_w;
wire       issue_a_dual_pipe_mul_w = issue_a_pipe_mul_w;
`ifdef CPU_REAL_MDU
wire       issue_a_real_mdu_req_w  = opcode_a_issue_w && issue_a_real_mdu_detach_w;
wire       issue_b_real_mdu_req_w  = opcode_b_issue_w && issue_b_real_mdu_detach_w;
wire       issue_a_mul_req_w       = issue_a_real_mdu_req_w;
wire       issue_b_mul_req_w       = issue_b_real_mdu_req_w;
wire       issue_dual_mul_w        = issue_a_real_mdu_req_w &&
                                     issue_b_real_mdu_req_w;
wire       issue_mul_selected_w    = issue_a_real_mdu_req_w | issue_b_real_mdu_req_w;
wire       issue_a_real_mdu_control_block_w =
            real_mdu_live_pending_w &&
            (issue_a_lsu_w || issue_a_csr_w || issue_a_div_w ||
             issue_a_invalid_w || issue_a_fault_any_w || issue_a_priv_fault_w);
wire       issue_b_real_mdu_control_block_w =
            real_mdu_live_pending_w &&
            (issue_b_lsu_w || issue_b_csr_w || issue_b_div_w ||
             issue_b_invalid_w || issue_b_fault_any_w || issue_b_priv_fault_w);
wire       issue_a_real_mdu_load_e2_dep_w =
            (SUPPORT_LOAD_BYPASS != 0) && issue_a_real_mdu_detach_w &&
            ((((|issue_a_ra_idx_w) &&
               ((pipe0_load_e2_w && (pipe0_rd_e2_w == issue_a_ra_idx_w)) ||
                (pipe1_load_e2_w && (pipe1_rd_e2_w == issue_a_ra_idx_w)))) ||
              ((|issue_a_rb_idx_w) &&
               ((pipe0_load_e2_w && (pipe0_rd_e2_w == issue_a_rb_idx_w)) ||
                (pipe1_load_e2_w && (pipe1_rd_e2_w == issue_a_rb_idx_w))))));
wire       issue_b_real_mdu_load_e2_dep_w =
            (SUPPORT_LOAD_BYPASS != 0) && issue_b_real_mdu_detach_w &&
            ((((|issue_b_ra_idx_w) &&
               ((pipe0_load_e2_w && (pipe0_rd_e2_w == issue_b_ra_idx_w)) ||
                (pipe1_load_e2_w && (pipe1_rd_e2_w == issue_b_ra_idx_w)))) ||
              ((|issue_b_rb_idx_w) &&
               ((pipe0_load_e2_w && (pipe0_rd_e2_w == issue_b_rb_idx_w)) ||
                (pipe1_load_e2_w && (pipe1_rd_e2_w == issue_b_rb_idx_w))))));
wire       issue_a_real_mdu_space_ok_w =
            !issue_a_mul_w ||
            (!issue_a_real_mdu_load_e2_dep_w && real_mdu_accept_one_w);
wire       issue_b_real_mdu_space_ok_w =
            !issue_b_mul_w ||
            (!issue_b_real_mdu_load_e2_dep_w &&
             (issue_a_real_mdu_detach_w ? real_mdu_accept_two_w : real_mdu_accept_one_w));
wire       legacy_mul_pending_w = 1'b0;
`else
wire       issue_a_real_mdu_req_w  = 1'b0;
wire       issue_b_real_mdu_req_w  = 1'b0;
wire       issue_a_mul_req_w       = opcode_a_issue_w && issue_a_mul_w;
wire       issue_b_mul_req_w       = opcode_b_issue_w && issue_b_mul_w;
wire       issue_dual_mul_w        = 1'b0;
wire       issue_mul_selected_w    = pipe1_mux_mul_r ? issue_b_mul_req_w : issue_a_mul_req_w;
wire       issue_a_real_mdu_control_block_w = 1'b0;
wire       issue_b_real_mdu_control_block_w = 1'b0;
wire       issue_a_real_mdu_load_e2_dep_w = 1'b0;
wire       issue_b_real_mdu_load_e2_dep_w = 1'b0;
wire       issue_a_real_mdu_space_ok_w = 1'b1;
wire       issue_b_real_mdu_space_ok_w = 1'b1;
wire       legacy_mul_pending_w = mul_pending_q != 3'b0;
`endif
`ifdef CPU_REAL_MDU
wire       lsu_skid_issue_ok_w = lsu_skid_ready_i &&
                                 !div_pending_q && !legacy_mul_pending_w &&
                                 !real_mdu_live_pending_w && !csr_pending_q &&
                                 opcode_a_valid_r &&
                                 issue_a_skid_safe_w &&
                                 issue_a_lsu_overlap_ok_w &&
                                 !take_interrupt_i && !squash_now_w;
`else
wire       lsu_skid_issue_ok_w = lsu_skid_ready_i &&
                                 !div_pending_q && !legacy_mul_pending_w && !csr_pending_q &&
                                 opcode_a_valid_r &&
                                 issue_a_skid_safe_w &&
                                 !take_interrupt_i && !squash_now_w;
`endif

// Check instructions can be issued in the second execution unit
wire pipe1_ok_w      = issue_b_slot1_alu_ok_w | issue_b_slot1_branch_ok_w |
                       issue_b_slot1_lsu_ok_w | issue_b_slot1_mul_ok_w;

// Is this combination of instructions possible to execute concurrently.
// This excludes result dependencies which may also block secondary execution.
wire dual_issue_ok_w =   enable_dual_issue_w &&  // Second pipe switched on
                        !issue_a_priv_fault_w &&
                         pipe1_ok_w &&           // Instruction 2 is possible on second exec unit
                        (((issue_a_exec_w | issue_a_lsu_w | issue_a_dual_pipe_mul_w) && issue_b_slot1_alu_ok_w)   ||
                         ((issue_a_exec_w | issue_a_lsu_w | issue_a_dual_pipe_mul_w) && issue_b_slot1_branch_ok_w) ||
                         ((issue_a_exec_w | issue_a_dual_pipe_mul_w) && issue_b_slot1_lsu_ok_w)                    ||
                         ((issue_a_exec_w | issue_a_lsu_w) && issue_b_slot1_mul_ok_w)                              ||
                         ( issue_a_real_mdu_mul_w        && issue_b_slot1_mul_ok_w)
                         ) && ~take_interrupt_i;

always @ *
begin
    opcode_a_issue_r     = 1'b0;
    opcode_b_issue_r     = 1'b0;
    opcode_a_accept_r    = 1'b0;
    opcode_b_accept_r    = 1'b0;
    scoreboard_r         = 32'b0;
    pipe1_mux_lsu_r      = 1'b0;
    pipe1_mux_mul_r      = 1'b0;

    // Execution units with >= 2 cycle latency. With load bypass disabled,
    // dependent consumers wait for the registered WB path instead of using
    // the timing-critical same-cycle D-cache result path.
    if (SUPPORT_LOAD_BYPASS == 0)
    begin
        if (pipe0_load_e2_w)
            scoreboard_r[pipe0_rd_e2_w] = 1'b1;
        if (pipe1_load_e2_w)
            scoreboard_r[pipe1_rd_e2_w] = 1'b1;
    end
    if (SUPPORT_MUL_BYPASS == 0)
    begin
        if (pipe0_mul_e2_w)
            scoreboard_r[pipe0_rd_e2_w] = 1'b1;
        if (pipe1_mul_e2_w)
            scoreboard_r[pipe1_rd_e2_w] = 1'b1;
    end
`ifdef CPU_REAL_MDU
    scoreboard_r = scoreboard_r | real_mdu_scoreboard_w;
`endif

    // Execution units with >= 1 cycle latency (loads / multiply)
    if (pipe0_load_e1_w || pipe0_mul_e1_w)
        scoreboard_r[pipe0_rd_e1_w] = 1'b1;
    if (pipe1_load_e1_w || pipe1_mul_e1_w)
        scoreboard_r[pipe1_rd_e1_w] = 1'b1;

    // Do not start multiply, division or CSR operation in the cycle after a load (leaving only ALU operations and branches)
    if ((pipe0_load_e1_w || pipe0_store_e1_w || pipe1_load_e1_w || pipe1_store_e1_w ) && (issue_a_mul_w || issue_a_div_w || issue_a_csr_w))
        scoreboard_r = 32'hFFFFFFFF;

    // LSU wait window: accept one safe primary-slot instruction while the
    // previous LSU request is waiting for D-cache accept. Load/store requests
    // are captured by the LSU registered input boundary; ALU work waits behind
    // the older memory op in the pipe. Control and sideband instructions remain
    // blocked.
    if (lsu_skid_issue_ok_w &&
        !exception_issue_block_w &&
        !(((|issue_a_ra_idx_w) && scoreboard_r[issue_a_ra_idx_w]) ||
          ((|issue_a_rb_idx_w) && scoreboard_r[issue_a_rb_idx_w]) ||
          ((|issue_a_rd_idx_w) && scoreboard_r[issue_a_rd_idx_w])))
    begin
        opcode_a_issue_r  = 1'b1;
        opcode_a_accept_r = 1'b1;

        if (opcode_a_accept_r && issue_a_sb_alloc_w && (|issue_a_rd_idx_w))
            scoreboard_r[issue_a_rd_idx_w] = 1'b1;
    end
    // Stall - no issues...
    else if (lsu_stall_i || div_pending_q || legacy_mul_pending_w || csr_pending_q ||
             exception_issue_block_w || issue_a_real_mdu_control_block_w)
        ;
    // Primary slot (lsu, branch, alu, mul, div, csr)
    else if (opcode_a_valid_r && !exception_issue_block_w &&
        issue_a_real_mdu_space_ok_w &&
        issue_a_lsu_overlap_ok_w &&
        !(((|issue_a_ra_idx_w) && scoreboard_r[issue_a_ra_idx_w]) ||
          ((|issue_a_rb_idx_w) && scoreboard_r[issue_a_rb_idx_w]) ||
          ((|issue_a_rd_idx_w) && scoreboard_r[issue_a_rd_idx_w])))
    begin
        opcode_a_issue_r  = 1'b1;
        opcode_a_accept_r = 1'b1;

        if (opcode_a_accept_r && issue_a_sb_alloc_w && (|issue_a_rd_idx_w))
            scoreboard_r[issue_a_rd_idx_w] = 1'b1;
    end

    // Stall - no issues...
    if ((lsu_stall_i && !opcode_a_accept_r) ||
        div_pending_q || legacy_mul_pending_w || csr_pending_q ||
        exception_issue_block_w || issue_a_real_mdu_control_block_w)
        ;
    // Secondary slot in the LSU skid window. Keep this to ALU and ordinary
    // load/store traffic; control and sideband operations wait for full drain.
    else if (lsu_stall_i && opcode_a_accept_r &&
        dual_issue_ok_w && opcode_b_valid_r && issue_b_skid_safe_w &&
        !issue_b_real_mdu_control_block_w && issue_b_real_mdu_space_ok_w &&
        !(((|issue_b_ra_idx_w) && scoreboard_r[issue_b_ra_idx_w]) ||
          ((|issue_b_rb_idx_w) && scoreboard_r[issue_b_rb_idx_w]) ||
          ((|issue_b_rd_idx_w) && scoreboard_r[issue_b_rd_idx_w])))
    begin
        opcode_b_issue_r  = 1'b1;
        opcode_b_accept_r = 1'b1;
        pipe1_mux_lsu_r   = issue_b_lsu_w;
        pipe1_mux_mul_r   = 1'b0;

        if (opcode_b_accept_r && issue_b_sb_alloc_w && (|issue_b_rd_idx_w))
            scoreboard_r[issue_b_rd_idx_w] = 1'b1;
    end
    // Secondary Slot (lsu, branch, alu, mul)
    else if (dual_issue_ok_w && opcode_b_valid_r && opcode_a_accept_r &&
        !issue_b_real_mdu_control_block_w && issue_b_real_mdu_space_ok_w &&
        !(((|issue_b_ra_idx_w) && scoreboard_r[issue_b_ra_idx_w]) ||
          ((|issue_b_rb_idx_w) && scoreboard_r[issue_b_rb_idx_w]) ||
          ((|issue_b_rd_idx_w) && scoreboard_r[issue_b_rd_idx_w])))
    begin
        opcode_b_issue_r  = 1'b1;
        opcode_b_accept_r = 1'b1;
        pipe1_mux_lsu_r   = issue_b_lsu_w;
        pipe1_mux_mul_r   = issue_b_mul_w && !issue_a_mul_w;

        if (opcode_b_accept_r && issue_b_sb_alloc_w && (|issue_b_rd_idx_w))
            scoreboard_r[issue_b_rd_idx_w] = 1'b1;
    end    
end

wire       lsu_opcode_priv_fault_w = pipe1_mux_lsu_r ? issue_b_priv_fault_w : issue_a_priv_fault_w;
assign lsu_opcode_valid_o   = (pipe1_mux_lsu_r ? (opcode_b_issue_w & issue_b_lsu_w) :
                                                      (opcode_a_issue_w & issue_a_lsu_w)) &
                               ~lsu_opcode_priv_fault_w & ~take_interrupt_i & issue_sideband_valid_w;
assign issue_pipe0_valid_w  = opcode_a_issue_w & issue_sideband_valid_w & ~issue_head_csr_irq_hold_w;
assign issue_pipe1_valid_w  = opcode_b_issue_w & issue_sideband_valid_w;

`ifdef CPU_REAL_MDU
assign exec0_opcode_valid_o = issue_pipe0_valid_w & !issue_a_real_mdu_detach_w;
`else
assign exec0_opcode_valid_o = issue_pipe0_valid_w;
`endif
assign mul_opcode_valid_o   = enable_muldiv_w & issue_mul_selected_w & issue_sideband_valid_w;
assign div_opcode_valid_o   = enable_muldiv_w & opcode_a_issue_w & issue_sideband_valid_w;
`ifdef CPU_REAL_MDU
assign interrupt_inhibit_o  = csr_pending_q ||
                              real_mdu_live_pending_w ||
                              issue_head_csr_w;
`else
assign interrupt_inhibit_o  = csr_pending_q ||
                              issue_head_csr_w;
`endif

`ifdef CPU_REAL_MDU
assign exec1_opcode_valid_o = issue_pipe1_valid_w & !issue_b_real_mdu_detach_w;
`else
assign exec1_opcode_valid_o = issue_pipe1_valid_w;
`endif

assign dual_issue_w         = opcode_b_issue_w & opcode_b_accept_w & ~take_interrupt_i;
assign single_issue_w       = (opcode_a_issue_w & opcode_a_accept_w) & ~dual_issue_w & ~take_interrupt_i;

assign fetch0_accept_o      = (fetch_enqueue0_r | (fetch_enqueue_upper_only_w && fetch0_valid_i)) &
                              (~take_interrupt_i | fetch_irq_empty_enqueue_w);
assign fetch1_accept_o      = fetch_enqueue1_r & (~take_interrupt_i | fetch_irq_empty_enqueue_w);

`ifdef CPU_REAL_MDU
assign stall_w              = pipe0_stall_raw_w | pipe1_stall_raw_w |
                              real_mdu_commit_stall_w;
`else
assign stall_w              = pipe0_stall_raw_w | pipe1_stall_raw_w;
`endif

//-------------------------------------------------------------
// Register File
//------------------------------------------------------------- 
wire [31:0] issue_a_ra_value_w;
wire [31:0] issue_a_rb_value_w;
wire [31:0] issue_b_ra_value_w;
wire [31:0] issue_b_rb_value_w;

// Register file: 2W4R
biloong_regfile
#(
     .SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX)
    ,.SUPPORT_DUAL_ISSUE(SUPPORT_DUAL_ISSUE)
)
u_regfile
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Write ports
    .rd0_i(pipe0_rd_wb_w),
    .rd0_value_i(pipe0_result_wb_w),
    .rd1_i(pipe1_rd_wb_w),
    .rd1_value_i(pipe1_result_wb_w),

    // Read ports
    .ra0_i(issue_a_ra_idx_rf_w),
    .rb0_i(issue_a_rb_idx_rf_w),
    .ra0_value_o(issue_a_ra_value_w),
    .rb0_value_o(issue_a_rb_value_w),

    .ra1_i(issue_b_ra_idx_rf_w),
    .rb1_i(issue_b_rb_idx_rf_w),
    .ra1_value_o(issue_b_ra_value_w),
    .rb1_value_o(issue_b_rb_value_w)    
);

//-------------------------------------------------------------
// Issue Slot 0
//------------------------------------------------------------- 
assign opcode0_opcode_o = opcode_a_r;
assign opcode0_pc_o     = opcode_a_pc_r;
assign opcode0_rd_idx_o = issue_a_rd_idx_w;
assign opcode0_ra_idx_o = issue_a_ra_idx_w;
assign opcode0_rb_idx_o = issue_a_rb_idx_w;
assign opcode0_alu_func_o = issue0_alu_func_w;
assign opcode0_alu_a_sel_o = issue0_alu_a_sel_w;
assign opcode0_alu_b_sel_o = issue0_alu_b_sel_w;
assign opcode0_direct_func_o = issue0_direct_func_w;
assign opcode0_branch_func_o = issue0_branch_func_w;
assign opcode0_imm_o = issue0_imm_w;
assign opcode0_invalid_o= 1'b0; 

reg [31:0] issue_a_ra_value_r;
reg [31:0] issue_a_rb_value_r;

always @ *
begin
    // NOTE: Newest version of operand takes priority
    issue_a_ra_value_r = issue_a_ra_value_w;
    issue_a_rb_value_r = issue_a_rb_value_w;

    // Bypass - WB.  Forwarding compares use raw (slot-valid-only) RF read
    // indexes to keep fault/invalid/priv gates out of this timing cone. Slot
    // is not issued when invalid, so a spurious match is harmless.
    if (pipe0_wb_fwd_issue_valid_w && (pipe0_rd_wb_raw_w == issue_a_ra_idx_rf_w))
        issue_a_ra_value_r = pipe0_result_wb_w;
    if (pipe0_wb_fwd_issue_valid_w && (pipe0_rd_wb_raw_w == issue_a_rb_idx_rf_w))
        issue_a_rb_value_r = pipe0_result_wb_w;

    if (pipe1_wb_fwd_issue_valid_w && (pipe1_rd_wb_raw_w == issue_a_ra_idx_rf_w))
        issue_a_ra_value_r = pipe1_result_wb_w;
    if (pipe1_wb_fwd_issue_valid_w && (pipe1_rd_wb_raw_w == issue_a_rb_idx_rf_w))
        issue_a_rb_value_r = pipe1_result_wb_w;

`ifdef CPU_REAL_MDU
    if (real_mdu_fwd_a_ra_hit_w)
        issue_a_ra_value_r = real_mdu_fwd_a_ra_value_w;
    if (real_mdu_fwd_a_rb_hit_w)
        issue_a_rb_value_r = real_mdu_fwd_a_rb_value_w;
`endif

    // Bypass - E2
    if (pipe0_rd_e2_w == issue_a_ra_idx_rf_w)
        issue_a_ra_value_r = pipe0_result_e2_fwd_w;
    if (pipe0_rd_e2_w == issue_a_rb_idx_rf_w)
        issue_a_rb_value_r = pipe0_result_e2_fwd_w;

    if (pipe1_rd_e2_w == issue_a_ra_idx_rf_w)
        issue_a_ra_value_r = pipe1_result_e2_fwd_w;
    if (pipe1_rd_e2_w == issue_a_rb_idx_rf_w)
        issue_a_rb_value_r = pipe1_result_e2_fwd_w;

    // Bypass - E1
    if (pipe0_rd_e1_w == issue_a_ra_idx_rf_w)
        issue_a_ra_value_r = writeback_exec0_value_i;
    if (pipe0_rd_e1_w == issue_a_rb_idx_rf_w)
        issue_a_rb_value_r = writeback_exec0_value_i;

    if (pipe1_rd_e1_w == issue_a_ra_idx_rf_w)
        issue_a_ra_value_r = writeback_exec1_value_i;
    if (pipe1_rd_e1_w == issue_a_rb_idx_rf_w)
        issue_a_rb_value_r = writeback_exec1_value_i;

    // Reg 0 source
    if (issue_a_ra_idx_w == 5'b0)
        issue_a_ra_value_r = 32'b0;
    if (issue_a_rb_idx_w == 5'b0)
        issue_a_rb_value_r = 32'b0;
end

assign opcode0_ra_operand_o = issue_a_ra_value_r;
assign opcode0_rb_operand_o = issue_a_rb_value_r;

//-------------------------------------------------------------
// Issue Slot 1
//------------------------------------------------------------- 
assign opcode1_opcode_o = opcode_b_r;
assign opcode1_pc_o     = opcode_b_pc_r;
assign opcode1_rd_idx_o = issue_b_rd_idx_w;
assign opcode1_ra_idx_o = issue_b_ra_idx_w;
assign opcode1_rb_idx_o = issue_b_rb_idx_w;
assign opcode1_alu_func_o = issue1_alu_func_w;
assign opcode1_alu_a_sel_o = issue1_alu_a_sel_w;
assign opcode1_alu_b_sel_o = issue1_alu_b_sel_w;
assign opcode1_direct_func_o = issue1_direct_func_w;
assign opcode1_branch_func_o = issue1_branch_func_w;
assign opcode1_imm_o = issue1_imm_w;
assign opcode1_invalid_o= 1'b0;

reg [31:0] issue_b_ra_value_r;
reg [31:0] issue_b_rb_value_r;

always @ *
begin
    // NOTE: Newest version of operand takes priority
    issue_b_ra_value_r = issue_b_ra_value_w;
    issue_b_rb_value_r = issue_b_rb_value_w;

    // Bypass - WB. See slot 0 note: forwarding compares use raw RF read
    // indexes to keep fault/invalid/priv gates out of this timing cone.
    if (pipe0_wb_fwd_issue_valid_w && (pipe0_rd_wb_raw_w == issue_b_ra_idx_rf_w))
        issue_b_ra_value_r = pipe0_result_wb_w;
    if (pipe0_wb_fwd_issue_valid_w && (pipe0_rd_wb_raw_w == issue_b_rb_idx_rf_w))
        issue_b_rb_value_r = pipe0_result_wb_w;

    if (pipe1_wb_fwd_issue_valid_w && (pipe1_rd_wb_raw_w == issue_b_ra_idx_rf_w))
        issue_b_ra_value_r = pipe1_result_wb_w;
    if (pipe1_wb_fwd_issue_valid_w && (pipe1_rd_wb_raw_w == issue_b_rb_idx_rf_w))
        issue_b_rb_value_r = pipe1_result_wb_w;

`ifdef CPU_REAL_MDU
    if (real_mdu_fwd_b_ra_hit_w)
        issue_b_ra_value_r = real_mdu_fwd_b_ra_value_w;
    if (real_mdu_fwd_b_rb_hit_w)
        issue_b_rb_value_r = real_mdu_fwd_b_rb_value_w;
`endif

    // Bypass - E2
    if (pipe0_rd_e2_w == issue_b_ra_idx_rf_w)
        issue_b_ra_value_r = pipe0_result_e2_fwd_w;
    if (pipe0_rd_e2_w == issue_b_rb_idx_rf_w)
        issue_b_rb_value_r = pipe0_result_e2_fwd_w;

    if (pipe1_rd_e2_w == issue_b_ra_idx_rf_w)
        issue_b_ra_value_r = pipe1_result_e2_fwd_w;
    if (pipe1_rd_e2_w == issue_b_rb_idx_rf_w)
        issue_b_rb_value_r = pipe1_result_e2_fwd_w;

    // Bypass - E1
    if (pipe0_rd_e1_w == issue_b_ra_idx_rf_w)
        issue_b_ra_value_r = writeback_exec0_value_i;
    if (pipe0_rd_e1_w == issue_b_rb_idx_rf_w)
        issue_b_rb_value_r = writeback_exec0_value_i;

    if (pipe1_rd_e1_w == issue_b_ra_idx_rf_w)
        issue_b_ra_value_r = writeback_exec1_value_i;
    if (pipe1_rd_e1_w == issue_b_rb_idx_rf_w)
        issue_b_rb_value_r = writeback_exec1_value_i;

    // Reg 0 source
    if (issue_b_ra_idx_w == 5'b0)
        issue_b_ra_value_r = 32'b0;
    if (issue_b_rb_idx_w == 5'b0)
        issue_b_rb_value_r = 32'b0;
end

assign opcode1_ra_operand_o = issue_b_ra_value_r;
assign opcode1_rb_operand_o = issue_b_rb_value_r;

//-------------------------------------------------------------
// Load store unit
//-------------------------------------------------------------
assign lsu_opcode_opcode_o      = pipe1_mux_lsu_r ? opcode1_opcode_o     : opcode0_opcode_o;
assign lsu_opcode_pc_o          = pipe1_mux_lsu_r ? opcode1_pc_o         : opcode0_pc_o;
assign lsu_opcode_rd_idx_o      = pipe1_mux_lsu_r ? opcode1_rd_idx_o     : opcode0_rd_idx_o;
assign lsu_opcode_ra_idx_o      = pipe1_mux_lsu_r ? opcode1_ra_idx_o     : opcode0_ra_idx_o;
assign lsu_opcode_rb_idx_o      = pipe1_mux_lsu_r ? opcode1_rb_idx_o     : opcode0_rb_idx_o;
assign lsu_opcode_ra_operand_o  = pipe1_mux_lsu_r ? opcode1_ra_operand_o : opcode0_ra_operand_o;
assign lsu_opcode_rb_operand_o  = pipe1_mux_lsu_r ? opcode1_rb_operand_o : opcode0_rb_operand_o;
assign lsu_opcode_invalid_o     = 1'b0;
assign lsu_opcode_pipe1_o        = pipe1_mux_lsu_r;

//-------------------------------------------------------------
// Multiply
//-------------------------------------------------------------
`ifdef CPU_REAL_MDU
wire   mul_opcode_pipe1_sel_w   = issue_b_real_mdu_req_w && !issue_a_real_mdu_req_w;
`else
wire   mul_opcode_pipe1_sel_w   = pipe1_mux_mul_r;
`endif
assign mul_opcode_opcode_o      = mul_opcode_pipe1_sel_w ? opcode1_opcode_o     : opcode0_opcode_o;
assign mul_opcode_pc_o          = mul_opcode_pipe1_sel_w ? opcode1_pc_o         : opcode0_pc_o;
assign mul_opcode_rd_idx_o      = mul_opcode_pipe1_sel_w ? opcode1_rd_idx_o     : opcode0_rd_idx_o;
assign mul_opcode_ra_idx_o      = mul_opcode_pipe1_sel_w ? opcode1_ra_idx_o     : opcode0_ra_idx_o;
assign mul_opcode_rb_idx_o      = mul_opcode_pipe1_sel_w ? opcode1_rb_idx_o     : opcode0_rb_idx_o;
assign mul_opcode_ra_operand_o  = mul_opcode_pipe1_sel_w ? opcode1_ra_operand_o : opcode0_ra_operand_o;
assign mul_opcode_rb_operand_o  = mul_opcode_pipe1_sel_w ? opcode1_rb_operand_o : opcode0_rb_operand_o;
assign mul_opcode_invalid_o     = 1'b0;
`ifdef CPU_REAL_MDU
assign mul_opcode_pipe1_o        = mul_opcode_pipe1_sel_w;
assign mul_opcode1_valid_o       = enable_muldiv_w & issue_dual_mul_w & issue_sideband_valid_w;
assign mul_opcode1_opcode_o      = opcode1_opcode_o;
assign mul_opcode1_ra_operand_o  = opcode1_ra_operand_o;
assign mul_opcode1_rb_operand_o  = opcode1_rb_operand_o;
`endif

//-------------------------------------------------------------
// CSR unit
//-------------------------------------------------------------
assign csr_opcode_valid_o       = opcode_a_issue_w & issue_a_csr_w & ~issue_a_priv_fault_w & ~take_interrupt_i & issue_sideband_valid_w;
assign csr_opcode_opcode_o      = opcode0_opcode_o;
assign csr_opcode_pc_o          = opcode0_pc_o;
assign csr_opcode_rd_idx_o      = opcode0_rd_idx_o;
assign csr_opcode_ra_idx_o      = opcode0_ra_idx_o;
assign csr_opcode_rb_idx_o      = opcode0_rb_idx_o;
assign csr_opcode_ra_operand_o  = opcode0_ra_operand_o;
assign csr_opcode_rb_operand_o  = opcode0_rb_operand_o;
assign csr_opcode_invalid_o     = opcode_a_issue_w && issue_a_invalid_w && issue_sideband_valid_w;

//-------------------------------------------------------------
// Checker Interface
//-------------------------------------------------------------
`ifdef verilator
biloong_trace_sim
u_pipe0_dec0_verif
(
     .valid_i(pipe0_valid_wb_w)
    ,.pc_i(pipe0_pc_wb_w)
    ,.opcode_i(pipe0_opc_wb_w)
);

wire [4:0] v_pipe0_rs1_w = pipe0_opc_wb_w[19:15];
wire [4:0] v_pipe0_rs2_w = pipe0_opc_wb_w[24:20];

function [0:0] complete_valid0; /*verilator public*/
begin
    complete_valid0 = pipe0_valid_wb_w;
end
endfunction
function [31:0] complete_pc0; /*verilator public*/
begin
    complete_pc0 = pipe0_pc_wb_w;
end
endfunction
function [31:0] complete_opcode0; /*verilator public*/
begin
    complete_opcode0 = pipe0_opc_wb_w;
end
endfunction
function [4:0] complete_ra0; /*verilator public*/
begin
    complete_ra0 = v_pipe0_rs1_w;
end
endfunction
function [4:0] complete_rb0; /*verilator public*/
begin
    complete_rb0 = v_pipe0_rs2_w;
end
endfunction
function [4:0] complete_rd0; /*verilator public*/
begin
    complete_rd0 = pipe0_rd_wb_w;
end
endfunction
function [31:0] complete_ra_val0; /*verilator public*/
begin
    complete_ra_val0 = pipe0_ra_val_wb_w;
end
endfunction
function [31:0] complete_rb_val0; /*verilator public*/
begin
    complete_rb_val0 = pipe0_rb_val_wb_w;
end
endfunction
function [31:0] complete_rd_val0; /*verilator public*/
begin
    if (|pipe0_rd_wb_w)
        complete_rd_val0 = pipe0_result_wb_w;
    else
        complete_rd_val0 = 32'b0;
end
endfunction

biloong_trace_sim
u_pipe0_dec1_verif
(
     .valid_i(pipe1_valid_wb_w)
    ,.pc_i(pipe1_pc_wb_w)
    ,.opcode_i(pipe1_opc_wb_w)
);

wire [4:0] v_pipe1_rs1_w = pipe1_opc_wb_w[19:15];
wire [4:0] v_pipe1_rs2_w = pipe1_opc_wb_w[24:20];

function [0:0] complete_valid1; /*verilator public*/
begin
    complete_valid1 = pipe1_valid_wb_w;
end
endfunction
function [31:0] complete_pc1; /*verilator public*/
begin
    complete_pc1 = pipe1_pc_wb_w;
end
endfunction
function [31:0] complete_opcode1; /*verilator public*/
begin
    complete_opcode1 = pipe1_opc_wb_w;
end
endfunction
function [4:0] complete_ra1; /*verilator public*/
begin
    complete_ra1 = v_pipe1_rs1_w;
end
endfunction
function [4:0] complete_rb1; /*verilator public*/
begin
    complete_rb1 = v_pipe1_rs2_w;
end
endfunction
function [4:0] complete_rd1; /*verilator public*/
begin
    complete_rd1 = pipe1_rd_wb_w;
end
endfunction
function [31:0] complete_ra_val1; /*verilator public*/
begin
    complete_ra_val1 = pipe1_ra_val_wb_w;
end
endfunction
function [31:0] complete_rb_val1; /*verilator public*/
begin
    complete_rb_val1 = pipe1_rb_val_wb_w;
end
endfunction
function [31:0] complete_rd_val1; /*verilator public*/
begin
    if (|pipe1_rd_wb_w)
        complete_rd_val1 = pipe1_result_wb_w;
    else
        complete_rd_val1 = 32'b0;
end
endfunction
function [5:0] complete_exception; /*verilator public*/
begin
    complete_exception = pipe0_exception_wb_w | pipe1_exception_wb_w;
end
endfunction
`endif


endmodule
