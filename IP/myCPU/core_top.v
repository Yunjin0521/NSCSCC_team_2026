`timescale 1ns / 1ps

module core_top #(
    parameter TLBNUM = 32,
`ifdef CPU_DISABLE_SLOT1_ALU
    parameter CORE_SLOT1_ALU_ENABLE    = 0,
`else
    parameter CORE_SLOT1_ALU_ENABLE    = 1,
`endif
`ifdef CPU_DISABLE_SLOT1_BRANCH
    parameter CORE_SLOT1_BRANCH_ENABLE = 0,
`else
    parameter CORE_SLOT1_BRANCH_ENABLE = 1,
`endif
`ifdef CPU_DISABLE_SLOT1_MUL
    parameter CORE_SLOT1_MUL_ENABLE    = 0,
`else
    parameter CORE_SLOT1_MUL_ENABLE    = 1,
`endif
`ifdef CPU_DISABLE_SLOT1_LOAD
    parameter CORE_SLOT1_LOAD_ENABLE   = 0,
`else
    parameter CORE_SLOT1_LOAD_ENABLE   = 1,
`endif
`ifdef CPU_DISABLE_SLOT1_STORE
    parameter CORE_SLOT1_STORE_ENABLE  = 0
`else
    parameter CORE_SLOT1_STORE_ENABLE  = 1
`endif
) (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [7:0]  intrpt,

    output wire [3:0]  arid,
    output wire [31:0] araddr,
    output wire [7:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [1:0]  arlock,
    output wire [3:0]  arcache,
    output wire [2:0]  arprot,
    output wire        arvalid,
    input  wire        arready,

    input  wire [3:0]  rid,
    input  wire [31:0] rdata,
    input  wire [1:0]  rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    output wire [3:0]  awid,
    output wire [31:0] awaddr,
    output wire [7:0]  awlen,
    output wire [2:0]  awsize,
    output wire [1:0]  awburst,
    output wire [1:0]  awlock,
    output wire [3:0]  awcache,
    output wire [2:0]  awprot,
    output wire        awvalid,
    input  wire        awready,

    output wire [3:0]  wid,
    output wire [31:0] wdata,
    output wire [3:0]  wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    input  wire [3:0]  bid,
    input  wire [1:0]  bresp,
    input  wire        bvalid,
    output wire        bready,

    input  wire        break_point,
    input  wire        infor_flag,
    input  wire [4:0]  reg_num,
    output wire        ws_valid,
    output wire [31:0] rf_rdata,

    output wire [31:0] debug0_wb_pc,
    output wire [3:0]  debug0_wb_rf_wen,
    output wire [4:0]  debug0_wb_rf_wnum,
    output wire [31:0] debug0_wb_rf_wdata,
    output wire [31:0] debug0_wb_inst
`ifdef CPU_2CMT
    ,
    output wire [31:0] debug1_wb_pc,
    output wire [3:0]  debug1_wb_rf_wen,
    output wire [4:0]  debug1_wb_rf_wnum,
    output wire [31:0] debug1_wb_rf_wdata
`endif
`ifdef BPU_PERF
    ,
    output wire        bpu_perf_valid_o,
    output wire        bpu_perf_is_branch_o,
    output wire        bpu_perf_is_jump_o,
    output wire        bpu_perf_is_ret_jirl_o,
    output wire        bpu_perf_is_indirect_jirl_o,
    output wire [31:0] bpu_perf_pc_o,
    output wire        bpu_perf_pred_taken_o,
    output wire        bpu_perf_actual_taken_o,
    output wire        bpu_perf_correct_o,
    output wire        bpu_perf_direction_miss_o,
    output wire        bpu_perf_target_miss_o,
    output wire        bpu_perf_exu_flush_o,
    output wire        bpu_perf_lookup_valid_o,
    output wire        bpu_perf_lookup_taken_o,
    output wire        bpu_perf_lookup_upper_o,
    output wire        bpu_perf_update_valid_o
`endif
`ifdef PERF_IC
    ,
    output wire        perf_ic_access_o,
    output wire        perf_ic_hit_o,
    output wire        perf_ic_miss_o,
    output wire        perf_ic_refill_o
`endif
`ifdef PERF_DC
    ,
    output wire        perf_dc_access_o,
    output wire        perf_dc_read_o,
    output wire        perf_dc_write_o,
    output wire        perf_dc_hit_o,
    output wire        perf_dc_miss_o,
    output wire        perf_dc_refill_o,
    output wire        perf_dc_evict_o
`endif
`ifdef PERF_MONI
    ,
    output wire [1:0]  perf_ff_count_o,
    output wire [2:0]  perf_iq_count_o,
    output wire        perf_stall_div_o,
    output wire        perf_stall_mem_o,
    output wire        perf_stall_mul_o,
    output wire        perf_iq_empty_o,
    output wire        perf_lsu_stall_o,
    output wire        perf_single_issue_o,
    output wire        perf_slot1_no_inst_o,
    output wire        perf_slot1_type_block_o,
    output wire        perf_slot1_dep_block_o,
    output wire        perf_enq_dual_o,
    output wire        perf_enq_single_taken_o,
    output wire        perf_enq_single_upper_o,
    output wire        perf_enq_single_no_fetch1_o,
    output wire        perf_iq_empty_after_flush_o,
    output wire        perf_iq_empty_steady_o,
    output wire        perf_dc_miss_busy_o
`endif
);

    wire rst = !aresetn;

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
    wire [7:0]  biloong_load_valid_w;
    wire [31:0] biloong_load_paddr_w;
    wire [31:0] biloong_load_vaddr_w;
    wire        biloong_load_index_w;
    wire [7:0]  biloong_store_valid_w;
    wire [31:0] biloong_store_paddr_w;
    wire [31:0] biloong_store_vaddr_w;
    wire [31:0] biloong_store_data_w;
    wire        biloong_store_index_w;

    wire        commit0_valid_w = u_biloong.u_core.u_issue.pipe0_valid_wb_w;
    wire [31:0] commit0_pc_w    = u_biloong.u_core.u_issue.pipe0_pc_wb_w;
    wire [31:0] commit0_inst_w  = u_biloong.u_core.u_issue.pipe0_opc_wb_w;
    wire [4:0]  commit0_rd_w    = u_biloong.u_core.u_issue.pipe0_rd_wb_w;
    wire [31:0] commit0_data_w  = u_biloong.u_core.u_issue.pipe0_result_wb_w;
    wire [5:0]  commit0_exc_w   = u_biloong.u_core.u_issue.pipe0_exception_wb_w;
    wire [5:0]  commit0_ecode_w = u_biloong.u_core.u_issue.pipe0_exception_ecode_wb_w;
    wire        commit1_valid_w = u_biloong.u_core.u_issue.pipe1_valid_wb_w;
    wire [31:0] commit1_pc_w    = u_biloong.u_core.u_issue.pipe1_pc_wb_w;
    wire [31:0] commit1_inst_w  = u_biloong.u_core.u_issue.pipe1_opc_wb_w;
    wire [4:0]  commit1_rd_w    = u_biloong.u_core.u_issue.pipe1_rd_wb_w;
    wire [31:0] commit1_data_w  = u_biloong.u_core.u_issue.pipe1_result_wb_w;
    wire [5:0]  commit1_exc_w   = u_biloong.u_core.u_issue.pipe1_exception_wb_w;
    wire [5:0]  commit1_ecode_w = u_biloong.u_core.u_issue.pipe1_exception_ecode_wb_w;
    wire        commit0_event_w = commit0_valid_w || (commit0_exc_w != 6'b0);
    wire        commit1_event_w = commit1_valid_w || (commit1_exc_w != 6'b0);
    wire [5:0]  commit_exc_w    = commit0_exc_w | commit1_exc_w;
    wire [5:0]  commit_exception_w = (commit0_exc_w != 6'b0) ? commit0_exc_w : commit1_exc_w;
    wire [5:0]  commit_ecode_w  = (commit0_exc_w != 6'b0) ? commit0_ecode_w : commit1_ecode_w;
    wire [31:0] commit_excp_pc_w = (commit0_exc_w != 6'b0) ? commit0_pc_w : commit1_pc_w;
    wire [31:0] commit_excp_inst_w = (commit0_exc_w != 6'b0) ? commit0_inst_w : commit1_inst_w;

    localparam [5:0] DIFF_EXCEPTION_MISALIGNED_FETCH       = 6'h10;
    localparam [5:0] DIFF_EXCEPTION_FAULT_FETCH            = 6'h11;
    localparam [5:0] DIFF_EXCEPTION_ILLEGAL_INSTRUCTION    = 6'h12;
    localparam [5:0] DIFF_EXCEPTION_BREAKPOINT             = 6'h13;
    localparam [5:0] DIFF_EXCEPTION_MISALIGNED_LOAD        = 6'h14;
    localparam [5:0] DIFF_EXCEPTION_FAULT_LOAD             = 6'h15;
    localparam [5:0] DIFF_EXCEPTION_MISALIGNED_STORE       = 6'h16;
    localparam [5:0] DIFF_EXCEPTION_FAULT_STORE            = 6'h17;
    localparam [5:0] DIFF_EXCEPTION_ECALL_U                = 6'h18;
    localparam [5:0] DIFF_EXCEPTION_ECALL_S                = 6'h19;
    localparam [5:0] DIFF_EXCEPTION_ECALL_H                = 6'h1a;
    localparam [5:0] DIFF_EXCEPTION_ECALL_M                = 6'h1b;
    localparam [5:0] DIFF_EXCEPTION_PAGE_FAULT_INST        = 6'h1c;
    localparam [5:0] DIFF_EXCEPTION_PAGE_FAULT_LOAD        = 6'h1d;
    localparam [5:0] DIFF_EXCEPTION_PRIVILEGED_INSTRUCTION = 6'h1e;
    localparam [5:0] DIFF_EXCEPTION_PAGE_FAULT_STORE       = 6'h1f;
    localparam [5:0] DIFF_EXCEPTION_FENCE                  = 6'h34;
    localparam [5:0] DIFF_EXCEPTION_IDLE                   = 6'h35;
    localparam [5:0] DIFF_LA_ECODE_PIL                     = 6'h01;
    localparam [5:0] DIFF_LA_ECODE_PIS                     = 6'h02;
    localparam [5:0] DIFF_LA_ECODE_PIF                     = 6'h03;
    localparam [5:0] DIFF_LA_ECODE_ADE                     = 6'h08;
    localparam [5:0] DIFF_LA_ECODE_ALE                     = 6'h09;
    localparam [5:0] DIFF_LA_ECODE_SYS                     = 6'h0b;
    localparam [5:0] DIFF_LA_ECODE_BRK                     = 6'h0c;
    localparam [5:0] DIFF_LA_ECODE_INE                     = 6'h0d;
    localparam [5:0] DIFF_LA_ECODE_IPE                     = 6'h0e;

    function [5:0] diff_la_ecode;
        input [5:0] exception;
        input [5:0] exception_ecode;
    begin
        case (exception)
        DIFF_EXCEPTION_FAULT_LOAD:
            diff_la_ecode = DIFF_LA_ECODE_PIL;
        DIFF_EXCEPTION_PAGE_FAULT_LOAD:
            diff_la_ecode = (exception_ecode != 6'b0) ? exception_ecode : DIFF_LA_ECODE_PIL;
        DIFF_EXCEPTION_FAULT_STORE:
            diff_la_ecode = DIFF_LA_ECODE_PIS;
        DIFF_EXCEPTION_PAGE_FAULT_STORE:
            diff_la_ecode = (exception_ecode != 6'b0) ? exception_ecode : DIFF_LA_ECODE_PIS;
        DIFF_EXCEPTION_PAGE_FAULT_INST:
            diff_la_ecode = (exception_ecode != 6'b0) ? exception_ecode : DIFF_LA_ECODE_PIF;
        DIFF_EXCEPTION_FAULT_FETCH,
        DIFF_EXCEPTION_MISALIGNED_FETCH:
            diff_la_ecode = DIFF_LA_ECODE_ADE;
        DIFF_EXCEPTION_MISALIGNED_LOAD,
        DIFF_EXCEPTION_MISALIGNED_STORE:
            diff_la_ecode = DIFF_LA_ECODE_ALE;
        DIFF_EXCEPTION_ECALL_U,
        DIFF_EXCEPTION_ECALL_S,
        DIFF_EXCEPTION_ECALL_H,
        DIFF_EXCEPTION_ECALL_M:
            diff_la_ecode = DIFF_LA_ECODE_SYS;
        DIFF_EXCEPTION_BREAKPOINT:
            diff_la_ecode = DIFF_LA_ECODE_BRK;
        DIFF_EXCEPTION_ILLEGAL_INSTRUCTION:
            diff_la_ecode = DIFF_LA_ECODE_INE;
        DIFF_EXCEPTION_PRIVILEGED_INSTRUCTION:
            diff_la_ecode = DIFF_LA_ECODE_IPE;
        default:
            diff_la_ecode = exception_ecode;
        endcase
    end
    endfunction

    assign ws_valid            = commit0_event_w || commit1_event_w;
    assign rf_rdata            = 32'h0;
    assign debug0_wb_pc        = commit0_pc_w;
    assign debug0_wb_inst      = commit0_inst_w;
    assign debug0_wb_rf_wen    = (commit0_valid_w && (commit0_rd_w != 5'd0) && (commit0_exc_w == 6'b0)) ? 4'hf : 4'h0;
    assign debug0_wb_rf_wnum   = commit0_rd_w;
    assign debug0_wb_rf_wdata  = commit0_data_w;
    assign arlock              = 2'b00;
    assign arcache             = 4'b0000;
    assign arprot              = 3'b000;
    assign awlock              = 2'b00;
    assign awcache             = 4'b0000;
    assign awprot              = 3'b000;
    assign wid                 = awid;
`ifdef CPU_2CMT
    assign debug1_wb_pc        = commit1_pc_w;
    assign debug1_wb_rf_wen    = (commit1_valid_w && (commit1_rd_w != 5'd0) && (commit1_exc_w == 6'b0)) ? 4'hf : 4'h0;
    assign debug1_wb_rf_wnum   = commit1_rd_w;
    assign debug1_wb_rf_wdata  = commit1_data_w;
`endif

    //-----------------------------------------------------------------
    // Biloong top: core + I-cache + D-cache, matching biRISC-V top split.
    //-----------------------------------------------------------------
    biloong_top #(
         .SUPPORT_BRANCH_PREDICTION(1)
        ,.SUPPORT_MULDIV(1)
        ,.SUPPORT_SUPER(0)
        ,.SUPPORT_MMU(1)
        ,.SUPPORT_DUAL_ISSUE(1)
        ,.SUPPORT_LOAD_BYPASS(1)
        ,.SUPPORT_MUL_BYPASS(1)
        ,.SUPPORT_REGFILE_XILINX(1)
        ,.SUPPORT_SLOT1_ALU(CORE_SLOT1_ALU_ENABLE)
        ,.SUPPORT_SLOT1_BRANCH(CORE_SLOT1_BRANCH_ENABLE)
        ,.SUPPORT_SLOT1_MUL(CORE_SLOT1_MUL_ENABLE)
        ,.SUPPORT_SLOT1_LOAD(CORE_SLOT1_LOAD_ENABLE)
        ,.SUPPORT_SLOT1_STORE(CORE_SLOT1_STORE_ENABLE)
        ,.MEM_CACHE_ADDR_MIN(32'h1c00_0000)
        ,.MEM_CACHE_ADDR_MAX(32'h1c0f_ffff)
        ,.ICACHE_AXI_ID(0)
        ,.DCACHE_AXI_ID(1)
    ) u_biloong (
         .clk_i(aclk)
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
        ,.intr_i(intrpt)
        ,.reset_vector_i(32'h1c00_0000)
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
        ,.diff_load_valid_o(biloong_load_valid_w)
        ,.diff_load_paddr_o(biloong_load_paddr_w)
        ,.diff_load_vaddr_o(biloong_load_vaddr_w)
        ,.diff_load_index_o(biloong_load_index_w)
        ,.diff_store_valid_o(biloong_store_valid_w)
        ,.diff_store_paddr_o(biloong_store_paddr_w)
        ,.diff_store_vaddr_o(biloong_store_vaddr_w)
        ,.diff_store_data_o(biloong_store_data_w)
        ,.diff_store_index_o(biloong_store_index_w)
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
`ifdef PERF_IC
        ,.perf_ic_access_o(perf_ic_access_o)
        ,.perf_ic_hit_o(perf_ic_hit_o)
        ,.perf_ic_miss_o(perf_ic_miss_o)
        ,.perf_ic_refill_o(perf_ic_refill_o)
`endif
`ifdef PERF_DC
        ,.perf_dc_access_o(perf_dc_access_o)
        ,.perf_dc_read_o(perf_dc_read_o)
        ,.perf_dc_write_o(perf_dc_write_o)
        ,.perf_dc_hit_o(perf_dc_hit_o)
        ,.perf_dc_miss_o(perf_dc_miss_o)
        ,.perf_dc_refill_o(perf_dc_refill_o)
        ,.perf_dc_evict_o(perf_dc_evict_o)
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
        ,.perf_dc_miss_busy_o(perf_dc_miss_busy_o)
`endif
    );

    //-----------------------------------------------------------------
    // I-cache and D-cache share the single Chiplab AXI master port.
    //-----------------------------------------------------------------
    axi_arbiter u_axi_arbiter (
        .clk(aclk),
        .rst_n(aresetn),
        .m0_axi_arvalid_i(i_axi_arvalid_w),
        .m0_axi_arready_o(i_axi_arready_w),
        .m0_axi_araddr_i(i_axi_araddr_w),
        .m0_axi_arid_i(i_axi_arid_w),
        .m0_axi_arlen_i(i_axi_arlen_w),
        .m0_axi_arsize_i(i_axi_arsize_w),
        .m0_axi_arburst_i(i_axi_arburst_w),
        .m0_axi_rvalid_o(i_axi_rvalid_w),
        .m0_axi_rready_i(i_axi_rready_w),
        .m0_axi_rdata_o(i_axi_rdata_w),
        .m0_axi_rresp_o(i_axi_rresp_w),
        .m0_axi_rid_o(i_axi_rid_w),
        .m0_axi_rlast_o(i_axi_rlast_w),
        .m1_axi_arvalid_i(d_axi_arvalid_w),
        .m1_axi_arready_o(d_axi_arready_w),
        .m1_axi_araddr_i(d_axi_araddr_w),
        .m1_axi_arid_i(d_axi_arid_w),
        .m1_axi_arlen_i(d_axi_arlen_w),
        .m1_axi_arsize_i(d_axi_arsize_w),
        .m1_axi_arburst_i(d_axi_arburst_w),
        .m1_axi_rvalid_o(d_axi_rvalid_w),
        .m1_axi_rready_i(d_axi_rready_w),
        .m1_axi_rdata_o(d_axi_rdata_w),
        .m1_axi_rresp_o(d_axi_rresp_w),
        .m1_axi_rid_o(d_axi_rid_w),
        .m1_axi_rlast_o(d_axi_rlast_w),
        .m1_axi_awvalid_i(d_axi_awvalid_w),
        .m1_axi_awready_o(d_axi_awready_w),
        .m1_axi_awaddr_i(d_axi_awaddr_w),
        .m1_axi_awid_i(d_axi_awid_w),
        .m1_axi_awlen_i(d_axi_awlen_w),
        .m1_axi_awsize_i(d_axi_awsize_w),
        .m1_axi_awburst_i(d_axi_awburst_w),
        .m1_axi_wvalid_i(d_axi_wvalid_w),
        .m1_axi_wready_o(d_axi_wready_w),
        .m1_axi_wdata_i(d_axi_wdata_w),
        .m1_axi_wstrb_i(d_axi_wstrb_w),
        .m1_axi_wlast_i(d_axi_wlast_w),
        .m1_axi_bvalid_o(d_axi_bvalid_w),
        .m1_axi_bready_i(d_axi_bready_w),
        .m1_axi_bresp_o(d_axi_bresp_w),
        .m1_axi_bid_o(d_axi_bid_w),
        .m1_axi_wr_pending0_i(d_axi_wr_pending0_w),
        .m1_axi_wr_pending0_addr_i(d_axi_wr_pending0_addr_w),
        .m1_axi_wr_pending1_i(d_axi_wr_pending1_w),
        .m1_axi_wr_pending1_addr_i(d_axi_wr_pending1_addr_w),
        .s_axi_arvalid_o(arvalid),
        .s_axi_arready_i(arready),
        .s_axi_araddr_o(araddr),
        .s_axi_arid_o(arid),
        .s_axi_arlen_o(arlen),
        .s_axi_arsize_o(arsize),
        .s_axi_arburst_o(arburst),
        .s_axi_rvalid_i(rvalid),
        .s_axi_rready_o(rready),
        .s_axi_rdata_i(rdata),
        .s_axi_rresp_i(rresp),
        .s_axi_rid_i(rid),
        .s_axi_rlast_i(rlast),
        .s_axi_awvalid_o(awvalid),
        .s_axi_awready_i(awready),
        .s_axi_awaddr_o(awaddr),
        .s_axi_awid_o(awid),
        .s_axi_awlen_o(awlen),
        .s_axi_awsize_o(awsize),
        .s_axi_awburst_o(awburst),
        .s_axi_wvalid_o(wvalid),
        .s_axi_wready_i(wready),
        .s_axi_wdata_o(wdata),
        .s_axi_wstrb_o(wstrb),
        .s_axi_wlast_o(wlast),
        .s_axi_bvalid_i(bvalid),
        .s_axi_bready_o(bready),
        .s_axi_bresp_i(bresp),
        .s_axi_bid_i(bid)
    );

    assign i_axi_awready_w = 1'b0;
    assign i_axi_wready_w  = 1'b0;
    assign i_axi_bvalid_w  = 1'b0;
    assign i_axi_bresp_w   = 2'b00;
    assign i_axi_bid_w     = 4'b0;

`ifdef DIFFTEST_EN
    wire [5:0]  commit0_op_31_26_w = commit0_inst_w[31:26];
    wire [3:0]  commit0_op_25_22_w = commit0_inst_w[25:22];
    wire [1:0]  commit0_op_21_20_w = commit0_inst_w[21:20];
    wire [4:0]  commit0_op_19_15_w = commit0_inst_w[19:15];
    wire [4:0]  commit0_rk_w       = commit0_inst_w[14:10];
    wire [4:0]  commit0_rj_w       = commit0_inst_w[9:5];
    wire [4:0]  commit0_rd_field_w = commit0_inst_w[4:0];
    wire        commit0_sys_base_w  = (commit0_op_31_26_w == 6'h01) &&
                                      (commit0_op_25_22_w == 4'h9) &&
                                      (commit0_op_21_20_w == 2'h0);
    wire        commit0_rdcnt_base_w = (commit0_op_31_26_w == 6'h00) &&
                                       (commit0_op_25_22_w == 4'h0) &&
                                       (commit0_op_21_20_w == 2'h0) &&
                                       (commit0_op_19_15_w == 5'h00);
    wire        commit0_rdcnt_w = commit0_rdcnt_base_w &&
                                  (((commit0_rk_w == 5'h18) && (commit0_rd_field_w == 5'd0)) ||
                                   ((commit0_rk_w == 5'h18) && (commit0_rj_w == 5'd0) && (commit0_rd_field_w != 5'd0)) ||
                                   ((commit0_rk_w == 5'h19) && (commit0_rj_w == 5'd0)));
    wire        commit0_rdtimel_w = commit0_rdcnt_base_w &&
                                    (commit0_rk_w == 5'h18) &&
                                    (commit0_rj_w == 5'd0) &&
                                    (commit0_rd_field_w != 5'd0);
    wire        commit0_rdtimeh_w = commit0_rdcnt_base_w &&
                                    (commit0_rk_w == 5'h19) &&
                                    (commit0_rj_w == 5'd0);
    wire        commit0_tlbfill_w = commit0_sys_base_w &&
                                    (commit0_op_19_15_w == 5'h10) &&
                                    (commit0_rk_w == 5'h0d) &&
                                    (commit0_rj_w == 5'd0) &&
                                    (commit0_rd_field_w == 5'd0);
    wire        commit0_ertn_w = commit0_sys_base_w &&
                                 (commit0_op_19_15_w == 5'h10) &&
                                 (commit0_rk_w == 5'h0e) &&
                                 (commit0_rj_w == 5'd0) &&
                                 (commit0_rd_field_w == 5'd0);
    wire        commit0_csr_reg_w = (commit0_op_31_26_w == 6'h01) &&
                                    !commit0_inst_w[25] &&
                                    !commit0_inst_w[24];
    wire        commit0_csr_estat_w = commit0_csr_reg_w &&
                                      (commit0_inst_w[23:10] == 14'h005);

    wire        diff_commit0_excp_w = (commit0_exc_w != 6'b0) && diff_excp_valid_w;
    wire        diff_commit_valid_w = commit0_valid_w && !diff_commit0_excp_w;
    wire [31:0] diff_commit_pc_w    = commit0_pc_w;
    wire [31:0] diff_commit_instr_w = commit0_inst_w;
    wire        diff_commit_wen_w   = commit0_valid_w && (commit0_rd_w != 5'd0) && (commit0_exc_w == 6'b0);
    wire [4:0]  diff_commit_wdest_w = commit0_rd_w;
    wire [31:0] diff_commit_wdata_w = commit0_data_w;
    wire        diff_commit_is_tlbfill_w = commit0_tlbfill_w && commit0_valid_w;
    wire [4:0]  diff_commit_tlbfill_index_w = u_biloong.u_core.u_csr.u_csrfile.tlbfill_index_q;
    wire        diff_commit_is_cntinst_w = commit0_valid_w && commit0_rdcnt_w;
    wire [63:0] diff_commit_timer64_w =
        commit0_rdtimel_w ? {32'h0, commit0_data_w} :
        commit0_rdtimeh_w ? {commit0_data_w, 32'h0} :
                             u_biloong.u_core.u_csr.u_csrfile.timer_64_q;
    wire        diff_commit_csr_rstat_w = diff_commit_valid_w && commit0_csr_estat_w;
    wire [31:0] diff_commit_csr_data_w = commit0_data_w;

`ifdef CPU_2CMT
    wire [5:0]  commit1_op_31_26_w = commit1_inst_w[31:26];
    wire [3:0]  commit1_op_25_22_w = commit1_inst_w[25:22];
    wire [1:0]  commit1_op_21_20_w = commit1_inst_w[21:20];
    wire [4:0]  commit1_op_19_15_w = commit1_inst_w[19:15];
    wire [4:0]  commit1_rk_w       = commit1_inst_w[14:10];
    wire [4:0]  commit1_rj_w       = commit1_inst_w[9:5];
    wire [4:0]  commit1_rd_field_w = commit1_inst_w[4:0];
    wire        commit1_sys_base_w  = (commit1_op_31_26_w == 6'h01) &&
                                      (commit1_op_25_22_w == 4'h9) &&
                                      (commit1_op_21_20_w == 2'h0);
    wire        commit1_rdcnt_base_w = (commit1_op_31_26_w == 6'h00) &&
                                       (commit1_op_25_22_w == 4'h0) &&
                                       (commit1_op_21_20_w == 2'h0) &&
                                       (commit1_op_19_15_w == 5'h00);
    wire        commit1_rdcnt_w = commit1_rdcnt_base_w &&
                                  (((commit1_rk_w == 5'h18) && (commit1_rd_field_w == 5'd0)) ||
                                   ((commit1_rk_w == 5'h18) && (commit1_rj_w == 5'd0) && (commit1_rd_field_w != 5'd0)) ||
                                   ((commit1_rk_w == 5'h19) && (commit1_rj_w == 5'd0)));
    wire        commit1_rdtimel_w = commit1_rdcnt_base_w &&
                                    (commit1_rk_w == 5'h18) &&
                                    (commit1_rj_w == 5'd0) &&
                                    (commit1_rd_field_w != 5'd0);
    wire        commit1_rdtimeh_w = commit1_rdcnt_base_w &&
                                    (commit1_rk_w == 5'h19) &&
                                    (commit1_rj_w == 5'd0);
    wire        commit1_tlbfill_w = commit1_sys_base_w &&
                                    (commit1_op_19_15_w == 5'h10) &&
                                    (commit1_rk_w == 5'h0d) &&
                                    (commit1_rj_w == 5'd0) &&
                                    (commit1_rd_field_w == 5'd0);
    wire        commit1_csr_reg_w = (commit1_op_31_26_w == 6'h01) &&
                                    !commit1_inst_w[25] &&
                                    !commit1_inst_w[24];
    wire        commit1_csr_estat_w = commit1_csr_reg_w &&
                                      (commit1_inst_w[23:10] == 14'h005);
    wire        diff_commit1_excp_w = (commit1_exc_w != 6'b0) && diff_excp_valid_w;
    wire        diff_commit1_valid_w = commit1_valid_w && !diff_commit1_excp_w;
    wire [31:0] diff_commit1_pc_w    = commit1_pc_w;
    wire [31:0] diff_commit1_instr_w = commit1_inst_w;
    wire        diff_commit1_wen_w   = commit1_valid_w && (commit1_rd_w != 5'd0) && (commit1_exc_w == 6'b0);
    wire [4:0]  diff_commit1_wdest_w = commit1_rd_w;
    wire [31:0] diff_commit1_wdata_w = commit1_data_w;
    wire        diff_commit1_is_tlbfill_w = commit1_tlbfill_w && commit1_valid_w;
    wire [4:0]  diff_commit1_tlbfill_index_w = u_biloong.u_core.u_csr.u_csrfile.tlbfill_index_q;
    wire        diff_commit1_is_cntinst_w = commit1_valid_w && commit1_rdcnt_w;
    wire [63:0] diff_commit1_timer64_w =
        commit1_rdtimel_w ? {32'h0, commit1_data_w} :
        commit1_rdtimeh_w ? {commit1_data_w, 32'h0} :
                             u_biloong.u_core.u_csr.u_csrfile.timer_64_q;
    wire        diff_commit1_csr_rstat_w = diff_commit1_valid_w && commit1_csr_estat_w;
    wire [31:0] diff_commit1_csr_data_w = commit1_data_w;
`endif

    wire        diff_ertn_w       = commit0_valid_w && commit0_ertn_w;
    wire        diff_internal_flush_w = (commit_exception_w == DIFF_EXCEPTION_FENCE) ||
                                        (commit_exception_w == DIFF_EXCEPTION_IDLE);
    wire        diff_excp_valid_w = (commit_exc_w != 6'b0) && !diff_ertn_w && !diff_internal_flush_w;
    wire [10:0] diff_intr_no_w    = diff_csr_estat_w[12:2];
    wire [5:0]  diff_excp_cause_w = diff_la_ecode(commit_exception_w, commit_ecode_w);
    wire [31:0] diff_excp_pc_w    = commit_excp_pc_w;
    wire [31:0] diff_excp_instr_w = commit_excp_inst_w;

    wire [31:0] diff_csr_crmd_w      = u_biloong.u_core.u_csr.u_csrfile.csr_crmd_q;
    wire [31:0] diff_csr_prmd_w      = u_biloong.u_core.u_csr.u_csrfile.csr_prmd_q;
    wire [31:0] diff_csr_ecfg_w      = u_biloong.u_core.u_csr.u_csrfile.csr_ecfg_q;
    wire [31:0] diff_csr_estat_w     = u_biloong.u_core.u_csr.u_csrfile.csr_estat_q;
    wire [31:0] diff_csr_era_w       = u_biloong.u_core.u_csr.u_csrfile.csr_era_q;
    wire [31:0] diff_csr_badv_w      = u_biloong.u_core.u_csr.u_csrfile.csr_badv_q;
    wire [31:0] diff_csr_eentry_w    = u_biloong.u_core.u_csr.u_csrfile.csr_eentry_q;
    wire [31:0] diff_csr_tlbidx_w    = u_biloong.u_core.u_csr.u_csrfile.csr_tlbidx_q;
    wire [31:0] diff_csr_tlbehi_w    = u_biloong.u_core.u_csr.u_csrfile.csr_tlbehi_q;
    wire [31:0] diff_csr_tlbelo0_w   = u_biloong.u_core.u_csr.u_csrfile.csr_tlbelo0_q;
    wire [31:0] diff_csr_tlbelo1_w   = u_biloong.u_core.u_csr.u_csrfile.csr_tlbelo1_q;
    wire [31:0] diff_csr_asid_w      = u_biloong.u_core.u_csr.u_csrfile.csr_asid_q;
    wire [31:0] diff_csr_pgdl_w      = u_biloong.u_core.u_csr.u_csrfile.csr_pgdl_q;
    wire [31:0] diff_csr_pgdh_w      = u_biloong.u_core.u_csr.u_csrfile.csr_pgdh_q;
    wire [31:0] diff_csr_save0_w     = u_biloong.u_core.u_csr.u_csrfile.csr_save0_q;
    wire [31:0] diff_csr_save1_w     = u_biloong.u_core.u_csr.u_csrfile.csr_save1_q;
    wire [31:0] diff_csr_save2_w     = u_biloong.u_core.u_csr.u_csrfile.csr_save2_q;
    wire [31:0] diff_csr_save3_w     = u_biloong.u_core.u_csr.u_csrfile.csr_save3_q;
    wire [31:0] diff_csr_tid_w       = u_biloong.u_core.u_csr.u_csrfile.csr_tid_q;
    wire [31:0] diff_csr_tcfg_w      = u_biloong.u_core.u_csr.u_csrfile.csr_tcfg_q;
    wire [31:0] diff_csr_tval_w      = u_biloong.u_core.u_csr.u_csrfile.csr_tval_q;
    wire [31:0] diff_csr_tlbrentry_w = u_biloong.u_core.u_csr.u_csrfile.csr_tlbrentry_q;
    wire [31:0] diff_csr_dmw0_w      = u_biloong.u_core.u_csr.u_csrfile.csr_dmw0_q;
    wire [31:0] diff_csr_dmw1_w      = u_biloong.u_core.u_csr.u_csrfile.csr_dmw1_q;
    wire        diff_csr_llbctl_write_w =
        u_biloong.u_core.csr_writeback_write_w &&
        (u_biloong.u_core.csr_writeback_waddr_w == 14'h060);
    wire        commit0_is_ll_w = (commit0_inst_w[31:26] == 6'h08) &&
                                  !commit0_inst_w[25] && !commit0_inst_w[24];
    wire        commit0_is_sc_w = (commit0_inst_w[31:26] == 6'h08) &&
                                  !commit0_inst_w[25] &&  commit0_inst_w[24];
    wire        commit1_is_ll_w = (commit1_inst_w[31:26] == 6'h08) &&
                                  !commit1_inst_w[25] && !commit1_inst_w[24];
    wire        commit1_is_sc_w = (commit1_inst_w[31:26] == 6'h08) &&
                                  !commit1_inst_w[25] &&  commit1_inst_w[24];
    reg  [31:0] cmt_csr_llbctl_next_r;

    reg        cmt_valid_r;
    reg [31:0] cmt_pc_r;
    reg [31:0] cmt_instr_r;
    reg        cmt_wen_r;
    reg [4:0]  cmt_wdest_r;
    reg [31:0] cmt_wdata_r;
    reg        cmt_is_tlbfill_r;
    reg [4:0]  cmt_tlbfill_index_r;
    reg        cmt_is_cntinst_r;
    reg [63:0] cmt_timer64_r;
    reg        cmt_csr_rstat_r;
    reg [31:0] cmt_csr_data_r;
`ifdef CPU_2CMT
    reg        cmt1_valid_r;
    reg [31:0] cmt1_pc_r;
    reg [31:0] cmt1_instr_r;
    reg        cmt1_wen_r;
    reg [4:0]  cmt1_wdest_r;
    reg [31:0] cmt1_wdata_r;
    reg        cmt1_is_tlbfill_r;
    reg [4:0]  cmt1_tlbfill_index_r;
    reg        cmt1_is_cntinst_r;
    reg [63:0] cmt1_timer64_r;
    reg        cmt1_csr_rstat_r;
    reg [31:0] cmt1_csr_data_r;
    reg [7:0]  cmt1_load_valid_r;
    reg [31:0] cmt1_load_paddr_r;
    reg [31:0] cmt1_load_vaddr_r;
    reg [7:0]  cmt1_store_valid_r;
    reg [31:0] cmt1_store_paddr_r;
    reg [31:0] cmt1_store_vaddr_r;
    reg [31:0] cmt1_store_data_r;
`endif
    reg        cmt_excp_valid_r;
    reg        cmt_ertn_r;
    reg [10:0] cmt_intr_no_r;
    reg [5:0]  cmt_excp_cause_r;
    reg [31:0] cmt_excp_pc_r;
    reg [31:0] cmt_excp_inst_r;
    reg [31:0] cmt_csr_llbctl_r;
    reg [7:0]  cmt_load_valid_r;
    reg [31:0] cmt_load_paddr_r;
    reg [31:0] cmt_load_vaddr_r;
    reg [7:0]  cmt_store_valid_r;
    reg [31:0] cmt_store_paddr_r;
    reg [31:0] cmt_store_vaddr_r;
    reg [31:0] cmt_store_data_r;
    reg [7:0]  pending_load_valid_r [0:1];
    reg [31:0] pending_load_paddr_r [0:1];
    reg [31:0] pending_load_vaddr_r [0:1];
    reg [7:0]  pending_store_valid_r [0:1];
    reg [31:0] pending_store_paddr_r [0:1];
    reg [31:0] pending_store_vaddr_r [0:1];
    reg [31:0] pending_store_data_r [0:1];
    reg [31:0] diff_gpr_r [0:31];
    integer diff_gpr_i;

    always @(*) begin
        cmt_csr_llbctl_next_r = cmt_csr_llbctl_r;

        if (diff_ertn_w) begin
            if (cmt_csr_llbctl_r[2])
                cmt_csr_llbctl_next_r[2] = 1'b0;
            else
                cmt_csr_llbctl_next_r[0] = 1'b0;
        end else if (diff_csr_llbctl_write_w) begin
            cmt_csr_llbctl_next_r[2] = u_biloong.u_core.csr_writeback_wdata_w[2];
            if (u_biloong.u_core.csr_writeback_wdata_w[1])
                cmt_csr_llbctl_next_r[0] = 1'b0;
        end else if (commit0_valid_w && (commit0_exc_w == 6'b0) &&
                     (commit0_is_ll_w || commit0_is_sc_w)) begin
            cmt_csr_llbctl_next_r[0] = commit0_is_ll_w;
        end

`ifdef CPU_2CMT
        if (commit1_valid_w && (commit1_exc_w == 6'b0) &&
            (commit1_is_ll_w || commit1_is_sc_w))
            cmt_csr_llbctl_next_r[0] = commit1_is_ll_w;
`endif
    end

    function [0:0] diff_is_load_inst;
        input [31:0] inst;
        begin
            diff_is_load_inst =
                ((inst[31:26] == 6'h0a) &&
                 ((inst[25:22] == 4'h0) || (inst[25:22] == 4'h1) ||
                  (inst[25:22] == 4'h2) || (inst[25:22] == 4'h8) ||
                  (inst[25:22] == 4'h9))) ||
                ((inst[31:26] == 6'h08) && !inst[25] && !inst[24]);
        end
    endfunction

    function [0:0] diff_is_store_inst;
        input [31:0] inst;
        begin
            diff_is_store_inst =
                ((inst[31:26] == 6'h0a) &&
                 ((inst[25:22] == 4'h4) || (inst[25:22] == 4'h5) ||
                  (inst[25:22] == 4'h6))) ||
                ((inst[31:26] == 6'h08) && !inst[25] && inst[24]);
        end
    endfunction

    always @(posedge aclk) begin
        if (!aresetn) begin
            cmt_valid_r <= 1'b0;
            cmt_pc_r <= 32'h0;
            cmt_instr_r <= 32'h0;
            cmt_wen_r <= 1'b0;
            cmt_wdest_r <= 5'h0;
            cmt_wdata_r <= 32'h0;
            cmt_is_tlbfill_r <= 1'b0;
            cmt_tlbfill_index_r <= 5'h0;
            cmt_is_cntinst_r <= 1'b0;
            cmt_timer64_r <= 64'h0;
            cmt_csr_rstat_r <= 1'b0;
            cmt_csr_data_r <= 32'h0;
`ifdef CPU_2CMT
            cmt1_valid_r <= 1'b0;
            cmt1_pc_r <= 32'h0;
            cmt1_instr_r <= 32'h0;
            cmt1_wen_r <= 1'b0;
            cmt1_wdest_r <= 5'h0;
            cmt1_wdata_r <= 32'h0;
            cmt1_is_tlbfill_r <= 1'b0;
            cmt1_tlbfill_index_r <= 5'h0;
            cmt1_is_cntinst_r <= 1'b0;
            cmt1_timer64_r <= 64'h0;
            cmt1_csr_rstat_r <= 1'b0;
            cmt1_csr_data_r <= 32'h0;
            cmt1_load_valid_r <= 8'h0;
            cmt1_load_paddr_r <= 32'h0;
            cmt1_load_vaddr_r <= 32'h0;
            cmt1_store_valid_r <= 8'h0;
            cmt1_store_paddr_r <= 32'h0;
            cmt1_store_vaddr_r <= 32'h0;
            cmt1_store_data_r <= 32'h0;
`endif
            cmt_excp_valid_r <= 1'b0;
            cmt_ertn_r <= 1'b0;
            cmt_intr_no_r <= 11'h0;
            cmt_excp_cause_r <= 6'h0;
            cmt_excp_pc_r <= 32'h0;
            cmt_excp_inst_r <= 32'h0;
            cmt_csr_llbctl_r <= 32'h0;
            cmt_load_valid_r <= 8'h0;
            cmt_load_paddr_r <= 32'h0;
            cmt_load_vaddr_r <= 32'h0;
            cmt_store_valid_r <= 8'h0;
            cmt_store_paddr_r <= 32'h0;
            cmt_store_vaddr_r <= 32'h0;
            cmt_store_data_r <= 32'h0;
            pending_load_valid_r[0] <= 8'h0;
            pending_load_paddr_r[0] <= 32'h0;
            pending_load_vaddr_r[0] <= 32'h0;
            pending_load_valid_r[1] <= 8'h0;
            pending_load_paddr_r[1] <= 32'h0;
            pending_load_vaddr_r[1] <= 32'h0;
            pending_store_valid_r[0] <= 8'h0;
            pending_store_paddr_r[0] <= 32'h0;
            pending_store_vaddr_r[0] <= 32'h0;
            pending_store_data_r[0] <= 32'h0;
            pending_store_valid_r[1] <= 8'h0;
            pending_store_paddr_r[1] <= 32'h0;
            pending_store_vaddr_r[1] <= 32'h0;
            pending_store_data_r[1] <= 32'h0;
            for (diff_gpr_i = 0; diff_gpr_i < 32; diff_gpr_i = diff_gpr_i + 1)
                diff_gpr_r[diff_gpr_i] <= 32'h0;
        end else begin
            if (biloong_load_valid_w != 8'h0) begin
                pending_load_valid_r[biloong_load_index_w] <= biloong_load_valid_w;
                pending_load_paddr_r[biloong_load_index_w] <= biloong_load_paddr_w;
                pending_load_vaddr_r[biloong_load_index_w] <= biloong_load_vaddr_w;
            end
            if (biloong_store_valid_w != 8'h0) begin
                pending_store_valid_r[biloong_store_index_w] <= biloong_store_valid_w;
                pending_store_paddr_r[biloong_store_index_w] <= biloong_store_paddr_w;
                pending_store_vaddr_r[biloong_store_index_w] <= biloong_store_vaddr_w;
                pending_store_data_r[biloong_store_index_w]  <= biloong_store_data_w;
            end

            cmt_valid_r <= diff_commit_valid_w;
            cmt_pc_r <= diff_commit_pc_w;
            cmt_instr_r <= diff_commit_instr_w;
            cmt_wen_r <= diff_commit_wen_w;
            cmt_wdest_r <= diff_commit_wdest_w;
            cmt_wdata_r <= diff_commit_wdata_w;
            cmt_is_tlbfill_r <= diff_commit_is_tlbfill_w;
            cmt_tlbfill_index_r <= diff_commit_tlbfill_index_w;
            cmt_is_cntinst_r <= diff_commit_is_cntinst_w;
            cmt_timer64_r <= diff_commit_timer64_w;
            cmt_csr_rstat_r <= diff_commit_csr_rstat_w;
            cmt_csr_data_r <= diff_commit_csr_data_w;
`ifdef CPU_2CMT
            cmt1_valid_r <= diff_commit1_valid_w;
            cmt1_pc_r <= diff_commit1_pc_w;
            cmt1_instr_r <= diff_commit1_instr_w;
            cmt1_wen_r <= diff_commit1_wen_w;
            cmt1_wdest_r <= diff_commit1_wdest_w;
            cmt1_wdata_r <= diff_commit1_wdata_w;
            cmt1_is_tlbfill_r <= diff_commit1_is_tlbfill_w;
            cmt1_tlbfill_index_r <= diff_commit1_tlbfill_index_w;
            cmt1_is_cntinst_r <= diff_commit1_is_cntinst_w;
            cmt1_timer64_r <= diff_commit1_timer64_w;
            cmt1_csr_rstat_r <= diff_commit1_csr_rstat_w;
            cmt1_csr_data_r <= diff_commit1_csr_data_w;
            cmt1_load_valid_r <= (diff_commit1_valid_w && diff_is_load_inst(diff_commit1_instr_w)) ?
                                 (((biloong_load_valid_w != 8'h0) && biloong_load_index_w) ?
                                  biloong_load_valid_w : pending_load_valid_r[1]) : 8'h0;
            cmt1_load_paddr_r <= ((biloong_load_valid_w != 8'h0) && biloong_load_index_w) ?
                                 biloong_load_paddr_w : pending_load_paddr_r[1];
            cmt1_load_vaddr_r <= ((biloong_load_valid_w != 8'h0) && biloong_load_index_w) ?
                                 biloong_load_vaddr_w : pending_load_vaddr_r[1];
            cmt1_store_valid_r <= (diff_commit1_valid_w && diff_is_store_inst(diff_commit1_instr_w)) ?
                                  (((biloong_store_valid_w != 8'h0) && biloong_store_index_w) ?
                                   biloong_store_valid_w : pending_store_valid_r[1]) : 8'h0;
            cmt1_store_paddr_r <= ((biloong_store_valid_w != 8'h0) && biloong_store_index_w) ?
                                  biloong_store_paddr_w : pending_store_paddr_r[1];
            cmt1_store_vaddr_r <= ((biloong_store_valid_w != 8'h0) && biloong_store_index_w) ?
                                  biloong_store_vaddr_w : pending_store_vaddr_r[1];
            cmt1_store_data_r <= ((biloong_store_valid_w != 8'h0) && biloong_store_index_w) ?
                                 biloong_store_data_w : pending_store_data_r[1];

            if (diff_commit1_valid_w && diff_is_load_inst(diff_commit1_instr_w))
                pending_load_valid_r[1] <= 8'h0;
            if (diff_commit1_valid_w && diff_is_store_inst(diff_commit1_instr_w))
                pending_store_valid_r[1] <= 8'h0;
`endif
            cmt_excp_valid_r <= diff_excp_valid_w;
            cmt_ertn_r <= diff_ertn_w;
            cmt_intr_no_r <= diff_intr_no_w;
            cmt_excp_cause_r <= diff_excp_cause_w;
            cmt_excp_pc_r <= diff_excp_pc_w;
            cmt_excp_inst_r <= diff_excp_instr_w;
            cmt_csr_llbctl_r <= cmt_csr_llbctl_next_r;
            cmt_load_valid_r <= (diff_commit_valid_w && diff_is_load_inst(diff_commit_instr_w)) ?
                                (((biloong_load_valid_w != 8'h0) && !biloong_load_index_w) ?
                                 biloong_load_valid_w : pending_load_valid_r[0]) : 8'h0;
            cmt_load_paddr_r <= ((biloong_load_valid_w != 8'h0) && !biloong_load_index_w) ?
                                biloong_load_paddr_w : pending_load_paddr_r[0];
            cmt_load_vaddr_r <= ((biloong_load_valid_w != 8'h0) && !biloong_load_index_w) ?
                                biloong_load_vaddr_w : pending_load_vaddr_r[0];
            cmt_store_valid_r <= (diff_commit_valid_w && diff_is_store_inst(diff_commit_instr_w)) ?
                                 (((biloong_store_valid_w != 8'h0) && !biloong_store_index_w) ?
                                  biloong_store_valid_w : pending_store_valid_r[0]) : 8'h0;
            cmt_store_paddr_r <= ((biloong_store_valid_w != 8'h0) && !biloong_store_index_w) ?
                                 biloong_store_paddr_w : pending_store_paddr_r[0];
            cmt_store_vaddr_r <= ((biloong_store_valid_w != 8'h0) && !biloong_store_index_w) ?
                                 biloong_store_vaddr_w : pending_store_vaddr_r[0];
            cmt_store_data_r <= ((biloong_store_valid_w != 8'h0) && !biloong_store_index_w) ?
                                biloong_store_data_w : pending_store_data_r[0];

            if (diff_commit_valid_w && diff_is_load_inst(diff_commit_instr_w))
                pending_load_valid_r[0] <= 8'h0;
            if (diff_commit_valid_w && diff_is_store_inst(diff_commit_instr_w))
                pending_store_valid_r[0] <= 8'h0;

            if (diff_commit_valid_w && diff_commit_wen_w && (diff_commit_wdest_w != 5'd0))
                diff_gpr_r[diff_commit_wdest_w] <= diff_commit_wdata_w;
`ifdef CPU_2CMT
            if (diff_commit1_valid_w && diff_commit1_wen_w && (diff_commit1_wdest_w != 5'd0))
                diff_gpr_r[diff_commit1_wdest_w] <= diff_commit1_wdata_w;
`endif
            diff_gpr_r[0] <= 32'h0;
        end
    end

    DifftestInstrCommit u_difftest_instr_commit (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd0),
        .valid          (cmt_valid_r),
        .pc             ({32'h0, cmt_pc_r}),
        .instr          (cmt_instr_r),
        .skip           (1'b0),
        .is_TLBFILL     (cmt_is_tlbfill_r),
        .TLBFILL_index  (cmt_tlbfill_index_r),
        .is_CNTinst     (cmt_is_cntinst_r),
        .timer_64_value (cmt_timer64_r),
        .wen            (cmt_wen_r),
        .wdest          ({3'h0, cmt_wdest_r}),
        .wdata          ({32'h0, cmt_wdata_r}),
        .csr_rstat      (cmt_csr_rstat_r),
        .csr_data       (cmt_csr_data_r)
    );

`ifdef CPU_2CMT
    DifftestInstrCommit u_difftest_instr_commit1 (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd1),
        .valid          (cmt1_valid_r),
        .pc             ({32'h0, cmt1_pc_r}),
        .instr          (cmt1_instr_r),
        .skip           (1'b0),
        .is_TLBFILL     (cmt1_is_tlbfill_r),
        .TLBFILL_index  (cmt1_tlbfill_index_r),
        .is_CNTinst     (cmt1_is_cntinst_r),
        .timer_64_value (cmt1_timer64_r),
        .wen            (cmt1_wen_r),
        .wdest          ({3'h0, cmt1_wdest_r}),
        .wdata          ({32'h0, cmt1_wdata_r}),
        .csr_rstat      (cmt1_csr_rstat_r),
        .csr_data       (cmt1_csr_data_r)
    );
`endif

    DifftestExcpEvent u_difftest_excp_event (
        .clock          (aclk),
        .coreid         (8'd0),
        .excp_valid     (cmt_excp_valid_r),
        .eret           (cmt_ertn_r),
        .intrNo         ({21'h0, cmt_intr_no_r}),
        .cause          ({26'h0, cmt_excp_cause_r}),
        .exceptionPC    ({32'h0, cmt_excp_pc_r}),
        .exceptionInst  (cmt_excp_inst_r)
    );

    DifftestTrapEvent u_difftest_trap_event (
        .clock          (aclk),
        .coreid         (8'd0),
        .valid          (1'b0),
        .code           (3'd0),
        .pc             ({32'h0, cmt_pc_r}),
        .cycleCnt       (64'h0),
        .instrCnt       (64'h0)
    );

    DifftestStoreEvent u_difftest_store_event (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd0),
        .valid          (cmt_store_valid_r),
        .storePAddr     ({32'h0, cmt_store_paddr_r}),
        .storeVAddr     ({32'h0, cmt_store_vaddr_r}),
        .storeData      ({32'h0, cmt_store_data_r})
    );

    DifftestLoadEvent u_difftest_load_event (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd0),
        .valid          (cmt_load_valid_r),
        .paddr          ({32'h0, cmt_load_paddr_r}),
        .vaddr          ({32'h0, cmt_load_vaddr_r})
    );

`ifdef CPU_2CMT
    DifftestStoreEvent u_difftest_store_event1 (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd1),
        .valid          (cmt1_store_valid_r),
        .storePAddr     ({32'h0, cmt1_store_paddr_r}),
        .storeVAddr     ({32'h0, cmt1_store_vaddr_r}),
        .storeData      ({32'h0, cmt1_store_data_r})
    );

    DifftestLoadEvent u_difftest_load_event1 (
        .clock          (aclk),
        .coreid         (8'd0),
        .index          (8'd1),
        .valid          (cmt1_load_valid_r),
        .paddr          ({32'h0, cmt1_load_paddr_r}),
        .vaddr          ({32'h0, cmt1_load_vaddr_r})
    );
`endif

    DifftestCSRRegState u_difftest_csr_state (
        .clock          (aclk),
        .coreid         (8'd0),
        .crmd           ({32'h0, diff_csr_crmd_w}),
        .prmd           ({32'h0, diff_csr_prmd_w}),
        .euen           (64'h0),
        .ecfg           ({32'h0, diff_csr_ecfg_w}),
        .estat          ({32'h0, diff_csr_estat_w}),
        .era            ({32'h0, diff_csr_era_w}),
        .badv           ({32'h0, diff_csr_badv_w}),
        .eentry         ({32'h0, diff_csr_eentry_w}),
        .tlbidx         ({32'h0, diff_csr_tlbidx_w}),
        .tlbehi         ({32'h0, diff_csr_tlbehi_w}),
        .tlbelo0        ({32'h0, diff_csr_tlbelo0_w}),
        .tlbelo1        ({32'h0, diff_csr_tlbelo1_w}),
        .asid           ({32'h0, diff_csr_asid_w}),
        .pgdl           ({32'h0, diff_csr_pgdl_w}),
        .pgdh           ({32'h0, diff_csr_pgdh_w}),
        .save0          ({32'h0, diff_csr_save0_w}),
        .save1          ({32'h0, diff_csr_save1_w}),
        .save2          ({32'h0, diff_csr_save2_w}),
        .save3          ({32'h0, diff_csr_save3_w}),
        .tid            ({32'h0, diff_csr_tid_w}),
        .tcfg           ({32'h0, diff_csr_tcfg_w}),
        .tval           ({32'h0, diff_csr_tval_w}),
        .ticlr          (64'h0),
        .llbctl         ({32'h0, cmt_csr_llbctl_r}),
        .tlbrentry      ({32'h0, diff_csr_tlbrentry_w}),
        .dmw0           ({32'h0, diff_csr_dmw0_w}),
        .dmw1           ({32'h0, diff_csr_dmw1_w})
    );

    DifftestGRegState u_difftest_gpr_state (
        .clock  (aclk),
        .coreid (8'd0),
        .gpr_0  ({32'h0, diff_gpr_r[ 0]}),
        .gpr_1  ({32'h0, diff_gpr_r[ 1]}),
        .gpr_2  ({32'h0, diff_gpr_r[ 2]}),
        .gpr_3  ({32'h0, diff_gpr_r[ 3]}),
        .gpr_4  ({32'h0, diff_gpr_r[ 4]}),
        .gpr_5  ({32'h0, diff_gpr_r[ 5]}),
        .gpr_6  ({32'h0, diff_gpr_r[ 6]}),
        .gpr_7  ({32'h0, diff_gpr_r[ 7]}),
        .gpr_8  ({32'h0, diff_gpr_r[ 8]}),
        .gpr_9  ({32'h0, diff_gpr_r[ 9]}),
        .gpr_10 ({32'h0, diff_gpr_r[10]}),
        .gpr_11 ({32'h0, diff_gpr_r[11]}),
        .gpr_12 ({32'h0, diff_gpr_r[12]}),
        .gpr_13 ({32'h0, diff_gpr_r[13]}),
        .gpr_14 ({32'h0, diff_gpr_r[14]}),
        .gpr_15 ({32'h0, diff_gpr_r[15]}),
        .gpr_16 ({32'h0, diff_gpr_r[16]}),
        .gpr_17 ({32'h0, diff_gpr_r[17]}),
        .gpr_18 ({32'h0, diff_gpr_r[18]}),
        .gpr_19 ({32'h0, diff_gpr_r[19]}),
        .gpr_20 ({32'h0, diff_gpr_r[20]}),
        .gpr_21 ({32'h0, diff_gpr_r[21]}),
        .gpr_22 ({32'h0, diff_gpr_r[22]}),
        .gpr_23 ({32'h0, diff_gpr_r[23]}),
        .gpr_24 ({32'h0, diff_gpr_r[24]}),
        .gpr_25 ({32'h0, diff_gpr_r[25]}),
        .gpr_26 ({32'h0, diff_gpr_r[26]}),
        .gpr_27 ({32'h0, diff_gpr_r[27]}),
        .gpr_28 ({32'h0, diff_gpr_r[28]}),
        .gpr_29 ({32'h0, diff_gpr_r[29]}),
        .gpr_30 ({32'h0, diff_gpr_r[30]}),
        .gpr_31 ({32'h0, diff_gpr_r[31]})
    );
`endif

    wire unused_inputs = break_point | infor_flag | (|reg_num) |
                         i_axi_awvalid_w | i_axi_bready_w | (|i_axi_awaddr_w) |
                         (|i_axi_awid_w) | (|i_axi_awlen_w) | (|i_axi_awsize_w) |
                         (|i_axi_awburst_w) | i_axi_wvalid_w | (|i_axi_wdata_w) |
                         (|i_axi_wstrb_w) | i_axi_wlast_w | (|bid) | (|rresp);
    wire unused_params = (TLBNUM != 0) | (CORE_SLOT1_ALU_ENABLE != 0) |
                         (CORE_SLOT1_BRANCH_ENABLE != 0) |
                         (CORE_SLOT1_MUL_ENABLE != 0) |
                         (CORE_SLOT1_LOAD_ENABLE != 0) |
                         (CORE_SLOT1_STORE_ENABLE != 0);

endmodule
