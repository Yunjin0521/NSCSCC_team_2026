//-----------------------------------------------------------------
//                         biRISC-V CPU
//                            V0.6.0
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

module dcache
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  mem_addr_i
    ,input  [ 31:0]  mem_lookup_addr_i
    ,input  [ 31:0]  mem_data_wr_i
    ,input           mem_rd_i
    ,input  [  3:0]  mem_wr_i
    ,input  [  1:0]  mem_size_i
    ,input           mem_cacheable_i
    ,input  [ 10:0]  mem_req_tag_i
    ,input           mem_invalidate_i
    ,input           mem_writeback_i
    ,input           mem_flush_i
    ,input           axi_awready_i
    ,input           axi_wready_i
    ,input           axi_bvalid_i
    ,input  [  1:0]  axi_bresp_i
    ,input  [  3:0]  axi_bid_i
    ,input           axi_arready_i
    ,input           axi_rvalid_i
    ,input  [ 31:0]  axi_rdata_i
    ,input  [  1:0]  axi_rresp_i
    ,input  [  3:0]  axi_rid_i
    ,input           axi_rlast_i

    // Outputs
    ,output [ 31:0]  mem_data_rd_o
    ,output          mem_accept_o
    ,output          mem_ack_o
    ,output          mem_error_o
    ,output [ 10:0]  mem_resp_tag_o
    ,output          axi_awvalid_o
    ,output [ 31:0]  axi_awaddr_o
    ,output [  3:0]  axi_awid_o
    ,output [  7:0]  axi_awlen_o
    ,output [  2:0]  axi_awsize_o
    ,output [  1:0]  axi_awburst_o
    ,output          axi_wvalid_o
    ,output [ 31:0]  axi_wdata_o
    ,output [  3:0]  axi_wstrb_o
    ,output          axi_wlast_o
    ,output          axi_bready_o
    ,output          axi_arvalid_o
    ,output [ 31:0]  axi_araddr_o
    ,output [  3:0]  axi_arid_o
    ,output [  7:0]  axi_arlen_o
    ,output [  2:0]  axi_arsize_o
    ,output [  1:0]  axi_arburst_o
    ,output          axi_rready_o
    ,output          axi_wr_pending0_o
    ,output [ 31:0]  axi_wr_pending0_addr_o
    ,output          axi_wr_pending1_o
    ,output [ 31:0]  axi_wr_pending1_addr_o
`ifdef PERF_DC
    ,output          perf_access_o
    ,output          perf_read_o
    ,output          perf_write_o
    ,output          perf_hit_o
    ,output          perf_miss_o
    ,output          perf_refill_o
    ,output          perf_evict_o
`endif
`ifdef PERF_MONI
    ,output          perf_miss_busy_o
`endif
);

wire           mem_uncached_invalidate_w;
wire  [  1:0]  mem_uncached_size_w;
wire  [  1:0]  pmem_size_w;
wire  [  1:0]  pmem_axi_size_w;
wire           pmem_cache_accept_w;
wire           mem_uncached_accept_w;
wire  [  7:0]  pmem_cache_len_w;
wire  [  3:0]  mem_cached_wr_w;
wire  [ 31:0]  pmem_cache_read_data_w;
wire           mem_cached_invalidate_w;
wire           pmem_uncached_ack_w;
wire  [  7:0]  pmem_len_w;
wire  [  1:0]  pmem_uncached_size_w;
wire           pmem_uncached_accept_w;
wire           mem_cached_accept_w;
wire           pmem_cache_ack_w;
wire  [ 31:0]  pmem_cache_addr_w;
wire           pmem_cache_rd_w;
wire           pmem_error_w;
wire  [ 31:0]  pmem_addr_w;
wire  [ 10:0]  mem_cached_req_tag_w;
wire           mem_uncached_ack_w;
wire           pmem_ack_w;
wire  [ 31:0]  mem_uncached_data_wr_w;
wire  [ 31:0]  pmem_uncached_addr_w;
wire  [ 31:0]  mem_cached_data_rd_w;
wire  [ 31:0]  pmem_uncached_read_data_w;
wire           mem_uncached_flush_w;
wire           pmem_uncached_error_w;
wire  [ 31:0]  mem_uncached_data_rd_w;
wire  [ 31:0]  pmem_write_data_w;
wire  [  3:0]  pmem_uncached_wr_w;
wire           mem_cached_rd_w;
wire  [ 10:0]  mem_cached_resp_tag_w;
wire  [  7:0]  pmem_uncached_len_w;
wire  [ 31:0]  mem_cached_data_wr_w;
wire  [  3:0]  pmem_wr_w;
wire           pmem_select_w;
wire           mem_cached_flush_w;
wire           mem_uncached_cacheable_w;
wire  [ 31:0]  mem_cached_addr_w;
wire           mem_uncached_writeback_w;
wire  [  3:0]  pmem_cache_wr_w;
wire           pmem_cache_error_w;
wire  [ 10:0]  mem_uncached_req_tag_w;
wire  [ 31:0]  pmem_uncached_write_data_w;
wire  [ 10:0]  mem_uncached_resp_tag_w;
wire           pmem_rd_w;
wire           mem_cached_cacheable_w;
wire  [  3:0]  mem_uncached_wr_w;
wire           mem_uncached_error_w;
wire           mem_uncached_rd_w;
wire           pmem_accept_w;
wire  [ 31:0]  pmem_cache_write_data_w;
wire           mem_cached_error_w;
wire  [ 31:0]  mem_uncached_addr_w;
wire           pmem_uncached_rd_w;
wire  [ 31:0]  pmem_read_data_w;
wire           mem_cached_ack_w;
wire           mem_cached_writeback_w;
wire  [ 31:0]  mem_cached_lookup_addr_w;
wire           pmem_axi_accept_w;
wire           pmem_req_valid_w;
wire           pmem_req_push_w;
wire           pmem_req_pop_w;
wire  [  3:0]  pmem_axi_wr_w;
wire           pmem_axi_rd_w;
wire  [  7:0]  pmem_axi_len_w;
wire  [ 31:0]  pmem_axi_addr_w;
wire  [ 31:0]  pmem_axi_write_data_w;

reg            pmem_req_valid_q;
reg   [  3:0]  pmem_req_wr_q;
reg            pmem_req_rd_q;
reg   [  1:0]  pmem_req_size_q;
reg   [  7:0]  pmem_req_len_q;
reg   [ 31:0]  pmem_req_addr_q;
reg   [ 31:0]  pmem_req_write_data_q;


dcache_if_pmem
u_uncached
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(mem_uncached_addr_w)
    ,.mem_data_wr_i(mem_uncached_data_wr_w)
    ,.mem_rd_i(mem_uncached_rd_w)
    ,.mem_wr_i(mem_uncached_wr_w)
    ,.mem_size_i(mem_uncached_size_w)
    ,.mem_cacheable_i(mem_uncached_cacheable_w)
    ,.mem_req_tag_i(mem_uncached_req_tag_w)
    ,.mem_invalidate_i(mem_uncached_invalidate_w)
    ,.mem_writeback_i(mem_uncached_writeback_w)
    ,.mem_flush_i(mem_uncached_flush_w)
    ,.outport_accept_i(pmem_uncached_accept_w)
    ,.outport_ack_i(pmem_uncached_ack_w)
    ,.outport_error_i(pmem_uncached_error_w)
    ,.outport_read_data_i(pmem_uncached_read_data_w)

    // Outputs
    ,.mem_data_rd_o(mem_uncached_data_rd_w)
    ,.mem_accept_o(mem_uncached_accept_w)
    ,.mem_ack_o(mem_uncached_ack_w)
    ,.mem_error_o(mem_uncached_error_w)
    ,.mem_resp_tag_o(mem_uncached_resp_tag_w)
    ,.outport_wr_o(pmem_uncached_wr_w)
    ,.outport_rd_o(pmem_uncached_rd_w)
    ,.outport_len_o(pmem_uncached_len_w)
    ,.outport_size_o(pmem_uncached_size_w)
    ,.outport_addr_o(pmem_uncached_addr_w)
    ,.outport_write_data_o(pmem_uncached_write_data_w)
);


dcache_pmem_mux
u_pmem_mux
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.outport_accept_i(pmem_accept_w)
    ,.outport_ack_i(pmem_ack_w)
    ,.outport_error_i(pmem_error_w)
    ,.outport_read_data_i(pmem_read_data_w)
    ,.select_i(pmem_select_w)
    ,.inport0_wr_i(pmem_uncached_wr_w)
    ,.inport0_rd_i(pmem_uncached_rd_w)
    ,.inport0_len_i(pmem_uncached_len_w)
    ,.inport0_size_i(pmem_uncached_size_w)
    ,.inport0_addr_i(pmem_uncached_addr_w)
    ,.inport0_write_data_i(pmem_uncached_write_data_w)
    ,.inport1_wr_i(pmem_cache_wr_w)
    ,.inport1_rd_i(pmem_cache_rd_w)
    ,.inport1_len_i(pmem_cache_len_w)
    ,.inport1_size_i(2'b10)
    ,.inport1_addr_i(pmem_cache_addr_w)
    ,.inport1_write_data_i(pmem_cache_write_data_w)

    // Outputs
    ,.outport_wr_o(pmem_wr_w)
    ,.outport_rd_o(pmem_rd_w)
    ,.outport_len_o(pmem_len_w)
    ,.outport_size_o(pmem_size_w)
    ,.outport_addr_o(pmem_addr_w)
    ,.outport_write_data_o(pmem_write_data_w)
    ,.inport0_accept_o(pmem_uncached_accept_w)
    ,.inport0_ack_o(pmem_uncached_ack_w)
    ,.inport0_error_o(pmem_uncached_error_w)
    ,.inport0_read_data_o(pmem_uncached_read_data_w)
    ,.inport1_accept_o(pmem_cache_accept_w)
    ,.inport1_ack_o(pmem_cache_ack_w)
    ,.inport1_error_o(pmem_cache_error_w)
    ,.inport1_read_data_o(pmem_cache_read_data_w)
);


dcache_mux
u_mux
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(mem_addr_i)
    ,.mem_lookup_addr_i(mem_lookup_addr_i)
    ,.mem_data_wr_i(mem_data_wr_i)
    ,.mem_rd_i(mem_rd_i)
    ,.mem_wr_i(mem_wr_i)
    ,.mem_size_i(mem_size_i)
    ,.mem_cacheable_i(mem_cacheable_i)
    ,.mem_req_tag_i(mem_req_tag_i)
    ,.mem_invalidate_i(mem_invalidate_i)
    ,.mem_writeback_i(mem_writeback_i)
    ,.mem_flush_i(mem_flush_i)
    ,.mem_cached_data_rd_i(mem_cached_data_rd_w)
    ,.mem_cached_accept_i(mem_cached_accept_w)
    ,.mem_cached_ack_i(mem_cached_ack_w)
    ,.mem_cached_error_i(mem_cached_error_w)
    ,.mem_cached_resp_tag_i(mem_cached_resp_tag_w)
    ,.mem_uncached_data_rd_i(mem_uncached_data_rd_w)
    ,.mem_uncached_accept_i(mem_uncached_accept_w)
    ,.mem_uncached_ack_i(mem_uncached_ack_w)
    ,.mem_uncached_error_i(mem_uncached_error_w)
    ,.mem_uncached_resp_tag_i(mem_uncached_resp_tag_w)

    // Outputs
    ,.mem_data_rd_o(mem_data_rd_o)
    ,.mem_accept_o(mem_accept_o)
    ,.mem_ack_o(mem_ack_o)
    ,.mem_error_o(mem_error_o)
    ,.mem_resp_tag_o(mem_resp_tag_o)
    ,.mem_cached_addr_o(mem_cached_addr_w)
    ,.mem_cached_lookup_addr_o(mem_cached_lookup_addr_w)
    ,.mem_cached_data_wr_o(mem_cached_data_wr_w)
    ,.mem_cached_rd_o(mem_cached_rd_w)
    ,.mem_cached_wr_o(mem_cached_wr_w)
    ,.mem_cached_cacheable_o(mem_cached_cacheable_w)
    ,.mem_cached_req_tag_o(mem_cached_req_tag_w)
    ,.mem_cached_invalidate_o(mem_cached_invalidate_w)
    ,.mem_cached_writeback_o(mem_cached_writeback_w)
    ,.mem_cached_flush_o(mem_cached_flush_w)
    ,.mem_uncached_addr_o(mem_uncached_addr_w)
    ,.mem_uncached_data_wr_o(mem_uncached_data_wr_w)
    ,.mem_uncached_rd_o(mem_uncached_rd_w)
    ,.mem_uncached_wr_o(mem_uncached_wr_w)
    ,.mem_uncached_size_o(mem_uncached_size_w)
    ,.mem_uncached_cacheable_o(mem_uncached_cacheable_w)
    ,.mem_uncached_req_tag_o(mem_uncached_req_tag_w)
    ,.mem_uncached_invalidate_o(mem_uncached_invalidate_w)
    ,.mem_uncached_writeback_o(mem_uncached_writeback_w)
    ,.mem_uncached_flush_o(mem_uncached_flush_w)
    ,.cache_active_o(pmem_select_w)
);


dcache_core
u_core
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(mem_cached_addr_w)
    ,.mem_lookup_addr_i(mem_cached_lookup_addr_w)
    ,.mem_data_wr_i(mem_cached_data_wr_w)
    ,.mem_rd_i(mem_cached_rd_w)
    ,.mem_wr_i(mem_cached_wr_w)
    ,.mem_cacheable_i(mem_cached_cacheable_w)
    ,.mem_req_tag_i(mem_cached_req_tag_w)
    ,.mem_invalidate_i(mem_cached_invalidate_w)
    ,.mem_writeback_i(mem_cached_writeback_w)
    ,.mem_flush_i(mem_cached_flush_w)
    ,.outport_accept_i(pmem_cache_accept_w)
    ,.outport_ack_i(pmem_cache_ack_w)
    ,.outport_error_i(pmem_cache_error_w)
    ,.outport_read_data_i(pmem_cache_read_data_w)

    // Outputs
    ,.mem_data_rd_o(mem_cached_data_rd_w)
    ,.mem_accept_o(mem_cached_accept_w)
    ,.mem_ack_o(mem_cached_ack_w)
    ,.mem_error_o(mem_cached_error_w)
    ,.mem_resp_tag_o(mem_cached_resp_tag_w)
    ,.outport_wr_o(pmem_cache_wr_w)
    ,.outport_rd_o(pmem_cache_rd_w)
    ,.outport_len_o(pmem_cache_len_w)
    ,.outport_addr_o(pmem_cache_addr_w)
    ,.outport_write_data_o(pmem_cache_write_data_w)
`ifdef PERF_DC
    ,.perf_access_o(perf_access_o)
    ,.perf_read_o(perf_read_o)
    ,.perf_write_o(perf_write_o)
    ,.perf_hit_o(perf_hit_o)
    ,.perf_miss_o(perf_miss_o)
    ,.perf_refill_o(perf_refill_o)
    ,.perf_evict_o(perf_evict_o)
`endif
`ifdef PERF_MONI
    ,.perf_miss_busy_o(perf_miss_busy_o)
`endif
);

//-----------------------------------------------------------------
// Registered PMEM request boundary
//-----------------------------------------------------------------
assign pmem_req_valid_w = pmem_rd_w || (pmem_wr_w != 4'b0);
assign pmem_req_pop_w   = pmem_req_valid_q && pmem_axi_accept_w;
assign pmem_accept_w    = !pmem_req_valid_q || pmem_axi_accept_w;
assign pmem_req_push_w  = pmem_req_valid_w && pmem_accept_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pmem_req_valid_q <= 1'b0;
else if (pmem_req_push_w)
    pmem_req_valid_q <= 1'b1;
else if (pmem_req_pop_w)
    pmem_req_valid_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    pmem_req_wr_q         <= 4'b0;
    pmem_req_rd_q         <= 1'b0;
    pmem_req_size_q       <= 2'b10;
    pmem_req_len_q        <= 8'b0;
    pmem_req_addr_q       <= 32'b0;
    pmem_req_write_data_q <= 32'b0;
end
else if (pmem_req_push_w)
begin
    pmem_req_wr_q         <= pmem_wr_w;
    pmem_req_rd_q         <= pmem_rd_w;
    pmem_req_size_q       <= pmem_size_w;
    pmem_req_len_q        <= pmem_len_w;
    pmem_req_addr_q       <= pmem_addr_w;
    pmem_req_write_data_q <= pmem_write_data_w;
end

assign pmem_axi_wr_w         = pmem_req_valid_q ? pmem_req_wr_q         : 4'b0;
assign pmem_axi_rd_w         = pmem_req_valid_q ? pmem_req_rd_q         : 1'b0;
assign pmem_axi_size_w       = pmem_req_valid_q ? pmem_req_size_q       : 2'b10;
assign pmem_axi_len_w        = pmem_req_valid_q ? pmem_req_len_q        : 8'b0;
assign pmem_axi_addr_w       = pmem_req_valid_q ? pmem_req_addr_q       : 32'b0;
assign pmem_axi_write_data_w = pmem_req_valid_q ? pmem_req_write_data_q : 32'b0;


dcache_axi
#(
     .AXI_ID(AXI_ID)
)
u_axi
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.outport_awready_i(axi_awready_i)
    ,.outport_wready_i(axi_wready_i)
    ,.outport_bvalid_i(axi_bvalid_i)
    ,.outport_bresp_i(axi_bresp_i)
    ,.outport_bid_i(axi_bid_i)
    ,.outport_arready_i(axi_arready_i)
    ,.outport_rvalid_i(axi_rvalid_i)
    ,.outport_rdata_i(axi_rdata_i)
    ,.outport_rresp_i(axi_rresp_i)
    ,.outport_rid_i(axi_rid_i)
    ,.outport_rlast_i(axi_rlast_i)
    ,.inport_wr_i(pmem_axi_wr_w)
    ,.inport_rd_i(pmem_axi_rd_w)
    ,.inport_len_i(pmem_axi_len_w)
    ,.inport_size_i(pmem_axi_size_w)
    ,.inport_addr_i(pmem_axi_addr_w)
    ,.inport_write_data_i(pmem_axi_write_data_w)

    // Outputs
    ,.outport_awvalid_o(axi_awvalid_o)
    ,.outport_awaddr_o(axi_awaddr_o)
    ,.outport_awid_o(axi_awid_o)
    ,.outport_awlen_o(axi_awlen_o)
    ,.outport_awsize_o(axi_awsize_o)
    ,.outport_awburst_o(axi_awburst_o)
    ,.outport_wvalid_o(axi_wvalid_o)
    ,.outport_wdata_o(axi_wdata_o)
    ,.outport_wstrb_o(axi_wstrb_o)
    ,.outport_wlast_o(axi_wlast_o)
    ,.outport_bready_o(axi_bready_o)
    ,.outport_arvalid_o(axi_arvalid_o)
    ,.outport_araddr_o(axi_araddr_o)
    ,.outport_arid_o(axi_arid_o)
    ,.outport_arlen_o(axi_arlen_o)
    ,.outport_arsize_o(axi_arsize_o)
    ,.outport_arburst_o(axi_arburst_o)
    ,.outport_rready_o(axi_rready_o)
    ,.outport_wr_pending0_o(axi_wr_pending0_o)
    ,.outport_wr_pending0_addr_o(axi_wr_pending0_addr_o)
    ,.outport_wr_pending1_o(axi_wr_pending1_o)
    ,.outport_wr_pending1_addr_o(axi_wr_pending1_addr_o)
    ,.inport_accept_o(pmem_axi_accept_w)
    ,.inport_ack_o(pmem_ack_w)
    ,.inport_error_o(pmem_error_w)
    ,.inport_read_data_o(pmem_read_data_w)
);



endmodule
