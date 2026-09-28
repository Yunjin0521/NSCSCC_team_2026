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
`include "biloong_defs.v"

module biloong_decoder
(
     input                        valid_i
    ,input                        fetch_fault_i
    ,input                        enable_muldiv_i
    ,input  [31:0]                opcode_i

    ,output                       invalid_o
    ,output                       exec_o
    ,output                       lsu_o
    ,output                       branch_o
    ,output                       mul_o
    ,output                       div_o
    ,output                       csr_o
    ,output                       rd_valid_o
);
wire [31:15] op_31_15 = opcode_i[`LA_OP_31_15_R];
wire [5:0] op_31_26 = opcode_i[`LA_OP_31_26_R];
wire [3:0] op_25_22 = opcode_i[`LA_OP_25_22_R];
wire [1:0] op_21_20 = opcode_i[`LA_OP_21_20_R];
wire [4:0] op_19_15 = opcode_i[`LA_OP_19_15_R];
wire [4:0] rk       = opcode_i[`LA_RK_R];
wire [4:0] rj       = opcode_i[`LA_RJ_R];
wire [4:0] rd       = opcode_i[`LA_RD_R];
wire inst_bdot_w     = (op_31_15 == 17'b11111111111111111);
wire inst_addi_w     = (op_31_26 == 6'h00) && (op_25_22 == 4'ha);
wire inst_ld_b       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h0);
wire inst_ld_h       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h1);
wire inst_ld_w       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h2);
wire inst_st_b       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h4);
wire inst_st_h       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h5);
wire inst_st_w       = (op_31_26 == 6'h0a) && (op_25_22 == 4'h6);
wire inst_ld_bu      = (op_31_26 == 6'h0a) && (op_25_22 == 4'h8);
wire inst_ld_hu      = (op_31_26 == 6'h0a) && (op_25_22 == 4'h9);
wire inst_preld      = (op_31_26 == 6'h0a) && (op_25_22 == 4'hb);
wire inst_ll_w       = (op_31_26 == 6'h08) && !opcode_i[25] && !opcode_i[24];
wire inst_sc_w       = (op_31_26 == 6'h08) && !opcode_i[25] &&  opcode_i[24];


wire inst_beq        = (op_31_26 == 6'h16);
wire inst_bne        = (op_31_26 == 6'h17);
wire inst_blt        = (op_31_26 == 6'h18);
wire inst_bge        = (op_31_26 == 6'h19);
wire inst_bltu       = (op_31_26 == 6'h1a);
wire inst_bgeu       = (op_31_26 == 6'h1b);
wire inst_b          = (op_31_26 == 6'h14);
wire inst_bl         = (op_31_26 == 6'h15);
wire inst_jirl       = (op_31_26 == 6'h13);

wire inst_lu12i_w    = (op_31_26 == 6'h05) && !opcode_i[25];
wire inst_pcaddi     = (op_31_26 == 6'h06) && !opcode_i[25];
wire inst_pcaddu12i  = (op_31_26 == 6'h07) && !opcode_i[25];
wire inst_alu_3r_base = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) && (op_21_20 == 2'h1);
wire inst_add_w      = inst_alu_3r_base && (op_19_15 == 5'h00);
wire inst_sub_w      = inst_alu_3r_base && (op_19_15 == 5'h02);
wire inst_slt        = inst_alu_3r_base && (op_19_15 == 5'h04);
wire inst_sltu       = inst_alu_3r_base && (op_19_15 == 5'h05);
wire inst_nor        = inst_alu_3r_base && (op_19_15 == 5'h08);
wire inst_and        = inst_alu_3r_base && (op_19_15 == 5'h09);
wire inst_or         = inst_alu_3r_base && (op_19_15 == 5'h0a);
wire inst_xor        = inst_alu_3r_base && (op_19_15 == 5'h0b);
wire inst_orn        = inst_alu_3r_base && (op_19_15 == 5'h0c);
wire inst_andn       = inst_alu_3r_base && (op_19_15 == 5'h0d);
wire inst_sll_w      = inst_alu_3r_base && (op_19_15 == 5'h0e);
wire inst_srl_w      = inst_alu_3r_base && (op_19_15 == 5'h0f);
wire inst_sra_w      = inst_alu_3r_base && (op_19_15 == 5'h10);
wire inst_mul_w      = inst_alu_3r_base && (op_19_15 == 5'h18);
wire inst_mulh_w     = inst_alu_3r_base && (op_19_15 == 5'h19);
wire inst_mulh_wu    = inst_alu_3r_base && (op_19_15 == 5'h1a);

wire inst_div_w      = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h00);
wire inst_mod_w      = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h01);
wire inst_div_wu     = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h02);
wire inst_mod_wu     = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h03);

wire inst_slli_w     = (op_31_26 == 6'h00) && (op_25_22 == 4'h1) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h01);
wire inst_srli_w     = (op_31_26 == 6'h00) && (op_25_22 == 4'h1) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h09);
wire inst_srai_w     = (op_31_26 == 6'h00) && (op_25_22 == 4'h1) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h11);
wire inst_slti       = (op_31_26 == 6'h00) && (op_25_22 == 4'h8);
wire inst_sltui      = (op_31_26 == 6'h00) && (op_25_22 == 4'h9);
wire inst_andi       = (op_31_26 == 6'h00) && (op_25_22 == 4'hd);
wire inst_ori        = (op_31_26 == 6'h00) && (op_25_22 == 4'he);
wire inst_xori       = (op_31_26 == 6'h00) && (op_25_22 == 4'hf);

wire inst_syscall    = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h16);
wire inst_break      = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h2) && (op_19_15 == 5'h14);
wire inst_idle       = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h11);
wire inst_dbar       = (op_31_26 == 6'h0e) && (op_25_22 == 4'h1) &&
                       (op_21_20 == 2'h3) && (op_19_15 == 5'h04);
wire inst_ibar       = (op_31_26 == 6'h0e) && (op_25_22 == 4'h1) &&
                       (op_21_20 == 2'h3) && (op_19_15 == 5'h05);
wire inst_rdcnt_base = (op_31_26 == 6'h00) && (op_25_22 == 4'h0) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h00);
wire inst_rdcntid_w  = inst_rdcnt_base && (rk == 5'h18) && (rd == 5'd0);
wire inst_rdcntvl_w  = inst_rdcnt_base && (rk == 5'h18) && (rj == 5'd0) && (rd != 5'd0);
wire inst_rdcntvh_w  = inst_rdcnt_base && (rk == 5'h19) && (rj == 5'd0);
wire inst_rdcnt      = inst_rdcntid_w || inst_rdcntvl_w || inst_rdcntvh_w;
wire inst_cpucfg     = inst_rdcnt_base && (rk == 5'h1b);

wire inst_csrrd      = (op_31_26 == 6'h01) && !opcode_i[25] && !opcode_i[24] && (rj == 5'd0);
wire inst_csrwr      = (op_31_26 == 6'h01) && !opcode_i[25] && !opcode_i[24] && (rj == 5'd1);
wire inst_csrxchg    = (op_31_26 == 6'h01) && !opcode_i[25] && !opcode_i[24] &&
                       (rj != 5'd0) && (rj != 5'd1);
wire inst_cacop      = (op_31_26 == 6'h01) && (op_25_22 == 4'h8);
wire inst_valid_cacop = inst_cacop &&
                        ((rd[2:0] == 3'b000) || (rd[2:0] == 3'b001)) &&
                        (rd[4:3] != 2'b11);
wire inst_cacop_nop  = inst_cacop && !inst_valid_cacop;
wire inst_ertn       = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h10) &&
                       (rk == 5'h0e) && (rj == 5'd0) && (rd == 5'd0);
wire inst_tlbsrch    = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h10) &&
                       (rk == 5'h0a) && (rj == 5'd0) && (rd == 5'd0);
wire inst_tlbrd      = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h10) &&
                       (rk == 5'h0b) && (rj == 5'd0) && (rd == 5'd0);
wire inst_tlbwr      = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h10) &&
                       (rk == 5'h0c) && (rj == 5'd0) && (rd == 5'd0);
wire inst_tlbfill    = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                       (op_21_20 == 2'h0) && (op_19_15 == 5'h10) &&
                       (rk == 5'h0d) && (rj == 5'd0) && (rd == 5'd0);
wire inst_invtlb_pattern = (op_31_26 == 6'h01) && (op_25_22 == 4'h9) &&
                           (op_21_20 == 2'h0) && (op_19_15 == 5'h13);
wire inst_invtlb     = inst_invtlb_pattern && (rd <= 5'd6);

wire alu_3r_w        = inst_add_w || inst_sub_w || inst_slt || inst_sltu ||
                       inst_nor || inst_and || inst_or || inst_xor ||
                       inst_orn || inst_andn || inst_sll_w || inst_srl_w ||
                       inst_sra_w || inst_bdot_w;
wire alu_2ri_w       = inst_slli_w || inst_srli_w || inst_srai_w ||
                       inst_slti || inst_sltui || inst_andi || inst_ori ||
                       inst_xori;
wire alu_w           = alu_3r_w || alu_2ri_w || inst_addi_w ||
                       inst_lu12i_w || inst_pcaddi || inst_pcaddu12i;
wire load_w          = inst_ld_b || inst_ld_h || inst_ld_w || inst_ld_bu ||
                       inst_ld_hu || inst_ll_w;
wire store_w         = inst_st_b || inst_st_h || inst_st_w || inst_sc_w;
wire branch_w        = inst_beq || inst_bne || inst_blt || inst_bge ||
                       inst_bltu || inst_bgeu || inst_b || inst_bl ||
                       inst_jirl;
wire mul_w           = inst_mul_w || inst_mulh_w || inst_mulh_wu;
wire div_w           = inst_div_w || inst_mod_w || inst_div_wu || inst_mod_wu;
wire csr_w           = inst_syscall || inst_break || inst_idle || inst_dbar ||
                       inst_ibar || inst_rdcnt || inst_cpucfg || inst_csrrd ||
                       inst_csrwr || inst_csrxchg || inst_cacop_nop ||
                       inst_ertn || inst_tlbsrch || inst_tlbrd || inst_tlbwr ||
                       inst_tlbfill || inst_invtlb;
wire lsu_sideband_w  = inst_valid_cacop || inst_preld;
wire known_w         = alu_w || load_w || store_w || branch_w || csr_w ||
                       lsu_sideband_w ||
                       (enable_muldiv_i && (mul_w || div_w));
wire invalid_w       = valid_i && !known_w;

assign invalid_o = invalid_w;
assign exec_o    = alu_w;
assign lsu_o     = load_w || store_w || lsu_sideband_w;
assign branch_o  = branch_w;
assign mul_o     = enable_muldiv_i && mul_w;
assign div_o     = enable_muldiv_i && div_w;
assign csr_o     = csr_w || invalid_w || fetch_fault_i;
assign rd_valid_o = alu_w || load_w || inst_sc_w || inst_bl || inst_jirl ||
                    (enable_muldiv_i && (mul_w || div_w)) ||
                    inst_rdcnt || inst_cpucfg || inst_csrrd || inst_csrwr ||
                    inst_csrxchg;

endmodule
