//-----------------------------------------------------------------
//                         Biloong CPU
//                            V0.8.1
//-----------------------------------------------------------------

module biloong_mmu
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter MEM_CACHE_ADDR_MIN = 0
    ,parameter MEM_CACHE_ADDR_MAX = 32'hffffffff
    ,parameter SUPPORT_MMU      = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  1:0]  priv_d_i
    ,input           sum_i
    ,input           mxr_i
    ,input           flush_i
    ,input  [ 31:0]  satp_i
    ,input  [ 31:0]  csr_crmd_i
    ,input  [ 31:0]  csr_asid_i
    ,input  [ 31:0]  csr_dmw0_i
    ,input  [ 31:0]  csr_dmw1_i
    ,input  [ 31:0]  tlb_e_i
    ,input  [32*19-1:0] tlb_vppn_i
    ,input  [32*10-1:0] tlb_asid_i
    ,input  [ 31:0]  tlb_g_i
    ,input  [32*6-1:0]  tlb_ps_i
    ,input  [32*20-1:0] tlb_ppn0_i
    ,input  [32*20-1:0] tlb_ppn1_i
    ,input  [32*2-1:0]  tlb_plv0_i
    ,input  [32*2-1:0]  tlb_plv1_i
    ,input  [32*2-1:0]  tlb_mat0_i
    ,input  [32*2-1:0]  tlb_mat1_i
    ,input  [ 31:0]  tlb_d0_i
    ,input  [ 31:0]  tlb_d1_i
    ,input  [ 31:0]  tlb_v0_i
    ,input  [ 31:0]  tlb_v1_i
    ,input           fetch_in_rd_i
    ,input           fetch_in_flush_i
    ,input           fetch_in_invalidate_i
    ,input  [ 31:0]  fetch_in_pc_i
    ,input  [  1:0]  fetch_in_priv_i
    ,input           fetch_out_accept_i
    ,input           fetch_out_valid_i
    ,input           fetch_out_error_i
    ,input  [ 63:0]  fetch_out_inst_i
    ,input  [ 31:0]  lsu_in_addr_i
    ,input  [ 31:0]  lsu_in_data_wr_i
    ,input           lsu_in_rd_i
    ,input  [  3:0]  lsu_in_wr_i
    ,input  [  1:0]  lsu_in_size_i
    ,input           lsu_in_cacheable_i
    ,input  [ 10:0]  lsu_in_req_tag_i
    ,input           lsu_in_invalidate_i
    ,input           lsu_in_writeback_i
    ,input           lsu_in_flush_i
    ,input  [ 31:0]  lsu_out_data_rd_i
    ,input           lsu_out_accept_i
    ,input           lsu_out_ack_i
    ,input           lsu_out_error_i
    ,input  [ 10:0]  lsu_out_resp_tag_i

    // Outputs
    ,output          fetch_in_accept_o
    ,output          fetch_in_valid_o
    ,output          fetch_in_error_o
    ,output [ 63:0]  fetch_in_inst_o
    ,output          fetch_out_rd_o
    ,output          fetch_out_flush_o
    ,output          fetch_out_invalidate_o
    ,output [ 31:0]  fetch_out_pc_o
    ,output          fetch_in_fault_o
    ,output [  5:0]  fetch_in_fault_ecode_o
    ,output [ 31:0]  lsu_in_data_rd_o
    ,output          lsu_in_accept_o
    ,output          lsu_in_ack_o
    ,output          lsu_in_error_o
    ,output [ 10:0]  lsu_in_resp_tag_o
    ,output [ 31:0]  lsu_out_addr_o
    ,output [ 31:0]  lsu_out_lookup_addr_o
    ,output [ 31:0]  lsu_out_data_wr_o
    ,output          lsu_out_rd_o
    ,output [  3:0]  lsu_out_wr_o
    ,output [  1:0]  lsu_out_size_o
    ,output          lsu_out_cacheable_o
    ,output [ 10:0]  lsu_out_req_tag_o
    ,output          lsu_out_invalidate_o
    ,output          lsu_out_writeback_o
    ,output          lsu_out_flush_o
    ,output          lsu_in_load_fault_o
    ,output          lsu_in_store_fault_o
    ,output [  5:0]  lsu_in_fault_ecode_o
    ,output [ 31:0]  lsu_in_paddr_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

//-----------------------------------------------------------------
// LoongArch direct-map / TLB translation
//-----------------------------------------------------------------
wire support_mmu_w = (SUPPORT_MMU != 0);
wire pg_mode_w     = support_mmu_w && !csr_crmd_i[3] && csr_crmd_i[4];

// Keep the fetch and LSU TLB consumers in separate low-width fanout domains.
// This preserves the CSR value and lookup timing while allowing Vivado to
// replicate/place the two ASID drivers locally instead of routing one wide
// CSR bus through both translation cones.
(* max_fanout = 8 *) wire [9:0] fetch_asid_w = csr_asid_i[9:0];
(* max_fanout = 16 *) wire [9:0] lsu_asid_w   = csr_asid_i[9:0];

function [0:0] dmw_hit;
    input [31:0] dmw;
    input [1:0]  plv;
    input [31:0] vaddr;
begin
    dmw_hit = ((dmw[0] && (plv == 2'd0)) || (dmw[3] && (plv == 2'd3))) &&
              (vaddr[31:29] == dmw[31:29]);
end
endfunction

function [31:0] dmw_paddr;
    input [31:0] dmw;
    input [31:0] vaddr;
begin
    dmw_paddr = {dmw[27:25], vaddr[28:0]};
end
endfunction

function [0:0] mat_cacheable;
    input [1:0] mat;
begin
    mat_cacheable = (mat == 2'b01);
end
endfunction

function [0:0] crmd_datm_cacheable;
    input [31:0] crmd;
begin
    crmd_datm_cacheable = (crmd[8:7] == 2'b01);
end
endfunction

// Balanced lowest-index priority encoder.  Keeping the selected index beside
// each subtree avoids the serial overwrite chain produced by a reverse loop.
function [4:0] first_tlb_hit_index;
    input [31:0] hit;
    integer enc_i;
    reg [15:0] valid_l1;
    reg [15:0] index_l1;
    reg [ 7:0] valid_l2;
    reg [15:0] index_l2;
    reg [ 3:0] valid_l3;
    reg [11:0] index_l3;
    reg [ 1:0] valid_l4;
    reg [ 7:0] index_l4;
    reg         valid_l5;
    reg [ 4:0] index_l5;
begin
    for (enc_i = 0; enc_i < 16; enc_i = enc_i + 1)
    begin
        valid_l1[enc_i] = |hit[enc_i*2 +: 2];
        index_l1[enc_i] = hit[enc_i*2] ? 1'b0 : 1'b1;
    end

    for (enc_i = 0; enc_i < 8; enc_i = enc_i + 1)
    begin
        valid_l2[enc_i] = valid_l1[enc_i*2] | valid_l1[enc_i*2+1];
        index_l2[enc_i*2 +: 2] = valid_l1[enc_i*2] ?
                                  {1'b0, index_l1[enc_i*2]} :
                                  {1'b1, index_l1[enc_i*2+1]};
    end

    for (enc_i = 0; enc_i < 4; enc_i = enc_i + 1)
    begin
        valid_l3[enc_i] = valid_l2[enc_i*2] | valid_l2[enc_i*2+1];
        index_l3[enc_i*3 +: 3] = valid_l2[enc_i*2] ?
                                  {1'b0, index_l2[enc_i*4 +: 2]} :
                                  {1'b1, index_l2[enc_i*4+2 +: 2]};
    end

    for (enc_i = 0; enc_i < 2; enc_i = enc_i + 1)
    begin
        valid_l4[enc_i] = valid_l3[enc_i*2] | valid_l3[enc_i*2+1];
        index_l4[enc_i*4 +: 4] = valid_l3[enc_i*2] ?
                                  {1'b0, index_l3[enc_i*6 +: 3]} :
                                  {1'b1, index_l3[enc_i*6+3 +: 3]};
    end

    valid_l5 = valid_l4[0] | valid_l4[1];
    index_l5 = valid_l4[0] ? {1'b0, index_l4[3:0]} :
                             {1'b1, index_l4[7:4]};
    first_tlb_hit_index = valid_l5 ? index_l5 : 5'b0;
end
endfunction

task automatic tlb_lookup;
    input [31:0] vaddr;
    input [9:0]  asid;
    output       found;
    output [5:0] ps;
    output [19:0] ppn;
    output [1:0] plv;
    output [1:0] mat;
    output       dirty;
    output       valid;
    integer lookup_i;
    reg [31:0] hit_w;
    reg [4:0]  index;
    reg        odd;
begin
    // Step 1: per-entry hit, all 32 computed in parallel.
    // Each hit_w[i] is independent; synthesis can place 32 small comparators
    // wherever it wants without serial dependency through a "!found" chain.
    for (lookup_i = 0; lookup_i < 32; lookup_i = lookup_i + 1)
    begin
        hit_w[lookup_i] = tlb_e_i[lookup_i] &&
            ((tlb_ps_i[lookup_i*6 +: 6] == 6'd12) ?
             (tlb_vppn_i[lookup_i*19 +: 19] == vaddr[31:13]) :
             (tlb_vppn_i[lookup_i*19 + 9 +: 10] == vaddr[31:22])) &&
            ((tlb_asid_i[lookup_i*10 +: 10] == asid) || tlb_g_i[lookup_i]);
    end

    // Step 2: any-hit -> found. 32-input OR, synthesis builds a balanced tree.
    found = |hit_w;

    // Step 3: lowest-index hit wins through a five-level balanced tree.
    index = first_tlb_hit_index(hit_w);

    // Step 4: page size from the matched entry; defaults to 4KB on miss
    // (matches the original initial assignment of ps = 6'd12).
    ps  = found ? tlb_ps_i[index*6 +: 6] : 6'd12;
    odd = (ps == 6'd12) ? vaddr[12] : vaddr[21];

    if (found && odd)
    begin
        ppn   = tlb_ppn1_i[index*20 +: 20];
        plv   = tlb_plv1_i[index*2 +: 2];
        mat   = tlb_mat1_i[index*2 +: 2];
        dirty = tlb_d1_i[index];
        valid = tlb_v1_i[index];
    end
    else if (found)
    begin
        ppn   = tlb_ppn0_i[index*20 +: 20];
        plv   = tlb_plv0_i[index*2 +: 2];
        mat   = tlb_mat0_i[index*2 +: 2];
        dirty = tlb_d0_i[index];
        valid = tlb_v0_i[index];
    end
    else
    begin
        ppn   = 20'b0;
        plv   = 2'b0;
        mat   = 2'b0;
        dirty = 1'b0;
        valid = 1'b0;
    end
end
endtask

reg        fetch_fault_r;
reg [5:0]  fetch_fault_ecode_r;
reg [31:0] fetch_paddr_r;
reg        fetch_translate_r;
reg        fetch_dmw0_hit_r;
reg        fetch_dmw1_hit_r;
reg        fetch_tlb_found_r;
reg [5:0]  fetch_tlb_ps_r;
reg [19:0] fetch_tlb_ppn_r;
reg [1:0]  fetch_tlb_plv_r;
reg [1:0]  fetch_tlb_mat_r;
reg        fetch_tlb_d_r;
reg        fetch_tlb_v_r;

always @ *
begin
    fetch_fault_r       = 1'b0;
    fetch_fault_ecode_r = 6'b0;
    fetch_paddr_r       = fetch_in_pc_i;
    fetch_tlb_found_r   = 1'b0;
    fetch_tlb_ps_r      = 6'd12;
    fetch_tlb_ppn_r     = 20'b0;
    fetch_tlb_plv_r     = 2'b0;
    fetch_tlb_mat_r     = 2'b0;
    fetch_tlb_d_r       = 1'b0;
    fetch_tlb_v_r       = 1'b0;
    fetch_dmw0_hit_r    = pg_mode_w && dmw_hit(csr_dmw0_i, fetch_in_priv_i, fetch_in_pc_i);
    fetch_dmw1_hit_r    = pg_mode_w && dmw_hit(csr_dmw1_i, fetch_in_priv_i, fetch_in_pc_i);
    fetch_translate_r   = pg_mode_w && !fetch_dmw0_hit_r && !fetch_dmw1_hit_r;

    if (pg_mode_w && fetch_dmw0_hit_r)
        fetch_paddr_r = dmw_paddr(csr_dmw0_i, fetch_in_pc_i);
    else if (pg_mode_w && fetch_dmw1_hit_r)
        fetch_paddr_r = dmw_paddr(csr_dmw1_i, fetch_in_pc_i);
    else if (fetch_translate_r)
    begin
        tlb_lookup(fetch_in_pc_i, fetch_asid_w, fetch_tlb_found_r,
                   fetch_tlb_ps_r, fetch_tlb_ppn_r, fetch_tlb_plv_r, fetch_tlb_mat_r,
                   fetch_tlb_d_r, fetch_tlb_v_r);
        if (!fetch_tlb_found_r)
        begin
            fetch_fault_r       = 1'b1;
            fetch_fault_ecode_r = `LA_ECODE_TLBR;
        end
        else if (!fetch_tlb_v_r)
        begin
            fetch_fault_r       = 1'b1;
            fetch_fault_ecode_r = `LA_ECODE_PIF;
        end
        else if (fetch_in_priv_i > fetch_tlb_plv_r)
        begin
            fetch_fault_r       = 1'b1;
            fetch_fault_ecode_r = `LA_ECODE_PPI;
        end
        else
            fetch_paddr_r = (fetch_tlb_ps_r == 6'd12) ? {fetch_tlb_ppn_r, fetch_in_pc_i[11:0]} :
                                                         {fetch_tlb_ppn_r[19:10], fetch_in_pc_i[21:0]};
    end
end

reg        lsu_fault_r;
reg [5:0]  lsu_fault_ecode_r;
reg [31:0] lsu_paddr_r;
reg [31:0] lsu_fast_paddr_r;
reg        lsu_input_translate_r;
reg        lsu_input_dmw0_hit_r;
reg        lsu_input_dmw1_hit_r;
reg        lsu_tlb_found_r;
reg [5:0]  lsu_tlb_ps_r;
reg [19:0] lsu_tlb_ppn_r;
reg [1:0]  lsu_tlb_plv_r;
reg [1:0]  lsu_tlb_mat_r;
reg        lsu_tlb_d_r;
reg        lsu_tlb_v_r;
wire       lsu_write_w = |lsu_in_wr_i;
wire       lsu_req_w   = lsu_in_rd_i || lsu_write_w || lsu_in_invalidate_i ||
                         lsu_in_writeback_i || lsu_in_flush_i;

always @ *
begin
    lsu_fast_paddr_r       = lsu_in_addr_i;
    lsu_input_dmw0_hit_r   = pg_mode_w && dmw_hit(csr_dmw0_i, priv_d_i, lsu_in_addr_i);
    lsu_input_dmw1_hit_r   = pg_mode_w && dmw_hit(csr_dmw1_i, priv_d_i, lsu_in_addr_i);
    lsu_input_translate_r  = pg_mode_w && !lsu_input_dmw0_hit_r && !lsu_input_dmw1_hit_r;

    if (pg_mode_w && lsu_input_dmw0_hit_r)
        lsu_fast_paddr_r = dmw_paddr(csr_dmw0_i, lsu_in_addr_i);
    else if (pg_mode_w && lsu_input_dmw1_hit_r)
        lsu_fast_paddr_r = dmw_paddr(csr_dmw1_i, lsu_in_addr_i);
end

reg        lsu_tlb_req_valid_q;
reg [31:0] lsu_tlb_req_addr_q;
reg [31:0] lsu_tlb_req_data_wr_q;
reg        lsu_tlb_req_rd_q;
reg [3:0]  lsu_tlb_req_wr_q;
reg [1:0]  lsu_tlb_req_size_q;
reg        lsu_tlb_req_cacheable_q;
reg [10:0] lsu_tlb_req_tag_q;
reg        lsu_tlb_req_invalidate_q;
reg        lsu_tlb_req_writeback_q;
reg        lsu_tlb_req_flush_q;
reg [1:0]  lsu_tlb_req_priv_q;
reg [9:0]  lsu_tlb_req_asid_q;

reg        lsu_tlb_lookup_valid_q;
reg [31:0] lsu_tlb_lookup_addr_q;
reg [31:0] lsu_tlb_lookup_data_wr_q;
reg        lsu_tlb_lookup_rd_q;
reg [3:0]  lsu_tlb_lookup_wr_q;
reg [1:0]  lsu_tlb_lookup_size_q;
reg        lsu_tlb_lookup_cacheable_q;
reg [10:0] lsu_tlb_lookup_tag_q;
reg        lsu_tlb_lookup_invalidate_q;
reg        lsu_tlb_lookup_writeback_q;
reg        lsu_tlb_lookup_flush_q;
reg [1:0]  lsu_tlb_lookup_priv_q;
reg        lsu_tlb_lookup_found_q;
reg [5:0]  lsu_tlb_lookup_ps_q;
reg [19:0] lsu_tlb_lookup_ppn_q;
reg [1:0]  lsu_tlb_lookup_plv_q;
reg [1:0]  lsu_tlb_lookup_mat_q;
reg        lsu_tlb_lookup_d_q;
reg        lsu_tlb_lookup_v_q;

wire       lsu_tlb_lookup_write_w = |lsu_tlb_lookup_wr_q;

always @ *
begin
    lsu_fault_r       = 1'b0;
    lsu_fault_ecode_r = 6'b0;
    lsu_paddr_r       = lsu_tlb_lookup_addr_q;
    lsu_tlb_found_r   = 1'b0;
    lsu_tlb_ps_r      = 6'd12;
    lsu_tlb_ppn_r     = 20'b0;
    lsu_tlb_plv_r     = 2'b0;
    lsu_tlb_mat_r     = 2'b0;
    lsu_tlb_d_r       = 1'b0;
    lsu_tlb_v_r       = 1'b0;

    if (lsu_tlb_req_valid_q)
    begin
        tlb_lookup(lsu_tlb_req_addr_q, lsu_tlb_req_asid_q, lsu_tlb_found_r,
                   lsu_tlb_ps_r, lsu_tlb_ppn_r, lsu_tlb_plv_r, lsu_tlb_mat_r,
                   lsu_tlb_d_r, lsu_tlb_v_r);
    end

    if (lsu_tlb_lookup_valid_q)
    begin
        if (!lsu_tlb_lookup_found_q)
        begin
            lsu_fault_r       = 1'b1;
            lsu_fault_ecode_r = `LA_ECODE_TLBR;
        end
        else if (!lsu_tlb_lookup_v_q)
        begin
            lsu_fault_r       = 1'b1;
            lsu_fault_ecode_r = lsu_tlb_lookup_write_w ? `LA_ECODE_PIS : `LA_ECODE_PIL;
        end
        else if (lsu_tlb_lookup_priv_q > lsu_tlb_lookup_plv_q)
        begin
            lsu_fault_r       = 1'b1;
            lsu_fault_ecode_r = `LA_ECODE_PPI;
        end
        else if (lsu_tlb_lookup_write_w && !lsu_tlb_lookup_d_q)
        begin
            lsu_fault_r       = 1'b1;
            lsu_fault_ecode_r = `LA_ECODE_PME;
        end
        else
            lsu_paddr_r = (lsu_tlb_lookup_ps_q == 6'd12) ?
                          {lsu_tlb_lookup_ppn_q, lsu_tlb_lookup_addr_q[11:0]} :
                          {lsu_tlb_lookup_ppn_q[19:10], lsu_tlb_lookup_addr_q[21:0]};
    end
end

reg        lsu_fault_pending_q;
reg        lsu_fault_is_load_q;
reg [5:0]  lsu_fault_ecode_q;
reg [10:0] lsu_fault_req_tag_q;
reg        lsu_slow_valid_q;
reg        lsu_slow_fault_q;
reg [5:0]  lsu_slow_fault_ecode_q;
reg [31:0] lsu_slow_addr_q;
reg [31:0] lsu_slow_lookup_addr_q;
reg [31:0] lsu_slow_data_wr_q;
reg        lsu_slow_rd_q;
reg [3:0]  lsu_slow_wr_q;
reg [1:0]  lsu_slow_size_q;
reg        lsu_slow_cacheable_q;
reg [10:0] lsu_slow_req_tag_q;
reg        lsu_slow_invalidate_q;
reg        lsu_slow_writeback_q;
reg        lsu_slow_flush_q;
reg        fetch_fault_pending_q;
reg [5:0]  fetch_fault_ecode_q;

wire fetch_req_accept_w  = !fetch_fault_pending_q && fetch_out_accept_i;
wire lsu_slow_req_w      = lsu_req_w && lsu_input_translate_r;
wire lsu_slow_out_valid_w = lsu_slow_valid_q && !lsu_slow_fault_q;
wire lsu_tlb_req_capture_w = !lsu_fault_pending_q && !lsu_tlb_req_valid_q &&
                             !lsu_tlb_lookup_valid_q && !lsu_slow_valid_q &&
                             lsu_slow_req_w;
wire lsu_tlb_lookup_capture_w = !lsu_fault_pending_q && lsu_tlb_req_valid_q &&
                                !lsu_tlb_lookup_valid_q;
wire lsu_slow_accept_w   = lsu_slow_valid_q && (lsu_slow_fault_q || lsu_out_accept_i);
wire lsu_slow_capture_w  = !lsu_fault_pending_q && lsu_tlb_lookup_valid_q &&
                           (!lsu_slow_valid_q || lsu_slow_accept_w);
wire lsu_fast_accept_w   = !lsu_fault_pending_q && !lsu_tlb_req_valid_q &&
                           !lsu_tlb_lookup_valid_q && !lsu_slow_valid_q &&
                           !lsu_slow_req_w &&
                           lsu_out_accept_i;
wire lsu_req_accept_w    = lsu_slow_accept_w || lsu_fast_accept_w;
wire fetch_fault_issue_w = fetch_in_rd_i && fetch_fault_r && fetch_req_accept_w;
wire lsu_slow_fault_issue_w = lsu_slow_valid_q && lsu_slow_fault_q &&
                              !lsu_fault_pending_q;
wire lsu_fault_issue_w   = lsu_slow_fault_issue_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    fetch_fault_pending_q <= 1'b0;
    fetch_fault_ecode_q   <= 6'b0;
end
else if (fetch_fault_issue_w)
begin
    fetch_fault_pending_q <= 1'b1;
    fetch_fault_ecode_q   <= fetch_fault_ecode_r;
end
else if (fetch_fault_pending_q)
begin
    fetch_fault_pending_q <= 1'b0;
    fetch_fault_ecode_q   <= 6'b0;
end

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    lsu_fault_pending_q <= 1'b0;
    lsu_fault_is_load_q <= 1'b0;
    lsu_fault_ecode_q   <= 6'b0;
    lsu_fault_req_tag_q <= 11'b0;
    lsu_tlb_req_valid_q <= 1'b0;
    lsu_tlb_req_addr_q  <= 32'b0;
    lsu_tlb_req_data_wr_q <= 32'b0;
    lsu_tlb_req_rd_q    <= 1'b0;
    lsu_tlb_req_wr_q    <= 4'b0;
    lsu_tlb_req_size_q  <= 2'b10;
    lsu_tlb_req_cacheable_q <= 1'b0;
    lsu_tlb_req_tag_q   <= 11'b0;
    lsu_tlb_req_invalidate_q <= 1'b0;
    lsu_tlb_req_writeback_q <= 1'b0;
    lsu_tlb_req_flush_q <= 1'b0;
    lsu_tlb_req_priv_q  <= 2'b0;
    lsu_tlb_req_asid_q  <= 10'b0;
    lsu_tlb_lookup_valid_q <= 1'b0;
    lsu_tlb_lookup_addr_q  <= 32'b0;
    lsu_tlb_lookup_data_wr_q <= 32'b0;
    lsu_tlb_lookup_rd_q    <= 1'b0;
    lsu_tlb_lookup_wr_q    <= 4'b0;
    lsu_tlb_lookup_size_q  <= 2'b10;
    lsu_tlb_lookup_cacheable_q <= 1'b0;
    lsu_tlb_lookup_tag_q   <= 11'b0;
    lsu_tlb_lookup_invalidate_q <= 1'b0;
    lsu_tlb_lookup_writeback_q <= 1'b0;
    lsu_tlb_lookup_flush_q <= 1'b0;
    lsu_tlb_lookup_priv_q  <= 2'b0;
    lsu_tlb_lookup_found_q <= 1'b0;
    lsu_tlb_lookup_ps_q    <= 6'd12;
    lsu_tlb_lookup_ppn_q   <= 20'b0;
    lsu_tlb_lookup_plv_q   <= 2'b0;
    lsu_tlb_lookup_mat_q   <= 2'b0;
    lsu_tlb_lookup_d_q     <= 1'b0;
    lsu_tlb_lookup_v_q     <= 1'b0;
    lsu_slow_valid_q    <= 1'b0;
    lsu_slow_fault_q    <= 1'b0;
    lsu_slow_fault_ecode_q <= 6'b0;
    lsu_slow_addr_q     <= 32'b0;
    lsu_slow_lookup_addr_q <= 32'b0;
    lsu_slow_data_wr_q  <= 32'b0;
    lsu_slow_rd_q       <= 1'b0;
    lsu_slow_wr_q       <= 4'b0;
    lsu_slow_size_q     <= 2'b10;
    lsu_slow_cacheable_q <= 1'b0;
    lsu_slow_req_tag_q  <= 11'b0;
    lsu_slow_invalidate_q <= 1'b0;
    lsu_slow_writeback_q <= 1'b0;
    lsu_slow_flush_q    <= 1'b0;
end
else
begin
    if (lsu_slow_accept_w)
        lsu_slow_valid_q <= 1'b0;

    if (lsu_slow_capture_w)
    begin
        lsu_tlb_lookup_valid_q <= 1'b0;
        lsu_slow_valid_q       <= 1'b1;
        lsu_slow_fault_q       <= lsu_fault_r;
        lsu_slow_fault_ecode_q <= lsu_fault_ecode_r;
        lsu_slow_addr_q        <= lsu_paddr_r;
        lsu_slow_lookup_addr_q <= lsu_paddr_r;
        lsu_slow_data_wr_q     <= lsu_tlb_lookup_data_wr_q;
        lsu_slow_rd_q          <= lsu_tlb_lookup_rd_q;
        lsu_slow_wr_q          <= lsu_tlb_lookup_wr_q;
        lsu_slow_size_q        <= lsu_tlb_lookup_size_q;
        lsu_slow_cacheable_q   <= mat_cacheable(lsu_tlb_lookup_mat_q) ||
                                  lsu_tlb_lookup_invalidate_q ||
                                  lsu_tlb_lookup_writeback_q ||
                                  lsu_tlb_lookup_flush_q;
        lsu_slow_req_tag_q     <= lsu_tlb_lookup_tag_q;
        lsu_slow_invalidate_q  <= lsu_tlb_lookup_invalidate_q;
        lsu_slow_writeback_q   <= lsu_tlb_lookup_writeback_q;
        lsu_slow_flush_q       <= lsu_tlb_lookup_flush_q;
    end
    else if (lsu_tlb_lookup_capture_w)
    begin
        lsu_tlb_req_valid_q       <= 1'b0;
        lsu_tlb_lookup_valid_q    <= 1'b1;
        lsu_tlb_lookup_addr_q     <= lsu_tlb_req_addr_q;
        lsu_tlb_lookup_data_wr_q  <= lsu_tlb_req_data_wr_q;
        lsu_tlb_lookup_rd_q       <= lsu_tlb_req_rd_q;
        lsu_tlb_lookup_wr_q       <= lsu_tlb_req_wr_q;
        lsu_tlb_lookup_size_q     <= lsu_tlb_req_size_q;
        lsu_tlb_lookup_cacheable_q <= lsu_tlb_req_cacheable_q;
        lsu_tlb_lookup_tag_q      <= lsu_tlb_req_tag_q;
        lsu_tlb_lookup_invalidate_q <= lsu_tlb_req_invalidate_q;
        lsu_tlb_lookup_writeback_q <= lsu_tlb_req_writeback_q;
        lsu_tlb_lookup_flush_q    <= lsu_tlb_req_flush_q;
        lsu_tlb_lookup_priv_q     <= lsu_tlb_req_priv_q;
        lsu_tlb_lookup_found_q    <= lsu_tlb_found_r;
        lsu_tlb_lookup_ps_q       <= lsu_tlb_ps_r;
        lsu_tlb_lookup_ppn_q      <= lsu_tlb_ppn_r;
        lsu_tlb_lookup_plv_q      <= lsu_tlb_plv_r;
        lsu_tlb_lookup_mat_q      <= lsu_tlb_mat_r;
        lsu_tlb_lookup_d_q        <= lsu_tlb_d_r;
        lsu_tlb_lookup_v_q        <= lsu_tlb_v_r;
    end
    else if (lsu_tlb_req_capture_w)
    begin
        lsu_tlb_req_valid_q     <= 1'b1;
        lsu_tlb_req_addr_q      <= lsu_in_addr_i;
        lsu_tlb_req_data_wr_q   <= lsu_in_data_wr_i;
        lsu_tlb_req_rd_q        <= lsu_in_rd_i;
        lsu_tlb_req_wr_q        <= lsu_in_wr_i;
        lsu_tlb_req_size_q      <= lsu_in_size_i;
        lsu_tlb_req_cacheable_q <= lsu_in_cacheable_i;
        lsu_tlb_req_tag_q       <= lsu_in_req_tag_i;
        lsu_tlb_req_invalidate_q <= lsu_in_invalidate_i;
        lsu_tlb_req_writeback_q <= lsu_in_writeback_i;
        lsu_tlb_req_flush_q     <= lsu_in_flush_i;
        lsu_tlb_req_priv_q      <= priv_d_i;
        lsu_tlb_req_asid_q      <= lsu_asid_w;
    end

    if (lsu_fault_issue_w && !lsu_fault_pending_q)
    begin
        lsu_fault_pending_q <= 1'b1;
        lsu_fault_is_load_q <= lsu_slow_rd_q;
        lsu_fault_ecode_q   <= lsu_slow_fault_ecode_q;
        lsu_fault_req_tag_q <= lsu_slow_req_tag_q;
    end
    else if (lsu_fault_pending_q)
    begin
        lsu_fault_pending_q <= 1'b0;
        lsu_fault_is_load_q <= 1'b0;
        lsu_fault_ecode_q   <= 6'b0;
        lsu_fault_req_tag_q <= 11'b0;
    end
end

assign fetch_out_rd_o         = fetch_in_rd_i && !fetch_fault_r && !fetch_fault_pending_q;
assign fetch_out_pc_o         = fetch_paddr_r;
assign fetch_out_flush_o      = fetch_in_flush_i;
assign fetch_out_invalidate_o = fetch_in_invalidate_i;
assign fetch_in_accept_o      = fetch_req_accept_w;
assign fetch_in_valid_o       = fetch_fault_pending_q || fetch_out_valid_i;
assign fetch_in_error_o       = fetch_fault_pending_q ? 1'b0 : fetch_out_error_i;
assign fetch_in_fault_o       = fetch_fault_pending_q;
assign fetch_in_fault_ecode_o = fetch_fault_pending_q ? fetch_fault_ecode_q : 6'b0;
assign fetch_in_inst_o        = fetch_fault_pending_q ? 64'b0 : fetch_out_inst_i;

wire lsu_fast_out_valid_w = !lsu_tlb_req_valid_q && !lsu_tlb_lookup_valid_q &&
                            !lsu_slow_valid_q && !lsu_slow_req_w;

assign lsu_out_rd_o           = lsu_slow_out_valid_w ? lsu_slow_rd_q :
                                (lsu_fast_out_valid_w ? lsu_in_rd_i : 1'b0);
assign lsu_out_wr_o           = lsu_slow_out_valid_w ? lsu_slow_wr_q :
                                (lsu_fast_out_valid_w ? lsu_in_wr_i : 4'b0);
assign lsu_out_size_o         = lsu_slow_out_valid_w ? lsu_slow_size_q :
                                (lsu_fast_out_valid_w ? lsu_in_size_i : 2'b10);
assign lsu_out_addr_o         = lsu_slow_out_valid_w ? lsu_slow_addr_q :
                                (lsu_fast_out_valid_w ? lsu_fast_paddr_r : 32'b0);
assign lsu_out_lookup_addr_o  = lsu_slow_out_valid_w ? lsu_slow_lookup_addr_q :
                                ((lsu_tlb_req_valid_q || lsu_tlb_lookup_valid_q || lsu_slow_valid_q || lsu_slow_req_w) ? 32'b0 : lsu_fast_paddr_r);
assign lsu_out_data_wr_o      = lsu_slow_out_valid_w ? lsu_slow_data_wr_q :
                                ((lsu_tlb_req_valid_q || lsu_tlb_lookup_valid_q || lsu_slow_valid_q || lsu_slow_req_w) ? 32'b0 : lsu_in_data_wr_i);
assign lsu_out_invalidate_o   = lsu_slow_out_valid_w ? lsu_slow_invalidate_q :
                                (lsu_fast_out_valid_w ? lsu_in_invalidate_i : 1'b0);
assign lsu_out_writeback_o    = lsu_slow_out_valid_w ? lsu_slow_writeback_q :
                                (lsu_fast_out_valid_w ? lsu_in_writeback_i : 1'b0);
wire lsu_fast_dmw_cacheable_w =
    (lsu_input_dmw0_hit_r && mat_cacheable(csr_dmw0_i[5:4])) ||
    (lsu_input_dmw1_hit_r && mat_cacheable(csr_dmw1_i[5:4]));
wire lsu_direct_cacheable_w =
    crmd_datm_cacheable(csr_crmd_i) ||
    lsu_in_invalidate_i ||
    lsu_in_writeback_i ||
    lsu_in_flush_i;
wire lsu_fast_cacheable_w =
    lsu_input_translate_r ? 1'b1 :
    ((lsu_input_dmw0_hit_r || lsu_input_dmw1_hit_r) ? lsu_fast_dmw_cacheable_w :
     (pg_mode_w ? lsu_in_cacheable_i : lsu_direct_cacheable_w));

assign lsu_out_cacheable_o    = lsu_slow_out_valid_w ? lsu_slow_cacheable_q :
                                (lsu_tlb_lookup_valid_q ? mat_cacheable(lsu_tlb_lookup_mat_q) :
                                 (lsu_tlb_req_valid_q ? 1'b1 :
                                  (lsu_slow_req_w ? 1'b1 : lsu_fast_cacheable_w)));
assign lsu_out_req_tag_o      = lsu_slow_out_valid_w ? lsu_slow_req_tag_q :
                                ((lsu_tlb_req_valid_q || lsu_tlb_lookup_valid_q || lsu_slow_valid_q || lsu_slow_req_w) ? 11'b0 : lsu_in_req_tag_i);
assign lsu_out_flush_o        = lsu_slow_out_valid_w ? lsu_slow_flush_q :
                                (lsu_fast_out_valid_w ? lsu_in_flush_i : 1'b0);

assign lsu_in_ack_o           = lsu_fault_pending_q || lsu_out_ack_i;
assign lsu_in_resp_tag_o      = lsu_fault_pending_q ? lsu_fault_req_tag_q : lsu_out_resp_tag_i;
assign lsu_in_error_o         = lsu_fault_pending_q || lsu_out_error_i;
assign lsu_in_data_rd_o       = lsu_out_data_rd_i;
assign lsu_in_store_fault_o   = lsu_fault_pending_q && !lsu_fault_is_load_q;
assign lsu_in_load_fault_o    = lsu_fault_pending_q && lsu_fault_is_load_q;
assign lsu_in_fault_ecode_o   = lsu_fault_pending_q ? lsu_fault_ecode_q : 6'b0;
assign lsu_in_accept_o        = lsu_req_accept_w;
assign lsu_in_paddr_o         = lsu_slow_valid_q ? lsu_slow_addr_q :
                                ((lsu_tlb_req_valid_q || lsu_tlb_lookup_valid_q || lsu_slow_req_w) ? 32'b0 : lsu_fast_paddr_r);

wire unused_sum   = sum_i;
wire unused_mxr   = mxr_i;
wire unused_flush = flush_i;
wire unused_satp  = |satp_i;
wire unused_fetch_tlb_mat = |fetch_tlb_mat_r;

endmodule
