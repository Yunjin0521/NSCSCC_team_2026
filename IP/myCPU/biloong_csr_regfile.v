//-----------------------------------------------------------------
//                         Biloong CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//-----------------------------------------------------------------
module biloong_csr_regfile
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MTIMECMP    = 1,
     parameter SUPPORT_SUPER       = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    ,input  [  7:0]  ext_intr_i
    ,input           timer_intr_i

    ,input [31:0]    cpu_id_i
    ,input [31:0]    misa_i

    ,input [5:0]     exception_i
    ,input [5:0]     exception_ecode_i
    ,input [31:0]    exception_pc_i
    ,input [31:0]    exception_addr_i

    // CSR read port
    ,input           csr_ren_i
    ,input  [13:0]   csr_raddr_i
    ,output [31:0]   csr_rdata_o

    // CSR write port
    ,input           csr_wen_i
    ,input  [13:0]   csr_waddr_i
    ,input  [31:0]   csr_wdata_i

    ,input           tlb_commit_tlbsrch_i
    ,input           tlb_commit_tlbrd_i
    ,input           tlb_commit_tlbwr_i
    ,input           tlb_commit_tlbfill_i
    ,input           tlb_commit_invtlb_i
    ,input  [4:0]    tlb_commit_invtlb_op_i
    ,input  [31:0]   tlb_commit_invtlb_asid_i
    ,input  [31:0]   tlb_commit_invtlb_vaddr_i

    ,input           llbit_set_i
    ,input           llbit_i
    ,output          llbit_o

    ,output          csr_branch_o
    ,output [31:0]   csr_target_o

    // CSR registers
    ,output [1:0]    priv_o
    ,output [31:0]   status_o
    ,output [31:0]   satp_o
    ,output [31:0]   mmu_crmd_o
    ,output [31:0]   mmu_asid_o
    ,output [31:0]   mmu_dmw0_o
    ,output [31:0]   mmu_dmw1_o
    ,output [31:0]   mmu_tlb_e_o
    ,output [32*19-1:0] mmu_tlb_vppn_o
    ,output [32*10-1:0] mmu_tlb_asid_o
    ,output [31:0]   mmu_tlb_g_o
    ,output [32*6-1:0]  mmu_tlb_ps_o
    ,output [32*20-1:0] mmu_tlb_ppn0_o
    ,output [32*20-1:0] mmu_tlb_ppn1_o
    ,output [32*2-1:0]  mmu_tlb_plv0_o
    ,output [32*2-1:0]  mmu_tlb_plv1_o
    ,output [32*2-1:0]  mmu_tlb_mat0_o
    ,output [32*2-1:0]  mmu_tlb_mat1_o
    ,output [31:0]   mmu_tlb_d0_o
    ,output [31:0]   mmu_tlb_d1_o
    ,output [31:0]   mmu_tlb_v0_o
    ,output [31:0]   mmu_tlb_v1_o

    // Masked interrupt output
    ,output [31:0]   interrupt_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

//-----------------------------------------------------------------
// LoongArch CSR addresses
//-----------------------------------------------------------------
localparam [13:0] LA_CSR_CRMD          = 14'h000;
localparam [13:0] LA_CSR_PRMD          = 14'h001;
localparam [13:0] LA_CSR_ECFG          = 14'h004;
localparam [13:0] LA_CSR_ESTAT         = 14'h005;
localparam [13:0] LA_CSR_ERA           = 14'h006;
localparam [13:0] LA_CSR_BADV          = 14'h007;
localparam [13:0] LA_CSR_EENTRY        = 14'h00c;
localparam [13:0] LA_CSR_TLBIDX        = 14'h010;
localparam [13:0] LA_CSR_TLBEHI        = 14'h011;
localparam [13:0] LA_CSR_TLBELO0       = 14'h012;
localparam [13:0] LA_CSR_TLBELO1       = 14'h013;
localparam [13:0] LA_CSR_ASID          = 14'h018;
localparam [13:0] LA_CSR_PGDL          = 14'h019;
localparam [13:0] LA_CSR_PGDH          = 14'h01a;
localparam [13:0] LA_CSR_PGD           = 14'h01b;
localparam [13:0] LA_CSR_CPUID         = 14'h020;
localparam [13:0] LA_CSR_SAVE0         = 14'h030;
localparam [13:0] LA_CSR_SAVE1         = 14'h031;
localparam [13:0] LA_CSR_SAVE2         = 14'h032;
localparam [13:0] LA_CSR_SAVE3         = 14'h033;
localparam [13:0] LA_CSR_TID           = 14'h040;
localparam [13:0] LA_CSR_TCFG          = 14'h041;
localparam [13:0] LA_CSR_TVAL          = 14'h042;
localparam [13:0] LA_CSR_CNTC          = 14'h043;
localparam [13:0] LA_CSR_TICLR         = 14'h044;
localparam [13:0] LA_CSR_LLBCTL        = 14'h060;
localparam [13:0] LA_CSR_TLBRENTRY     = 14'h088;
localparam [13:0] LA_CSR_DISABLE_CACHE = 14'h101;
localparam [13:0] LA_CSR_DMW0          = 14'h180;
localparam [13:0] LA_CSR_DMW1          = 14'h181;
localparam [13:0] LA_CSR_SIM_CTRL      = 14'h8b2;

//-----------------------------------------------------------------
// CSR state
//-----------------------------------------------------------------
reg [31:0] csr_crmd_q;
reg [31:0] csr_prmd_q;
reg [31:0] csr_ecfg_q;
reg [31:0] csr_estat_q;
reg [31:0] csr_era_q;
reg [31:0] csr_badv_q;
reg [31:0] csr_eentry_q;
reg [31:0] csr_tlbidx_q;
reg [31:0] csr_tlbehi_q;
reg [31:0] csr_tlbelo0_q;
reg [31:0] csr_tlbelo1_q;
reg [31:0] csr_asid_q;
reg [31:0] csr_pgdl_q;
reg [31:0] csr_pgdh_q;
reg [31:0] csr_save0_q;
reg [31:0] csr_save1_q;
reg [31:0] csr_save2_q;
reg [31:0] csr_save3_q;
reg [31:0] csr_tid_q;
reg [31:0] csr_tcfg_q;
reg [31:0] csr_tval_q;
reg [31:0] csr_cntc_q;
reg [31:0] csr_llbctl_q;
reg        llbit_q;
reg [31:0] csr_tlbrentry_q;
reg [31:0] csr_disable_cache_q;
reg [31:0] csr_dmw0_q;
reg [31:0] csr_dmw1_q;
reg        timer_en_q;
reg [63:0] timer_64_q;
reg [4:0]  tlbfill_index_q;

reg        tlb_e_q    [0:31];
reg [18:0] tlb_vppn_q [0:31];
reg [9:0]  tlb_asid_q [0:31];
reg        tlb_g_q    [0:31];
reg [5:0]  tlb_ps_q   [0:31];
reg [19:0] tlb_ppn0_q [0:31];
reg [19:0] tlb_ppn1_q [0:31];
reg [1:0]  tlb_plv0_q [0:31];
reg [1:0]  tlb_plv1_q [0:31];
reg [1:0]  tlb_mat0_q [0:31];
reg [1:0]  tlb_mat1_q [0:31];
reg        tlb_d0_q   [0:31];
reg        tlb_d1_q   [0:31];
reg        tlb_v0_q   [0:31];
reg        tlb_v1_q   [0:31];

integer tlb_reset_i;
integer tlb_inv_i;
integer tlb_search_i;

wire [31:0] csr_pgd_w = csr_badv_q[31] ? csr_pgdh_q : csr_pgdl_q;

wire [31:0] csr_dmw_wdata_w = {csr_wdata_i[31:29],
                               1'b0,
                               csr_wdata_i[27:25],
                               19'b0,
                               csr_wdata_i[5:4],
                               csr_wdata_i[3],
                               2'b0,
                               csr_wdata_i[0]};

//-----------------------------------------------------------------
// Software-visible TLB state for TLB management instructions
//-----------------------------------------------------------------
reg        tlbsrch_found_r;
reg [4:0]  tlbsrch_index_r;

wire [4:0]  tlbrd_index_w     = csr_tlbidx_q[4:0];
wire        tlbrd_found_w     = tlb_e_q[tlbrd_index_w];
wire [31:0] tlbrd_tlbidx_w    = {1'b0, 1'b0, tlb_ps_q[tlbrd_index_w], 19'b0, tlbrd_index_w};
wire [31:0] tlbrd_tlbehi_w    = {tlb_vppn_q[tlbrd_index_w], 13'b0};
wire [31:0] tlbrd_tlbelo0_w   = {4'b0, tlb_ppn0_q[tlbrd_index_w], 1'b0,
                                  tlb_g_q[tlbrd_index_w], tlb_mat0_q[tlbrd_index_w],
                                  tlb_plv0_q[tlbrd_index_w], tlb_d0_q[tlbrd_index_w],
                                  tlb_v0_q[tlbrd_index_w]};
wire [31:0] tlbrd_tlbelo1_w   = {4'b0, tlb_ppn1_q[tlbrd_index_w], 1'b0,
                                  tlb_g_q[tlbrd_index_w], tlb_mat1_q[tlbrd_index_w],
                                  tlb_plv1_q[tlbrd_index_w], tlb_d1_q[tlbrd_index_w],
                                  tlb_v1_q[tlbrd_index_w]};
wire [31:0] tlbrd_asid_w      = {22'h280, tlb_asid_q[tlbrd_index_w]};
wire [4:0]  tlb_write_index_w = tlb_commit_tlbfill_i ? tlbfill_index_q : csr_tlbidx_q[4:0];
wire        tlb_write_enable_w = (csr_estat_q[21:16] == `LA_ECODE_TLBR) || ~csr_tlbidx_q[31];

always @ *
begin
    tlbsrch_found_r = 1'b0;
    tlbsrch_index_r = 5'b0;

    for (tlb_search_i = 0; tlb_search_i < 32; tlb_search_i = tlb_search_i + 1)
    begin
        if (!tlbsrch_found_r && tlb_e_q[tlb_search_i] &&
            ((tlb_ps_q[tlb_search_i] == 6'd12) ?
             (tlb_vppn_q[tlb_search_i] == csr_tlbehi_q[31:13]) :
             (tlb_vppn_q[tlb_search_i][18:9] == csr_tlbehi_q[31:22])) &&
            ((tlb_asid_q[tlb_search_i] == csr_asid_q[9:0]) || tlb_g_q[tlb_search_i]))
        begin
            tlbsrch_found_r = 1'b1;
            tlbsrch_index_r = tlb_search_i[4:0];
        end
    end
end

//-----------------------------------------------------------------
// Read port
//-----------------------------------------------------------------
reg [31:0] rdata_r;
wire       llbit_visible_w = llbit_set_i ? llbit_i : llbit_q;

always @ *
begin
    rdata_r = 32'b0;

    case (csr_raddr_i)
    LA_CSR_CRMD:          rdata_r = csr_crmd_q;
    LA_CSR_PRMD:          rdata_r = csr_prmd_q;
    LA_CSR_ECFG:          rdata_r = csr_ecfg_q;
    LA_CSR_ESTAT:         rdata_r = csr_estat_q;
    LA_CSR_ERA:           rdata_r = csr_era_q;
    LA_CSR_BADV:          rdata_r = csr_badv_q;
    LA_CSR_EENTRY:        rdata_r = csr_eentry_q;
    LA_CSR_TLBIDX:        rdata_r = csr_tlbidx_q;
    LA_CSR_TLBEHI:        rdata_r = csr_tlbehi_q;
    LA_CSR_TLBELO0:       rdata_r = csr_tlbelo0_q;
    LA_CSR_TLBELO1:       rdata_r = csr_tlbelo1_q;
    LA_CSR_ASID:          rdata_r = csr_asid_q;
    LA_CSR_PGDL:          rdata_r = csr_pgdl_q;
    LA_CSR_PGDH:          rdata_r = csr_pgdh_q;
    LA_CSR_PGD:           rdata_r = csr_pgd_w;
    LA_CSR_CPUID:         rdata_r = cpu_id_i;
    LA_CSR_SAVE0:         rdata_r = csr_save0_q;
    LA_CSR_SAVE1:         rdata_r = csr_save1_q;
    LA_CSR_SAVE2:         rdata_r = csr_save2_q;
    LA_CSR_SAVE3:         rdata_r = csr_save3_q;
    LA_CSR_TID:           rdata_r = csr_tid_q;
    LA_CSR_TCFG:          rdata_r = csr_tcfg_q;
    LA_CSR_TVAL:          rdata_r = csr_tval_q;
    LA_CSR_CNTC:          rdata_r = csr_cntc_q;
    LA_CSR_TICLR:         rdata_r = 32'b0;
    LA_CSR_LLBCTL:        rdata_r = {csr_llbctl_q[31:1], llbit_visible_w};
    LA_CSR_TLBRENTRY:     rdata_r = csr_tlbrentry_q;
    LA_CSR_DISABLE_CACHE: rdata_r = csr_disable_cache_q;
    LA_CSR_DMW0:          rdata_r = csr_dmw0_q;
    LA_CSR_DMW1:          rdata_r = csr_dmw1_q;
    default:              rdata_r = 32'b0;
    endcase
end

assign csr_rdata_o = rdata_r;

//-----------------------------------------------------------------
// Exception mapping
//-----------------------------------------------------------------
function [5:0] la_ecode;
    input [5:0] exception;
begin
    case (exception)
    `EXCEPTION_FAULT_LOAD:
        la_ecode = `LA_ECODE_PIL;
    `EXCEPTION_PAGE_FAULT_LOAD:
        la_ecode = exception_ecode_i;
    `EXCEPTION_FAULT_STORE:
        la_ecode = `LA_ECODE_PIS;
    `EXCEPTION_PAGE_FAULT_STORE:
        la_ecode = exception_ecode_i;
    `EXCEPTION_PAGE_FAULT_INST:
        la_ecode = exception_ecode_i;
    `EXCEPTION_FAULT_FETCH,
    `EXCEPTION_MISALIGNED_FETCH:
        la_ecode = `LA_ECODE_ADE;
    `EXCEPTION_MISALIGNED_LOAD,
    `EXCEPTION_MISALIGNED_STORE:
        la_ecode = `LA_ECODE_ALE;
    `EXCEPTION_ECALL_U,
    `EXCEPTION_ECALL_S,
    `EXCEPTION_ECALL_H,
    `EXCEPTION_ECALL_M:
        la_ecode = `LA_ECODE_SYS;
    `EXCEPTION_BREAKPOINT:
        la_ecode = `LA_ECODE_BRK;
    `EXCEPTION_ILLEGAL_INSTRUCTION:
        la_ecode = `LA_ECODE_INE;
    `EXCEPTION_PRIVILEGED_INSTRUCTION:
        la_ecode = `LA_ECODE_IPE;
    default:
        la_ecode = `LA_ECODE_INE;
    endcase
    if (((exception == `EXCEPTION_PAGE_FAULT_LOAD) ||
         (exception == `EXCEPTION_PAGE_FAULT_STORE) ||
         (exception == `EXCEPTION_PAGE_FAULT_INST)) &&
        (exception_ecode_i == 6'b0))
    begin
        case (exception)
        `EXCEPTION_PAGE_FAULT_LOAD:  la_ecode = `LA_ECODE_PIL;
        `EXCEPTION_PAGE_FAULT_STORE: la_ecode = `LA_ECODE_PIS;
        default:                     la_ecode = `LA_ECODE_PIF;
        endcase
    end
end
endfunction

wire [5:0] exception_ecode_w = la_ecode(exception_i);
wire exception_interrupt_w = (exception_i == `EXCEPTION_INTERRUPT);
wire exception_regular_w   = ((exception_i & `EXCEPTION_TYPE_MASK) == `EXCEPTION_EXCEPTION);
wire exception_trap_w      = exception_interrupt_w || exception_regular_w;
wire exception_ertn_w      = (exception_i >= `EXCEPTION_ERET_U) && (exception_i <= `EXCEPTION_ERET_M);
wire exception_fence_w     = (exception_i == `EXCEPTION_FENCE);
wire exception_idle_w      = (exception_i == `EXCEPTION_IDLE);
wire exception_page_fault_w = (exception_i == `EXCEPTION_PAGE_FAULT_INST) ||
                              (exception_i == `EXCEPTION_PAGE_FAULT_LOAD) ||
                              (exception_i == `EXCEPTION_PAGE_FAULT_STORE);
wire exception_badv_w      = (exception_i == `EXCEPTION_FAULT_FETCH) ||
                             (exception_i == `EXCEPTION_MISALIGNED_FETCH) ||
                             (exception_i == `EXCEPTION_FAULT_LOAD) ||
                             (exception_i == `EXCEPTION_MISALIGNED_LOAD) ||
                             (exception_i == `EXCEPTION_FAULT_STORE) ||
                             (exception_i == `EXCEPTION_MISALIGNED_STORE) ||
                             (exception_i == `EXCEPTION_PAGE_FAULT_INST) ||
                             (exception_i == `EXCEPTION_PAGE_FAULT_LOAD) ||
                             (exception_i == `EXCEPTION_PAGE_FAULT_STORE);
// Fault-load/store always map to TLB-related ecodes. Page-fault inputs either
// carry one of the TLB ecodes directly or use the same TLB fallback when the
// MMU leaves exception_ecode_i at zero. Keep this predicate independent of the
// general exception-to-ecode case tree so the CSR update enable is shallower.
wire exception_page_fault_tlb_w = exception_page_fault_w &&
                                   ((exception_ecode_i == 6'b0) ||
                                    (exception_ecode_i == `LA_ECODE_TLBR) ||
                                    (exception_ecode_i == `LA_ECODE_PIL) ||
                                    (exception_ecode_i == `LA_ECODE_PIS) ||
                                    (exception_ecode_i == `LA_ECODE_PIF) ||
                                    (exception_ecode_i == `LA_ECODE_PME) ||
                                    (exception_ecode_i == `LA_ECODE_PPI));
wire exception_tlb_refill_w = exception_page_fault_w &&
                               (exception_ecode_i == `LA_ECODE_TLBR);
wire exception_tlb_related_w = (exception_i == `EXCEPTION_FAULT_LOAD) ||
                               (exception_i == `EXCEPTION_FAULT_STORE) ||
                               exception_page_fault_tlb_w;

//-----------------------------------------------------------------
// Interrupts
//-----------------------------------------------------------------
wire [12:0] interrupt_pending_w = csr_estat_q[12:0];
wire [12:0] interrupt_masked_w  = csr_ecfg_q[12:0] & interrupt_pending_w & {13{csr_crmd_q[2]}};

assign interrupt_o = {19'b0, interrupt_masked_w};

//-----------------------------------------------------------------
// Sequential state
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    csr_crmd_q          <= 32'h0000_0008;
    csr_prmd_q          <= 32'b0;
    csr_ecfg_q          <= 32'b0;
    csr_estat_q         <= 32'b0;
    csr_era_q           <= 32'b0;
    csr_badv_q          <= 32'b0;
    csr_eentry_q        <= 32'b0;
    csr_tlbidx_q        <= 32'b0;
    csr_tlbehi_q        <= 32'b0;
    csr_tlbelo0_q       <= 32'b0;
    csr_tlbelo1_q       <= 32'b0;
    csr_asid_q          <= {22'h280, 10'b0};
    csr_pgdl_q          <= 32'b0;
    csr_pgdh_q          <= 32'b0;
    csr_save0_q         <= 32'b0;
    csr_save1_q         <= 32'b0;
    csr_save2_q         <= 32'b0;
    csr_save3_q         <= 32'b0;
    csr_tid_q           <= 32'b0;
    csr_tcfg_q          <= 32'b0;
    csr_tval_q          <= 32'b0;
    csr_cntc_q          <= 32'b0;
    csr_llbctl_q        <= 32'b0;
    llbit_q             <= 1'b0;
    csr_tlbrentry_q     <= 32'b0;
    csr_disable_cache_q <= 32'b0;
    csr_dmw0_q          <= 32'b0;
    csr_dmw1_q          <= 32'b0;
    timer_en_q          <= 1'b0;
    timer_64_q          <= 64'b0;
    tlbfill_index_q     <= 5'b0;
    for (tlb_reset_i = 0; tlb_reset_i < 32; tlb_reset_i = tlb_reset_i + 1)
    begin
        tlb_e_q[tlb_reset_i]    <= 1'b0;
        tlb_vppn_q[tlb_reset_i] <= 19'b0;
        tlb_asid_q[tlb_reset_i] <= 10'b0;
        tlb_g_q[tlb_reset_i]    <= 1'b0;
        tlb_ps_q[tlb_reset_i]   <= 6'd12;
        tlb_ppn0_q[tlb_reset_i] <= 20'b0;
        tlb_ppn1_q[tlb_reset_i] <= 20'b0;
        tlb_plv0_q[tlb_reset_i] <= 2'b0;
        tlb_plv1_q[tlb_reset_i] <= 2'b0;
        tlb_mat0_q[tlb_reset_i] <= 2'b0;
        tlb_mat1_q[tlb_reset_i] <= 2'b0;
        tlb_d0_q[tlb_reset_i]   <= 1'b0;
        tlb_d1_q[tlb_reset_i]   <= 1'b0;
        tlb_v0_q[tlb_reset_i]   <= 1'b0;
        tlb_v1_q[tlb_reset_i]   <= 1'b0;
    end
end
else
begin
    timer_64_q <= timer_64_q + 64'd1;
    csr_estat_q[9:2] <= ext_intr_i;
`ifdef UARTSIM_DEBUG_INPUT
    if (ext_intr_i != csr_estat_q[9:2])
        $display("[csr] ext_intr=0x%02x estat_is=0x%03x ecfg=0x%03x crmd=0x%08x interrupt=0x%08x time=%0t", ext_intr_i, csr_estat_q[12:0], csr_ecfg_q[12:0], csr_crmd_q, interrupt_o, $time);
`endif


    if (timer_intr_i)
        csr_estat_q[11] <= 1'b1;

    if (SUPPORT_MTIMECMP && timer_en_q)
    begin
        if (csr_tval_q != 32'b0)
            csr_tval_q <= csr_tval_q - 32'd1;
        else
        begin
            csr_estat_q[11] <= 1'b1;
            timer_en_q <= csr_tcfg_q[1];
            csr_tval_q <= csr_tcfg_q[1] ? {csr_tcfg_q[31:2], 2'b0} : 32'hffff_ffff;
        end
    end

    if (exception_trap_w)
    begin
        csr_prmd_q[1:0]    <= csr_crmd_q[1:0];
        csr_prmd_q[2]      <= csr_crmd_q[2];
        csr_crmd_q[1:0]    <= 2'b0;
        csr_crmd_q[2]      <= 1'b0;
        if (exception_tlb_refill_w)
        begin
            csr_crmd_q[3]  <= 1'b1;
            csr_crmd_q[4]  <= 1'b0;
        end
        csr_era_q          <= exception_pc_i;
        csr_estat_q[21:16] <= exception_interrupt_w ? 6'b0 : exception_ecode_w;
        csr_estat_q[30:22] <= 9'b0;

        if (exception_badv_w)
        begin
            csr_badv_q <= exception_addr_i;
            if (exception_tlb_related_w)
                csr_tlbehi_q <= {exception_addr_i[31:13], 13'b0};
        end
    end
    else if (exception_ertn_w)
    begin
        csr_crmd_q[1:0] <= csr_prmd_q[1:0];
        csr_crmd_q[2]   <= csr_prmd_q[2];
        if (csr_estat_q[21:16] == `LA_ECODE_TLBR)
        begin
            csr_crmd_q[3] <= 1'b0;
            csr_crmd_q[4] <= 1'b1;
        end
        if (csr_llbctl_q[2])
            csr_llbctl_q[2] <= 1'b0;
        else
            llbit_q <= 1'b0;
    end
    else if (csr_wen_i)
    begin
        case (csr_waddr_i)
        LA_CSR_CRMD:
        begin
            csr_crmd_q[1:0] <= csr_wdata_i[1:0];
            csr_crmd_q[2]   <= csr_wdata_i[2];
            csr_crmd_q[3]   <= csr_wdata_i[3];
            csr_crmd_q[4]   <= csr_wdata_i[4];
            csr_crmd_q[6:5] <= csr_wdata_i[6:5];
            csr_crmd_q[8:7] <= csr_wdata_i[8:7];
        end
        LA_CSR_PRMD:
        begin
            csr_prmd_q[1:0] <= csr_wdata_i[1:0];
            csr_prmd_q[2]   <= csr_wdata_i[2];
        end
        LA_CSR_ECFG:          csr_ecfg_q          <= {19'b0, csr_wdata_i[12:11], 1'b0, csr_wdata_i[9:0]};
        LA_CSR_ESTAT:         csr_estat_q[1:0]    <= csr_wdata_i[1:0];
        LA_CSR_ERA:           csr_era_q           <= csr_wdata_i;
        LA_CSR_BADV:          csr_badv_q          <= csr_wdata_i;
        LA_CSR_EENTRY:        csr_eentry_q        <= {csr_wdata_i[31:6], 6'b0};
        LA_CSR_TLBIDX:        csr_tlbidx_q        <= {csr_wdata_i[31], 1'b0, csr_wdata_i[29:24], 19'b0, csr_wdata_i[4:0]};
        LA_CSR_TLBEHI:        csr_tlbehi_q        <= {csr_wdata_i[31:13], 13'b0};
        LA_CSR_TLBELO0:       csr_tlbelo0_q       <= {4'b0, csr_wdata_i[27:8], 1'b0, csr_wdata_i[6:0]};
        LA_CSR_TLBELO1:       csr_tlbelo1_q       <= {4'b0, csr_wdata_i[27:8], 1'b0, csr_wdata_i[6:0]};
        LA_CSR_ASID:          csr_asid_q          <= {22'h280, csr_wdata_i[9:0]};
        LA_CSR_PGDL:          csr_pgdl_q          <= {csr_wdata_i[31:12], 12'b0};
        LA_CSR_PGDH:          csr_pgdh_q          <= {csr_wdata_i[31:12], 12'b0};
        LA_CSR_SAVE0:         csr_save0_q         <= csr_wdata_i;
        LA_CSR_SAVE1:         csr_save1_q         <= csr_wdata_i;
        LA_CSR_SAVE2:         csr_save2_q         <= csr_wdata_i;
        LA_CSR_SAVE3:         csr_save3_q         <= csr_wdata_i;
        LA_CSR_TID:           csr_tid_q           <= csr_wdata_i;
        LA_CSR_TCFG:
        begin
            csr_tcfg_q <= csr_wdata_i;
            csr_tval_q <= {csr_wdata_i[31:2], 2'b0};
            timer_en_q <= csr_wdata_i[0];
        end
        LA_CSR_CNTC:          csr_cntc_q          <= csr_wdata_i;
        LA_CSR_TICLR:
        begin
            if (csr_wdata_i[0])
                csr_estat_q[11] <= 1'b0;
        end
        LA_CSR_LLBCTL:
        begin
            csr_llbctl_q[2] <= csr_wdata_i[2];
            if (csr_wdata_i[1])
                llbit_q <= 1'b0;
        end
        LA_CSR_TLBRENTRY:     csr_tlbrentry_q     <= {csr_wdata_i[31:6], 6'b0};
        LA_CSR_DISABLE_CACHE: csr_disable_cache_q <= csr_wdata_i;
        LA_CSR_DMW0:          csr_dmw0_q          <= csr_dmw_wdata_w;
        LA_CSR_DMW1:          csr_dmw1_q          <= csr_dmw_wdata_w;
        default: ;
        endcase
    end
    else if (tlb_commit_tlbrd_i)
    begin
        if (tlbrd_found_w)
        begin
            csr_tlbidx_q  <= tlbrd_tlbidx_w;
            csr_tlbehi_q  <= tlbrd_tlbehi_w;
            csr_tlbelo0_q <= tlbrd_tlbelo0_w;
            csr_tlbelo1_q <= tlbrd_tlbelo1_w;
            csr_asid_q    <= tlbrd_asid_w;
        end
        else
        begin
            csr_tlbidx_q  <= {1'b1, 1'b0, 6'b0, 19'b0, csr_tlbidx_q[4:0]};
            csr_tlbehi_q  <= 32'b0;
            csr_tlbelo0_q <= 32'b0;
            csr_tlbelo1_q <= 32'b0;
            csr_asid_q    <= {22'h280, 10'b0};
        end
    end
    else if (tlb_commit_tlbsrch_i)
    begin
        if (tlbsrch_found_r)
            csr_tlbidx_q <= {1'b0, csr_tlbidx_q[30:5], tlbsrch_index_r};
        else
            csr_tlbidx_q <= {1'b1, csr_tlbidx_q[30:0]};
    end
    else if (llbit_set_i)
        llbit_q <= llbit_i;

    if (tlb_commit_tlbwr_i || tlb_commit_tlbfill_i)
    begin
        tlb_vppn_q[tlb_write_index_w] <= csr_tlbehi_q[31:13];
        tlb_asid_q[tlb_write_index_w] <= csr_asid_q[9:0];
        tlb_g_q[tlb_write_index_w]    <= csr_tlbelo0_q[6] & csr_tlbelo1_q[6];
        tlb_ps_q[tlb_write_index_w]   <= csr_tlbidx_q[29:24];
        tlb_e_q[tlb_write_index_w]    <= tlb_write_enable_w;
        tlb_ppn0_q[tlb_write_index_w] <= csr_tlbelo0_q[27:8];
        tlb_ppn1_q[tlb_write_index_w] <= csr_tlbelo1_q[27:8];
        tlb_plv0_q[tlb_write_index_w] <= csr_tlbelo0_q[3:2];
        tlb_plv1_q[tlb_write_index_w] <= csr_tlbelo1_q[3:2];
        tlb_mat0_q[tlb_write_index_w] <= csr_tlbelo0_q[5:4];
        tlb_mat1_q[tlb_write_index_w] <= csr_tlbelo1_q[5:4];
        tlb_d0_q[tlb_write_index_w]   <= csr_tlbelo0_q[1];
        tlb_d1_q[tlb_write_index_w]   <= csr_tlbelo1_q[1];
        tlb_v0_q[tlb_write_index_w]   <= csr_tlbelo0_q[0];
        tlb_v1_q[tlb_write_index_w]   <= csr_tlbelo1_q[0];

        if (tlb_commit_tlbfill_i)
            tlbfill_index_q <= tlbfill_index_q + 5'd1;
    end
    else if (tlb_commit_invtlb_i)
    begin
        for (tlb_inv_i = 0; tlb_inv_i < 32; tlb_inv_i = tlb_inv_i + 1)
        begin
            if ((tlb_commit_invtlb_op_i == 5'd0) || (tlb_commit_invtlb_op_i == 5'd1))
                tlb_e_q[tlb_inv_i] <= 1'b0;
            else if ((tlb_commit_invtlb_op_i == 5'd2) && tlb_g_q[tlb_inv_i])
                tlb_e_q[tlb_inv_i] <= 1'b0;
            else if ((tlb_commit_invtlb_op_i == 5'd3) && !tlb_g_q[tlb_inv_i])
                tlb_e_q[tlb_inv_i] <= 1'b0;
            else if ((tlb_commit_invtlb_op_i == 5'd4) && !tlb_g_q[tlb_inv_i] &&
                     (tlb_asid_q[tlb_inv_i] == tlb_commit_invtlb_asid_i[9:0]))
                tlb_e_q[tlb_inv_i] <= 1'b0;
            else if ((tlb_commit_invtlb_op_i == 5'd5) && !tlb_g_q[tlb_inv_i] &&
                     (tlb_asid_q[tlb_inv_i] == tlb_commit_invtlb_asid_i[9:0]) &&
                     ((tlb_ps_q[tlb_inv_i] == 6'd12) ?
                      (tlb_vppn_q[tlb_inv_i] == tlb_commit_invtlb_vaddr_i[31:13]) :
                      (tlb_vppn_q[tlb_inv_i][18:9] == tlb_commit_invtlb_vaddr_i[31:22])))
                tlb_e_q[tlb_inv_i] <= 1'b0;
            else if ((tlb_commit_invtlb_op_i == 5'd6) &&
                     (tlb_g_q[tlb_inv_i] ||
                      (tlb_asid_q[tlb_inv_i] == tlb_commit_invtlb_asid_i[9:0])) &&
                     ((tlb_ps_q[tlb_inv_i] == 6'd12) ?
                      (tlb_vppn_q[tlb_inv_i] == tlb_commit_invtlb_vaddr_i[31:13]) :
                      (tlb_vppn_q[tlb_inv_i][18:9] == tlb_commit_invtlb_vaddr_i[31:22])))
                tlb_e_q[tlb_inv_i] <= 1'b0;
        end
    end

`ifdef verilator
    if (csr_wen_i && (csr_waddr_i == LA_CSR_SIM_CTRL) && (csr_wdata_i[31:24] == 8'h01))
        $write("%c", csr_wdata_i[7:0]);
`endif
end

//-----------------------------------------------------------------
// Branch target
//-----------------------------------------------------------------
assign csr_branch_o = exception_trap_w || exception_ertn_w || exception_fence_w || exception_idle_w;
assign csr_target_o = exception_ertn_w       ? csr_era_q :
                      (exception_fence_w ||
                       exception_idle_w)     ? exception_pc_i + 32'd4 :
                      exception_tlb_refill_w ? csr_tlbrentry_q :
                                               csr_eentry_q;

//-----------------------------------------------------------------
// MMU-visible CSR state
//-----------------------------------------------------------------
genvar mmu_tlb_pack_g;
generate
for (mmu_tlb_pack_g = 0; mmu_tlb_pack_g < 32; mmu_tlb_pack_g = mmu_tlb_pack_g + 1)
begin : g_mmu_tlb_pack
    assign mmu_tlb_e_o[mmu_tlb_pack_g] = tlb_e_q[mmu_tlb_pack_g];
    assign mmu_tlb_vppn_o[mmu_tlb_pack_g*19 +: 19] = tlb_vppn_q[mmu_tlb_pack_g];
    assign mmu_tlb_asid_o[mmu_tlb_pack_g*10 +: 10] = tlb_asid_q[mmu_tlb_pack_g];
    assign mmu_tlb_g_o[mmu_tlb_pack_g] = tlb_g_q[mmu_tlb_pack_g];
    assign mmu_tlb_ps_o[mmu_tlb_pack_g*6 +: 6] = tlb_ps_q[mmu_tlb_pack_g];
    assign mmu_tlb_ppn0_o[mmu_tlb_pack_g*20 +: 20] = tlb_ppn0_q[mmu_tlb_pack_g];
    assign mmu_tlb_ppn1_o[mmu_tlb_pack_g*20 +: 20] = tlb_ppn1_q[mmu_tlb_pack_g];
    assign mmu_tlb_plv0_o[mmu_tlb_pack_g*2 +: 2] = tlb_plv0_q[mmu_tlb_pack_g];
    assign mmu_tlb_plv1_o[mmu_tlb_pack_g*2 +: 2] = tlb_plv1_q[mmu_tlb_pack_g];
    assign mmu_tlb_mat0_o[mmu_tlb_pack_g*2 +: 2] = tlb_mat0_q[mmu_tlb_pack_g];
    assign mmu_tlb_mat1_o[mmu_tlb_pack_g*2 +: 2] = tlb_mat1_q[mmu_tlb_pack_g];
    assign mmu_tlb_d0_o[mmu_tlb_pack_g] = tlb_d0_q[mmu_tlb_pack_g];
    assign mmu_tlb_d1_o[mmu_tlb_pack_g] = tlb_d1_q[mmu_tlb_pack_g];
    assign mmu_tlb_v0_o[mmu_tlb_pack_g] = tlb_v0_q[mmu_tlb_pack_g];
    assign mmu_tlb_v1_o[mmu_tlb_pack_g] = tlb_v1_q[mmu_tlb_pack_g];
end
endgenerate

assign priv_o   = csr_crmd_q[1:0];
assign status_o = 32'b0;
assign satp_o   = 32'b0;
// The CSR read port keeps same-cycle visibility, but LSU feedback must come
// from registered state.  Otherwise a D-cache completion crosses LSU -> CSR
// -> LSU combinationally and reaches the global issue release path.
assign llbit_o  = llbit_q;
assign mmu_crmd_o = csr_crmd_q;
assign mmu_asid_o = csr_asid_q;
assign mmu_dmw0_o = csr_dmw0_q;
assign mmu_dmw1_o = csr_dmw1_q;

`ifdef verilator
function [31:0] get_mcycle; /*verilator public*/
begin
    get_mcycle = timer_64_q[31:0];
end
endfunction

`endif

endmodule
