//-----------------------------------------------------------------
//                         Biloong CPU
// Top level matching the biRISC-V core + I-cache + D-cache split.
//-----------------------------------------------------------------

module biloong_top
#(
     parameter CORE_ID          = 0
    ,parameter ICACHE_AXI_ID    = 0
    ,parameter DCACHE_AXI_ID    = 1
    ,parameter SUPPORT_BRANCH_PREDICTION = 1
    ,parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_SUPER    = 0
    ,parameter SUPPORT_MMU      = 0
    ,parameter SUPPORT_DUAL_ISSUE = 1
    ,parameter SUPPORT_LOAD_BYPASS = 0
    ,parameter SUPPORT_MUL_BYPASS = 1
    ,parameter SUPPORT_REGFILE_XILINX = 0
    ,parameter SUPPORT_SLOT1_ALU = 1
    ,parameter SUPPORT_SLOT1_BRANCH = 1
    ,parameter SUPPORT_SLOT1_MUL = 1
    ,parameter SUPPORT_SLOT1_LOAD = 1
    ,parameter SUPPORT_SLOT1_STORE = 1
    ,parameter EXTRA_DECODE_STAGE = 0
    ,parameter MEM_CACHE_ADDR_MIN = 32'h80000000
    ,parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff
    ,parameter NUM_BTB_ENTRIES  = 32
    ,parameter NUM_BTB_ENTRIES_W = 5
    ,parameter NUM_BHT_ENTRIES  = 512
    ,parameter NUM_BHT_ENTRIES_W = 9
    ,parameter RAS_ENABLE       = 1
    ,parameter GSHARE_ENABLE    = 0
    ,parameter BHT_ENABLE       = 1
    ,parameter NUM_RAS_ENTRIES  = 8
    ,parameter NUM_RAS_ENTRIES_W = 3
)
(
     input           clk_i
    ,input           rst_i
    ,input           axi_i_awready_i
    ,input           axi_i_wready_i
    ,input           axi_i_bvalid_i
    ,input  [  1:0]  axi_i_bresp_i
    ,input  [  3:0]  axi_i_bid_i
    ,input           axi_i_arready_i
    ,input           axi_i_rvalid_i
    ,input  [ 31:0]  axi_i_rdata_i
    ,input  [  1:0]  axi_i_rresp_i
    ,input  [  3:0]  axi_i_rid_i
    ,input           axi_i_rlast_i
    ,input           axi_d_awready_i
    ,input           axi_d_wready_i
    ,input           axi_d_bvalid_i
    ,input  [  1:0]  axi_d_bresp_i
    ,input  [  3:0]  axi_d_bid_i
    ,input           axi_d_arready_i
    ,input           axi_d_rvalid_i
    ,input  [ 31:0]  axi_d_rdata_i
    ,input  [  1:0]  axi_d_rresp_i
    ,input  [  3:0]  axi_d_rid_i
    ,input           axi_d_rlast_i
    ,input  [  7:0]  intr_i
    ,input  [ 31:0]  reset_vector_i

    ,output          axi_i_awvalid_o
    ,output [ 31:0]  axi_i_awaddr_o
    ,output [  3:0]  axi_i_awid_o
    ,output [  7:0]  axi_i_awlen_o
    ,output [  2:0]  axi_i_awsize_o
    ,output [  1:0]  axi_i_awburst_o
    ,output          axi_i_wvalid_o
    ,output [ 31:0]  axi_i_wdata_o
    ,output [  3:0]  axi_i_wstrb_o
    ,output          axi_i_wlast_o
    ,output          axi_i_bready_o
    ,output          axi_i_arvalid_o
    ,output [ 31:0]  axi_i_araddr_o
    ,output [  3:0]  axi_i_arid_o
    ,output [  7:0]  axi_i_arlen_o
    ,output [  2:0]  axi_i_arsize_o
    ,output [  1:0]  axi_i_arburst_o
    ,output          axi_i_rready_o
    ,output          axi_d_awvalid_o
    ,output [ 31:0]  axi_d_awaddr_o
    ,output [  3:0]  axi_d_awid_o
    ,output [  7:0]  axi_d_awlen_o
    ,output [  2:0]  axi_d_awsize_o
    ,output [  1:0]  axi_d_awburst_o
    ,output          axi_d_wvalid_o
    ,output [ 31:0]  axi_d_wdata_o
    ,output [  3:0]  axi_d_wstrb_o
    ,output          axi_d_wlast_o
    ,output          axi_d_bready_o
    ,output          axi_d_arvalid_o
    ,output [ 31:0]  axi_d_araddr_o
    ,output [  3:0]  axi_d_arid_o
    ,output [  7:0]  axi_d_arlen_o
    ,output [  2:0]  axi_d_arsize_o
    ,output [  1:0]  axi_d_arburst_o
    ,output          axi_d_rready_o
    ,output          axi_d_wr_pending0_o
    ,output [ 31:0]  axi_d_wr_pending0_addr_o
    ,output          axi_d_wr_pending1_o
    ,output [ 31:0]  axi_d_wr_pending1_addr_o
    ,output [  7:0]  diff_load_valid_o
    ,output [ 31:0]  diff_load_paddr_o
    ,output [ 31:0]  diff_load_vaddr_o
    ,output          diff_load_index_o
    ,output [  7:0]  diff_store_valid_o
    ,output [ 31:0]  diff_store_paddr_o
    ,output [ 31:0]  diff_store_vaddr_o
    ,output [ 31:0]  diff_store_data_o
    ,output          diff_store_index_o
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
    ,output          bpu_perf_lookup_valid_o
    ,output          bpu_perf_lookup_taken_o
    ,output          bpu_perf_lookup_upper_o
    ,output          bpu_perf_update_valid_o
`endif
`ifdef PERF_MONI
    ,output [  1:0]  perf_ff_count_o
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
    ,output          perf_dc_miss_busy_o
`endif
`ifdef PERF_IC
    ,output          perf_ic_access_o
    ,output          perf_ic_hit_o
    ,output          perf_ic_miss_o
    ,output          perf_ic_refill_o
`endif
`ifdef PERF_DC
    ,output          perf_dc_access_o
    ,output          perf_dc_read_o
    ,output          perf_dc_write_o
    ,output          perf_dc_hit_o
    ,output          perf_dc_miss_o
    ,output          perf_dc_refill_o
    ,output          perf_dc_evict_o
`endif
);

wire           icache_valid_w;
wire           icache_flush_w;
wire           dcache_flush_w;
wire           dcache_invalidate_w;
wire           dcache_ack_w;
wire  [ 10:0]  dcache_resp_tag_w;
wire  [ 63:0]  icache_inst_w;
wire  [ 31:0]  cpu_id_w = CORE_ID;
wire           dcache_rd_w;
wire  [ 31:0]  dcache_addr_w;
wire  [ 31:0]  dcache_lookup_addr_w;
wire  [  1:0]  dcache_size_w;
wire           dcache_accept_w;
wire           dcache_accept_raw_w;
wire           icache_invalidate_w;
wire           dcache_writeback_w;
wire  [ 10:0]  dcache_req_tag_w;
wire           dcache_cacheable_w;
wire           icache_error_w;
wire  [ 31:0]  dcache_data_rd_w;
wire           icache_accept_w;
wire  [  3:0]  dcache_wr_w;
wire  [ 31:0]  icache_pc_w;
wire           icache_lookup_rd_w;
wire  [ 31:0]  icache_lookup_pc_w;
wire           icache_rd_w;
wire           dcache_error_w;
wire  [ 31:0]  dcache_data_wr_w;
wire           dcache_core_req_w;
wire  [ 31:0]  dcache_req_addr_w;
wire  [ 31:0]  dcache_req_lookup_addr_w;
wire  [  1:0]  dcache_req_size_w;
wire  [ 31:0]  dcache_req_data_wr_w;
wire           dcache_req_rd_w;
wire  [  3:0]  dcache_req_wr_w;
wire           dcache_req_cacheable_w;
wire  [ 10:0]  dcache_req_tag_to_cache_w;
wire           dcache_req_invalidate_w;
wire           dcache_req_writeback_w;
wire           dcache_req_flush_w;

reg            dcache_skid_valid_q;
reg  [ 31:0]  dcache_skid_addr_q;
reg  [ 31:0]  dcache_skid_lookup_addr_q;
reg  [  1:0]  dcache_skid_size_q;
reg  [ 31:0]  dcache_skid_data_wr_q;
reg            dcache_skid_rd_q;
reg  [  3:0]  dcache_skid_wr_q;
reg            dcache_skid_cacheable_q;
reg  [ 10:0]  dcache_skid_req_tag_q;
reg            dcache_skid_invalidate_q;
reg            dcache_skid_writeback_q;
reg            dcache_skid_flush_q;

assign dcache_core_req_w = dcache_rd_w || (dcache_wr_w != 4'b0) ||
                           dcache_invalidate_w || dcache_writeback_w ||
                           dcache_flush_w;

assign dcache_accept_w = !dcache_skid_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    dcache_skid_valid_q       <= 1'b0;
    dcache_skid_addr_q        <= 32'b0;
    dcache_skid_lookup_addr_q <= 32'b0;
    dcache_skid_size_q        <= 2'b10;
    dcache_skid_data_wr_q     <= 32'b0;
    dcache_skid_rd_q          <= 1'b0;
    dcache_skid_wr_q          <= 4'b0;
    dcache_skid_cacheable_q   <= 1'b0;
    dcache_skid_req_tag_q     <= 11'b0;
    dcache_skid_invalidate_q  <= 1'b0;
    dcache_skid_writeback_q   <= 1'b0;
    dcache_skid_flush_q       <= 1'b0;
end
else
begin
    if (dcache_skid_valid_q && dcache_accept_raw_w)
        dcache_skid_valid_q <= 1'b0;

    if (!dcache_skid_valid_q && dcache_core_req_w && !dcache_accept_raw_w)
    begin
        dcache_skid_valid_q       <= 1'b1;
        dcache_skid_addr_q        <= dcache_addr_w;
        dcache_skid_lookup_addr_q <= dcache_lookup_addr_w;
        dcache_skid_size_q        <= dcache_size_w;
        dcache_skid_data_wr_q     <= dcache_data_wr_w;
        dcache_skid_rd_q          <= dcache_rd_w;
        dcache_skid_wr_q          <= dcache_wr_w;
        dcache_skid_cacheable_q   <= dcache_cacheable_w;
        dcache_skid_req_tag_q     <= dcache_req_tag_w;
        dcache_skid_invalidate_q  <= dcache_invalidate_w;
        dcache_skid_writeback_q   <= dcache_writeback_w;
        dcache_skid_flush_q       <= dcache_flush_w;
    end
end

assign dcache_req_addr_w         = dcache_skid_valid_q ? dcache_skid_addr_q        : dcache_addr_w;
assign dcache_req_lookup_addr_w  = dcache_skid_valid_q ? dcache_skid_lookup_addr_q : dcache_lookup_addr_w;
assign dcache_req_size_w         = dcache_skid_valid_q ? dcache_skid_size_q        : dcache_size_w;
assign dcache_req_data_wr_w      = dcache_skid_valid_q ? dcache_skid_data_wr_q     : dcache_data_wr_w;
assign dcache_req_rd_w           = dcache_skid_valid_q ? dcache_skid_rd_q          : dcache_rd_w;
assign dcache_req_wr_w           = dcache_skid_valid_q ? dcache_skid_wr_q          : dcache_wr_w;
assign dcache_req_cacheable_w    = dcache_skid_valid_q ? dcache_skid_cacheable_q   : dcache_cacheable_w;
assign dcache_req_tag_to_cache_w = dcache_skid_valid_q ? dcache_skid_req_tag_q     : dcache_req_tag_w;
assign dcache_req_invalidate_w   = dcache_skid_valid_q ? dcache_skid_invalidate_q  : dcache_invalidate_w;
assign dcache_req_writeback_w    = dcache_skid_valid_q ? dcache_skid_writeback_q   : dcache_writeback_w;
assign dcache_req_flush_w        = dcache_skid_valid_q ? dcache_skid_flush_q       : dcache_flush_w;

dcache
#(.AXI_ID(DCACHE_AXI_ID))
u_dcache
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(dcache_req_addr_w)
    ,.mem_lookup_addr_i(dcache_req_lookup_addr_w)
    ,.mem_data_wr_i(dcache_req_data_wr_w)
    ,.mem_rd_i(dcache_req_rd_w)
    ,.mem_wr_i(dcache_req_wr_w)
    ,.mem_size_i(dcache_req_size_w)
    ,.mem_cacheable_i(dcache_req_cacheable_w)
    ,.mem_req_tag_i(dcache_req_tag_to_cache_w)
    ,.mem_invalidate_i(dcache_req_invalidate_w)
    ,.mem_writeback_i(dcache_req_writeback_w)
    ,.mem_flush_i(dcache_req_flush_w)
    ,.axi_awready_i(axi_d_awready_i)
    ,.axi_wready_i(axi_d_wready_i)
    ,.axi_bvalid_i(axi_d_bvalid_i)
    ,.axi_bresp_i(axi_d_bresp_i)
    ,.axi_bid_i(axi_d_bid_i)
    ,.axi_arready_i(axi_d_arready_i)
    ,.axi_rvalid_i(axi_d_rvalid_i)
    ,.axi_rdata_i(axi_d_rdata_i)
    ,.axi_rresp_i(axi_d_rresp_i)
    ,.axi_rid_i(axi_d_rid_i)
    ,.axi_rlast_i(axi_d_rlast_i)
    ,.mem_data_rd_o(dcache_data_rd_w)
    ,.mem_accept_o(dcache_accept_raw_w)
    ,.mem_ack_o(dcache_ack_w)
    ,.mem_error_o(dcache_error_w)
    ,.mem_resp_tag_o(dcache_resp_tag_w)
    ,.axi_awvalid_o(axi_d_awvalid_o)
    ,.axi_awaddr_o(axi_d_awaddr_o)
    ,.axi_awid_o(axi_d_awid_o)
    ,.axi_awlen_o(axi_d_awlen_o)
    ,.axi_awsize_o(axi_d_awsize_o)
    ,.axi_awburst_o(axi_d_awburst_o)
    ,.axi_wvalid_o(axi_d_wvalid_o)
    ,.axi_wdata_o(axi_d_wdata_o)
    ,.axi_wstrb_o(axi_d_wstrb_o)
    ,.axi_wlast_o(axi_d_wlast_o)
    ,.axi_bready_o(axi_d_bready_o)
    ,.axi_arvalid_o(axi_d_arvalid_o)
    ,.axi_araddr_o(axi_d_araddr_o)
    ,.axi_arid_o(axi_d_arid_o)
    ,.axi_arlen_o(axi_d_arlen_o)
    ,.axi_arsize_o(axi_d_arsize_o)
    ,.axi_arburst_o(axi_d_arburst_o)
    ,.axi_rready_o(axi_d_rready_o)
    ,.axi_wr_pending0_o(axi_d_wr_pending0_o)
    ,.axi_wr_pending0_addr_o(axi_d_wr_pending0_addr_o)
    ,.axi_wr_pending1_o(axi_d_wr_pending1_o)
    ,.axi_wr_pending1_addr_o(axi_d_wr_pending1_addr_o)
`ifdef PERF_DC
    ,.perf_access_o(perf_dc_access_o)
    ,.perf_read_o(perf_dc_read_o)
    ,.perf_write_o(perf_dc_write_o)
    ,.perf_hit_o(perf_dc_hit_o)
    ,.perf_miss_o(perf_dc_miss_o)
    ,.perf_refill_o(perf_dc_refill_o)
    ,.perf_evict_o(perf_dc_evict_o)
`endif
`ifdef PERF_MONI
    ,.perf_miss_busy_o(perf_dc_miss_busy_o)
`endif
);

biloong_core
#(
     .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN)
    ,.MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
    ,.SUPPORT_BRANCH_PREDICTION(SUPPORT_BRANCH_PREDICTION)
    ,.SUPPORT_MULDIV(SUPPORT_MULDIV)
    ,.SUPPORT_SUPER(SUPPORT_SUPER)
    ,.SUPPORT_MMU(SUPPORT_MMU)
    ,.SUPPORT_DUAL_ISSUE(SUPPORT_DUAL_ISSUE)
    ,.SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
    ,.SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX)
    ,.SUPPORT_SLOT1_ALU(SUPPORT_SLOT1_ALU)
    ,.SUPPORT_SLOT1_BRANCH(SUPPORT_SLOT1_BRANCH)
    ,.SUPPORT_SLOT1_MUL(SUPPORT_SLOT1_MUL)
    ,.SUPPORT_SLOT1_LOAD(SUPPORT_SLOT1_LOAD)
    ,.SUPPORT_SLOT1_STORE(SUPPORT_SLOT1_STORE)
    ,.EXTRA_DECODE_STAGE(EXTRA_DECODE_STAGE)
    ,.NUM_BTB_ENTRIES(NUM_BTB_ENTRIES)
    ,.NUM_BTB_ENTRIES_W(NUM_BTB_ENTRIES_W)
    ,.NUM_BHT_ENTRIES(NUM_BHT_ENTRIES)
    ,.NUM_BHT_ENTRIES_W(NUM_BHT_ENTRIES_W)
    ,.RAS_ENABLE(RAS_ENABLE)
    ,.GSHARE_ENABLE(GSHARE_ENABLE)
    ,.BHT_ENABLE(BHT_ENABLE)
    ,.NUM_RAS_ENTRIES(NUM_RAS_ENTRIES)
    ,.NUM_RAS_ENTRIES_W(NUM_RAS_ENTRIES_W)
)
u_core
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_d_data_rd_i(dcache_data_rd_w)
    ,.mem_d_accept_i(dcache_accept_w)
    ,.mem_d_ack_i(dcache_ack_w)
    ,.mem_d_error_i(dcache_error_w)
    ,.mem_d_resp_tag_i(dcache_resp_tag_w)
    ,.mem_i_accept_i(icache_accept_w)
    ,.mem_i_valid_i(icache_valid_w)
    ,.mem_i_error_i(icache_error_w)
    ,.mem_i_inst_i(icache_inst_w)
    ,.intr_i(intr_i)
    ,.reset_vector_i(reset_vector_i)
    ,.cpu_id_i(cpu_id_w)
    ,.mem_d_addr_o(dcache_addr_w)
    ,.mem_d_lookup_addr_o(dcache_lookup_addr_w)
    ,.mem_d_data_wr_o(dcache_data_wr_w)
    ,.mem_d_rd_o(dcache_rd_w)
    ,.mem_d_wr_o(dcache_wr_w)
    ,.mem_d_size_o(dcache_size_w)
    ,.mem_d_cacheable_o(dcache_cacheable_w)
    ,.mem_d_req_tag_o(dcache_req_tag_w)
    ,.mem_d_invalidate_o(dcache_invalidate_w)
    ,.mem_d_writeback_o(dcache_writeback_w)
    ,.mem_d_flush_o(dcache_flush_w)
    ,.mem_i_rd_o(icache_rd_w)
    ,.mem_i_flush_o(icache_flush_w)
    ,.mem_i_invalidate_o(icache_invalidate_w)
    ,.mem_i_pc_o(icache_pc_w)
    ,.mem_i_lookup_rd_o(icache_lookup_rd_w)
    ,.mem_i_lookup_pc_o(icache_lookup_pc_w)
    ,.diff_load_valid_o(diff_load_valid_o)
    ,.diff_load_paddr_o(diff_load_paddr_o)
    ,.diff_load_vaddr_o(diff_load_vaddr_o)
    ,.diff_load_index_o(diff_load_index_o)
    ,.diff_store_valid_o(diff_store_valid_o)
    ,.diff_store_paddr_o(diff_store_paddr_o)
    ,.diff_store_vaddr_o(diff_store_vaddr_o)
    ,.diff_store_data_o(diff_store_data_o)
    ,.diff_store_index_o(diff_store_index_o)
`ifdef BPU_PERF
    ,.bpu_perf_valid_o(bpu_perf_valid_o)
    ,.bpu_perf_is_branch_o(bpu_perf_is_branch_o)
    ,.bpu_perf_is_jump_o(bpu_perf_is_jump_o)
    ,.bpu_perf_is_ret_jirl_o(bpu_perf_is_ret_jirl_o)
    ,.bpu_perf_is_indirect_jirl_o(bpu_perf_is_indirect_jirl_o)
    ,.bpu_perf_pc_o(bpu_perf_pc_o)
    ,.bpu_perf_pred_taken_o(bpu_perf_pred_taken_o)
    ,.bpu_perf_actual_taken_o(bpu_perf_actual_taken_o)
    ,.bpu_perf_correct_o(bpu_perf_correct_o)
    ,.bpu_perf_direction_miss_o(bpu_perf_direction_miss_o)
    ,.bpu_perf_target_miss_o(bpu_perf_target_miss_o)
    ,.bpu_perf_exu_flush_o(bpu_perf_exu_flush_o)
    ,.bpu_perf_lookup_valid_o(bpu_perf_lookup_valid_o)
    ,.bpu_perf_lookup_taken_o(bpu_perf_lookup_taken_o)
    ,.bpu_perf_lookup_upper_o(bpu_perf_lookup_upper_o)
    ,.bpu_perf_update_valid_o(bpu_perf_update_valid_o)
`endif
`ifdef PERF_MONI
    ,.perf_ff_count_o(perf_ff_count_o)
    ,.perf_iq_count_o(perf_iq_count_o)
    ,.perf_stall_div_o(perf_stall_div_o)
    ,.perf_stall_mem_o(perf_stall_mem_o)
    ,.perf_stall_mul_o(perf_stall_mul_o)
    ,.perf_iq_empty_o(perf_iq_empty_o)
    ,.perf_lsu_stall_o(perf_lsu_stall_o)
    ,.perf_single_issue_o(perf_single_issue_o)
    ,.perf_slot1_no_inst_o(perf_slot1_no_inst_o)
    ,.perf_slot1_type_block_o(perf_slot1_type_block_o)
    ,.perf_slot1_dep_block_o(perf_slot1_dep_block_o)
    ,.perf_enq_dual_o(perf_enq_dual_o)
    ,.perf_enq_single_taken_o(perf_enq_single_taken_o)
    ,.perf_enq_single_upper_o(perf_enq_single_upper_o)
    ,.perf_enq_single_no_fetch1_o(perf_enq_single_no_fetch1_o)
    ,.perf_iq_empty_after_flush_o(perf_iq_empty_after_flush_o)
    ,.perf_iq_empty_steady_o(perf_iq_empty_steady_o)
`endif
);

icache
#(.AXI_ID(ICACHE_AXI_ID))
u_icache
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.req_rd_i(icache_rd_w)
    ,.req_lookup_rd_i(icache_lookup_rd_w)
    ,.req_flush_i(icache_flush_w)
    ,.req_invalidate_i(icache_invalidate_w)
    ,.req_pc_i(icache_pc_w)
    ,.req_lookup_pc_i(icache_lookup_pc_w)
    ,.axi_awready_i(axi_i_awready_i)
    ,.axi_wready_i(axi_i_wready_i)
    ,.axi_bvalid_i(axi_i_bvalid_i)
    ,.axi_bresp_i(axi_i_bresp_i)
    ,.axi_bid_i(axi_i_bid_i)
    ,.axi_arready_i(axi_i_arready_i)
    ,.axi_rvalid_i(axi_i_rvalid_i)
    ,.axi_rdata_i(axi_i_rdata_i)
    ,.axi_rresp_i(axi_i_rresp_i)
    ,.axi_rid_i(axi_i_rid_i)
    ,.axi_rlast_i(axi_i_rlast_i)
    ,.req_accept_o(icache_accept_w)
    ,.req_valid_o(icache_valid_w)
    ,.req_error_o(icache_error_w)
    ,.req_inst_o(icache_inst_w)
    ,.axi_awvalid_o(axi_i_awvalid_o)
    ,.axi_awaddr_o(axi_i_awaddr_o)
    ,.axi_awid_o(axi_i_awid_o)
    ,.axi_awlen_o(axi_i_awlen_o)
    ,.axi_awburst_o(axi_i_awburst_o)
    ,.axi_wvalid_o(axi_i_wvalid_o)
    ,.axi_wdata_o(axi_i_wdata_o)
    ,.axi_wstrb_o(axi_i_wstrb_o)
    ,.axi_wlast_o(axi_i_wlast_o)
    ,.axi_bready_o(axi_i_bready_o)
    ,.axi_arvalid_o(axi_i_arvalid_o)
    ,.axi_araddr_o(axi_i_araddr_o)
    ,.axi_arid_o(axi_i_arid_o)
    ,.axi_arlen_o(axi_i_arlen_o)
    ,.axi_arburst_o(axi_i_arburst_o)
    ,.axi_rready_o(axi_i_rready_o)
`ifdef PERF_IC
    ,.perf_access_o(perf_ic_access_o)
    ,.perf_hit_o(perf_ic_hit_o)
    ,.perf_miss_o(perf_ic_miss_o)
    ,.perf_refill_o(perf_ic_refill_o)
`endif
);

assign axi_i_awsize_o = 3'b010;
assign axi_i_arsize_o = 3'b010;

endmodule
