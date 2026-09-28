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

module biloong_csr
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_SUPER    = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  7:0]  intr_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_ra_idx_i
    ,input  [  4:0]  opcode_rb_idx_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input           csr_writeback_write_i
    ,input  [ 13:0]  csr_writeback_waddr_i
    ,input  [ 31:0]  csr_writeback_wdata_i
    ,input  [  5:0]  csr_writeback_exception_i
    ,input  [  5:0]  csr_writeback_exception_ecode_i
    ,input  [ 31:0]  csr_writeback_exception_pc_i
    ,input  [ 31:0]  csr_writeback_exception_addr_i
    ,input  [ 31:0]  cpu_id_i
    ,input  [ 31:0]  reset_vector_i
    ,input           interrupt_inhibit_i
    ,input           llbit_set_i
    ,input           llbit_i
    ,input           csr_writeback_valid_i

    // Outputs
    ,output [ 31:0]  csr_result_e1_value_o
    ,output          csr_result_e1_write_o
    ,output [ 31:0]  csr_result_e1_wdata_o
    ,output [  5:0]  csr_result_e1_exception_o
    ,output          branch_csr_request_o
    ,output [ 31:0]  branch_csr_pc_o
    ,output [  1:0]  branch_csr_priv_o
    ,output          take_interrupt_o
    ,output          interrupt_ready_o
    ,output          ifence_o
    ,output          idle_o
    ,output [  1:0]  mmu_priv_d_o
    ,output          mmu_sum_o
    ,output          mmu_mxr_o
    ,output          mmu_flush_o
    ,output [ 31:0]  mmu_satp_o
    ,output [ 31:0]  mmu_crmd_o
    ,output [ 31:0]  mmu_asid_o
    ,output [ 31:0]  mmu_dmw0_o
    ,output [ 31:0]  mmu_dmw1_o
    ,output [ 31:0]  mmu_tlb_e_o
    ,output [32*19-1:0] mmu_tlb_vppn_o
    ,output [32*10-1:0] mmu_tlb_asid_o
    ,output [ 31:0]  mmu_tlb_g_o
    ,output [32*6-1:0]  mmu_tlb_ps_o
    ,output [32*20-1:0] mmu_tlb_ppn0_o
    ,output [32*20-1:0] mmu_tlb_ppn1_o
    ,output [32*2-1:0]  mmu_tlb_plv0_o
    ,output [32*2-1:0]  mmu_tlb_plv1_o
    ,output [32*2-1:0]  mmu_tlb_mat0_o
    ,output [32*2-1:0]  mmu_tlb_mat1_o
    ,output [ 31:0]  mmu_tlb_d0_o
    ,output [ 31:0]  mmu_tlb_d1_o
    ,output [ 31:0]  mmu_tlb_v0_o
    ,output [ 31:0]  mmu_tlb_v1_o
    ,output          llbit_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
localparam LA_CSR_TID = 14'h040;

reg         opcode_valid_q;
reg [31:0]  opcode_opcode_q;
reg         opcode_invalid_q;
reg [31:0]  opcode_ra_operand_q;
reg [31:0]  opcode_rb_operand_q;
reg [63:0]  opcode_timer_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    opcode_valid_q      <= 1'b0;
    opcode_opcode_q     <= 32'b0;
    opcode_invalid_q    <= 1'b0;
    opcode_ra_operand_q <= 32'b0;
    opcode_rb_operand_q <= 32'b0;
    opcode_timer_q      <= 64'b0;
end
else
begin
    opcode_valid_q <= opcode_valid_i;

    if (opcode_valid_i)
    begin
        opcode_opcode_q     <= opcode_opcode_i;
        opcode_invalid_q    <= opcode_invalid_i;
        opcode_ra_operand_q <= opcode_ra_operand_i;
        opcode_rb_operand_q <= opcode_rb_operand_i;
        opcode_timer_q      <= timer_q;
    end
    else
    begin
        opcode_opcode_q     <= 32'b0;
        opcode_invalid_q    <= 1'b0;
        opcode_ra_operand_q <= 32'b0;
        opcode_rb_operand_q <= 32'b0;
        opcode_timer_q      <= 64'b0;
    end
end

wire [5:0] op_31_26_w = opcode_opcode_q[`LA_OP_31_26_R];
wire [3:0] op_25_22_w = opcode_opcode_q[`LA_OP_25_22_R];
wire [1:0] op_21_20_w = opcode_opcode_q[`LA_OP_21_20_R];
wire [4:0] op_19_15_w = opcode_opcode_q[`LA_OP_19_15_R];
wire [4:0] rk_w       = opcode_opcode_q[`LA_RK_R];
wire [4:0] rj_w       = opcode_opcode_q[`LA_RJ_R];
wire [4:0] rd_w       = opcode_opcode_q[`LA_RD_R];

wire inst_csr_reg_w    = (op_31_26_w == 6'h01) && !opcode_opcode_q[25] && !opcode_opcode_q[24];
wire inst_csrrd_w      = opcode_valid_q && inst_csr_reg_w && (rj_w == 5'd0);
wire inst_csrwr_w      = opcode_valid_q && inst_csr_reg_w && (rj_w == 5'd1);
wire inst_csrxchg_w    = opcode_valid_q && inst_csr_reg_w && (rj_w != 5'd0) && (rj_w != 5'd1);
wire inst_syscall_w    = opcode_valid_q && (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                         (op_21_20_w == 2'h2) && (op_19_15_w == 5'h16);
wire inst_break_w      = opcode_valid_q && (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                         (op_21_20_w == 2'h2) && (op_19_15_w == 5'h14);
wire inst_ertn_w       = opcode_valid_q && (op_31_26_w == 6'h01) && (op_25_22_w == 4'h9) &&
                         (op_21_20_w == 2'h0) && (op_19_15_w == 5'h10) &&
                         (rk_w == 5'h0e) && (rj_w == 5'd0) && (rd_w == 5'd0);
wire inst_idle_w       = opcode_valid_q && (op_31_26_w == 6'h01) && (op_25_22_w == 4'h9) &&
                         (op_21_20_w == 2'h0) && (op_19_15_w == 5'h11);
wire inst_ibar_w       = opcode_valid_q && (op_31_26_w == 6'h0e) && (op_25_22_w == 4'h1) &&
                         (op_21_20_w == 2'h3) && (op_19_15_w == 5'h05);
wire inst_rdcnt_base_w = opcode_valid_q && (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                         (op_21_20_w == 2'h0) && (op_19_15_w == 5'h00);
wire inst_rdcntid_w    = inst_rdcnt_base_w && (rk_w == 5'h18) && (rd_w == 5'd0);
wire inst_rdcntvl_w    = inst_rdcnt_base_w && (rk_w == 5'h18) && (rj_w == 5'd0) && (rd_w != 5'd0);
wire inst_rdcntvh_w    = inst_rdcnt_base_w && (rk_w == 5'h19) && (rj_w == 5'd0);
wire inst_cpucfg_w     = inst_rdcnt_base_w && (rk_w == 5'h1b);

wire csr_write_w       = inst_csrwr_w || inst_csrxchg_w;
wire [13:0] csr_addr_w = inst_rdcntid_w ? LA_CSR_TID : opcode_opcode_q[`LA_CSR_NUM_R];

reg [31:0] csr_commit_opcode_q;
reg [31:0] csr_commit_ra_operand_q;
reg [31:0] csr_commit_rb_operand_q;

wire [5:0] commit_op_31_26_w = csr_commit_opcode_q[`LA_OP_31_26_R];
wire [3:0] commit_op_25_22_w = csr_commit_opcode_q[`LA_OP_25_22_R];
wire [1:0] commit_op_21_20_w = csr_commit_opcode_q[`LA_OP_21_20_R];
wire [4:0] commit_op_19_15_w = csr_commit_opcode_q[`LA_OP_19_15_R];
wire [4:0] commit_rk_w       = csr_commit_opcode_q[`LA_RK_R];
wire [4:0] commit_rj_w       = csr_commit_opcode_q[`LA_RJ_R];
wire [4:0] commit_rd_w       = csr_commit_opcode_q[`LA_RD_R];
wire       csr_commit_ok_w   = csr_writeback_valid_i;
wire       commit_sys_base_w = (commit_op_31_26_w == 6'h01) &&
                               (commit_op_25_22_w == 4'h9) &&
                               (commit_op_21_20_w == 2'h0);
wire       commit_tlbsrch_w  = csr_commit_ok_w && commit_sys_base_w &&
                               (commit_op_19_15_w == 5'h10) &&
                               (commit_rk_w == 5'h0a) &&
                               (commit_rj_w == 5'd0) &&
                               (commit_rd_w == 5'd0);
wire       commit_tlbrd_w    = csr_commit_ok_w && commit_sys_base_w &&
                               (commit_op_19_15_w == 5'h10) &&
                               (commit_rk_w == 5'h0b) &&
                               (commit_rj_w == 5'd0) &&
                               (commit_rd_w == 5'd0);
wire       commit_tlbwr_w    = csr_commit_ok_w && commit_sys_base_w &&
                               (commit_op_19_15_w == 5'h10) &&
                               (commit_rk_w == 5'h0c) &&
                               (commit_rj_w == 5'd0) &&
                               (commit_rd_w == 5'd0);
wire       commit_tlbfill_w  = csr_commit_ok_w && commit_sys_base_w &&
                               (commit_op_19_15_w == 5'h10) &&
                               (commit_rk_w == 5'h0d) &&
                               (commit_rj_w == 5'd0) &&
                               (commit_rd_w == 5'd0);
wire       commit_invtlb_w   = csr_commit_ok_w && commit_sys_base_w &&
                               (commit_op_19_15_w == 5'h13) &&
                               (commit_rd_w <= 5'd6);

//-----------------------------------------------------------------
// CSR handling
//-----------------------------------------------------------------
wire [1:0]  current_priv_w;
reg         csr_fault_r;

reg [31:0]  data_r;
reg [31:0]  cpucfg_r;
reg [31:0]  csr_result_r;
reg [`EXCEPTION_W-1:0] csr_exception_r;
reg [63:0]  timer_q;
wire [31:0] csr_rdata_w;

localparam [31:0] CPUCFG0_VALUE  = 32'h0000_0001;
localparam [31:0] CPUCFG1_VALUE  = 32'h0001_f1f4;
localparam [31:0] CPUCFG2_VALUE  = SUPPORT_MULDIV ? 32'h0000_0001 : 32'h0000_0000;
localparam [31:0] CPUCFG10_VALUE = 32'h0000_0005;
localparam [31:0] CPUCFG11_VALUE = 32'h0508_0001;
localparam [31:0] CPUCFG12_VALUE = 32'h0508_0001;
localparam [31:0] CPUCFG13_VALUE = 32'h0000_0000;

always @ *
begin
    data_r       = 32'b0;
    cpucfg_r     = 32'b0;
    csr_result_r = csr_rdata_w;

    case (opcode_ra_operand_q[13:0])
    14'h000: cpucfg_r = CPUCFG0_VALUE;
    14'h001: cpucfg_r = CPUCFG1_VALUE;
    14'h002: cpucfg_r = CPUCFG2_VALUE;
    14'h010: cpucfg_r = CPUCFG10_VALUE;
    14'h011: cpucfg_r = CPUCFG11_VALUE;
    14'h012: cpucfg_r = CPUCFG12_VALUE;
    14'h013: cpucfg_r = CPUCFG13_VALUE;
    default: cpucfg_r = 32'b0;
    endcase

    if (inst_csrwr_w)
        data_r = opcode_rb_operand_q;
    else if (inst_csrxchg_w)
        data_r = (opcode_ra_operand_q & opcode_rb_operand_q) |
                 (~opcode_ra_operand_q & csr_rdata_w);

    if (inst_rdcntid_w)
        csr_result_r = csr_rdata_w;
    else if (inst_rdcntvl_w)
        csr_result_r = opcode_timer_q[31:0];
    else if (inst_rdcntvh_w)
        csr_result_r = opcode_timer_q[63:32];
    else if (inst_cpucfg_w)
        csr_result_r = cpucfg_r;

    csr_fault_r = 1'b0;
end

always @ *
begin
    if (inst_syscall_w)
        csr_exception_r = `EXCEPTION_ECALL_M;
    else if (inst_break_w)
        csr_exception_r = `EXCEPTION_BREAKPOINT;
    else if (inst_ertn_w)
        csr_exception_r = `EXCEPTION_ERET_M;
    else if (opcode_invalid_q || csr_fault_r)
        csr_exception_r = `EXCEPTION_ILLEGAL_INSTRUCTION;
    else if (inst_idle_w)
        csr_exception_r = `EXCEPTION_IDLE;
    else if (inst_ibar_w)
        csr_exception_r = `EXCEPTION_FENCE;
    else
        csr_exception_r = `EXCEPTION_W'b0;
end

wire ifence_w      = inst_ibar_w;

//-----------------------------------------------------------------
// CSR register file
//-----------------------------------------------------------------
wire timer_irq_w = 1'b0;

wire [31:0] misa_w = 32'b0;

wire        csr_branch_w;
wire [31:0] csr_target_w;

wire [31:0] interrupt_w;
wire [31:0] unused_status_w;
wire [31:0] unused_satp_w;

biloong_csr_regfile
#( .SUPPORT_MTIMECMP(1)
  ,.SUPPORT_SUPER(SUPPORT_SUPER) )
u_csrfile
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.ext_intr_i(intr_i)
    ,.timer_intr_i(timer_irq_w)
    ,.cpu_id_i(cpu_id_i)
    ,.misa_i(misa_w)

    // Issue
    ,.csr_ren_i(opcode_valid_q)
    ,.csr_raddr_i(csr_addr_w)
    ,.csr_rdata_o(csr_rdata_w)

    // Exception (WB)
    ,.exception_i(csr_writeback_exception_i)
    ,.exception_ecode_i(csr_writeback_exception_ecode_i)
    ,.exception_pc_i(csr_writeback_exception_pc_i)
    ,.exception_addr_i(csr_writeback_exception_addr_i)

    // CSR register writes (WB)
    ,.csr_wen_i(csr_writeback_write_i)
    ,.csr_waddr_i(csr_writeback_waddr_i)
    ,.csr_wdata_i(csr_writeback_wdata_i)
    ,.tlb_commit_tlbsrch_i(commit_tlbsrch_w)
    ,.tlb_commit_tlbrd_i(commit_tlbrd_w)
    ,.tlb_commit_tlbwr_i(commit_tlbwr_w)
    ,.tlb_commit_tlbfill_i(commit_tlbfill_w)
    ,.tlb_commit_invtlb_i(commit_invtlb_w)
    ,.tlb_commit_invtlb_op_i(commit_rd_w)
    ,.tlb_commit_invtlb_asid_i(csr_commit_ra_operand_q)
    ,.tlb_commit_invtlb_vaddr_i(csr_commit_rb_operand_q)
    ,.llbit_set_i(llbit_set_i)
    ,.llbit_i(llbit_i)
    ,.llbit_o(llbit_o)

    // CSR branches
    ,.csr_branch_o(csr_branch_w)
    ,.csr_target_o(csr_target_w)

    // Various CSR registers
    ,.priv_o(current_priv_w)
    ,.status_o(unused_status_w)
    ,.satp_o(unused_satp_w)
    ,.mmu_crmd_o(mmu_crmd_o)
    ,.mmu_asid_o(mmu_asid_o)
    ,.mmu_dmw0_o(mmu_dmw0_o)
    ,.mmu_dmw1_o(mmu_dmw1_o)
    ,.mmu_tlb_e_o(mmu_tlb_e_o)
    ,.mmu_tlb_vppn_o(mmu_tlb_vppn_o)
    ,.mmu_tlb_asid_o(mmu_tlb_asid_o)
    ,.mmu_tlb_g_o(mmu_tlb_g_o)
    ,.mmu_tlb_ps_o(mmu_tlb_ps_o)
    ,.mmu_tlb_ppn0_o(mmu_tlb_ppn0_o)
    ,.mmu_tlb_ppn1_o(mmu_tlb_ppn1_o)
    ,.mmu_tlb_plv0_o(mmu_tlb_plv0_o)
    ,.mmu_tlb_plv1_o(mmu_tlb_plv1_o)
    ,.mmu_tlb_mat0_o(mmu_tlb_mat0_o)
    ,.mmu_tlb_mat1_o(mmu_tlb_mat1_o)
    ,.mmu_tlb_d0_o(mmu_tlb_d0_o)
    ,.mmu_tlb_d1_o(mmu_tlb_d1_o)
    ,.mmu_tlb_v0_o(mmu_tlb_v0_o)
    ,.mmu_tlb_v1_o(mmu_tlb_v1_o)

    // Masked interrupt output
    ,.interrupt_o(interrupt_w)
);

//-----------------------------------------------------------------
// CSR Read Result (E1) / Early exceptions
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    csr_commit_opcode_q     <= 32'b0;
    csr_commit_ra_operand_q <= 32'b0;
    csr_commit_rb_operand_q <= 32'b0;
end
else if (opcode_valid_q)
begin
    csr_commit_opcode_q     <= opcode_opcode_q;
    csr_commit_ra_operand_q <= opcode_ra_operand_q;
    csr_commit_rb_operand_q <= opcode_rb_operand_q;
end

assign csr_result_e1_value_o     = (opcode_invalid_q || csr_fault_r) ? opcode_opcode_q : csr_result_r;
assign csr_result_e1_write_o     = opcode_valid_q && csr_write_w && ~csr_fault_r;
assign csr_result_e1_wdata_o     = data_r;
assign csr_result_e1_exception_o = opcode_valid_q ? csr_exception_r : `EXCEPTION_W'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    timer_q <= 64'b0;
else
    timer_q <= timer_q + 64'd1;

//-----------------------------------------------------------------
// Interrupt launch enable
//-----------------------------------------------------------------
reg take_interrupt_q;
wire interrupt_ready_w = |interrupt_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    take_interrupt_q    <= 1'b0;
else
    take_interrupt_q    <= interrupt_ready_w & ~interrupt_inhibit_i;

assign take_interrupt_o = take_interrupt_q;
assign interrupt_ready_o = interrupt_ready_w;

//-----------------------------------------------------------------
// TLB flush
//-----------------------------------------------------------------
reg tlb_flush_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    tlb_flush_q <= 1'b0;
else
    tlb_flush_q <= 1'b0;

//-----------------------------------------------------------------
// ifence
//-----------------------------------------------------------------
assign ifence_o = ifence_w;

//-----------------------------------------------------------------
// Execute - Branch operations
//-----------------------------------------------------------------
reg        branch_q;
reg [31:0] branch_target_q;
reg        idle_q;
reg        reset_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    branch_target_q <= 32'b0;
    branch_q        <= 1'b0;
    idle_q          <= 1'b0;
    reset_q         <= 1'b1;
end
else if (reset_q)
begin
    branch_target_q <= reset_vector_i;
    branch_q        <= 1'b1;
    idle_q          <= 1'b0;
    reset_q         <= 1'b0;
end
else
begin
    branch_q        <= csr_branch_w;
    branch_target_q <= csr_target_w;
    idle_q          <= csr_writeback_exception_i == `EXCEPTION_IDLE;
end

assign branch_csr_request_o = branch_q;
assign branch_csr_pc_o      = branch_target_q;
assign branch_csr_priv_o    = current_priv_w;
assign idle_o               = idle_q;

//-----------------------------------------------------------------
// MMU
//-----------------------------------------------------------------
assign mmu_priv_d_o     = current_priv_w;
assign mmu_satp_o       = 32'b0;
assign mmu_flush_o      = tlb_flush_q;
assign mmu_sum_o        = 1'b0;
assign mmu_mxr_o        = 1'b0;

endmodule
