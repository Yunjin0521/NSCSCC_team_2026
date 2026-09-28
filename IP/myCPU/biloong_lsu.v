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

module biloong_lsu
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter MEM_CACHE_ADDR_MIN = 0
    ,parameter MEM_CACHE_ADDR_MAX = 32'hffffffff
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_ra_idx_i
    ,input  [  4:0]  opcode_rb_idx_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input           llbit_i
    ,input  [ 31:0]  mem_data_rd_i
    ,input           mem_accept_i
    ,input           mem_ack_i
    ,input           mem_error_i
    ,input  [ 10:0]  mem_resp_tag_i
    ,input           mem_load_fault_i
    ,input           mem_store_fault_i
    ,input  [  5:0]  mem_fault_ecode_i
    ,input  [ 31:0]  mem_paddr_i
    ,input           opcode_pipe1_i

    // Outputs
    ,output [ 31:0]  mem_addr_o
    ,output [ 31:0]  mem_data_wr_o
    ,output          mem_rd_o
    ,output [  3:0]  mem_wr_o
    ,output [  1:0]  mem_size_o
    ,output          mem_cacheable_o
    ,output [ 10:0]  mem_req_tag_o
    ,output          mem_invalidate_o
    ,output          mem_writeback_o
    ,output          mem_flush_o
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_value_o
    ,output [  5:0]  writeback_exception_o
    ,output [  5:0]  writeback_exception_ecode_o
    ,output          writeback_pipe1_o
    ,output          llbit_set_o
    ,output          llbit_value_o
    ,output [  7:0]  diff_load_valid_o
    ,output [ 31:0]  diff_load_paddr_o
    ,output [ 31:0]  diff_load_vaddr_o
    ,output          diff_load_index_o
    ,output [  7:0]  diff_store_valid_o
    ,output [ 31:0]  diff_store_paddr_o
    ,output [ 31:0]  diff_store_vaddr_o
    ,output [ 31:0]  diff_store_data_o
    ,output          diff_store_index_o
    ,output          stall_o
    ,output          skid_ready_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
reg          mem_unaligned_e2_q;

reg          mem_sc_fail_e2_q;
reg          mem_preld_e2_q;
reg          mem_cacop_index_e2_q;

reg          pkt_valid_q;
// This opcode fans into the LSU decode, response tracking, and exception
// paths.  Bound the local fanout so the timing tool can replicate the source
// register instead of routing one long control net through the core.
(* max_fanout = 16 *) reg [ 31:0] pkt_opcode_q;
reg [ 31:0] pkt_ra_operand_q;
reg [ 31:0] pkt_rb_operand_q;
reg          pkt_sc_success_q;
reg          pkt_pipe1_q;
reg          pkt_req_active_q;
reg          pkt_unaligned_q;
reg          pkt_sc_fail_q;

reg          skid_valid_q;
reg [ 31:0] skid_opcode_q;
reg [ 31:0] skid_ra_operand_q;
reg [ 31:0] skid_rb_operand_q;
reg          skid_sc_success_q;
reg          skid_pipe1_q;
reg          skid_req_active_q;
reg          skid_unaligned_q;
reg          skid_sc_fail_q;

reg          req_hold_valid_q;
reg [ 31:0] req_hold_addr_q;
reg [ 31:0] req_hold_vaddr_q;
reg [ 31:0] req_hold_data_q;
reg          req_hold_rd_q;
reg [  3:0] req_hold_wr_q;
reg          req_hold_cacheable_q;
reg          req_hold_invalidate_q;
reg          req_hold_writeback_q;
reg          req_hold_flush_q;
reg          req_hold_load_q;
reg          req_hold_byte_q;
reg          req_hold_half_q;
reg          req_hold_signed_q;
reg          req_hold_ll_q;
reg          req_hold_sc_q;
reg          req_hold_sc_success_q;
reg [  7:0] req_hold_load_valid_q;
reg [  7:0] req_hold_store_valid_q;
reg          req_hold_pipe1_q;

localparam REQ_ENTRY_W = 129;
reg          req_buf_valid_q;
reg [REQ_ENTRY_W-1:0] req_buf_q;

wire [REQ_ENTRY_W-1:0] req_local_entry_w;
wire [ 31:0] req_buf_addr_w;
wire [ 31:0] req_buf_vaddr_w;
wire [ 31:0] req_buf_data_w;
wire         req_buf_rd_w;
wire [  3:0] req_buf_wr_w;
wire         req_buf_cacheable_w;
wire         req_buf_invalidate_w;
wire         req_buf_writeback_w;
wire         req_buf_flush_w;
wire         req_buf_load_w;
wire         req_buf_byte_w;
wire         req_buf_half_w;
wire         req_buf_signed_w;
wire         req_buf_ll_w;
wire         req_buf_sc_w;
wire         req_buf_sc_success_w;
wire [  7:0] req_buf_load_valid_w;
wire [  7:0] req_buf_store_valid_w;
wire         req_buf_pipe1_w;
wire [ 31:0] req_head_addr_w;
wire [ 31:0] req_head_vaddr_w;
wire [ 31:0] req_head_data_w;
wire         req_head_rd_w;
wire [  3:0] req_head_wr_w;
wire         req_head_cacheable_w;
wire         req_head_invalidate_w;
wire         req_head_writeback_w;
wire         req_head_flush_w;
wire         req_head_load_w;
wire         req_head_byte_w;
wire         req_head_half_w;
wire         req_head_signed_w;
wire         req_head_ll_w;
wire         req_head_sc_w;
wire         req_head_sc_success_w;
wire [  7:0] req_head_load_valid_w;
wire [  7:0] req_head_store_valid_w;
wire         req_head_pipe1_w;
wire         req_head_addr_cacheable_w;
wire         req_head_cacheable_calc_w;
wire         req_head_valid_w;
wire         req_queue_full_w;
wire         req_enqueue_local_w;
wire         req_enqueue_w;
wire         req_enqueue_to_head_w;
wire         req_enqueue_to_buf_w;

wire         req_slot_ready_w;
wire         active_req_ready_w;
wire         active_dummy_ready_w;
wire         output_req_active_w;
wire         local_req_launch_w;
wire         local_req_issue_w;
wire         active_dummy_complete_w;
wire         local_dummy_complete_w;
wire         packet_complete_w;
wire         pkt_stall_w;
wire         req_hold_fire_w;
wire         mem_issue_valid_w;
wire         mem_issue_accept_w;

reg          mem_issue_valid_q;
reg [ 31:0] mem_issue_addr_q;
reg [ 31:0] mem_issue_vaddr_q;
reg [ 31:0] mem_issue_data_q;
reg          mem_issue_rd_q;
reg [  3:0] mem_issue_wr_q;
reg          mem_issue_cacheable_q;
reg          mem_issue_invalidate_q;
reg          mem_issue_writeback_q;
reg          mem_issue_flush_q;
reg          mem_issue_load_q;
reg          mem_issue_byte_q;
reg          mem_issue_half_q;
reg          mem_issue_signed_q;
reg          mem_issue_ll_q;
reg          mem_issue_sc_q;
reg          mem_issue_sc_success_q;
reg [  7:0] mem_issue_load_valid_q;
reg [  7:0] mem_issue_store_valid_q;
reg          mem_issue_pipe1_q;

//-----------------------------------------------------------------
// Outstanding Access Tracking
//-----------------------------------------------------------------
reg [1:0] pending_lsu_count_q;
reg       mem_accept_q;

wire complete_ok_e2_w  = mem_ack_i & ~mem_error_i;
wire complete_err_e2_w = mem_ack_i & mem_error_i;
wire req_head_valid_issue_w = req_hold_valid_q ||
                              (local_req_launch_w && !req_hold_valid_q &&
                               !req_buf_valid_q && !mem_issue_valid_q &&
                               (pending_lsu_count_q == 2'd0));
wire req_context_ready_w = (pending_lsu_count_q == 2'd0) || complete_ok_e2_w;
wire req_mem_issue_allowed_w = req_context_ready_w && !complete_err_e2_w;
assign mem_issue_valid_w = mem_issue_valid_q || (req_head_valid_w && req_mem_issue_allowed_w);
assign mem_issue_accept_w = mem_issue_valid_w && mem_accept_i;
assign req_hold_fire_w = req_head_valid_w && req_mem_issue_allowed_w && !mem_issue_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pending_lsu_count_q <= 2'b0;
else if (complete_err_e2_w)
    pending_lsu_count_q <= 2'b0;
else
begin
    case ({mem_issue_accept_w, complete_ok_e2_w})
    2'b10:
        pending_lsu_count_q <= 2'd1;
    2'b01:
        if (pending_lsu_count_q != 2'd0)
            pending_lsu_count_q <= pending_lsu_count_q - 2'd1;
    2'b11:
        pending_lsu_count_q <= 2'd1;
    default:
        ;
    endcase
end

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_accept_q <= 1'b0;
else
    mem_accept_q <= mem_accept_i;

assign req_queue_full_w = req_hold_valid_q && req_buf_valid_q;
assign req_slot_ready_w = !req_queue_full_w;
assign active_req_ready_w = req_slot_ready_w;
assign active_dummy_ready_w = req_slot_ready_w && (pending_lsu_count_q == 2'd0) &&
                              !req_head_valid_w && !mem_issue_valid_q;

//-----------------------------------------------------------------
// Dummy Ack (unaligned access /E2)
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_unaligned_e2_q <= 1'b0;
else
    mem_unaligned_e2_q <= active_valid_w & pkt_unaligned_q & active_dummy_ready_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_sc_fail_e2_q <= 1'b0;
else
    mem_sc_fail_e2_q <= active_valid_w & sc_fail_w & active_dummy_ready_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_preld_e2_q <= 1'b0;
else
    mem_preld_e2_q <= active_valid_w & inst_preld_w & active_dummy_ready_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_cacop_index_e2_q <= 1'b0;
else
    mem_cacop_index_e2_q <= active_valid_w & inst_cacop_index_w &
                            active_dummy_ready_w;

//-----------------------------------------------------------------
// Opcode decode
//-----------------------------------------------------------------

wire [31:0] active_opcode_w     = pkt_opcode_q;
wire [31:0] active_ra_operand_w = pkt_ra_operand_q;
wire [31:0] active_rb_operand_w = pkt_rb_operand_q;
wire        active_pipe1_w      = pkt_pipe1_q;
wire        active_valid_w      = pkt_valid_q;

wire [5:0] op_31_26_w = active_opcode_w[`LA_OP_31_26_R];
wire [3:0] op_25_22_w = active_opcode_w[`LA_OP_25_22_R];
wire [31:0] imm12_s_w = {{20{active_opcode_w[21]}}, active_opcode_w[21:10]};
wire [31:0] llsc_imm_w = {{16{active_opcode_w[23]}}, active_opcode_w[23:10], 2'b0};

wire inst_ld_b_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h0);
wire inst_ld_h_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h1);
wire inst_ld_w_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h2);
wire inst_st_b_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h4);
wire inst_st_h_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h5);
wire inst_st_w_w  = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h6);
wire inst_ld_bu_w = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h8);
wire inst_ld_hu_w = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'h9);
wire inst_preld_w = (op_31_26_w == 6'h0a) && (op_25_22_w == 4'hb);
wire inst_ll_w_w  = (op_31_26_w == 6'h08) && !active_opcode_w[25] && !active_opcode_w[24];
wire inst_sc_w_w  = (op_31_26_w == 6'h08) && !active_opcode_w[25] &&  active_opcode_w[24];
wire inst_cacop_w = (op_31_26_w == 6'h01) && (op_25_22_w == 4'h8);
wire inst_cacop_translate_w = inst_cacop_w && (active_opcode_w[4:3] == 2'b10);
wire inst_cacop_index_w     = inst_cacop_w && (active_opcode_w[4:3] != 2'b10);

wire load_inst_w        = inst_ld_b_w || inst_ld_h_w || inst_ld_w_w ||
                          inst_ld_bu_w || inst_ld_hu_w || inst_ll_w_w;
wire load_signed_inst_w = inst_ld_b_w || inst_ld_h_w || inst_ld_w_w || inst_ll_w_w;
wire store_inst_w       = inst_st_b_w || inst_st_h_w || inst_st_w_w || inst_sc_w_w;
// Apply older in-flight LSU LL/SC effects before deciding the current SC.
// This preserves program order when LL/SC packets are queued behind memory stalls.
wire resp_llbit_valid_w = resp_dummy_q ? (resp_dummy_ll_q || resp_dummy_sc_q) :
                          ((pending_lsu_count_q != 2'd0) &&
                           (resp_mem_ll_q || resp_mem_sc_q));
wire resp_llbit_value_w = resp_dummy_q ? resp_dummy_ll_q : resp_mem_ll_q;
wire llbit_after_resp_w = resp_llbit_valid_w ? resp_llbit_value_w : llbit_i;
wire llbit_after_mem_issue_w =
    (mem_issue_valid_q && (mem_issue_ll_q || mem_issue_sc_q)) ?
    mem_issue_ll_q : llbit_after_resp_w;
wire llbit_after_req_hold_w =
    (req_hold_valid_q && (req_hold_ll_q || req_hold_sc_q)) ?
    req_hold_ll_q : llbit_after_mem_issue_w;
wire lsu_ordered_llbit_w =
    (req_buf_valid_q && (req_buf_ll_w || req_buf_sc_w)) ?
    req_buf_ll_w : llbit_after_req_hold_w;
wire active_sc_success_w = lsu_ordered_llbit_w;

wire req_lb_w = inst_ld_b_w || inst_ld_bu_w;
wire req_lh_w = inst_ld_h_w || inst_ld_hu_w;
wire req_lw_w = inst_ld_w_w || inst_ll_w_w;
wire req_sb_w = inst_st_b_w;
wire req_sh_w = inst_st_h_w;
wire req_sw_w = inst_st_w_w || (inst_sc_w_w && active_sc_success_w);

wire req_word_align_w = inst_st_w_w || inst_sc_w_w || req_lw_w;
wire req_sh_lh_w = req_sh_w || req_lh_w;
wire [31:0] addr_offset_w = (active_valid_w && (inst_ll_w_w || inst_sc_w_w)) ? llsc_imm_w : imm12_s_w;

reg [31:0]  mem_addr_r;
reg         mem_unaligned_r;
reg [31:0]  mem_data_r;
reg         mem_rd_r;
reg [3:0]   mem_wr_r;

always @ *
begin
    mem_addr_r      = 32'b0;
    mem_data_r      = 32'b0;
    mem_unaligned_r = 1'b0;
    mem_wr_r        = 4'b0;
    mem_rd_r        = 1'b0;

    mem_addr_r = active_ra_operand_w + addr_offset_w;

    if (active_valid_w && req_word_align_w)
        mem_unaligned_r = (mem_addr_r[1:0] != 2'b0);
    else if (active_valid_w && req_sh_lh_w)
        mem_unaligned_r = mem_addr_r[0];

    mem_rd_r = active_valid_w && load_inst_w && !mem_unaligned_r;

    if (active_valid_w && req_sw_w && !mem_unaligned_r)
    begin
        mem_data_r  = active_rb_operand_w;
        mem_wr_r    = 4'hF;
    end
    else if (active_valid_w && req_sh_w && !mem_unaligned_r)
    begin
        case (mem_addr_r[1:0])
        2'h2 :
        begin
            mem_data_r  = {active_rb_operand_w[15:0],16'h0000};
            mem_wr_r    = 4'b1100;
        end
        default :
        begin
            mem_data_r  = {16'h0000,active_rb_operand_w[15:0]};
            mem_wr_r    = 4'b0011;
        end
        endcase
    end
    else if (active_valid_w && req_sb_w)
    begin
        case (mem_addr_r[1:0])
        2'h3 :
        begin
            mem_data_r  = {active_rb_operand_w[7:0],24'h000000};
            mem_wr_r    = 4'b1000;
        end
        2'h2 :
        begin
            mem_data_r  = {{8'h00,active_rb_operand_w[7:0]},16'h0000};
            mem_wr_r    = 4'b0100;
        end
        2'h1 :
        begin
            mem_data_r  = {{16'h0000,active_rb_operand_w[7:0]},8'h00};
            mem_wr_r    = 4'b0010;
        end
        2'h0 :
        begin
            mem_data_r  = {24'h000000,active_rb_operand_w[7:0]};
            mem_wr_r    = 4'b0001;
        end
        default :
        ;
        endcase
    end
    else
        mem_wr_r    = 4'b0;
end

wire sc_fail_w = active_valid_w && inst_sc_w_w && !active_sc_success_w && !mem_unaligned_r;

wire [4:0] cacop_rd_w = active_opcode_w[`LA_RD_R];
wire [1:0] cacop_mode_w = cacop_rd_w[4:3];
wire [2:0] cacop_target_w = cacop_rd_w[2:0];
wire cacop_dcache_w = inst_cacop_translate_w && (cacop_target_w == 3'b001);
wire cacop_icache_w = inst_cacop_translate_w && (cacop_target_w == 3'b000);
wire dcache_invalidate_w = 1'b0;
wire dcache_flush_w      = cacop_dcache_w && (cacop_mode_w == 2'b10);
wire dcache_writeback_w  = 1'b0;
wire icache_probe_w      = cacop_icache_w && (cacop_mode_w == 2'b10);

localparam [31:0] CACHE_ADDR_MIN = MEM_CACHE_ADDR_MIN;
localparam [31:0] CACHE_ADDR_MAX = MEM_CACHE_ADDR_MAX;
localparam        CACHE_RANGE_FULL =
    (CACHE_ADDR_MIN == 32'h0000_0000) && (CACHE_ADDR_MAX == 32'hffff_ffff);
localparam        CACHE_RANGE_1MB =
    (CACHE_ADDR_MIN[19:0] == 20'h00000) &&
    (CACHE_ADDR_MAX[19:0] == 20'hfffff) &&
    (CACHE_ADDR_MIN[31:20] == CACHE_ADDR_MAX[31:20]);
localparam        CACHE_RANGE_16MB =
    (CACHE_ADDR_MIN[23:0] == 24'h000000) &&
    (CACHE_ADDR_MAX[23:0] == 24'hffffff) &&
    (CACHE_ADDR_MIN[31:24] == CACHE_ADDR_MAX[31:24]);
localparam        CACHE_RANGE_256MB =
    (CACHE_ADDR_MIN[27:0] == 28'h0000000) &&
    (CACHE_ADDR_MAX[27:0] == 28'hfffffff) &&
    (CACHE_ADDR_MIN[31:28] == CACHE_ADDR_MAX[31:28]);

wire [20:0] cache_low_1mb_sum_w = {1'b0, active_ra_operand_w[19:0]} +
                                  {1'b0, addr_offset_w[19:0]};
wire [12:0] cache_high_1mb_sum_w = {1'b0, active_ra_operand_w[31:20]} +
                                   {1'b0, addr_offset_w[31:20]} +
                                   {12'b0, cache_low_1mb_sum_w[20]};
wire [24:0] cache_low_16mb_sum_w = {1'b0, active_ra_operand_w[23:0]} +
                                   {1'b0, addr_offset_w[23:0]};
wire [8:0]  cache_high_16mb_sum_w = {1'b0, active_ra_operand_w[31:24]} +
                                    {1'b0, addr_offset_w[31:24]} +
                                    {8'b0, cache_low_16mb_sum_w[24]};
wire [28:0] cache_low_256mb_sum_w = {1'b0, active_ra_operand_w[27:0]} +
                                    {1'b0, addr_offset_w[27:0]};
wire [4:0]  cache_high_256mb_sum_w = {1'b0, active_ra_operand_w[31:28]} +
                                     {1'b0, addr_offset_w[31:28]} +
                                     {4'b0, cache_low_256mb_sum_w[28]};

wire mem_addr_cacheable_w =
    CACHE_RANGE_FULL  ? 1'b1 :
    CACHE_RANGE_1MB   ? (cache_high_1mb_sum_w[11:0] == CACHE_ADDR_MIN[31:20]) :
    CACHE_RANGE_16MB  ? (cache_high_16mb_sum_w[7:0] == CACHE_ADDR_MIN[31:24]) :
    CACHE_RANGE_256MB ? (cache_high_256mb_sum_w[3:0] == CACHE_ADDR_MIN[31:28]) :
                        (mem_addr_r >= CACHE_ADDR_MIN && mem_addr_r <= CACHE_ADDR_MAX);

wire input_cacheable_w =
    mem_addr_cacheable_w ||
    (active_valid_w && (dcache_invalidate_w || dcache_writeback_w || dcache_flush_w));
wire input_invalidate_w  = active_valid_w & dcache_invalidate_w;
wire input_writeback_w   = active_valid_w & dcache_writeback_w;
wire input_flush_w       = active_valid_w & dcache_flush_w;
wire input_load_w        = active_valid_w && load_inst_w;
wire input_mem_rd_w      = mem_rd_r || (active_valid_w && icache_probe_w);
wire input_ll_w          = active_valid_w && inst_ll_w_w && !mem_unaligned_r;
wire input_sc_w          = active_valid_w && inst_sc_w_w && !mem_unaligned_r;
wire input_sc_success_w  = active_valid_w && inst_sc_w_w && active_sc_success_w && !mem_unaligned_r;
wire [7:0] input_load_valid_w =
    (active_valid_w && !mem_unaligned_r) ?
    {2'b0, inst_ll_w_w, inst_ld_w_w, inst_ld_hu_w, inst_ld_h_w, inst_ld_bu_w, inst_ld_b_w} :
    8'b0;
wire [7:0] input_store_valid_w =
    (active_valid_w && !mem_unaligned_r) ?
    {4'b0, (inst_sc_w_w && active_sc_success_w), inst_st_w_w, inst_st_h_w, inst_st_b_w} :
    8'b0;
assign active_dummy_complete_w = active_valid_w &&
                                 (pkt_unaligned_q || sc_fail_w ||
                                  inst_preld_w || inst_cacop_index_w);
assign output_req_active_w = input_mem_rd_w || (|mem_wr_r) ||
                             input_invalidate_w || input_writeback_w || input_flush_w;
assign local_req_launch_w = active_valid_w && output_req_active_w && active_req_ready_w;
assign local_req_issue_w = local_req_launch_w && !req_hold_valid_q && !req_buf_valid_q &&
                           !mem_issue_valid_q && req_mem_issue_allowed_w;
assign local_dummy_complete_w = active_dummy_complete_w && active_dummy_ready_w;
assign packet_complete_w = local_req_launch_w || local_dummy_complete_w;
assign pkt_stall_w = pkt_valid_q && !local_req_launch_w;
wire skid_ready_packet_drain_w = local_req_launch_w;

wire [5:0] input_op_31_26_w = opcode_opcode_i[`LA_OP_31_26_R];
wire [3:0] input_op_25_22_w = opcode_opcode_i[`LA_OP_25_22_R];
wire [31:0] input_imm12_s_w = {{20{opcode_opcode_i[21]}}, opcode_opcode_i[21:10]};
wire [31:0] input_llsc_imm_w = {{16{opcode_opcode_i[23]}}, opcode_opcode_i[23:10], 2'b0};
wire input_inst_ld_b_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h0);
wire input_inst_ld_h_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h1);
wire input_inst_ld_w_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h2);
wire input_inst_st_b_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h4);
wire input_inst_st_h_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h5);
wire input_inst_st_w_w  = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h6);
wire input_inst_ld_bu_w = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h8);
wire input_inst_ld_hu_w = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'h9);
wire input_inst_ll_w_w  = (input_op_31_26_w == 6'h08) && !opcode_opcode_i[25] && !opcode_opcode_i[24];
wire input_inst_sc_w_w  = (input_op_31_26_w == 6'h08) && !opcode_opcode_i[25] &&  opcode_opcode_i[24];
wire input_inst_preld_w = (input_op_31_26_w == 6'h0a) && (input_op_25_22_w == 4'hb);
wire input_inst_cacop_w = (input_op_31_26_w == 6'h01) && (input_op_25_22_w == 4'h8);
wire input_inst_cacop_translate_w = input_inst_cacop_w &&
                                    (opcode_opcode_i[4:3] == 2'b10);
wire current_input_load_w =
    input_inst_ll_w_w || input_inst_ld_b_w || input_inst_ld_h_w || input_inst_ld_w_w ||
    input_inst_ld_bu_w || input_inst_ld_hu_w;
wire current_input_store_w =
    input_inst_sc_w_w || input_inst_st_b_w || input_inst_st_h_w || input_inst_st_w_w;
wire current_input_lsu_w = opcode_valid_i;
wire current_input_skiddable_w = opcode_valid_i && (current_input_load_w || current_input_store_w);
// Predict LLBit in program order using LSU-local registered state.  This keeps
// a D-cache completion from returning through the CSR combinational bypass,
// while still accounting for older active and skid-buffered LL/SC operations.
wire skid_inst_ll_w = (skid_opcode_q[31:26] == 6'h08) &&
                      !skid_opcode_q[25] && !skid_opcode_q[24];
wire skid_inst_sc_w = (skid_opcode_q[31:26] == 6'h08) &&
                      !skid_opcode_q[25] &&  skid_opcode_q[24];
wire llbit_after_active_w =
    (active_valid_w && (inst_ll_w_w || inst_sc_w_w)) ?
    inst_ll_w_w : lsu_ordered_llbit_w;
wire llbit_before_input_w =
    (skid_valid_q && (skid_inst_ll_w || skid_inst_sc_w)) ?
    skid_inst_ll_w : llbit_after_active_w;
wire current_input_sc_success_w = input_inst_sc_w_w && llbit_before_input_w;
wire [31:0] current_input_addr_offset_w =
    (opcode_valid_i && (input_inst_ll_w_w || input_inst_sc_w_w)) ? input_llsc_imm_w : input_imm12_s_w;
wire [31:0] current_input_addr_w = opcode_ra_operand_i + current_input_addr_offset_w;
wire current_input_word_align_w =
    input_inst_st_w_w || input_inst_sc_w_w || input_inst_ld_w_w || input_inst_ll_w_w;
wire current_input_half_align_w =
    input_inst_st_h_w || input_inst_ld_h_w || input_inst_ld_hu_w;
wire current_input_unaligned_w =
    opcode_valid_i &&
    ((current_input_word_align_w && (current_input_addr_w[1:0] != 2'b0)) ||
     (current_input_half_align_w && current_input_addr_w[0]));
wire current_input_sc_fail_w =
    opcode_valid_i && input_inst_sc_w_w && !current_input_sc_success_w &&
    !current_input_unaligned_w;
wire current_input_req_wr_w =
    opcode_valid_i && !current_input_unaligned_w &&
    (input_inst_st_b_w || input_inst_st_h_w || input_inst_st_w_w ||
     (input_inst_sc_w_w && current_input_sc_success_w));
wire current_input_req_rd_w =
    opcode_valid_i && !current_input_unaligned_w && current_input_load_w;
wire [4:0] current_input_cacop_rd_w = opcode_opcode_i[`LA_RD_R];
wire [1:0] current_input_cacop_mode_w = current_input_cacop_rd_w[4:3];
wire [2:0] current_input_cacop_target_w = current_input_cacop_rd_w[2:0];
wire current_input_cacop_icache_w =
    input_inst_cacop_translate_w &&
    (current_input_cacop_target_w == 3'b000) &&
    (current_input_cacop_mode_w == 2'b10);
wire current_input_cacop_dcache_w =
    input_inst_cacop_translate_w &&
    (current_input_cacop_target_w == 3'b001) &&
    (current_input_cacop_mode_w == 2'b10);
wire current_input_cacheop_w =
    opcode_valid_i && (current_input_cacop_icache_w ||
                       current_input_cacop_dcache_w);
wire current_input_req_active_w =
    current_input_req_rd_w || current_input_req_wr_w || current_input_cacheop_w;

assign req_local_entry_w = {mem_addr_r[31:2], 2'b0,
                            mem_addr_r,
                            mem_data_r,
                            input_mem_rd_w,
                            mem_wr_r,
                            1'b0,
                            input_invalidate_w,
                            input_writeback_w,
                            input_flush_w,
                            input_load_w,
                            req_lb_w | req_sb_w,
                            req_lh_w | req_sh_w,
                            load_signed_inst_w,
                            input_ll_w,
                            input_sc_w,
                            input_sc_success_w,
                            input_load_valid_w,
                            input_store_valid_w,
                            active_pipe1_w};

assign {req_buf_addr_w,
        req_buf_vaddr_w,
        req_buf_data_w,
        req_buf_rd_w,
        req_buf_wr_w,
        req_buf_cacheable_w,
        req_buf_invalidate_w,
        req_buf_writeback_w,
        req_buf_flush_w,
        req_buf_load_w,
        req_buf_byte_w,
        req_buf_half_w,
        req_buf_signed_w,
        req_buf_ll_w,
        req_buf_sc_w,
        req_buf_sc_success_w,
        req_buf_load_valid_w,
        req_buf_store_valid_w,
        req_buf_pipe1_w} = req_buf_q;

assign req_head_valid_w = req_hold_valid_q || local_req_issue_w;
assign req_head_addr_w = req_hold_valid_q ? req_hold_addr_q : {mem_addr_r[31:2], 2'b0};
assign req_head_vaddr_w = req_hold_valid_q ? req_hold_vaddr_q : mem_addr_r;
assign req_head_data_w = req_hold_valid_q ? req_hold_data_q : mem_data_r;
assign req_head_rd_w = req_hold_valid_q ? req_hold_rd_q : input_mem_rd_w;
assign req_head_wr_w = req_hold_valid_q ? req_hold_wr_q : mem_wr_r;
assign req_head_cacheable_w = req_hold_valid_q ? req_hold_cacheable_q : 1'b0;
assign req_head_invalidate_w = req_hold_valid_q ? req_hold_invalidate_q : input_invalidate_w;
assign req_head_writeback_w = req_hold_valid_q ? req_hold_writeback_q : input_writeback_w;
assign req_head_flush_w = req_hold_valid_q ? req_hold_flush_q : input_flush_w;
assign req_head_load_w = req_hold_valid_q ? req_hold_load_q : input_load_w;
assign req_head_byte_w = req_hold_valid_q ? req_hold_byte_q : (req_lb_w | req_sb_w);
assign req_head_half_w = req_hold_valid_q ? req_hold_half_q : (req_lh_w | req_sh_w);
assign req_head_signed_w = req_hold_valid_q ? req_hold_signed_q : load_signed_inst_w;
assign req_head_ll_w = req_hold_valid_q ? req_hold_ll_q : input_ll_w;
assign req_head_sc_w = req_hold_valid_q ? req_hold_sc_q : input_sc_w;
assign req_head_sc_success_w = req_hold_valid_q ? req_hold_sc_success_q : input_sc_success_w;
assign req_head_load_valid_w = req_hold_valid_q ? req_hold_load_valid_q : input_load_valid_w;
assign req_head_store_valid_w = req_hold_valid_q ? req_hold_store_valid_q : input_store_valid_w;
assign req_head_pipe1_w = req_hold_valid_q ? req_hold_pipe1_q : active_pipe1_w;
assign req_head_addr_cacheable_w =
    CACHE_RANGE_FULL  ? 1'b1 :
    CACHE_RANGE_1MB   ? (req_head_vaddr_w[31:20] == CACHE_ADDR_MIN[31:20]) :
    CACHE_RANGE_16MB  ? (req_head_vaddr_w[31:24] == CACHE_ADDR_MIN[31:24]) :
    CACHE_RANGE_256MB ? (req_head_vaddr_w[31:28] == CACHE_ADDR_MIN[31:28]) :
                        (req_head_vaddr_w >= CACHE_ADDR_MIN &&
                         req_head_vaddr_w <= CACHE_ADDR_MAX);
assign req_head_cacheable_calc_w = req_head_addr_cacheable_w ||
                                   req_head_invalidate_w ||
                                   req_head_writeback_w ||
                                   req_head_flush_w;

assign req_enqueue_local_w = local_req_launch_w && !local_req_issue_w;
assign req_enqueue_w = req_enqueue_local_w;
assign req_enqueue_to_head_w = req_enqueue_w &&
                               (!req_hold_valid_q ||
                                (req_hold_fire_w && !req_buf_valid_q));
assign req_enqueue_to_buf_w = req_enqueue_w && !req_enqueue_to_head_w;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    pkt_valid_q        <= 1'b0;
    pkt_opcode_q       <= 32'b0;
    pkt_ra_operand_q   <= 32'b0;
    pkt_rb_operand_q   <= 32'b0;
    pkt_sc_success_q   <= 1'b0;
    pkt_pipe1_q        <= 1'b0;
    pkt_req_active_q   <= 1'b0;
    pkt_unaligned_q    <= 1'b0;
    pkt_sc_fail_q      <= 1'b0;
    skid_valid_q       <= 1'b0;
    skid_sc_success_q  <= 1'b0;
    skid_opcode_q      <= 32'b0;
    skid_ra_operand_q  <= 32'b0;
    skid_rb_operand_q  <= 32'b0;
    skid_pipe1_q       <= 1'b0;
    skid_req_active_q  <= 1'b0;
    skid_unaligned_q   <= 1'b0;
    skid_sc_fail_q     <= 1'b0;
    req_hold_valid_q   <= 1'b0;
    req_hold_addr_q    <= 32'b0;
    req_hold_vaddr_q   <= 32'b0;
    req_hold_data_q    <= 32'b0;
    req_hold_rd_q      <= 1'b0;
    req_hold_wr_q      <= 4'b0;
    req_hold_cacheable_q <= 1'b0;
    req_hold_invalidate_q <= 1'b0;
    req_hold_writeback_q <= 1'b0;
    req_hold_flush_q   <= 1'b0;
    req_hold_load_q    <= 1'b0;
    req_hold_byte_q    <= 1'b0;
    req_hold_half_q    <= 1'b0;
    req_hold_signed_q  <= 1'b0;
    req_hold_ll_q      <= 1'b0;
    req_hold_sc_q      <= 1'b0;
    req_hold_sc_success_q <= 1'b0;
    req_hold_load_valid_q <= 8'b0;
    req_hold_store_valid_q <= 8'b0;
    req_hold_pipe1_q   <= 1'b0;
    req_buf_valid_q    <= 1'b0;
    req_buf_q          <= {REQ_ENTRY_W{1'b0}};
    mem_issue_valid_q  <= 1'b0;
    mem_issue_addr_q   <= 32'b0;
    mem_issue_vaddr_q  <= 32'b0;
    mem_issue_data_q   <= 32'b0;
    mem_issue_rd_q     <= 1'b0;
    mem_issue_wr_q     <= 4'b0;
    mem_issue_cacheable_q <= 1'b0;
    mem_issue_invalidate_q <= 1'b0;
    mem_issue_writeback_q <= 1'b0;
    mem_issue_flush_q  <= 1'b0;
    mem_issue_load_q   <= 1'b0;
    mem_issue_byte_q   <= 1'b0;
    mem_issue_half_q   <= 1'b0;
    mem_issue_signed_q <= 1'b0;
    mem_issue_ll_q     <= 1'b0;
    mem_issue_sc_q     <= 1'b0;
    mem_issue_sc_success_q <= 1'b0;
    mem_issue_load_valid_q <= 8'b0;
    mem_issue_store_valid_q <= 8'b0;
    mem_issue_pipe1_q  <= 1'b0;
end
// Memory access fault - squash next operation (exception coming...)
else if (complete_err_e2_w || mem_unaligned_e2_q)
begin
    pkt_valid_q        <= 1'b0;
    pkt_opcode_q       <= 32'b0;
    pkt_ra_operand_q   <= 32'b0;
    pkt_rb_operand_q   <= 32'b0;
    pkt_sc_success_q   <= 1'b0;
    pkt_pipe1_q        <= 1'b0;
    pkt_req_active_q   <= 1'b0;
    pkt_unaligned_q    <= 1'b0;
    pkt_sc_fail_q      <= 1'b0;
    skid_valid_q       <= 1'b0;
    skid_sc_success_q  <= 1'b0;
    skid_opcode_q      <= 32'b0;
    skid_ra_operand_q  <= 32'b0;
    skid_rb_operand_q  <= 32'b0;
    skid_pipe1_q       <= 1'b0;
    skid_req_active_q  <= 1'b0;
    skid_unaligned_q   <= 1'b0;
    skid_sc_fail_q     <= 1'b0;
    req_hold_valid_q   <= 1'b0;
    req_hold_addr_q    <= 32'b0;
    req_hold_vaddr_q   <= 32'b0;
    req_hold_data_q    <= 32'b0;
    req_hold_rd_q      <= 1'b0;
    req_hold_wr_q      <= 4'b0;
    req_hold_cacheable_q <= 1'b0;
    req_hold_invalidate_q <= 1'b0;
    req_hold_writeback_q <= 1'b0;
    req_hold_flush_q   <= 1'b0;
    req_hold_load_q    <= 1'b0;
    req_hold_byte_q    <= 1'b0;
    req_hold_half_q    <= 1'b0;
    req_hold_signed_q  <= 1'b0;
    req_hold_ll_q      <= 1'b0;
    req_hold_sc_q      <= 1'b0;
    req_hold_sc_success_q <= 1'b0;
    req_hold_load_valid_q <= 8'b0;
    req_hold_store_valid_q <= 8'b0;
    req_hold_pipe1_q   <= 1'b0;
    req_buf_valid_q    <= 1'b0;
    req_buf_q          <= {REQ_ENTRY_W{1'b0}};
    mem_issue_valid_q  <= 1'b0;
    mem_issue_addr_q   <= 32'b0;
    mem_issue_vaddr_q  <= 32'b0;
    mem_issue_data_q   <= 32'b0;
    mem_issue_rd_q     <= 1'b0;
    mem_issue_wr_q     <= 4'b0;
    mem_issue_cacheable_q <= 1'b0;
    mem_issue_invalidate_q <= 1'b0;
    mem_issue_writeback_q <= 1'b0;
    mem_issue_flush_q  <= 1'b0;
    mem_issue_load_q   <= 1'b0;
    mem_issue_byte_q   <= 1'b0;
    mem_issue_half_q   <= 1'b0;
    mem_issue_signed_q <= 1'b0;
    mem_issue_ll_q     <= 1'b0;
    mem_issue_sc_q     <= 1'b0;
    mem_issue_sc_success_q <= 1'b0;
    mem_issue_load_valid_q <= 8'b0;
    mem_issue_store_valid_q <= 8'b0;
    mem_issue_pipe1_q  <= 1'b0;
end
else
begin
    if (mem_issue_accept_w)
        mem_issue_valid_q <= 1'b0;

    if (req_hold_fire_w)
    begin
        mem_issue_valid_q <= !mem_accept_i;
        mem_issue_addr_q <= req_head_addr_w;
        mem_issue_vaddr_q <= req_head_vaddr_w;
        mem_issue_data_q <= req_head_data_w;
        mem_issue_rd_q <= req_head_rd_w;
        mem_issue_wr_q <= req_head_wr_w;
        mem_issue_cacheable_q <= req_head_cacheable_calc_w;
        mem_issue_invalidate_q <= req_head_invalidate_w;
        mem_issue_writeback_q <= req_head_writeback_w;
        mem_issue_flush_q <= req_head_flush_w;
        mem_issue_load_q <= req_head_load_w;
        mem_issue_byte_q <= req_head_byte_w;
        mem_issue_half_q <= req_head_half_w;
        mem_issue_signed_q <= req_head_signed_w;
        mem_issue_ll_q <= req_head_ll_w;
        mem_issue_sc_q <= req_head_sc_w;
        mem_issue_sc_success_q <= req_head_sc_success_w;
        mem_issue_load_valid_q <= req_head_load_valid_w;
        mem_issue_store_valid_q <= req_head_store_valid_w;
        mem_issue_pipe1_q <= req_head_pipe1_w;

        if (req_buf_valid_q)
        begin
            {req_hold_addr_q,
             req_hold_vaddr_q,
             req_hold_data_q,
             req_hold_rd_q,
             req_hold_wr_q,
             req_hold_cacheable_q,
             req_hold_invalidate_q,
             req_hold_writeback_q,
             req_hold_flush_q,
             req_hold_load_q,
             req_hold_byte_q,
             req_hold_half_q,
             req_hold_signed_q,
             req_hold_ll_q,
             req_hold_sc_q,
             req_hold_sc_success_q,
             req_hold_load_valid_q,
             req_hold_store_valid_q,
             req_hold_pipe1_q} <= req_buf_q;
            req_hold_valid_q <= 1'b1;
            req_buf_valid_q  <= 1'b0;
        end
        else
            req_hold_valid_q <= 1'b0;
    end

    if (req_enqueue_to_head_w)
    begin
        {req_hold_addr_q,
         req_hold_vaddr_q,
         req_hold_data_q,
         req_hold_rd_q,
         req_hold_wr_q,
         req_hold_cacheable_q,
         req_hold_invalidate_q,
         req_hold_writeback_q,
         req_hold_flush_q,
         req_hold_load_q,
         req_hold_byte_q,
         req_hold_half_q,
         req_hold_signed_q,
         req_hold_ll_q,
         req_hold_sc_q,
         req_hold_sc_success_q,
         req_hold_load_valid_q,
         req_hold_store_valid_q,
         req_hold_pipe1_q} <= req_local_entry_w;
        req_hold_valid_q   <= 1'b1;
    end
    else if (req_enqueue_to_buf_w)
    begin
        req_buf_q         <= req_local_entry_w;
        req_buf_valid_q   <= 1'b1;
    end

    if (packet_complete_w)
    begin
        if (skid_valid_q)
        begin
            pkt_valid_q        <= 1'b1;
            pkt_opcode_q       <= skid_opcode_q;
            pkt_ra_operand_q   <= skid_ra_operand_q;
            pkt_rb_operand_q   <= skid_rb_operand_q;
            pkt_sc_success_q   <= skid_sc_success_q;
            pkt_pipe1_q        <= skid_pipe1_q;
            pkt_req_active_q   <= skid_req_active_q;
            pkt_unaligned_q    <= skid_unaligned_q;
            pkt_sc_fail_q      <= skid_sc_fail_q;

            if (current_input_lsu_w)
            begin
                skid_valid_q       <= 1'b1;
                skid_opcode_q      <= opcode_opcode_i;
                skid_ra_operand_q  <= opcode_ra_operand_i;
                skid_rb_operand_q  <= opcode_rb_operand_i;
                skid_sc_success_q  <= current_input_sc_success_w;
                skid_pipe1_q       <= opcode_pipe1_i;
                skid_req_active_q  <= current_input_req_active_w;
                skid_unaligned_q   <= current_input_unaligned_w;
                skid_sc_fail_q     <= current_input_sc_fail_w;
            end
            else
            begin
                skid_valid_q       <= 1'b0;
                skid_req_active_q  <= 1'b0;
                skid_unaligned_q   <= 1'b0;
                skid_sc_fail_q     <= 1'b0;
            end
        end
        else if (current_input_lsu_w)
        begin
            pkt_valid_q        <= 1'b1;
            pkt_opcode_q       <= opcode_opcode_i;
            pkt_ra_operand_q   <= opcode_ra_operand_i;
            pkt_rb_operand_q   <= opcode_rb_operand_i;
            pkt_sc_success_q   <= current_input_sc_success_w;
            pkt_pipe1_q        <= opcode_pipe1_i;
            pkt_req_active_q   <= current_input_req_active_w;
            pkt_unaligned_q    <= current_input_unaligned_w;
            pkt_sc_fail_q      <= current_input_sc_fail_w;
            skid_valid_q       <= 1'b0;
            skid_req_active_q  <= 1'b0;
            skid_unaligned_q   <= 1'b0;
            skid_sc_fail_q     <= 1'b0;
        end
        else
        begin
            pkt_valid_q        <= 1'b0;
            pkt_req_active_q   <= 1'b0;
            pkt_unaligned_q    <= 1'b0;
            pkt_sc_fail_q      <= 1'b0;
        end
    end
    else if (!pkt_valid_q)
    begin
        if (current_input_lsu_w)
        begin
            pkt_valid_q        <= 1'b1;
            pkt_opcode_q       <= opcode_opcode_i;
            pkt_ra_operand_q   <= opcode_ra_operand_i;
            pkt_rb_operand_q   <= opcode_rb_operand_i;
            pkt_sc_success_q   <= current_input_sc_success_w;
            pkt_pipe1_q        <= opcode_pipe1_i;
            pkt_req_active_q   <= current_input_req_active_w;
            pkt_unaligned_q    <= current_input_unaligned_w;
            pkt_sc_fail_q      <= current_input_sc_fail_w;
        end
        else
        begin
            pkt_req_active_q   <= 1'b0;
            pkt_unaligned_q    <= 1'b0;
            pkt_sc_fail_q      <= 1'b0;
        end
    end
    else if (current_input_skiddable_w && !skid_valid_q && local_req_launch_w)
    begin
        skid_valid_q       <= 1'b1;
        skid_opcode_q      <= opcode_opcode_i;
        skid_ra_operand_q  <= opcode_ra_operand_i;
        skid_rb_operand_q  <= opcode_rb_operand_i;
        skid_sc_success_q  <= current_input_sc_success_w;
        skid_pipe1_q       <= opcode_pipe1_i;
        skid_req_active_q  <= current_input_req_active_w;
        skid_unaligned_q   <= current_input_unaligned_w;
        skid_sc_fail_q     <= current_input_sc_fail_w;
    end
end

wire [31:0] mem_issue_addr_w = mem_issue_valid_q ? mem_issue_addr_q : req_head_addr_w;
wire [31:0] mem_issue_vaddr_w = mem_issue_valid_q ? mem_issue_vaddr_q : req_head_vaddr_w;
wire [31:0] mem_issue_data_w = mem_issue_valid_q ? mem_issue_data_q : req_head_data_w;
wire        mem_issue_rd_w = mem_issue_valid_q ? mem_issue_rd_q : req_head_rd_w;
wire [ 3:0] mem_issue_wr_w = mem_issue_valid_q ? mem_issue_wr_q : req_head_wr_w;
wire        mem_issue_cacheable_w = mem_issue_valid_q ? mem_issue_cacheable_q : req_head_cacheable_calc_w;
wire        mem_issue_invalidate_w = mem_issue_valid_q ? mem_issue_invalidate_q : req_head_invalidate_w;
wire        mem_issue_writeback_w = mem_issue_valid_q ? mem_issue_writeback_q : req_head_writeback_w;
wire        mem_issue_flush_w = mem_issue_valid_q ? mem_issue_flush_q : req_head_flush_w;
wire        mem_issue_load_w = mem_issue_valid_q ? mem_issue_load_q : req_head_load_w;
wire        mem_issue_byte_w = mem_issue_valid_q ? mem_issue_byte_q : req_head_byte_w;
wire        mem_issue_half_w = mem_issue_valid_q ? mem_issue_half_q : req_head_half_w;
wire        mem_issue_signed_w = mem_issue_valid_q ? mem_issue_signed_q : req_head_signed_w;
wire        mem_issue_ll_w = mem_issue_valid_q ? mem_issue_ll_q : req_head_ll_w;
wire        mem_issue_sc_w = mem_issue_valid_q ? mem_issue_sc_q : req_head_sc_w;
wire        mem_issue_sc_success_w = mem_issue_valid_q ? mem_issue_sc_success_q : req_head_sc_success_w;
wire [ 7:0] mem_issue_load_valid_w = mem_issue_valid_q ? mem_issue_load_valid_q : req_head_load_valid_w;
wire [ 7:0] mem_issue_store_valid_w = mem_issue_valid_q ? mem_issue_store_valid_q : req_head_store_valid_w;
wire        mem_issue_pipe1_w = mem_issue_valid_q ? mem_issue_pipe1_q : req_head_pipe1_w;

assign mem_addr_o       = mem_issue_vaddr_w;
assign mem_data_wr_o    = mem_issue_data_w;
assign mem_rd_o         = mem_issue_valid_w ? mem_issue_rd_w : 1'b0;
assign mem_wr_o         = mem_issue_valid_w ? mem_issue_wr_w : 4'b0;
assign mem_size_o       = mem_issue_byte_w ? 2'b00 :
                          mem_issue_half_w ? 2'b01 :
                                              2'b10;
assign mem_cacheable_o  = mem_issue_cacheable_w;
assign mem_req_tag_o    = 11'b0;
assign mem_invalidate_o = mem_issue_valid_w ? mem_issue_invalidate_w : 1'b0;
assign mem_writeback_o  = mem_issue_valid_w ? mem_issue_writeback_w : 1'b0;
assign mem_flush_o      = mem_issue_valid_w ? mem_issue_flush_w : 1'b0;

// Stall upstream only on LSU-local backpressure. Once a request is accepted,
// the pipe_ctrl E2 mem_complete stall owns unresolved load/store ordering; that
// keeps current-cycle D-cache/MMU ack out of the LSU-to-issue release path.
assign stall_o          = pkt_stall_w || skid_valid_q ||
                          (mem_issue_valid_q ||
                           (req_head_valid_issue_w && !mem_accept_q));
assign skid_ready_o     = (!pkt_valid_q || skid_ready_packet_drain_w) && !skid_valid_q &&
                          !mem_issue_valid_q && req_slot_ready_w;

    reg         resp_dummy_q;

    reg         resp_mem_load_q;
    reg  [31:0] resp_mem_addr_q;
    reg         resp_mem_byte_q;
    reg         resp_mem_half_q;
    reg         resp_mem_signed_q;
    reg         resp_mem_ll_q;
    reg         resp_mem_sc_q;
    reg         resp_mem_sc_success_q;
    reg  [31:0] resp_mem_paddr_q;
    reg  [31:0] resp_mem_store_data_q;
    reg  [ 7:0] resp_mem_load_valid_q;
    reg  [ 7:0] resp_mem_store_valid_q;
    reg         resp_mem_pipe1_q;

    reg         resp_dummy_load_q;
    reg  [31:0] resp_dummy_addr_q;
    reg         resp_dummy_byte_q;
    reg         resp_dummy_half_q;
    reg         resp_dummy_signed_q;
    reg         resp_dummy_ll_q;
    reg         resp_dummy_sc_q;
    reg         resp_dummy_sc_success_q;
    reg  [31:0] resp_dummy_paddr_q;
    reg  [31:0] resp_dummy_store_data_q;
    reg  [ 7:0] resp_dummy_load_valid_q;
    reg  [ 7:0] resp_dummy_store_valid_q;
    reg         resp_dummy_pipe1_q;

    wire        resp_push_w = mem_issue_accept_w || local_dummy_complete_w;
    wire        resp_pop_w  = mem_ack_i || mem_unaligned_e2_q ||
                              mem_sc_fail_e2_q || mem_preld_e2_q ||
                              mem_cacop_index_e2_q;
    wire        resp_push_dummy_w = !mem_issue_accept_w && local_dummy_complete_w;
    wire        resp_mem_track_w = mem_issue_accept_w;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        resp_dummy_q <= 1'b0;

        resp_mem_load_q <= 1'b0;
        resp_mem_addr_q <= 32'b0;
        resp_mem_byte_q <= 1'b0;
        resp_mem_half_q <= 1'b0;
        resp_mem_signed_q <= 1'b0;
        resp_mem_ll_q <= 1'b0;
        resp_mem_sc_q <= 1'b0;
        resp_mem_sc_success_q <= 1'b0;
        resp_mem_paddr_q <= 32'b0;
        resp_mem_store_data_q <= 32'b0;
        resp_mem_load_valid_q <= 8'b0;
        resp_mem_store_valid_q <= 8'b0;
        resp_mem_pipe1_q <= 1'b0;

        resp_dummy_load_q <= 1'b0;
        resp_dummy_addr_q <= 32'b0;
        resp_dummy_byte_q <= 1'b0;
        resp_dummy_half_q <= 1'b0;
        resp_dummy_signed_q <= 1'b0;
        resp_dummy_ll_q <= 1'b0;
        resp_dummy_sc_q <= 1'b0;
        resp_dummy_sc_success_q <= 1'b0;
        resp_dummy_paddr_q <= 32'b0;
        resp_dummy_store_data_q <= 32'b0;
        resp_dummy_load_valid_q <= 8'b0;
        resp_dummy_store_valid_q <= 8'b0;
        resp_dummy_pipe1_q <= 1'b0;
    end
    else
    begin
        if (resp_mem_track_w)
        begin
            resp_mem_load_q        <= mem_issue_load_w;
            resp_mem_addr_q        <= mem_issue_vaddr_w;
            resp_mem_byte_q        <= mem_issue_byte_w;
            resp_mem_half_q        <= mem_issue_half_w;
            resp_mem_signed_q      <= mem_issue_signed_w;
            resp_mem_ll_q          <= mem_issue_ll_w;
            resp_mem_sc_q          <= mem_issue_sc_w;
            resp_mem_sc_success_q  <= mem_issue_sc_success_w;
            resp_mem_paddr_q       <= {mem_paddr_i[31:2], mem_issue_vaddr_w[1:0]};
            resp_mem_store_data_q  <= mem_issue_data_w;
            resp_mem_load_valid_q  <= mem_issue_load_valid_w;
            resp_mem_store_valid_q <= mem_issue_store_valid_w;
            resp_mem_pipe1_q       <= mem_issue_pipe1_w;
        end

        if (local_dummy_complete_w)
        begin
            resp_dummy_load_q        <= input_load_w;
            resp_dummy_addr_q        <= mem_addr_r;
            resp_dummy_byte_q        <= req_lb_w | req_sb_w;
            resp_dummy_half_q        <= req_lh_w | req_sh_w;
            resp_dummy_signed_q      <= load_signed_inst_w;
            resp_dummy_ll_q          <= input_ll_w;
            resp_dummy_sc_q          <= input_sc_w;
            resp_dummy_sc_success_q  <= input_sc_success_w;
            resp_dummy_paddr_q       <= 32'b0;
            resp_dummy_store_data_q  <= mem_data_r;
            resp_dummy_load_valid_q  <= input_load_valid_w;
            resp_dummy_store_valid_q <= input_store_valid_w;
            resp_dummy_pipe1_q       <= active_pipe1_w;
        end

        case ({resp_push_w, resp_pop_w})
        2'b10:
        begin
            resp_dummy_q <= resp_push_dummy_w;
        end
        2'b01:
        begin
            resp_dummy_q <= 1'b0;
        end
        2'b11:
        begin
            resp_dummy_q <= resp_push_dummy_w;
        end
        default:
            ;
        endcase
    end

    wire        resp_load_w        = resp_dummy_q ? resp_dummy_load_q : resp_mem_load_q;
    wire [31:0] resp_addr_w        = resp_dummy_q ? resp_dummy_addr_q : resp_mem_addr_q;
    wire        resp_byte_w        = resp_dummy_q ? resp_dummy_byte_q : resp_mem_byte_q;
    wire        resp_half_w        = resp_dummy_q ? resp_dummy_half_q : resp_mem_half_q;
    wire        resp_signed_w      = resp_dummy_q ? resp_dummy_signed_q : resp_mem_signed_q;
    wire        resp_ll_w          = resp_dummy_q ? resp_dummy_ll_q : resp_mem_ll_q;
    wire        resp_sc_w          = resp_dummy_q ? resp_dummy_sc_q : resp_mem_sc_q;
    wire        resp_sc_success_w  = resp_dummy_q ? resp_dummy_sc_success_q :
                                                    resp_mem_sc_success_q;
    wire [31:0] resp_paddr_w       = resp_dummy_q ? resp_dummy_paddr_q : resp_mem_paddr_q;
    wire [31:0] resp_store_data_w  = resp_dummy_q ? resp_dummy_store_data_q :
                                                    resp_mem_store_data_q;
    wire [ 7:0] resp_load_valid_w  = resp_dummy_q ? resp_dummy_load_valid_q :
                                                    resp_mem_load_valid_q;
    wire [ 7:0] resp_store_valid_w = resp_dummy_q ? resp_dummy_store_valid_q :
                                                    resp_mem_store_valid_q;
    wire        resp_pipe1_w       = resp_dummy_q ? resp_dummy_pipe1_q : resp_mem_pipe1_q;

//-----------------------------------------------------------------
// Load response
//-----------------------------------------------------------------
reg [1:0]  addr_lsb_r;
reg        load_byte_r;
reg        load_half_r;
reg        load_signed_r;
reg [31:0] load_result_r;
reg [31:0] wb_result_r;

always @ *
begin
    // Tag associated with load
    addr_lsb_r    = resp_addr_w[1:0];
    load_byte_r   = resp_byte_w;
    load_half_r   = resp_half_w;
    load_signed_r = resp_signed_w;

    // Keep byte/half alignment and sign extension on a dedicated load-data
    // cone.  Exception, SC and response-valid control only select this
    // already-formed value below.
    load_result_r = mem_data_rd_i;
    if (load_byte_r)
    begin
        case (addr_lsb_r[1:0])
        2'h3: load_result_r = {24'b0, mem_data_rd_i[31:24]};
        2'h2: load_result_r = {24'b0, mem_data_rd_i[23:16]};
        2'h1: load_result_r = {24'b0, mem_data_rd_i[15:8]};
        2'h0: load_result_r = {24'b0, mem_data_rd_i[7:0]};
        endcase

        if (load_signed_r && load_result_r[7])
            load_result_r = {24'hFFFFFF, load_result_r[7:0]};
    end
    else if (load_half_r)
    begin
        if (addr_lsb_r[1])
            load_result_r = {16'b0, mem_data_rd_i[31:16]};
        else
            load_result_r = {16'b0, mem_data_rd_i[15:0]};

        if (load_signed_r && load_result_r[15])
            load_result_r = {16'hFFFF, load_result_r[15:0]};
    end

    // writeback_valid_o qualifies this bus; keep hit/ack out of the data mux.
    wb_result_r = 32'b0;
    if (mem_error_i || mem_unaligned_e2_q)
        wb_result_r = resp_addr_w;
    else if (resp_sc_w)
        wb_result_r = {31'b0, resp_sc_success_w};
    else if (resp_load_w)
        wb_result_r = load_result_r;
end

assign writeback_valid_o    = mem_ack_i | mem_unaligned_e2_q |
                              mem_sc_fail_e2_q | mem_preld_e2_q |
                              mem_cacop_index_e2_q;
assign writeback_value_o    = wb_result_r;
assign writeback_pipe1_o    = resp_pipe1_w;

wire fault_load_align_w     = mem_unaligned_e2_q & resp_load_w;
wire fault_store_align_w    = mem_unaligned_e2_q & ~resp_load_w;
wire fault_load_bus_w       = mem_error_i &&  resp_load_w;
wire fault_store_bus_w      = mem_error_i && ~resp_load_w;
wire fault_load_page_w      = mem_error_i && mem_load_fault_i;
wire fault_store_page_w     = mem_error_i && mem_store_fault_i;


wire [`EXCEPTION_W-1:0] writeback_exception_w =
                                       fault_load_align_w  ? `EXCEPTION_MISALIGNED_LOAD:
                                       fault_store_align_w ? `EXCEPTION_MISALIGNED_STORE:
                                       fault_load_page_w   ? `EXCEPTION_PAGE_FAULT_LOAD:
                                       fault_store_page_w  ? `EXCEPTION_PAGE_FAULT_STORE:
                                       fault_load_bus_w    ? `EXCEPTION_FAULT_LOAD:
                                       fault_store_bus_w   ? `EXCEPTION_FAULT_STORE:
                                       `EXCEPTION_W'b0;

assign writeback_exception_o = writeback_exception_w;
assign writeback_exception_ecode_o =
                                    (fault_load_page_w || fault_store_page_w) ? mem_fault_ecode_i :
                                    `EXCEPTION_W'b0;
assign llbit_set_o           = writeback_valid_o && (writeback_exception_w == `EXCEPTION_W'b0) && (resp_ll_w || resp_sc_w);
assign llbit_value_o         = resp_ll_w;

reg [ 7:0] diff_load_valid_q;
reg [31:0] diff_load_paddr_q;
reg [31:0] diff_load_vaddr_q;
reg        diff_load_index_q;
reg [ 7:0] diff_store_valid_q;
reg [31:0] diff_store_paddr_q;
reg [31:0] diff_store_vaddr_q;
reg [31:0] diff_store_data_q;
reg        diff_store_index_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    diff_load_valid_q  <= 8'b0;
    diff_load_paddr_q  <= 32'b0;
    diff_load_vaddr_q  <= 32'b0;
    diff_load_index_q  <= 1'b0;
    diff_store_valid_q <= 8'b0;
    diff_store_paddr_q <= 32'b0;
    diff_store_vaddr_q <= 32'b0;
    diff_store_data_q  <= 32'b0;
    diff_store_index_q <= 1'b0;
end
else
begin
    diff_load_valid_q  <= 8'b0;
    diff_load_paddr_q  <= 32'b0;
    diff_load_vaddr_q  <= 32'b0;
    diff_load_index_q  <= 1'b0;
    diff_store_valid_q <= 8'b0;
    diff_store_paddr_q <= 32'b0;
    diff_store_vaddr_q <= 32'b0;
    diff_store_data_q  <= 32'b0;
    diff_store_index_q <= 1'b0;

    if (writeback_valid_o && (writeback_exception_w == `EXCEPTION_W'b0))
    begin
        diff_load_valid_q  <= resp_load_valid_w;
        diff_load_paddr_q  <= resp_paddr_w;
        diff_load_vaddr_q  <= resp_addr_w;
        diff_load_index_q  <= resp_pipe1_w;
        diff_store_valid_q <= resp_store_valid_w;
        diff_store_paddr_q <= resp_paddr_w;
        diff_store_vaddr_q <= resp_addr_w;
        diff_store_data_q  <= resp_store_data_w;
        diff_store_index_q <= resp_pipe1_w;
    end
end

assign diff_load_valid_o  = diff_load_valid_q;
assign diff_load_paddr_o  = diff_load_paddr_q;
assign diff_load_vaddr_o  = diff_load_vaddr_q;
assign diff_load_index_o  = diff_load_index_q;
assign diff_store_valid_o = diff_store_valid_q;
assign diff_store_paddr_o = diff_store_paddr_q;
assign diff_store_vaddr_o = diff_store_vaddr_q;
assign diff_store_data_o  = diff_store_data_q;
assign diff_store_index_o = diff_store_index_q;

endmodule 
