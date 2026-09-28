`timescale 1ns / 1ps
`include "rtl_debug.vh"

// ============================================================================
// AXI arbiter - share one external AXI port between I-cache and D-cache.
//
// Master 0: I-cache, AR/R only
// Master 1: D-cache, AR/R/AW/W/B
//
// The FPGA external path is not trusted to preserve read IDs during bring-up.
// Keep only one read burst outstanding and route R responses to the AR owner.
// Drive external AXI IDs as zero; rd_arid_q keeps the original cache ID.
// ============================================================================
module axi_arbiter #(
    parameter AXI_ID_WIDTH = 4
) (
    input  wire        clk,
    input  wire        rst_n,

    // Master 0 (L2 读通道) - AR/R only
    input  wire        m0_axi_arvalid_i,
    output reg         m0_axi_arready_o,
    input  wire [31:0] m0_axi_araddr_i,
    input  wire [AXI_ID_WIDTH-1:0] m0_axi_arid_i,
    input  wire [7:0]  m0_axi_arlen_i,
    input  wire [2:0]  m0_axi_arsize_i,
    input  wire [1:0]  m0_axi_arburst_i,
    output reg         m0_axi_rvalid_o,
    input  wire        m0_axi_rready_i,
    output reg  [31:0] m0_axi_rdata_o,
    output reg  [1:0]  m0_axi_rresp_o,
    output reg  [AXI_ID_WIDTH-1:0] m0_axi_rid_o,
    output reg         m0_axi_rlast_o,

    // Master 1 (L2 写通道) - AR/R/AW/W/B
    input  wire        m1_axi_arvalid_i,
    output reg         m1_axi_arready_o,
    input  wire [31:0] m1_axi_araddr_i,
    input  wire [AXI_ID_WIDTH-1:0] m1_axi_arid_i,
    input  wire [7:0]  m1_axi_arlen_i,
    input  wire [2:0]  m1_axi_arsize_i,
    input  wire [1:0]  m1_axi_arburst_i,
    output reg         m1_axi_rvalid_o,
    input  wire        m1_axi_rready_i,
    output reg  [31:0] m1_axi_rdata_o,
    output reg  [1:0]  m1_axi_rresp_o,
    output reg  [AXI_ID_WIDTH-1:0] m1_axi_rid_o,
    output reg         m1_axi_rlast_o,
    input  wire        m1_axi_awvalid_i,
    output wire        m1_axi_awready_o,
    input  wire [31:0] m1_axi_awaddr_i,
    input  wire [AXI_ID_WIDTH-1:0] m1_axi_awid_i,
    input  wire [7:0]  m1_axi_awlen_i,
    input  wire [2:0]  m1_axi_awsize_i,
    input  wire [1:0]  m1_axi_awburst_i,
    input  wire        m1_axi_wvalid_i,
    output wire        m1_axi_wready_o,
    input  wire [31:0] m1_axi_wdata_i,
    input  wire [3:0]  m1_axi_wstrb_i,
    input  wire        m1_axi_wlast_i,
    output wire        m1_axi_bvalid_o,
    input  wire        m1_axi_bready_i,
    output wire [1:0]  m1_axi_bresp_o,
    output wire [AXI_ID_WIDTH-1:0] m1_axi_bid_o,
    input  wire        m1_axi_wr_pending0_i,
    input  wire [31:0] m1_axi_wr_pending0_addr_i,
    input  wire        m1_axi_wr_pending1_i,
    input  wire [31:0] m1_axi_wr_pending1_addr_i,

    // Slave (Memory)
    output reg         s_axi_arvalid_o,
    input  wire        s_axi_arready_i,
    output reg  [31:0] s_axi_araddr_o,
    output reg  [AXI_ID_WIDTH-1:0] s_axi_arid_o,
    output reg  [7:0]  s_axi_arlen_o,
    output reg  [2:0]  s_axi_arsize_o,
    output reg  [1:0]  s_axi_arburst_o,
    input  wire        s_axi_rvalid_i,
    output wire        s_axi_rready_o,
    input  wire [31:0] s_axi_rdata_i,
    input  wire [1:0]  s_axi_rresp_i,
    input  wire [AXI_ID_WIDTH-1:0] s_axi_rid_i,
    input  wire        s_axi_rlast_i,
    output wire        s_axi_awvalid_o,
    input  wire        s_axi_awready_i,
    output wire [31:0] s_axi_awaddr_o,
    output wire [AXI_ID_WIDTH-1:0] s_axi_awid_o,
    output wire [7:0]  s_axi_awlen_o,
    output wire [2:0]  s_axi_awsize_o,
    output wire [1:0]  s_axi_awburst_o,
    output wire        s_axi_wvalid_o,
    input  wire        s_axi_wready_i,
    output wire [31:0] s_axi_wdata_o,
    output wire [3:0]  s_axi_wstrb_o,
    output wire        s_axi_wlast_o,
    input  wire        s_axi_bvalid_i,
    output wire        s_axi_bready_o,
    input  wire [1:0]  s_axi_bresp_i,
    input  wire [AXI_ID_WIDTH-1:0] s_axi_bid_i
);

    // Last accepted read master, kept for debug. The real AR arbitration is
    // done by one-entry hold registers so external AXI payloads stay stable
    // while VALID waits for READY.
    reg [1:0] arb_state_q;
    reg       rd_busy_q;
    reg       rd_owner_q; // 1'b0: M0/I-cache, 1'b1: M1/D-cache
    reg [AXI_ID_WIDTH-1:0] rd_arid_q;
    reg       ar_hold_valid_q;
    reg       ar_hold_owner_q;
    reg [AXI_ID_WIDTH-1:0] ar_hold_id_q;
    reg [31:0] ar_hold_addr_q;
    reg [7:0]  ar_hold_len_q;
    reg [2:0]  ar_hold_size_q;
    reg [1:0]  ar_hold_burst_q;
    reg       aw_hold_valid_q;
    reg [AXI_ID_WIDTH-1:0] aw_hold_id_q;
    reg [31:0] aw_hold_addr_q;
    reg [7:0]  aw_hold_len_q;
    reg [2:0]  aw_hold_size_q;
    reg [1:0]  aw_hold_burst_q;
    reg       w_hold_valid_q;
    reg [31:0] w_hold_data_q;
    reg [3:0]  w_hold_strb_q;
    reg       w_hold_last_q;
    reg       wr_busy_q;
    reg       wr_aw_done_q;
    reg       wr_w_done_q;
    reg [AXI_ID_WIDTH-1:0] wr_id_q;

    localparam ARB_IDLE = 2'd0;
    localparam ARB_M0 = 2'd1;
    localparam ARB_M1 = 2'd2;
    localparam AXI_ADDR_CONFLICT_LSB = 5; // 32-byte cache-line granularity
    localparam [AXI_ID_WIDTH-1:0] EXT_AXI_ID_ZERO = {AXI_ID_WIDTH{1'b0}};

    function same_addr_conflict;
        input [31:0] addr_a;
        input [31:0] addr_b;
        begin
            same_addr_conflict =
                (addr_a[31:AXI_ADDR_CONFLICT_LSB] ==
                 addr_b[31:AXI_ADDR_CONFLICT_LSB]);
        end
    endfunction

    wire m0_rid_match_w = s_axi_rid_i == m0_axi_arid_i;
    wire m1_rid_match_w = s_axi_rid_i == m1_axi_arid_i;
    wire write_wait_resp_w = wr_busy_q && wr_aw_done_q && wr_w_done_q;
    // Do not expose a write address to the external fabric until the first
    // write-data beat has also been captured locally.  Reset can still abort a
    // transaction already accepted outside myCPU, but this avoids creating an
    // AW-only external transaction from a partially captured DCache request.
    wire wr_aw_valid_w   = rst_n && aw_hold_valid_q && w_hold_valid_q;
    wire wr_w_valid_w    = rst_n && w_hold_valid_q && wr_aw_done_q;
    wire wr_aw_fire_w    = wr_aw_valid_w && s_axi_awready_i;
    wire wr_w_fire_w     = wr_w_valid_w && s_axi_wready_i;
    wire wr_w_last_fire_w = wr_w_fire_w && w_hold_last_q;
    wire wr_done_w       = rst_n && s_axi_bvalid_i && s_axi_bready_o;

    wire read_req_m1_w   = m1_axi_arvalid_i;
    wire read_req_m0_w   = !m1_axi_arvalid_i && m0_axi_arvalid_i;
    wire read_req_valid_w = read_req_m1_w || read_req_m0_w;
    wire [31:0] read_req_addr_w = read_req_m1_w ? m1_axi_araddr_i :
                                                   m0_axi_araddr_i;

    wire read_pending_w = rd_busy_q || ar_hold_valid_q;
    wire write_addr_known_w = aw_hold_valid_q || wr_aw_done_q;
    wire incoming_aw_start_w = m1_axi_awvalid_i && !wr_aw_done_q &&
                               !aw_hold_valid_q && !write_wait_resp_w;
    wire write_addr_unknown_w = !write_addr_known_w && !m1_axi_awvalid_i &&
                                (wr_busy_q || w_hold_valid_q || m1_axi_wvalid_i);

    wire read_hits_active_write_w =
        read_req_valid_w && write_addr_known_w &&
        same_addr_conflict(read_req_addr_w, aw_hold_addr_q);
    wire read_hits_incoming_write_w =
        read_req_valid_w && incoming_aw_start_w &&
        same_addr_conflict(read_req_addr_w, m1_axi_awaddr_i);
    wire read_hits_pending_write0_w =
        read_req_valid_w && m1_axi_wr_pending0_i &&
        same_addr_conflict(read_req_addr_w, m1_axi_wr_pending0_addr_i);
    wire read_hits_pending_write1_w =
        read_req_valid_w && m1_axi_wr_pending1_i &&
        same_addr_conflict(read_req_addr_w, m1_axi_wr_pending1_addr_i);
    wire read_blocked_by_write_w =
        read_req_valid_w &&
        (write_addr_unknown_w || read_hits_active_write_w ||
         read_hits_incoming_write_w || read_hits_pending_write0_w ||
         read_hits_pending_write1_w);

    wire write_hits_pending_read_w =
        incoming_aw_start_w && read_pending_w &&
        same_addr_conflict(m1_axi_awaddr_i, ar_hold_addr_q);
    wire write_addr_unknown_with_pending_read_w =
        read_pending_w && !write_addr_known_w && !m1_axi_awvalid_i &&
        (wr_busy_q || w_hold_valid_q || m1_axi_wvalid_i);
    wire write_blocked_by_read_w =
        write_hits_pending_read_w || write_addr_unknown_with_pending_read_w;

    wire can_issue_write_w = rst_n && !write_wait_resp_w &&
                             !write_blocked_by_read_w;
    wire can_accept_ar_w = rst_n && !rd_busy_q && !ar_hold_valid_q &&
                           !read_blocked_by_write_w;
    wire aw_capture_w   = can_issue_write_w && !wr_aw_done_q &&
                          !aw_hold_valid_q && m1_axi_awvalid_i;
    wire w_capture_w    = can_issue_write_w && !wr_w_done_q &&
                          !w_hold_valid_q && m1_axi_wvalid_i;
    wire grant_m1_w     = can_accept_ar_w && read_req_m1_w;
    wire grant_m0_w     = can_accept_ar_w && read_req_m0_w;
    wire ar_capture_w   = grant_m0_w || grant_m1_w;
    wire ar_hs_w        = ar_hold_valid_q && s_axi_arready_i;
    wire r_owner_m0_w   = rd_busy_q && !rd_owner_q;
    wire r_owner_m1_w   = rd_busy_q &&  rd_owner_q;
    wire rd_done_w      = rst_n && s_axi_rvalid_i && s_axi_rready_o && s_axi_rlast_i;

    // AR channel: accept one I/D request into a hold register, then present a
    // stable AXI request until the external slave accepts it.
    always @(posedge clk) begin
        if (!rst_n) begin
            arb_state_q     <= ARB_IDLE;
            rd_busy_q       <= 1'b0;
            rd_owner_q      <= 1'b0;
            rd_arid_q       <= {AXI_ID_WIDTH{1'b0}};
            ar_hold_valid_q <= 1'b0;
            ar_hold_owner_q <= 1'b0;
            ar_hold_id_q    <= {AXI_ID_WIDTH{1'b0}};
            ar_hold_addr_q  <= 32'h0;
            ar_hold_len_q   <= 8'h0;
            ar_hold_size_q  <= 3'b010;
            ar_hold_burst_q <= 2'b01;
            aw_hold_valid_q <= 1'b0;
            aw_hold_id_q    <= {AXI_ID_WIDTH{1'b0}};
            aw_hold_addr_q  <= 32'h0;
            aw_hold_len_q   <= 8'h0;
            aw_hold_size_q  <= 3'b010;
            aw_hold_burst_q <= 2'b01;
            w_hold_valid_q  <= 1'b0;
            w_hold_data_q   <= 32'h0;
            w_hold_strb_q   <= 4'h0;
            w_hold_last_q   <= 1'b0;
            wr_busy_q       <= 1'b0;
            wr_aw_done_q    <= 1'b0;
            wr_w_done_q     <= 1'b0;
            wr_id_q         <= {AXI_ID_WIDTH{1'b0}};
        end else begin
            if (rd_done_w)
                rd_busy_q <= 1'b0;

            if (ar_capture_w) begin
                ar_hold_valid_q <= 1'b1;
                ar_hold_owner_q <= grant_m1_w;
                ar_hold_id_q    <= grant_m1_w ? m1_axi_arid_i    : m0_axi_arid_i;
                ar_hold_addr_q  <= grant_m1_w ? m1_axi_araddr_i  : m0_axi_araddr_i;
                ar_hold_len_q   <= grant_m1_w ? m1_axi_arlen_i   : m0_axi_arlen_i;
                ar_hold_size_q  <= grant_m1_w ? m1_axi_arsize_i  : m0_axi_arsize_i;
                ar_hold_burst_q <= grant_m1_w ? m1_axi_arburst_i : m0_axi_arburst_i;
            end

            if (ar_hs_w) begin
                ar_hold_valid_q <= 1'b0;
                arb_state_q     <= ar_hold_owner_q ? ARB_M1 : ARB_M0;
                rd_busy_q       <= 1'b1;
                rd_owner_q      <= ar_hold_owner_q;
                rd_arid_q       <= ar_hold_id_q;
            end

            if (aw_capture_w) begin
                aw_hold_valid_q <= 1'b1;
                aw_hold_id_q    <= m1_axi_awid_i;
                aw_hold_addr_q  <= m1_axi_awaddr_i;
                aw_hold_len_q   <= m1_axi_awlen_i;
                aw_hold_size_q  <= m1_axi_awsize_i;
                aw_hold_burst_q <= m1_axi_awburst_i;
            end
            if (w_capture_w) begin
                w_hold_valid_q <= 1'b1;
                w_hold_data_q  <= m1_axi_wdata_i;
                w_hold_strb_q  <= m1_axi_wstrb_i;
                w_hold_last_q  <= m1_axi_wlast_i;
            end

            if (wr_aw_fire_w) begin
                aw_hold_valid_q <= 1'b0;
                wr_aw_done_q <= 1'b1;
                wr_id_q      <= aw_hold_id_q;
            end
            if (wr_w_fire_w)
                w_hold_valid_q <= 1'b0;
            if (wr_w_last_fire_w)
                wr_w_done_q <= 1'b1;
            if (aw_capture_w || w_capture_w || wr_aw_fire_w || wr_w_fire_w)
                wr_busy_q <= 1'b1;
            if (wr_done_w) begin
                wr_busy_q       <= 1'b0;
                wr_aw_done_q    <= 1'b0;
                wr_w_done_q     <= 1'b0;
                wr_id_q         <= {AXI_ID_WIDTH{1'b0}};
                aw_hold_valid_q <= 1'b0;
                w_hold_valid_q  <= 1'b0;
            end
        end
    end

    // AR mux. DCache gets priority because a D-side miss usually blocks the
    // pipeline; ICache refill can continue after this read returns.
    always @(*) begin
        s_axi_arvalid_o  = rst_n && ar_hold_valid_q;
        s_axi_araddr_o   = ar_hold_addr_q;
        s_axi_arid_o     = EXT_AXI_ID_ZERO;
        s_axi_arlen_o    = ar_hold_len_q;
        s_axi_arsize_o   = ar_hold_size_q;
        s_axi_arburst_o  = ar_hold_burst_q;
        m0_axi_arready_o = grant_m0_w;
        m1_axi_arready_o = grant_m1_w;
    end

    // R 通道路由：按已接受 AR 的 owner 路由，不依赖外部返回 RID。
    assign s_axi_rready_o = rst_n &&
                            (r_owner_m1_w ? m1_axi_rready_i :
                             (r_owner_m0_w ? m0_axi_rready_i : 1'b0));

    always @(*) begin
        if (!rst_n) begin
            m0_axi_rvalid_o = 1'b0;
            m0_axi_rdata_o = 32'h0;
            m0_axi_rresp_o = 2'b0;
            m0_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m0_axi_rlast_o = 1'b0;
            m1_axi_rvalid_o = 1'b0;
            m1_axi_rdata_o = 32'h0;
            m1_axi_rresp_o = 2'b0;
            m1_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m1_axi_rlast_o = 1'b0;
        end else if (r_owner_m0_w) begin
            m0_axi_rvalid_o = s_axi_rvalid_i;
            m0_axi_rdata_o = s_axi_rdata_i;
            m0_axi_rresp_o = s_axi_rresp_i;
            m0_axi_rid_o = rd_arid_q;
            m0_axi_rlast_o = s_axi_rlast_i;
            m1_axi_rvalid_o = 1'b0;
            m1_axi_rdata_o = 32'h0;
            m1_axi_rresp_o = 2'b0;
            m1_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m1_axi_rlast_o = 1'b0;
        end else if (r_owner_m1_w) begin
            m0_axi_rvalid_o = 1'b0;
            m0_axi_rdata_o = 32'h0;
            m0_axi_rresp_o = 2'b0;
            m0_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m0_axi_rlast_o = 1'b0;
            m1_axi_rvalid_o = s_axi_rvalid_i;
            m1_axi_rdata_o = s_axi_rdata_i;
            m1_axi_rresp_o = s_axi_rresp_i;
            m1_axi_rid_o = rd_arid_q;
            m1_axi_rlast_o = s_axi_rlast_i;
        end else begin
            m0_axi_rvalid_o = 1'b0;
            m0_axi_rdata_o = 32'h0;
            m0_axi_rresp_o = 2'b0;
            m0_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m0_axi_rlast_o = 1'b0;
            m1_axi_rvalid_o = 1'b0;
            m1_axi_rdata_o = 32'h0;
            m1_axi_rresp_o = 2'b0;
            m1_axi_rid_o = {AXI_ID_WIDTH{1'b0}};
            m1_axi_rlast_o = 1'b0;
        end
    end

    // AW/W/B channel: only DCache writes. Latch AW/W into local hold
    // registers before driving the external port, so payloads remain stable
    // while waiting for READY. W beats are presented only after AW is
    // accepted by the external slave.
    assign s_axi_awvalid_o = wr_aw_valid_w;
    assign s_axi_awaddr_o  = aw_hold_addr_q;
    assign s_axi_awid_o    = EXT_AXI_ID_ZERO;
    assign s_axi_awlen_o   = aw_hold_len_q;
    assign s_axi_awsize_o  = aw_hold_size_q;
    assign s_axi_awburst_o = aw_hold_burst_q;
    assign m1_axi_awready_o = aw_capture_w;

    assign s_axi_wvalid_o = wr_w_valid_w;
    assign s_axi_wdata_o  = w_hold_data_q;
    assign s_axi_wstrb_o  = w_hold_strb_q;
    assign s_axi_wlast_o  = w_hold_last_q;
    assign m1_axi_wready_o = w_capture_w;

    assign m1_axi_bvalid_o = rst_n && write_wait_resp_w && s_axi_bvalid_i;
    assign m1_axi_bresp_o  = s_axi_bresp_i;
    assign m1_axi_bid_o    = wr_id_q;
    assign s_axi_bready_o  = rst_n && write_wait_resp_w && m1_axi_bready_i;

`ifdef CPU_DEBUG_HAS_RUNTIME
    wire [1:0] dbg_expected_ar_grant =
        grant_m1_w ? ARB_M1 :
        (grant_m0_w ? ARB_M0 : ARB_IDLE);
    wire [1:0] dbg_actual_ar_grant =
        m1_axi_arready_o ? ARB_M1 :
        (m0_axi_arready_o ? ARB_M0 : ARB_IDLE);

    reg        dbg_m0_ar_hold_q;
    reg [31:0] dbg_m0_araddr_q;
    reg [AXI_ID_WIDTH-1:0] dbg_m0_arid_q;
    reg [7:0]  dbg_m0_arlen_q;
    reg [1:0]  dbg_m0_arburst_q;
    reg        dbg_m1_ar_hold_q;
    reg [31:0] dbg_m1_araddr_q;
    reg [AXI_ID_WIDTH-1:0] dbg_m1_arid_q;
    reg [7:0]  dbg_m1_arlen_q;
    reg [1:0]  dbg_m1_arburst_q;
    reg        dbg_m1_aw_hold_q;
    reg [31:0] dbg_m1_awaddr_q;
    reg [AXI_ID_WIDTH-1:0] dbg_m1_awid_q;
    reg [7:0]  dbg_m1_awlen_q;
    reg [1:0]  dbg_m1_awburst_q;
    reg        dbg_m1_w_hold_q;
    reg [31:0] dbg_m1_wdata_q;
    reg [3:0]  dbg_m1_wstrb_q;
    reg        dbg_m1_wlast_q;

    always @(posedge clk) begin
        if (!rst_n) begin
            dbg_m0_ar_hold_q <= 1'b0;
            dbg_m1_ar_hold_q <= 1'b0;
            dbg_m1_aw_hold_q <= 1'b0;
            dbg_m1_w_hold_q  <= 1'b0;
            `CPU_DEBUG($sformatf("[AXI][RESET] expected_state=ARB_IDLE(0) actual_state=%0d", arb_state_q));
        end else begin
            `CPU_ASSERT("AXI_AR_SINGLE_GRANT",
                !(m0_axi_arready_o && m1_axi_arready_o),
                $sformatf("[AXI][ASSERT] both AR masters ready: state=%0d m0_valid=%0d m1_valid=%0d s_ready=%0d",
                          arb_state_q, m0_axi_arvalid_i, m1_axi_arvalid_i, s_axi_arready_i))
            `CPU_ASSERT("AXI_R_SINGLE_ROUTE",
                !(m0_axi_rvalid_o && m1_axi_rvalid_o),
                $sformatf("[AXI][ASSERT] R channel routed to both masters: state=%0d s_rvalid=%0d id=0x%0x",
                          arb_state_q, s_axi_rvalid_i, s_axi_rid_i))
            `CPU_ASSERT("AXI_R_OUTSTANDING",
                !s_axi_rvalid_i || rd_busy_q,
                $sformatf("[AXI][ASSERT] slave R valid without outstanding read: id=0x%0x last=%0d data=0x%08x",
                          s_axi_rid_i, s_axi_rlast_i, s_axi_rdata_i))

            if (dbg_m0_ar_hold_q) begin
                `CPU_ASSERT("AXI_M0_AR_STABLE",
                    !m0_axi_arvalid_i || m0_axi_arready_o ||
                    ((m0_axi_araddr_i == dbg_m0_araddr_q) &&
                     (m0_axi_arid_i == dbg_m0_arid_q) &&
                     (m0_axi_arlen_i == dbg_m0_arlen_q) &&
                     (m0_axi_arburst_i == dbg_m0_arburst_q)),
                    $sformatf("[AXI][ASSERT] M0 AR changed while stalled: prev(addr=0x%08x id=0x%0x len=%0d burst=%0d) now(addr=0x%08x id=0x%0x len=%0d burst=%0d)",
                              dbg_m0_araddr_q, dbg_m0_arid_q, dbg_m0_arlen_q, dbg_m0_arburst_q,
                              m0_axi_araddr_i, m0_axi_arid_i, m0_axi_arlen_i, m0_axi_arburst_i))
            end
            if (dbg_m1_ar_hold_q) begin
                `CPU_ASSERT("AXI_M1_AR_STABLE",
                    !m1_axi_arvalid_i || m1_axi_arready_o ||
                    ((m1_axi_araddr_i == dbg_m1_araddr_q) &&
                     (m1_axi_arid_i == dbg_m1_arid_q) &&
                     (m1_axi_arlen_i == dbg_m1_arlen_q) &&
                     (m1_axi_arburst_i == dbg_m1_arburst_q)),
                    $sformatf("[AXI][ASSERT] M1 AR changed while stalled: prev(addr=0x%08x id=0x%0x len=%0d burst=%0d) now(addr=0x%08x id=0x%0x len=%0d burst=%0d)",
                              dbg_m1_araddr_q, dbg_m1_arid_q, dbg_m1_arlen_q, dbg_m1_arburst_q,
                              m1_axi_araddr_i, m1_axi_arid_i, m1_axi_arlen_i, m1_axi_arburst_i))
            end
            if (dbg_m1_aw_hold_q) begin
                `CPU_ASSERT("AXI_M1_AW_STABLE",
                    !m1_axi_awvalid_i || m1_axi_awready_o ||
                    ((m1_axi_awaddr_i == dbg_m1_awaddr_q) &&
                     (m1_axi_awid_i == dbg_m1_awid_q) &&
                     (m1_axi_awlen_i == dbg_m1_awlen_q) &&
                     (m1_axi_awburst_i == dbg_m1_awburst_q)),
                    $sformatf("[AXI][ASSERT] M1 AW changed while stalled: prev(addr=0x%08x id=0x%0x len=%0d burst=%0d) now(addr=0x%08x id=0x%0x len=%0d burst=%0d)",
                              dbg_m1_awaddr_q, dbg_m1_awid_q, dbg_m1_awlen_q, dbg_m1_awburst_q,
                              m1_axi_awaddr_i, m1_axi_awid_i, m1_axi_awlen_i, m1_axi_awburst_i))
            end
            if (dbg_m1_w_hold_q) begin
                `CPU_ASSERT("AXI_M1_W_STABLE",
                    !m1_axi_wvalid_i || m1_axi_wready_o ||
                    ((m1_axi_wdata_i == dbg_m1_wdata_q) &&
                     (m1_axi_wstrb_i == dbg_m1_wstrb_q) &&
                     (m1_axi_wlast_i == dbg_m1_wlast_q)),
                    $sformatf("[AXI][ASSERT] M1 W changed while stalled: prev(data=0x%08x strb=0x%0x last=%0d) now(data=0x%08x strb=0x%0x last=%0d)",
                              dbg_m1_wdata_q, dbg_m1_wstrb_q, dbg_m1_wlast_q,
                              m1_axi_wdata_i, m1_axi_wstrb_i, m1_axi_wlast_i))
            end

            dbg_m0_ar_hold_q <= m0_axi_arvalid_i && !m0_axi_arready_o;
            dbg_m0_araddr_q  <= m0_axi_araddr_i;
            dbg_m0_arid_q    <= m0_axi_arid_i;
            dbg_m0_arlen_q   <= m0_axi_arlen_i;
            dbg_m0_arburst_q <= m0_axi_arburst_i;
            dbg_m1_ar_hold_q <= m1_axi_arvalid_i && !m1_axi_arready_o;
            dbg_m1_araddr_q  <= m1_axi_araddr_i;
            dbg_m1_arid_q    <= m1_axi_arid_i;
            dbg_m1_arlen_q   <= m1_axi_arlen_i;
            dbg_m1_arburst_q <= m1_axi_arburst_i;
            dbg_m1_aw_hold_q <= m1_axi_awvalid_i && !m1_axi_awready_o;
            dbg_m1_awaddr_q  <= m1_axi_awaddr_i;
            dbg_m1_awid_q    <= m1_axi_awid_i;
            dbg_m1_awlen_q   <= m1_axi_awlen_i;
            dbg_m1_awburst_q <= m1_axi_awburst_i;
            dbg_m1_w_hold_q  <= m1_axi_wvalid_i && !m1_axi_wready_o;
            dbg_m1_wdata_q   <= m1_axi_wdata_i;
            dbg_m1_wstrb_q   <= m1_axi_wstrb_i;
            dbg_m1_wlast_q   <= m1_axi_wlast_i;

            if (m0_axi_arvalid_i || m1_axi_arvalid_i || s_axi_arvalid_o) begin
                `CPU_DEBUG($sformatf(
                    "[AXI][AR] state actual=%0d expected_grant=%0d actual_grant=%0d m0(valid=%0d ready=%0d addr=0x%08x id=0x%0x) m1(valid=%0d ready=%0d addr=0x%08x id=0x%0x) slave(valid=%0d ready=%0d addr=0x%08x id=0x%0x)",
                    arb_state_q, dbg_expected_ar_grant, dbg_actual_ar_grant,
                    m0_axi_arvalid_i, m0_axi_arready_o, m0_axi_araddr_i, m0_axi_arid_i,
                    m1_axi_arvalid_i, m1_axi_arready_o, m1_axi_araddr_i, m1_axi_arid_i,
                    s_axi_arvalid_o, s_axi_arready_i, s_axi_araddr_o, s_axi_arid_o
                ));
            end
            if (s_axi_rvalid_i || m0_axi_rvalid_o || m1_axi_rvalid_o) begin
                `CPU_DEBUG($sformatf(
                    "[AXI][R] owner=%0d busy=%0d saved_id=0x%0x id_match(m0=%0d m1=%0d) actual_m0_valid=%0d actual_m1_valid=%0d slave(valid=%0d ready=%0d last=%0d data=0x%08x id=0x%0x)",
                    rd_owner_q ? ARB_M1 : ARB_M0, rd_busy_q, rd_arid_q,
                    m0_rid_match_w, m1_rid_match_w, m0_axi_rvalid_o, m1_axi_rvalid_o,
                    s_axi_rvalid_i, s_axi_rready_o, s_axi_rlast_i, s_axi_rdata_i, s_axi_rid_i
                ));
            end
            if (m1_axi_awvalid_i || m1_axi_wvalid_i || s_axi_bvalid_i) begin
                `CPU_DEBUG($sformatf(
                    "[AXI][WRITE] aw(valid=%0d ready=%0d addr=0x%08x id=0x%0x) w(valid=%0d ready=%0d data=0x%08x strb=0x%0x last=%0d) b(valid=%0d ready=%0d id=0x%0x resp=0x%0x)",
                    s_axi_awvalid_o, m1_axi_awready_o, s_axi_awaddr_o, s_axi_awid_o,
                    s_axi_wvalid_o, m1_axi_wready_o, s_axi_wdata_o, s_axi_wstrb_o, s_axi_wlast_o,
                    m1_axi_bvalid_o, s_axi_bready_o, m1_axi_bid_o, m1_axi_bresp_o
                ));
            end
        end
    end
`endif

    `CPU_DEBUG_MODULE("axi_arbiter")
endmodule
