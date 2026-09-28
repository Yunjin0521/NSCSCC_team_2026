//-----------------------------------------------------------------
//                         Biloong CPU
//                            V0.8.1
//-----------------------------------------------------------------
`include "biloong_defs.v"

module biloong_trace_sim
(
     input                        valid_i
    ,input  [31:0]                pc_i
    ,input  [31:0]                opcode_i
);

`ifdef verilator
//-----------------------------------------------------------------
// LoongArch debug register names
//-----------------------------------------------------------------
function [79:0] get_regname_str;
    input [4:0] regnum;
begin
    case (regnum)
    5'd0:  get_regname_str = "zero";
    5'd1:  get_regname_str = "ra";
    5'd2:  get_regname_str = "tp";
    5'd3:  get_regname_str = "sp";
    5'd4:  get_regname_str = "a0";
    5'd5:  get_regname_str = "a1";
    5'd6:  get_regname_str = "a2";
    5'd7:  get_regname_str = "a3";
    5'd8:  get_regname_str = "a4";
    5'd9:  get_regname_str = "a5";
    5'd10: get_regname_str = "a6";
    5'd11: get_regname_str = "a7";
    5'd12: get_regname_str = "t0";
    5'd13: get_regname_str = "t1";
    5'd14: get_regname_str = "t2";
    5'd15: get_regname_str = "t3";
    5'd16: get_regname_str = "t4";
    5'd17: get_regname_str = "t5";
    5'd18: get_regname_str = "t6";
    5'd19: get_regname_str = "t7";
    5'd20: get_regname_str = "t8";
    5'd21: get_regname_str = "u0";
    5'd22: get_regname_str = "fp";
    5'd23: get_regname_str = "s0";
    5'd24: get_regname_str = "s1";
    5'd25: get_regname_str = "s2";
    5'd26: get_regname_str = "s3";
    5'd27: get_regname_str = "s4";
    5'd28: get_regname_str = "s5";
    5'd29: get_regname_str = "s6";
    5'd30: get_regname_str = "s7";
    5'd31: get_regname_str = "s8";
    default: get_regname_str = "-";
    endcase
end
endfunction

function [31:0] sext12;
    input [11:0] imm;
begin
    sext12 = {{20{imm[11]}}, imm};
end
endfunction

function [31:0] sext16_shift2;
    input [15:0] imm;
begin
    sext16_shift2 = {{14{imm[15]}}, imm, 2'b0};
end
endfunction

function [31:0] sext20_shift2;
    input [19:0] imm;
begin
    sext20_shift2 = {{10{imm[19]}}, imm, 2'b0};
end
endfunction

function [31:0] sext20_shift12;
    input [19:0] imm;
begin
    sext20_shift12 = {imm, 12'b0};
end
endfunction

function [31:0] sext26_shift2;
    input [25:0] imm;
begin
    sext26_shift2 = {{4{imm[25]}}, imm, 2'b0};
end
endfunction

//-------------------------------------------------------------------
// LoongArch decode
//-------------------------------------------------------------------
wire [5:0] op_31_26_w = opcode_i[`LA_OP_31_26_R];
wire [3:0] op_25_22_w = opcode_i[`LA_OP_25_22_R];
wire [1:0] op_21_20_w = opcode_i[`LA_OP_21_20_R];
wire [4:0] op_19_15_w = opcode_i[`LA_OP_19_15_R];
wire [4:0] rk_idx_w   = opcode_i[`LA_RK_R];
wire [4:0] rj_idx_w   = opcode_i[`LA_RJ_R];
wire [4:0] rd_idx_w   = opcode_i[`LA_RD_R];

wire [11:0] imm12_w = opcode_i[21:10];
wire [15:0] imm16_w = opcode_i[25:10];
wire [19:0] imm20_w = opcode_i[24:5];
wire [25:0] imm26_w = {opcode_i[9:0], opcode_i[25:10]};

wire inst_alu_3r_base_w = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                          (op_21_20_w == 2'h1);
wire inst_add_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h00);
wire inst_sub_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h02);
wire inst_slt_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h04);
wire inst_sltu_w        = inst_alu_3r_base_w && (op_19_15_w == 5'h05);
wire inst_nor_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h08);
wire inst_and_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h09);
wire inst_or_w          = inst_alu_3r_base_w && (op_19_15_w == 5'h0a);
wire inst_xor_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h0b);
wire inst_orn_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h0c);
wire inst_andn_w        = inst_alu_3r_base_w && (op_19_15_w == 5'h0d);
wire inst_sll_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h0e);
wire inst_srl_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h0f);
wire inst_sra_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h10);
wire inst_mul_w         = inst_alu_3r_base_w && (op_19_15_w == 5'h18);
wire inst_mulh_w        = inst_alu_3r_base_w && (op_19_15_w == 5'h19);
wire inst_mulh_wu_w     = inst_alu_3r_base_w && (op_19_15_w == 5'h1a);

wire inst_div_base_w = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                       (op_21_20_w == 2'h2);
wire inst_div_w      = inst_div_base_w && (op_19_15_w == 5'h00);
wire inst_mod_w      = inst_div_base_w && (op_19_15_w == 5'h01);
wire inst_div_wu_w   = inst_div_base_w && (op_19_15_w == 5'h02);
wire inst_mod_wu_w   = inst_div_base_w && (op_19_15_w == 5'h03);
wire inst_break_w    = inst_div_base_w && (op_19_15_w == 5'h14);
wire inst_syscall_w  = inst_div_base_w && (op_19_15_w == 5'h16);

wire inst_shift_imm_base_w = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h1) &&
                             (op_21_20_w == 2'h0);
wire inst_slli_w           = inst_shift_imm_base_w && (op_19_15_w == 5'h01);
wire inst_srli_w           = inst_shift_imm_base_w && (op_19_15_w == 5'h09);
wire inst_srai_w           = inst_shift_imm_base_w && (op_19_15_w == 5'h11);

wire inst_slti_w       = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h8);
wire inst_sltui_w      = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h9);
wire inst_addi_w       = (op_31_26_w == 6'h00) && (op_25_22_w == 4'ha);
wire inst_andi_w       = (op_31_26_w == 6'h00) && (op_25_22_w == 4'hd);
wire inst_ori_w        = (op_31_26_w == 6'h00) && (op_25_22_w == 4'he);
wire inst_xori_w       = (op_31_26_w == 6'h00) && (op_25_22_w == 4'hf);
wire inst_lu12i_w      = (op_31_26_w == 6'h05) && !opcode_i[25];
wire inst_pcaddi_w     = (op_31_26_w == 6'h06) && !opcode_i[25];
wire inst_pcaddu12i_w  = (op_31_26_w == 6'h07) && !opcode_i[25];

wire inst_ld_b_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h0);
wire inst_ld_h_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h1);
wire inst_ld_w_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h2);
wire inst_st_b_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h4);
wire inst_st_h_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h5);
wire inst_st_w_w       = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h6);
wire inst_ld_bu_w      = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h8);
wire inst_ld_hu_w      = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h9);
wire inst_preld_w      = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'hb);
wire inst_ll_w         = (op_31_26_w == 6'h08) && !opcode_i[25] && !opcode_i[24];
wire inst_sc_w         = (op_31_26_w == 6'h08) && !opcode_i[25] && opcode_i[24];

wire inst_beq_w        = (op_31_26_w == 6'h16);
wire inst_bne_w        = (op_31_26_w == 6'h17);
wire inst_blt_w        = (op_31_26_w == 6'h18);
wire inst_bge_w        = (op_31_26_w == 6'h19);
wire inst_bltu_w       = (op_31_26_w == 6'h1a);
wire inst_bgeu_w       = (op_31_26_w == 6'h1b);
wire inst_b_w          = (op_31_26_w == 6'h14);
wire inst_bl_w         = (op_31_26_w == 6'h15);
wire inst_jirl_w       = (op_31_26_w == 6'h13);

wire inst_sys_base_w   = (op_31_26_w == 6'h01) && (op_25_22_w == 4'h9) &&
                         (op_21_20_w == 2'h0);
wire inst_csr_reg_w    = (op_31_26_w == 6'h01) && !opcode_i[25] && !opcode_i[24];
wire inst_csrrd_w      = inst_csr_reg_w && (rj_idx_w == 5'd0);
wire inst_csrwr_w      = inst_csr_reg_w && (rj_idx_w == 5'd1);
wire inst_csrxchg_w    = inst_csr_reg_w && (rj_idx_w != 5'd0) && (rj_idx_w != 5'd1);
wire inst_cacop_w      = (op_31_26_w == 6'h01) && (op_25_22_w == 4'h8);
wire inst_ertn_w       = inst_sys_base_w && (op_19_15_w == 5'h10) &&
                         (rk_idx_w == 5'h0e) && (rj_idx_w == 5'd0) && (rd_idx_w == 5'd0);
wire inst_tlbsrch_w    = inst_sys_base_w && (op_19_15_w == 5'h10) &&
                         (rk_idx_w == 5'h0a) && (rj_idx_w == 5'd0) && (rd_idx_w == 5'd0);
wire inst_tlbrd_w      = inst_sys_base_w && (op_19_15_w == 5'h10) &&
                         (rk_idx_w == 5'h0b) && (rj_idx_w == 5'd0) && (rd_idx_w == 5'd0);
wire inst_tlbwr_w      = inst_sys_base_w && (op_19_15_w == 5'h10) &&
                         (rk_idx_w == 5'h0c) && (rj_idx_w == 5'd0) && (rd_idx_w == 5'd0);
wire inst_tlbfill_w    = inst_sys_base_w && (op_19_15_w == 5'h10) &&
                         (rk_idx_w == 5'h0d) && (rj_idx_w == 5'd0) && (rd_idx_w == 5'd0);
wire inst_invtlb_w     = inst_sys_base_w && (op_19_15_w == 5'h13) && (rd_idx_w <= 5'd6);

wire inst_idle_w       = (op_31_26_w == 6'h01) && (op_25_22_w == 4'h9) &&
                         (op_21_20_w == 2'h0) && (op_19_15_w == 5'h11);
wire inst_dbar_w       = (op_31_26_w == 6'h0e) && (op_25_22_w == 4'h1) &&
                         (op_21_20_w == 2'h3) && (op_19_15_w == 5'h04);
wire inst_ibar_w       = (op_31_26_w == 6'h0e) && (op_25_22_w == 4'h1) &&
                         (op_21_20_w == 2'h3) && (op_19_15_w == 5'h05);
wire inst_rdcnt_base_w = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                         (op_21_20_w == 2'h0) && (op_19_15_w == 5'h00);
wire inst_rdcntid_w    = inst_rdcnt_base_w && (rk_idx_w == 5'h18) && (rd_idx_w == 5'd0);
wire inst_rdcntvl_w    = inst_rdcnt_base_w && (rk_idx_w == 5'h18) &&
                         (rj_idx_w == 5'd0) && (rd_idx_w != 5'd0);
wire inst_rdcntvh_w    = inst_rdcnt_base_w && (rk_idx_w == 5'h19) && (rj_idx_w == 5'd0);
wire inst_cpucfg_w     = inst_rdcnt_base_w && (rk_idx_w == 5'h1b);

wire inst_alu_3r_w     = inst_add_w || inst_sub_w || inst_slt_w || inst_sltu_w ||
                         inst_nor_w || inst_and_w || inst_or_w || inst_xor_w ||
                         inst_orn_w || inst_andn_w || inst_sll_w || inst_srl_w ||
                         inst_sra_w || inst_mul_w || inst_mulh_w || inst_mulh_wu_w;
wire inst_div_3r_w     = inst_div_w || inst_mod_w || inst_div_wu_w || inst_mod_wu_w;
wire inst_shift_imm_w  = inst_slli_w || inst_srli_w || inst_srai_w;
wire inst_alu_i12_w    = inst_slti_w || inst_sltui_w || inst_addi_w ||
                         inst_andi_w || inst_ori_w || inst_xori_w;
wire inst_load_w       = inst_ld_b_w || inst_ld_h_w || inst_ld_w_w ||
                         inst_ld_bu_w || inst_ld_hu_w || inst_ll_w;
wire inst_store_w      = inst_st_b_w || inst_st_h_w || inst_st_w_w || inst_sc_w;
wire inst_cond_branch_w = inst_beq_w || inst_bne_w || inst_blt_w || inst_bge_w ||
                          inst_bltu_w || inst_bgeu_w;

wire inst_uses_rj_w    = inst_alu_3r_w || inst_div_3r_w || inst_shift_imm_w ||
                         inst_alu_i12_w || inst_load_w || inst_store_w ||
                         inst_preld_w || inst_cond_branch_w || inst_jirl_w ||
                         inst_cpucfg_w || inst_csrxchg_w || inst_cacop_w ||
                         inst_invtlb_w;
wire inst_uses_rk_w    = inst_alu_3r_w || inst_div_3r_w || inst_invtlb_w;
wire inst_uses_rd_src_w = inst_store_w || inst_cond_branch_w ||
                          inst_csrwr_w || inst_csrxchg_w;
wire inst_has_dest_w   = inst_alu_3r_w || inst_div_3r_w || inst_shift_imm_w ||
                         inst_alu_i12_w || inst_lu12i_w || inst_pcaddi_w ||
                         inst_pcaddu12i_w || inst_load_w || inst_sc_w ||
                         inst_bl_w || inst_jirl_w || inst_rdcntid_w ||
                         inst_rdcntvl_w || inst_rdcntvh_w || inst_cpucfg_w ||
                         inst_csrrd_w || inst_csrwr_w || inst_csrxchg_w;
wire [4:0] inst_dest_idx_w = inst_bl_w      ? 5'd1 :
                             inst_rdcntid_w ? rj_idx_w :
                                             rd_idx_w;

//-------------------------------------------------------------------
// Debug strings
//-------------------------------------------------------------------
reg [79:0] dbg_inst_str;
reg [79:0] dbg_inst_ra;
reg [79:0] dbg_inst_rb;
reg [79:0] dbg_inst_rd;
reg [31:0] dbg_inst_imm;
reg [31:0] dbg_inst_pc;

always @ *
begin
    dbg_inst_str = "-";
    dbg_inst_ra  = "-";
    dbg_inst_rb  = "-";
    dbg_inst_rd  = "-";
    dbg_inst_imm = 32'b0;
    dbg_inst_pc  = 32'bx;

    if (valid_i)
    begin
        dbg_inst_pc = pc_i;

        if (inst_uses_rj_w)
            dbg_inst_ra = get_regname_str(rj_idx_w);
        if (inst_uses_rk_w)
            dbg_inst_rb = get_regname_str(rk_idx_w);
        else if (inst_uses_rd_src_w)
            dbg_inst_rb = get_regname_str(rd_idx_w);
        if (inst_has_dest_w)
            dbg_inst_rd = get_regname_str(inst_dest_idx_w);

        case (1'b1)
        inst_add_w:       dbg_inst_str = "add.w";
        inst_sub_w:       dbg_inst_str = "sub.w";
        inst_slt_w:       dbg_inst_str = "slt";
        inst_sltu_w:      dbg_inst_str = "sltu";
        inst_nor_w:       dbg_inst_str = "nor";
        inst_and_w:       dbg_inst_str = "and";
        inst_or_w:        dbg_inst_str = "or";
        inst_xor_w:       dbg_inst_str = "xor";
        inst_orn_w:       dbg_inst_str = "orn";
        inst_andn_w:      dbg_inst_str = "andn";
        inst_sll_w:       dbg_inst_str = "sll.w";
        inst_srl_w:       dbg_inst_str = "srl.w";
        inst_sra_w:       dbg_inst_str = "sra.w";
        inst_mul_w:       dbg_inst_str = "mul.w";
        inst_mulh_w:      dbg_inst_str = "mulh.w";
        inst_mulh_wu_w:   dbg_inst_str = "mulh.wu";
        inst_div_w:       dbg_inst_str = "div.w";
        inst_mod_w:       dbg_inst_str = "mod.w";
        inst_div_wu_w:    dbg_inst_str = "div.wu";
        inst_mod_wu_w:    dbg_inst_str = "mod.wu";
        inst_slli_w:      dbg_inst_str = "slli.w";
        inst_srli_w:      dbg_inst_str = "srli.w";
        inst_srai_w:      dbg_inst_str = "srai.w";
        inst_slti_w:      dbg_inst_str = "slti";
        inst_sltui_w:     dbg_inst_str = "sltui";
        inst_addi_w:      dbg_inst_str = "addi.w";
        inst_andi_w:      dbg_inst_str = "andi";
        inst_ori_w:       dbg_inst_str = "ori";
        inst_xori_w:      dbg_inst_str = "xori";
        inst_lu12i_w:     dbg_inst_str = "lu12i.w";
        inst_pcaddi_w:    dbg_inst_str = "pcaddi";
        inst_pcaddu12i_w: dbg_inst_str = "pcaddu12i";
        inst_ld_b_w:      dbg_inst_str = "ld.b";
        inst_ld_h_w:      dbg_inst_str = "ld.h";
        inst_ld_w_w:      dbg_inst_str = "ld.w";
        inst_ld_bu_w:     dbg_inst_str = "ld.bu";
        inst_ld_hu_w:     dbg_inst_str = "ld.hu";
        inst_st_b_w:      dbg_inst_str = "st.b";
        inst_st_h_w:      dbg_inst_str = "st.h";
        inst_st_w_w:      dbg_inst_str = "st.w";
        inst_preld_w:     dbg_inst_str = "preld";
        inst_ll_w:        dbg_inst_str = "ll.w";
        inst_sc_w:        dbg_inst_str = "sc.w";
        inst_beq_w:       dbg_inst_str = "beq";
        inst_bne_w:       dbg_inst_str = "bne";
        inst_blt_w:       dbg_inst_str = "blt";
        inst_bge_w:       dbg_inst_str = "bge";
        inst_bltu_w:      dbg_inst_str = "bltu";
        inst_bgeu_w:      dbg_inst_str = "bgeu";
        inst_b_w:         dbg_inst_str = "b";
        inst_bl_w:        dbg_inst_str = "bl";
        inst_jirl_w:      dbg_inst_str = "jirl";
        inst_csrrd_w:     dbg_inst_str = "csrrd";
        inst_csrwr_w:     dbg_inst_str = "csrwr";
        inst_csrxchg_w:   dbg_inst_str = "csrxchg";
        inst_cacop_w:     dbg_inst_str = "cacop";
        inst_syscall_w:   dbg_inst_str = "syscall";
        inst_break_w:     dbg_inst_str = "break";
        inst_idle_w:      dbg_inst_str = "idle";
        inst_dbar_w:      dbg_inst_str = "dbar";
        inst_ibar_w:      dbg_inst_str = "ibar";
        inst_rdcntid_w:   dbg_inst_str = "rdcntid.w";
        inst_rdcntvl_w:   dbg_inst_str = "rdcntvl.w";
        inst_rdcntvh_w:   dbg_inst_str = "rdcntvh.w";
        inst_cpucfg_w:    dbg_inst_str = "cpucfg";
        inst_ertn_w:      dbg_inst_str = "ertn";
        inst_tlbsrch_w:   dbg_inst_str = "tlbsrch";
        inst_tlbrd_w:     dbg_inst_str = "tlbrd";
        inst_tlbwr_w:     dbg_inst_str = "tlbwr";
        inst_tlbfill_w:   dbg_inst_str = "tlbfill";
        inst_invtlb_w:    dbg_inst_str = "invtlb";
        default:          dbg_inst_str = "unknown";
        endcase

        case (1'b1)
        inst_andi_w, inst_ori_w, inst_xori_w:
            dbg_inst_imm = {20'b0, imm12_w};
        inst_alu_i12_w, inst_load_w, inst_store_w, inst_preld_w,
        inst_ll_w, inst_sc_w, inst_cacop_w:
            dbg_inst_imm = sext12(imm12_w);
        inst_shift_imm_w:
            dbg_inst_imm = {27'b0, rk_idx_w};
        inst_lu12i_w, inst_pcaddu12i_w:
            dbg_inst_imm = sext20_shift12(imm20_w);
        inst_pcaddi_w:
            dbg_inst_imm = pc_i + sext20_shift2(imm20_w);
        inst_cond_branch_w:
            dbg_inst_imm = pc_i + sext16_shift2(imm16_w);
        inst_jirl_w:
            dbg_inst_imm = sext16_shift2(imm16_w);
        inst_b_w, inst_bl_w:
            dbg_inst_imm = pc_i + sext26_shift2(imm26_w);
        inst_csr_reg_w:
            dbg_inst_imm = {18'b0, opcode_i[`LA_CSR_NUM_R]};
        default:
            dbg_inst_imm = 32'b0;
        endcase

        if (inst_b_w)
        begin
            dbg_inst_ra = "-";
            dbg_inst_rb = "-";
        end

        if (inst_bl_w)
        begin
            dbg_inst_ra = "-";
            dbg_inst_rb = "-";
        end

        if (inst_jirl_w && (rj_idx_w == 5'd1) && (rd_idx_w == 5'd0) && (imm16_w == 16'd0))
            dbg_inst_str = "ret";
        else if (inst_jirl_w && (rd_idx_w == 5'd1))
            dbg_inst_str = "call (R)";
        else if (inst_bl_w)
            dbg_inst_str = "call";

        if (inst_csrwr_w)
        begin
            dbg_inst_ra = get_regname_str(rd_idx_w);
            dbg_inst_rb = "-";
        end
        else if (inst_csrxchg_w)
        begin
            dbg_inst_ra = get_regname_str(rd_idx_w);
            dbg_inst_rb = get_regname_str(rj_idx_w);
        end
    end
end
`endif

endmodule
