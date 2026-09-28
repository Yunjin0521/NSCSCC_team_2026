`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Biloong synthesizable AXI top.
//
// This wrapper keeps the biRISC-V-style CPU top boundary internally
// (biloong_top = I-cache + core + D-cache), then adapts the separate I/D AXI
// ports to one external AXI master through axi_arbiter.
// -----------------------------------------------------------------------------
module biloong_axi_top #(
     parameter CORE_ID          = 0
    ,parameter RESET_VECTOR     = 32'h1c00_0000
    ,parameter ICACHE_AXI_ID    = 0
    ,parameter DCACHE_AXI_ID    = 1
    ,parameter SUPPORT_BRANCH_PREDICTION = 1
    ,parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_SUPER    = 0
    ,parameter SUPPORT_MMU      = 1
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
    ,parameter MEM_CACHE_ADDR_MIN = 32'h1c00_0000
    ,parameter MEM_CACHE_ADDR_MAX = 32'h1c0f_ffff
    ,parameter NUM_BTB_ENTRIES  = 32
    ,parameter NUM_BTB_ENTRIES_W = 5
    ,parameter NUM_BHT_ENTRIES  = 512
    ,parameter NUM_BHT_ENTRIES_W = 9
    ,parameter RAS_ENABLE       = 1
    ,parameter GSHARE_ENABLE    = 0
    ,parameter BHT_ENABLE       = 1
    ,parameter NUM_RAS_ENTRIES  = 8
    ,parameter NUM_RAS_ENTRIES_W = 3
) (
     input  wire        clk
    ,input  wire        rst_n
    ,input  wire [7:0]  interrupt_i

    ,output wire        axi_arvalid_o
    ,input  wire        axi_arready_i
    ,output wire [31:0] axi_araddr_o
    ,output wire [3:0]  axi_arid_o
    ,output wire [7:0]  axi_arlen_o
    ,output wire [2:0]  axi_arsize_o
    ,output wire [1:0]  axi_arburst_o
    ,output wire [1:0]  axi_arlock_o
    ,output wire [3:0]  axi_arcache_o
    ,output wire [2:0]  axi_arprot_o
    ,input  wire        axi_rvalid_i
    ,output wire        axi_rready_o
    ,input  wire [31:0] axi_rdata_i
    ,input  wire [1:0]  axi_rresp_i
    ,input  wire [3:0]  axi_rid_i
    ,input  wire        axi_rlast_i

    ,output wire        axi_awvalid_o
    ,input  wire        axi_awready_i
    ,output wire [31:0] axi_awaddr_o
    ,output wire [3:0]  axi_awid_o
    ,output wire [7:0]  axi_awlen_o
    ,output wire [2:0]  axi_awsize_o
    ,output wire [1:0]  axi_awburst_o
    ,output wire [1:0]  axi_awlock_o
    ,output wire [3:0]  axi_awcache_o
    ,output wire [2:0]  axi_awprot_o
    ,output wire [3:0]  axi_wid_o
    ,output wire        axi_wvalid_o
    ,input  wire        axi_wready_i
    ,output wire [31:0] axi_wdata_o
    ,output wire [3:0]  axi_wstrb_o
    ,output wire        axi_wlast_o
    ,input  wire        axi_bvalid_i
    ,output wire        axi_bready_o
    ,input  wire [1:0]  axi_bresp_i
    ,input  wire [3:0]  axi_bid_i
);

    wire rst = !rst_n;

    wire        i_axi_awvalid_w;
    wire        i_axi_awready_w;
    wire [31:0] i_axi_awaddr_w;
    wire [3:0]  i_axi_awid_w;
    wire [7:0]  i_axi_awlen_w;
    wire [2:0]  i_axi_awsize_w;
    wire [1:0]  i_axi_awburst_w;
    wire        i_axi_wvalid_w;
    wire        i_axi_wready_w;
    wire [31:0] i_axi_wdata_w;
    wire [3:0]  i_axi_wstrb_w;
    wire        i_axi_wlast_w;
    wire        i_axi_bvalid_w;
    wire        i_axi_bready_w;
    wire [1:0]  i_axi_bresp_w;
    wire [3:0]  i_axi_bid_w;
    wire        i_axi_arvalid_w;
    wire        i_axi_arready_w;
    wire [31:0] i_axi_araddr_w;
    wire [3:0]  i_axi_arid_w;
    wire [7:0]  i_axi_arlen_w;
    wire [2:0]  i_axi_arsize_w;
    wire [1:0]  i_axi_arburst_w;
    wire        i_axi_rvalid_w;
    wire        i_axi_rready_w;
    wire [31:0] i_axi_rdata_w;
    wire [1:0]  i_axi_rresp_w;
    wire [3:0]  i_axi_rid_w;
    wire        i_axi_rlast_w;

    wire        d_axi_awvalid_w;
    wire        d_axi_awready_w;
    wire [31:0] d_axi_awaddr_w;
    wire [3:0]  d_axi_awid_w;
    wire [7:0]  d_axi_awlen_w;
    wire [2:0]  d_axi_awsize_w;
    wire [1:0]  d_axi_awburst_w;
    wire        d_axi_wvalid_w;
    wire        d_axi_wready_w;
    wire [31:0] d_axi_wdata_w;
    wire [3:0]  d_axi_wstrb_w;
    wire        d_axi_wlast_w;
    wire        d_axi_bvalid_w;
    wire        d_axi_bready_w;
    wire [1:0]  d_axi_bresp_w;
    wire [3:0]  d_axi_bid_w;
    wire        d_axi_arvalid_w;
    wire        d_axi_arready_w;
    wire [31:0] d_axi_araddr_w;
    wire [3:0]  d_axi_arid_w;
    wire [7:0]  d_axi_arlen_w;
    wire [2:0]  d_axi_arsize_w;
    wire [1:0]  d_axi_arburst_w;
    wire        d_axi_rvalid_w;
    wire        d_axi_rready_w;
    wire [31:0] d_axi_rdata_w;
    wire [1:0]  d_axi_rresp_w;
    wire [3:0]  d_axi_rid_w;
    wire        d_axi_rlast_w;
    wire        d_axi_wr_pending0_w;
    wire [31:0] d_axi_wr_pending0_addr_w;
    wire        d_axi_wr_pending1_w;
    wire [31:0] d_axi_wr_pending1_addr_w;

    wire [7:0]  diff_load_valid_w;
    wire [31:0] diff_load_paddr_w;
    wire [31:0] diff_load_vaddr_w;
    wire        diff_load_index_w;
    wire [7:0]  diff_store_valid_w;
    wire [31:0] diff_store_paddr_w;
    wire [31:0] diff_store_vaddr_w;
    wire [31:0] diff_store_data_w;
    wire        diff_store_index_w;
`ifdef BPU_PERF
    wire        unused_bpu_perf_valid_w;
    wire        unused_bpu_perf_is_branch_w;
    wire        unused_bpu_perf_is_jump_w;
    wire        unused_bpu_perf_is_ret_jirl_w;
    wire        unused_bpu_perf_is_indirect_jirl_w;
    wire [31:0] unused_bpu_perf_pc_w;
    wire        unused_bpu_perf_pred_taken_w;
    wire        unused_bpu_perf_actual_taken_w;
    wire        unused_bpu_perf_correct_w;
    wire        unused_bpu_perf_direction_miss_w;
    wire        unused_bpu_perf_target_miss_w;
    wire        unused_bpu_perf_exu_flush_w;
    wire        unused_bpu_perf_lookup_valid_w;
    wire        unused_bpu_perf_lookup_taken_w;
    wire        unused_bpu_perf_lookup_upper_w;
    wire        unused_bpu_perf_update_valid_w;
`endif
`ifdef PERF_MONI
    wire [1:0]  unused_perf_ff_count_w;
    wire [2:0]  unused_perf_iq_count_w;
    wire        unused_perf_stall_div_w;
    wire        unused_perf_stall_mem_w;
    wire        unused_perf_stall_mul_w;
    wire        unused_perf_iq_empty_w;
    wire        unused_perf_lsu_stall_w;
    wire        unused_perf_single_issue_w;
    wire        unused_perf_slot1_no_inst_w;
    wire        unused_perf_slot1_type_block_w;
    wire        unused_perf_slot1_dep_block_w;
    wire        unused_perf_enq_dual_w;
    wire        unused_perf_enq_single_taken_w;
    wire        unused_perf_enq_single_upper_w;
    wire        unused_perf_enq_single_no_fetch1_w;
    wire        unused_perf_iq_empty_after_flush_w;
    wire        unused_perf_iq_empty_steady_w;
    wire        unused_perf_dc_miss_busy_w;
`endif
`ifdef PERF_IC
    wire        unused_perf_ic_access_w;
    wire        unused_perf_ic_hit_w;
    wire        unused_perf_ic_miss_w;
    wire        unused_perf_ic_refill_w;
`endif
`ifdef PERF_DC
    wire        unused_perf_dc_access_w;
    wire        unused_perf_dc_read_w;
    wire        unused_perf_dc_write_w;
    wire        unused_perf_dc_hit_w;
    wire        unused_perf_dc_miss_w;
    wire        unused_perf_dc_refill_w;
    wire        unused_perf_dc_evict_w;
`endif

    assign axi_arlock_o  = 2'b00;
    assign axi_arcache_o = 4'b0000;
    assign axi_arprot_o  = 3'b000;
    assign axi_awlock_o  = 2'b00;
    assign axi_awcache_o = 4'b0000;
    assign axi_awprot_o  = 3'b000;
    assign axi_wid_o     = axi_awid_o;

    biloong_top #(
         .CORE_ID(CORE_ID)
        ,.ICACHE_AXI_ID(ICACHE_AXI_ID)
        ,.DCACHE_AXI_ID(DCACHE_AXI_ID)
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
        ,.MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN)
        ,.MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
        ,.NUM_BTB_ENTRIES(NUM_BTB_ENTRIES)
        ,.NUM_BTB_ENTRIES_W(NUM_BTB_ENTRIES_W)
        ,.NUM_BHT_ENTRIES(NUM_BHT_ENTRIES)
        ,.NUM_BHT_ENTRIES_W(NUM_BHT_ENTRIES_W)
        ,.RAS_ENABLE(RAS_ENABLE)
        ,.GSHARE_ENABLE(GSHARE_ENABLE)
        ,.BHT_ENABLE(BHT_ENABLE)
        ,.NUM_RAS_ENTRIES(NUM_RAS_ENTRIES)
        ,.NUM_RAS_ENTRIES_W(NUM_RAS_ENTRIES_W)
    ) u_biloong (
         .clk_i(clk)
        ,.rst_i(rst)
        ,.axi_i_awready_i(i_axi_awready_w)
        ,.axi_i_wready_i(i_axi_wready_w)
        ,.axi_i_bvalid_i(i_axi_bvalid_w)
        ,.axi_i_bresp_i(i_axi_bresp_w)
        ,.axi_i_bid_i(i_axi_bid_w)
        ,.axi_i_arready_i(i_axi_arready_w)
        ,.axi_i_rvalid_i(i_axi_rvalid_w)
        ,.axi_i_rdata_i(i_axi_rdata_w)
        ,.axi_i_rresp_i(i_axi_rresp_w)
        ,.axi_i_rid_i(i_axi_rid_w)
        ,.axi_i_rlast_i(i_axi_rlast_w)
        ,.axi_d_awready_i(d_axi_awready_w)
        ,.axi_d_wready_i(d_axi_wready_w)
        ,.axi_d_bvalid_i(d_axi_bvalid_w)
        ,.axi_d_bresp_i(d_axi_bresp_w)
        ,.axi_d_bid_i(d_axi_bid_w)
        ,.axi_d_arready_i(d_axi_arready_w)
        ,.axi_d_rvalid_i(d_axi_rvalid_w)
        ,.axi_d_rdata_i(d_axi_rdata_w)
        ,.axi_d_rresp_i(d_axi_rresp_w)
        ,.axi_d_rid_i(d_axi_rid_w)
        ,.axi_d_rlast_i(d_axi_rlast_w)
        ,.intr_i(interrupt_i)
        ,.reset_vector_i(RESET_VECTOR)
        ,.axi_i_awvalid_o(i_axi_awvalid_w)
        ,.axi_i_awaddr_o(i_axi_awaddr_w)
        ,.axi_i_awid_o(i_axi_awid_w)
        ,.axi_i_awlen_o(i_axi_awlen_w)
        ,.axi_i_awsize_o(i_axi_awsize_w)
        ,.axi_i_awburst_o(i_axi_awburst_w)
        ,.axi_i_wvalid_o(i_axi_wvalid_w)
        ,.axi_i_wdata_o(i_axi_wdata_w)
        ,.axi_i_wstrb_o(i_axi_wstrb_w)
        ,.axi_i_wlast_o(i_axi_wlast_w)
        ,.axi_i_bready_o(i_axi_bready_w)
        ,.axi_i_arvalid_o(i_axi_arvalid_w)
        ,.axi_i_araddr_o(i_axi_araddr_w)
        ,.axi_i_arid_o(i_axi_arid_w)
        ,.axi_i_arlen_o(i_axi_arlen_w)
        ,.axi_i_arsize_o(i_axi_arsize_w)
        ,.axi_i_arburst_o(i_axi_arburst_w)
        ,.axi_i_rready_o(i_axi_rready_w)
        ,.axi_d_awvalid_o(d_axi_awvalid_w)
        ,.axi_d_awaddr_o(d_axi_awaddr_w)
        ,.axi_d_awid_o(d_axi_awid_w)
        ,.axi_d_awlen_o(d_axi_awlen_w)
        ,.axi_d_awsize_o(d_axi_awsize_w)
        ,.axi_d_awburst_o(d_axi_awburst_w)
        ,.axi_d_wvalid_o(d_axi_wvalid_w)
        ,.axi_d_wdata_o(d_axi_wdata_w)
        ,.axi_d_wstrb_o(d_axi_wstrb_w)
        ,.axi_d_wlast_o(d_axi_wlast_w)
        ,.axi_d_bready_o(d_axi_bready_w)
        ,.axi_d_arvalid_o(d_axi_arvalid_w)
        ,.axi_d_araddr_o(d_axi_araddr_w)
        ,.axi_d_arid_o(d_axi_arid_w)
        ,.axi_d_arlen_o(d_axi_arlen_w)
        ,.axi_d_arsize_o(d_axi_arsize_w)
        ,.axi_d_arburst_o(d_axi_arburst_w)
        ,.axi_d_rready_o(d_axi_rready_w)
        ,.axi_d_wr_pending0_o(d_axi_wr_pending0_w)
        ,.axi_d_wr_pending0_addr_o(d_axi_wr_pending0_addr_w)
        ,.axi_d_wr_pending1_o(d_axi_wr_pending1_w)
        ,.axi_d_wr_pending1_addr_o(d_axi_wr_pending1_addr_w)
        ,.diff_load_valid_o(diff_load_valid_w)
        ,.diff_load_paddr_o(diff_load_paddr_w)
        ,.diff_load_vaddr_o(diff_load_vaddr_w)
        ,.diff_load_index_o(diff_load_index_w)
        ,.diff_store_valid_o(diff_store_valid_w)
        ,.diff_store_paddr_o(diff_store_paddr_w)
        ,.diff_store_vaddr_o(diff_store_vaddr_w)
        ,.diff_store_data_o(diff_store_data_w)
        ,.diff_store_index_o(diff_store_index_w)
`ifdef BPU_PERF
        ,.bpu_perf_valid_o(unused_bpu_perf_valid_w)
        ,.bpu_perf_is_branch_o(unused_bpu_perf_is_branch_w)
        ,.bpu_perf_is_jump_o(unused_bpu_perf_is_jump_w)
        ,.bpu_perf_is_ret_jirl_o(unused_bpu_perf_is_ret_jirl_w)
        ,.bpu_perf_is_indirect_jirl_o(unused_bpu_perf_is_indirect_jirl_w)
        ,.bpu_perf_pc_o(unused_bpu_perf_pc_w)
        ,.bpu_perf_pred_taken_o(unused_bpu_perf_pred_taken_w)
        ,.bpu_perf_actual_taken_o(unused_bpu_perf_actual_taken_w)
        ,.bpu_perf_correct_o(unused_bpu_perf_correct_w)
        ,.bpu_perf_direction_miss_o(unused_bpu_perf_direction_miss_w)
        ,.bpu_perf_target_miss_o(unused_bpu_perf_target_miss_w)
        ,.bpu_perf_exu_flush_o(unused_bpu_perf_exu_flush_w)
        ,.bpu_perf_lookup_valid_o(unused_bpu_perf_lookup_valid_w)
        ,.bpu_perf_lookup_taken_o(unused_bpu_perf_lookup_taken_w)
        ,.bpu_perf_lookup_upper_o(unused_bpu_perf_lookup_upper_w)
        ,.bpu_perf_update_valid_o(unused_bpu_perf_update_valid_w)
`endif
`ifdef PERF_MONI
        ,.perf_ff_count_o(unused_perf_ff_count_w)
        ,.perf_iq_count_o(unused_perf_iq_count_w)
        ,.perf_stall_div_o(unused_perf_stall_div_w)
        ,.perf_stall_mem_o(unused_perf_stall_mem_w)
        ,.perf_stall_mul_o(unused_perf_stall_mul_w)
        ,.perf_iq_empty_o(unused_perf_iq_empty_w)
        ,.perf_lsu_stall_o(unused_perf_lsu_stall_w)
        ,.perf_single_issue_o(unused_perf_single_issue_w)
        ,.perf_slot1_no_inst_o(unused_perf_slot1_no_inst_w)
        ,.perf_slot1_type_block_o(unused_perf_slot1_type_block_w)
        ,.perf_slot1_dep_block_o(unused_perf_slot1_dep_block_w)
        ,.perf_enq_dual_o(unused_perf_enq_dual_w)
        ,.perf_enq_single_taken_o(unused_perf_enq_single_taken_w)
        ,.perf_enq_single_upper_o(unused_perf_enq_single_upper_w)
        ,.perf_enq_single_no_fetch1_o(unused_perf_enq_single_no_fetch1_w)
        ,.perf_iq_empty_after_flush_o(unused_perf_iq_empty_after_flush_w)
        ,.perf_iq_empty_steady_o(unused_perf_iq_empty_steady_w)
        ,.perf_dc_miss_busy_o(unused_perf_dc_miss_busy_w)
`endif
`ifdef PERF_IC
        ,.perf_ic_access_o(unused_perf_ic_access_w)
        ,.perf_ic_hit_o(unused_perf_ic_hit_w)
        ,.perf_ic_miss_o(unused_perf_ic_miss_w)
        ,.perf_ic_refill_o(unused_perf_ic_refill_w)
`endif
`ifdef PERF_DC
        ,.perf_dc_access_o(unused_perf_dc_access_w)
        ,.perf_dc_read_o(unused_perf_dc_read_w)
        ,.perf_dc_write_o(unused_perf_dc_write_w)
        ,.perf_dc_hit_o(unused_perf_dc_hit_w)
        ,.perf_dc_miss_o(unused_perf_dc_miss_w)
        ,.perf_dc_refill_o(unused_perf_dc_refill_w)
        ,.perf_dc_evict_o(unused_perf_dc_evict_w)
`endif
    );

    axi_arbiter u_axi_arbiter (
         .clk(clk)
        ,.rst_n(rst_n)
        ,.m0_axi_arvalid_i(i_axi_arvalid_w)
        ,.m0_axi_arready_o(i_axi_arready_w)
        ,.m0_axi_araddr_i(i_axi_araddr_w)
        ,.m0_axi_arid_i(i_axi_arid_w)
        ,.m0_axi_arlen_i(i_axi_arlen_w)
        ,.m0_axi_arsize_i(i_axi_arsize_w)
        ,.m0_axi_arburst_i(i_axi_arburst_w)
        ,.m0_axi_rvalid_o(i_axi_rvalid_w)
        ,.m0_axi_rready_i(i_axi_rready_w)
        ,.m0_axi_rdata_o(i_axi_rdata_w)
        ,.m0_axi_rresp_o(i_axi_rresp_w)
        ,.m0_axi_rid_o(i_axi_rid_w)
        ,.m0_axi_rlast_o(i_axi_rlast_w)
        ,.m1_axi_arvalid_i(d_axi_arvalid_w)
        ,.m1_axi_arready_o(d_axi_arready_w)
        ,.m1_axi_araddr_i(d_axi_araddr_w)
        ,.m1_axi_arid_i(d_axi_arid_w)
        ,.m1_axi_arlen_i(d_axi_arlen_w)
        ,.m1_axi_arsize_i(d_axi_arsize_w)
        ,.m1_axi_arburst_i(d_axi_arburst_w)
        ,.m1_axi_rvalid_o(d_axi_rvalid_w)
        ,.m1_axi_rready_i(d_axi_rready_w)
        ,.m1_axi_rdata_o(d_axi_rdata_w)
        ,.m1_axi_rresp_o(d_axi_rresp_w)
        ,.m1_axi_rid_o(d_axi_rid_w)
        ,.m1_axi_rlast_o(d_axi_rlast_w)
        ,.m1_axi_awvalid_i(d_axi_awvalid_w)
        ,.m1_axi_awready_o(d_axi_awready_w)
        ,.m1_axi_awaddr_i(d_axi_awaddr_w)
        ,.m1_axi_awid_i(d_axi_awid_w)
        ,.m1_axi_awlen_i(d_axi_awlen_w)
        ,.m1_axi_awsize_i(d_axi_awsize_w)
        ,.m1_axi_awburst_i(d_axi_awburst_w)
        ,.m1_axi_wvalid_i(d_axi_wvalid_w)
        ,.m1_axi_wready_o(d_axi_wready_w)
        ,.m1_axi_wdata_i(d_axi_wdata_w)
        ,.m1_axi_wstrb_i(d_axi_wstrb_w)
        ,.m1_axi_wlast_i(d_axi_wlast_w)
        ,.m1_axi_bvalid_o(d_axi_bvalid_w)
        ,.m1_axi_bready_i(d_axi_bready_w)
        ,.m1_axi_bresp_o(d_axi_bresp_w)
        ,.m1_axi_bid_o(d_axi_bid_w)
        ,.m1_axi_wr_pending0_i(d_axi_wr_pending0_w)
        ,.m1_axi_wr_pending0_addr_i(d_axi_wr_pending0_addr_w)
        ,.m1_axi_wr_pending1_i(d_axi_wr_pending1_w)
        ,.m1_axi_wr_pending1_addr_i(d_axi_wr_pending1_addr_w)
        ,.s_axi_arvalid_o(axi_arvalid_o)
        ,.s_axi_arready_i(axi_arready_i)
        ,.s_axi_araddr_o(axi_araddr_o)
        ,.s_axi_arid_o(axi_arid_o)
        ,.s_axi_arlen_o(axi_arlen_o)
        ,.s_axi_arsize_o(axi_arsize_o)
        ,.s_axi_arburst_o(axi_arburst_o)
        ,.s_axi_rvalid_i(axi_rvalid_i)
        ,.s_axi_rready_o(axi_rready_o)
        ,.s_axi_rdata_i(axi_rdata_i)
        ,.s_axi_rresp_i(axi_rresp_i)
        ,.s_axi_rid_i(axi_rid_i)
        ,.s_axi_rlast_i(axi_rlast_i)
        ,.s_axi_awvalid_o(axi_awvalid_o)
        ,.s_axi_awready_i(axi_awready_i)
        ,.s_axi_awaddr_o(axi_awaddr_o)
        ,.s_axi_awid_o(axi_awid_o)
        ,.s_axi_awlen_o(axi_awlen_o)
        ,.s_axi_awsize_o(axi_awsize_o)
        ,.s_axi_awburst_o(axi_awburst_o)
        ,.s_axi_wvalid_o(axi_wvalid_o)
        ,.s_axi_wready_i(axi_wready_i)
        ,.s_axi_wdata_o(axi_wdata_o)
        ,.s_axi_wstrb_o(axi_wstrb_o)
        ,.s_axi_wlast_o(axi_wlast_o)
        ,.s_axi_bvalid_i(axi_bvalid_i)
        ,.s_axi_bready_o(axi_bready_o)
        ,.s_axi_bresp_i(axi_bresp_i)
        ,.s_axi_bid_i(axi_bid_i)
    );

    assign i_axi_awready_w = 1'b0;
    assign i_axi_wready_w  = 1'b0;
    assign i_axi_bvalid_w  = 1'b0;
    assign i_axi_bresp_w   = 2'b00;
    assign i_axi_bid_w     = 4'b0000;

    wire unused_i_write_w = i_axi_awvalid_w | i_axi_wvalid_w | i_axi_bready_w |
                            (|i_axi_awaddr_w) | (|i_axi_awid_w) |
                            (|i_axi_awlen_w) | (|i_axi_awsize_w) |
                            (|i_axi_awburst_w) | (|i_axi_wdata_w) |
                            (|i_axi_wstrb_w) | i_axi_wlast_w;
    wire unused_diff_w = (|diff_load_valid_w) | (|diff_load_paddr_w) |
                         (|diff_load_vaddr_w) | diff_load_index_w |
                         (|diff_store_valid_w) | (|diff_store_paddr_w) |
                         (|diff_store_vaddr_w) | (|diff_store_data_w) |
                         diff_store_index_w | unused_i_write_w;

endmodule
