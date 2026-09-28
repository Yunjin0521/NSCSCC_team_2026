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
module biloong_pipe_ctrl
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_LOAD_BYPASS = 0
    ,parameter SUPPORT_MUL_BYPASS  = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    // Issue
    ,input           issue_valid_i
    ,input           issue_accept_i
    ,input           issue_stall_i
    ,input           issue_lsu_i
    ,input           issue_csr_i
    ,input           issue_div_i
    ,input           issue_mul_i
    ,input           issue_branch_i
`ifdef BPU_PERF
    ,input           issue_pred_branch_i
`endif
    ,input           issue_rd_valid_i
    ,input  [4:0]    issue_rd_i
    ,input  [15:0]   issue_seq_i
    ,input  [5:0]    issue_exception_i
    ,input  [5:0]    issue_exception_ecode_i
    ,input [31:0]    issue_exception_addr_i
    ,input           take_interrupt_i
    ,input           issue_branch_taken_i
    ,input [31:0]    issue_branch_target_i
    ,input [31:0]    issue_pc_i
    ,input [31:0]    issue_opcode_i
    ,input [31:0]    issue_operand_ra_i
    ,input [31:0]    issue_operand_rb_i

    // Execution stage 1: ALU result
    ,input [31:0]    alu_result_e1_i

    // Execution stage 1: CSR read result / early exceptions
    ,input [ 31:0]   csr_result_value_e1_i
    ,input           csr_result_write_e1_i
    ,input [ 31:0]   csr_result_wdata_e1_i
    ,input [  5:0]   csr_result_exception_e1_i

    // Execution stage 1
    ,output          load_e1_o
    ,output          store_e1_o
    ,output          mul_e1_o
    ,output          branch_e1_o
`ifdef BPU_PERF
    ,output          pred_branch_e1_o
`endif
    ,output [  4:0]  rd_e1_o
    ,output [31:0]   pc_e1_o
    ,output [31:0]   opcode_e1_o
    ,output [31:0]   operand_ra_e1_o
    ,output [31:0]   operand_rb_e1_o

    // Execution stage 2: Other results
    ,input           mem_complete_i
    ,input [31:0]    mem_result_e2_i
    ,input  [5:0]    mem_exception_e2_i
    ,input  [5:0]    mem_exception_ecode_e2_i
    ,input [31:0]    mul_result_e2_i
    ,input           mul_complete_i

    // Execution stage 2
    ,output          load_e2_o
    ,output          mul_e2_o
    ,output [  4:0]  rd_e2_o
    ,output [31:0]   result_e2_o
    ,output          complete_e1_o
    ,output [ 15:0]  seq_e1_o
    ,output          complete_e2_o
    ,output [ 15:0]  seq_e2_o
    ,output          complete_wb_o

    // Out of pipe: Divide Result
    ,input           div_complete_i
    ,input  [31:0]   div_result_i

    // Commit
    ,output          valid_wb_o
    ,output          csr_wb_o
    ,output [  4:0]  rd_wb_o
    ,output [ 15:0]  seq_wb_o
    ,output [31:0]   result_wb_o
    ,output [31:0]   pc_wb_o
    ,output [31:0]   opcode_wb_o
    ,output [31:0]   operand_ra_wb_o
    ,output [31:0]   operand_rb_wb_o
    ,output [5:0]    exception_wb_o
    ,output [5:0]    exception_ecode_wb_o
    ,output          csr_write_wb_o
    ,output [13:0]   csr_waddr_wb_o
    ,output [31:0]   csr_wdata_wb_o

    ,output          stall_o
    ,output          squash_e1_e2_o
    ,input           squash_e1_e2_i
    ,input           squash_wb_i
`ifdef PERF_MONI
    ,output          perf_stall_div_o
    ,output          perf_stall_mem_o
    ,output          perf_stall_mul_o
`endif
);

//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "biloong_defs.v"

wire squash_e1_e2_w;
wire flush_e1_e2_priority_w;

//-------------------------------------------------------------
// E1 / Address
//------------------------------------------------------------- 
`define PCINFO_W     10
`define PCINFO_ALU       0
`define PCINFO_LOAD      1
`define PCINFO_STORE     2
`define PCINFO_CSR       3
`define PCINFO_DIV       4
`define PCINFO_MUL       5
`define PCINFO_BRANCH    6
`define PCINFO_RD_VALID  7
`define PCINFO_INTR      8
`define PCINFO_COMPLETE  9

reg                     valid_e1_q;
reg [`PCINFO_W-1:0]     ctrl_e1_q;
reg [4:0]               rd_e1_q;
reg [15:0]              seq_e1_q;
reg [31:0]              pc_e1_q;
reg [31:0]              npc_e1_q;
reg [31:0]              opcode_e1_q;
// Operand A is consumed by LSU, ALU, branch, and multiplier control cones.
// Keep fanout bounded so these cones can receive local replicated drivers.
(* max_fanout = 16 *) reg [31:0]              operand_ra_e1_q;
reg [31:0]              operand_rb_e1_q;
`ifdef BPU_PERF
reg                     pred_branch_e1_q;
`endif
reg [31:0]              exception_addr_e1_q;
reg [`EXCEPTION_W-1:0]  exception_e1_q;
reg [5:0]               exception_ecode_e1_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_e1_q      <= 1'b0;
    ctrl_e1_q       <= `PCINFO_W'b0;
    rd_e1_q         <= 5'b0;
    seq_e1_q        <= 16'b0;
    pc_e1_q         <= 32'b0;
    npc_e1_q        <= 32'b0;
    opcode_e1_q     <= 32'b0;
    operand_ra_e1_q <= 32'b0;
    operand_rb_e1_q <= 32'b0;
`ifdef BPU_PERF
    pred_branch_e1_q <= 1'b0;
`endif
    exception_addr_e1_q <= 32'b0;
    exception_e1_q  <= `EXCEPTION_W'b0;
    exception_ecode_e1_q <= 6'b0;
end
// Committed exceptions and older-pipe squashes must kill younger work even
// when a stale E2 operation is holding the issue stage in stall.
else if (issue_stall_i && !flush_e1_e2_priority_w)
    ;
else if ((issue_valid_i && issue_accept_i) && ~(squash_e1_e2_o || squash_e1_e2_i))
begin
    valid_e1_q                  <= 1'b1;
    ctrl_e1_q[`PCINFO_ALU]      <= ~(issue_lsu_i | issue_csr_i | issue_div_i | issue_mul_i);
    ctrl_e1_q[`PCINFO_LOAD]     <= issue_lsu_i &  issue_rd_valid_i & ~take_interrupt_i; // TODO: Check
    ctrl_e1_q[`PCINFO_STORE]    <= issue_lsu_i & ~issue_rd_valid_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_CSR]      <= issue_csr_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_DIV]      <= issue_div_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_MUL]      <= issue_mul_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_BRANCH]   <= issue_branch_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_RD_VALID] <= issue_rd_valid_i & ~take_interrupt_i;
    ctrl_e1_q[`PCINFO_INTR]     <= take_interrupt_i;
    ctrl_e1_q[`PCINFO_COMPLETE] <= 1'b1;

    pc_e1_q         <= issue_pc_i;
    rd_e1_q         <= issue_rd_i;
    seq_e1_q        <= issue_seq_i;
    npc_e1_q        <= issue_branch_taken_i ? issue_branch_target_i : issue_pc_i + 32'd4;
    opcode_e1_q     <= issue_opcode_i;
    operand_ra_e1_q <= issue_operand_ra_i;
    operand_rb_e1_q <= issue_operand_rb_i;
`ifdef BPU_PERF
    pred_branch_e1_q <= issue_pred_branch_i & ~take_interrupt_i;
`endif
    exception_addr_e1_q <= issue_exception_addr_i;
    exception_e1_q  <= issue_exception_i;
    exception_ecode_e1_q <= issue_exception_ecode_i;
end
// No valid instruction (or pipeline flush event)
else
begin
    valid_e1_q      <= 1'b0;
    ctrl_e1_q       <= `PCINFO_W'b0;
    rd_e1_q         <= 5'b0;
    seq_e1_q        <= 16'b0;
    pc_e1_q         <= 32'b0;
    npc_e1_q        <= 32'b0;
    opcode_e1_q     <= 32'b0;
    operand_ra_e1_q <= 32'b0;
    operand_rb_e1_q <= 32'b0;
`ifdef BPU_PERF
    pred_branch_e1_q <= 1'b0;
`endif
    exception_addr_e1_q <= 32'b0;
    exception_e1_q  <= `EXCEPTION_W'b0;
    exception_ecode_e1_q <= 6'b0;
end

wire   alu_e1_w        = ctrl_e1_q[`PCINFO_ALU];
assign load_e1_o       = ctrl_e1_q[`PCINFO_LOAD];
assign store_e1_o      = ctrl_e1_q[`PCINFO_STORE];
wire   csr_e1_w        = ctrl_e1_q[`PCINFO_CSR];
wire   div_e1_w        = ctrl_e1_q[`PCINFO_DIV];
assign mul_e1_o        = ctrl_e1_q[`PCINFO_MUL];
assign branch_e1_o     = ctrl_e1_q[`PCINFO_BRANCH];
`ifdef BPU_PERF
assign pred_branch_e1_o = pred_branch_e1_q;
`endif
assign rd_e1_o         = {5{ctrl_e1_q[`PCINFO_RD_VALID]}} & rd_e1_q;
assign pc_e1_o         = pc_e1_q;
assign opcode_e1_o     = opcode_e1_q;
assign operand_ra_e1_o = operand_ra_e1_q;
assign operand_rb_e1_o = operand_rb_e1_q;

reg                    csr_result_hold_valid_q;
reg [31:0]             csr_result_value_hold_q;
reg                    csr_result_write_hold_q;
reg [31:0]             csr_result_wdata_hold_q;
reg [`EXCEPTION_W-1:0] csr_result_exception_hold_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    csr_result_hold_valid_q     <= 1'b0;
    csr_result_value_hold_q     <= 32'b0;
    csr_result_write_hold_q     <= 1'b0;
    csr_result_wdata_hold_q     <= 32'b0;
    csr_result_exception_hold_q <= `EXCEPTION_W'b0;
end
else if (squash_e1_e2_o || squash_e1_e2_i)
begin
    csr_result_hold_valid_q     <= 1'b0;
    csr_result_value_hold_q     <= 32'b0;
    csr_result_write_hold_q     <= 1'b0;
    csr_result_wdata_hold_q     <= 32'b0;
    csr_result_exception_hold_q <= `EXCEPTION_W'b0;
end
else if (issue_stall_i && valid_e1_q && csr_e1_w && !csr_result_hold_valid_q)
begin
    csr_result_hold_valid_q     <= 1'b1;
    csr_result_value_hold_q     <= csr_result_value_e1_i;
    csr_result_write_hold_q     <= csr_result_write_e1_i;
    csr_result_wdata_hold_q     <= csr_result_wdata_e1_i;
    csr_result_exception_hold_q <= csr_result_exception_e1_i;
end
else if (!issue_stall_i)
begin
    csr_result_hold_valid_q     <= 1'b0;
    csr_result_value_hold_q     <= 32'b0;
    csr_result_write_hold_q     <= 1'b0;
    csr_result_wdata_hold_q     <= 32'b0;
    csr_result_exception_hold_q <= `EXCEPTION_W'b0;
end

wire [31:0]             csr_result_value_e1_w     = csr_result_hold_valid_q ? csr_result_value_hold_q     : csr_result_value_e1_i;
wire                    csr_result_write_e1_w     = csr_result_hold_valid_q ? csr_result_write_hold_q     : csr_result_write_e1_i;
wire [31:0]             csr_result_wdata_e1_w     = csr_result_hold_valid_q ? csr_result_wdata_hold_q     : csr_result_wdata_e1_i;
wire [`EXCEPTION_W-1:0] csr_result_exception_e1_w = csr_result_hold_valid_q ? csr_result_exception_hold_q : csr_result_exception_e1_i;

//-------------------------------------------------------------
// E2 / Mem result
//------------------------------------------------------------- 
reg                     valid_e2_q;
reg [`PCINFO_W-1:0]     ctrl_e2_q;
reg                     csr_wr_e2_q;
reg [31:0]              csr_wdata_e2_q;
reg [31:0]              result_e2_q;
reg [4:0]               rd_e2_q;
reg [15:0]              seq_e2_q;
reg [31:0]              pc_e2_q;
reg [31:0]              npc_e2_q;
reg [31:0]              opcode_e2_q;
reg [31:0]              operand_ra_e2_q;
reg [31:0]              operand_rb_e2_q;
reg [31:0]              exception_addr_e2_q;
reg [`EXCEPTION_W-1:0]  exception_e2_q;
reg [5:0]               exception_ecode_e2_q;

wire   load_store_e2_w = ctrl_e2_q[`PCINFO_LOAD] | ctrl_e2_q[`PCINFO_STORE];

reg                    mem_complete_hold_valid_q;
reg [31:0]             mem_result_hold_q;
reg [`EXCEPTION_W-1:0] mem_exception_hold_q;
reg [5:0]              mem_exception_ecode_hold_q;
reg                    mul_complete_hold_valid_q;
reg [31:0]             mul_result_hold_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    mem_complete_hold_valid_q <= 1'b0;
    mem_result_hold_q         <= 32'b0;
    mem_exception_hold_q      <= `EXCEPTION_W'b0;
    mem_exception_ecode_hold_q <= 6'b0;
    mul_complete_hold_valid_q <= 1'b0;
    mul_result_hold_q         <= 32'b0;
end
else if (squash_e1_e2_o || squash_e1_e2_i || squash_wb_i)
begin
    mem_complete_hold_valid_q <= 1'b0;
    mem_result_hold_q         <= 32'b0;
    mem_exception_hold_q      <= `EXCEPTION_W'b0;
    mem_exception_ecode_hold_q <= 6'b0;
    mul_complete_hold_valid_q <= 1'b0;
    mul_result_hold_q         <= 32'b0;
end
else if (!issue_stall_i)
begin
    mem_complete_hold_valid_q <= 1'b0;
    mem_result_hold_q         <= 32'b0;
    mem_exception_hold_q      <= `EXCEPTION_W'b0;
    mem_exception_ecode_hold_q <= 6'b0;
    mul_complete_hold_valid_q <= 1'b0;
    mul_result_hold_q         <= 32'b0;
end
else
begin
    if (valid_e2_q && load_store_e2_w && mem_complete_i && !mem_complete_hold_valid_q)
    begin
        mem_complete_hold_valid_q <= 1'b1;
        mem_result_hold_q         <= mem_result_e2_i;
        mem_exception_hold_q      <= mem_exception_e2_i;
        mem_exception_ecode_hold_q <= mem_exception_ecode_e2_i;
    end

    if (valid_e2_q && ctrl_e2_q[`PCINFO_MUL] && mul_complete_i && !mul_complete_hold_valid_q)
    begin
        mul_complete_hold_valid_q <= 1'b1;
        mul_result_hold_q         <= mul_result_e2_i;
    end
end

wire                    mem_complete_e2_w = mem_complete_hold_valid_q | mem_complete_i;
wire [31:0]             mem_result_e2_w   = mem_complete_hold_valid_q ? mem_result_hold_q : mem_result_e2_i;
wire [`EXCEPTION_W-1:0] mem_exception_e2_w = mem_complete_hold_valid_q ? mem_exception_hold_q : mem_exception_e2_i;
wire [5:0]              mem_exception_ecode_e2_w = mem_complete_hold_valid_q ? mem_exception_ecode_hold_q :
                                                                             mem_exception_ecode_e2_i;
wire                    mul_complete_e2_w = mul_complete_hold_valid_q | mul_complete_i;
wire [31:0]             mul_result_e2_w   = mul_complete_hold_valid_q ? mul_result_hold_q : mul_result_e2_i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_e2_q      <= 1'b0;
    ctrl_e2_q       <= `PCINFO_W'b0;
    csr_wr_e2_q     <= 1'b0;
    csr_wdata_e2_q  <= 32'b0;
    rd_e2_q         <= 5'b0;
    seq_e2_q        <= 16'b0;
    pc_e2_q         <= 32'b0;
    npc_e2_q        <= 32'b0;
    opcode_e2_q     <= 32'b0;
    operand_ra_e2_q <= 32'b0;
    operand_rb_e2_q <= 32'b0;
    exception_addr_e2_q <= 32'b0;
    result_e2_q     <= 32'b0;
    exception_e2_q  <= `EXCEPTION_W'b0;
    exception_ecode_e2_q <= 6'b0;
end
// Keep E2 self-exceptions held during stalls until WB can capture them, but
// let already-committed exception flushes clear younger E2 contents.
else if (issue_stall_i && !flush_e1_e2_priority_w)
    ;
// Pipeline flush
else if (squash_e1_e2_o || squash_e1_e2_i)
begin
    valid_e2_q      <= 1'b0;
    ctrl_e2_q       <= `PCINFO_W'b0;
    csr_wr_e2_q     <= 1'b0;
    csr_wdata_e2_q  <= 32'b0;
    rd_e2_q         <= 5'b0;
    seq_e2_q        <= 16'b0;
    pc_e2_q         <= 32'b0;
    npc_e2_q        <= 32'b0;
    opcode_e2_q     <= 32'b0;
    operand_ra_e2_q <= 32'b0;
    operand_rb_e2_q <= 32'b0;
    exception_addr_e2_q <= 32'b0;
    result_e2_q     <= 32'b0;
    exception_e2_q  <= `EXCEPTION_W'b0;
    exception_ecode_e2_q <= 6'b0;
end
// Normal pipeline advance
else
begin
    valid_e2_q      <= valid_e1_q;
    ctrl_e2_q       <= ctrl_e1_q;
    csr_wr_e2_q     <= csr_e1_w && csr_result_write_e1_w &&
                       (exception_e1_q == `EXCEPTION_W'b0) &&
                       (csr_result_exception_e1_w == `EXCEPTION_W'b0);
    csr_wdata_e2_q  <= csr_result_wdata_e1_w;
    rd_e2_q         <= rd_e1_q;
    seq_e2_q        <= seq_e1_q;
    pc_e2_q         <= pc_e1_q;
    npc_e2_q        <= npc_e1_q;
    opcode_e2_q     <= opcode_e1_q;
    operand_ra_e2_q <= operand_ra_e1_q;
    operand_rb_e2_q <= operand_rb_e1_q;
    exception_addr_e2_q <= exception_addr_e1_q;
    exception_ecode_e2_q <= exception_ecode_e1_q;

    // Launch interrupt
    if (ctrl_e1_q[`PCINFO_INTR])
    begin
        exception_e2_q  <= `EXCEPTION_INTERRUPT;
        exception_ecode_e2_q <= 6'b0;
    end
    // If frontend reports bad instruction, ignore later CSR errors...
    else if (|exception_e1_q)
    begin
        valid_e2_q      <= 1'b0;
        exception_e2_q  <= exception_e1_q;
        exception_ecode_e2_q <= exception_ecode_e1_q;
    end
    else if (csr_e1_w)
    begin
        exception_e2_q  <= csr_result_exception_e1_w;
        exception_ecode_e2_q <= 6'b0;
    end
    else
    begin
        exception_e2_q  <= `EXCEPTION_W'b0;
        exception_ecode_e2_q <= 6'b0;
    end

    if (ctrl_e1_q[`PCINFO_DIV])
        result_e2_q <= div_result_i; 
    else if (ctrl_e1_q[`PCINFO_CSR])
        result_e2_q <= csr_result_value_e1_w;
    else
        result_e2_q <= alu_result_e1_i;
end

reg [31:0] result_e2_r;

wire valid_e2_bypass_w  = valid_e2_q;
wire valid_e2_advance_w = valid_e2_q & ~issue_stall_i;

always @ *
begin
    // Default: ALU result
    result_e2_r = result_e2_q;

    if (SUPPORT_LOAD_BYPASS && valid_e2_bypass_w && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]))
        result_e2_r = mem_result_e2_w;
    else if (SUPPORT_MUL_BYPASS && valid_e2_bypass_w && ctrl_e2_q[`PCINFO_MUL])
        result_e2_r = mul_result_e2_w;
end

assign load_e2_o       = ctrl_e2_q[`PCINFO_LOAD];
assign mul_e2_o        = ctrl_e2_q[`PCINFO_MUL];
assign rd_e2_o         = {5{valid_e2_q && ctrl_e2_q[`PCINFO_RD_VALID]}} & rd_e2_q;
assign result_e2_o     = result_e2_r;
assign complete_e1_o   = ctrl_e1_q[`PCINFO_COMPLETE];
assign seq_e1_o        = seq_e1_q;
assign complete_e2_o   = ctrl_e2_q[`PCINFO_COMPLETE];
assign seq_e2_o        = seq_e2_q;

// Load store result not ready when reaching E2
assign stall_o         = (ctrl_e1_q[`PCINFO_DIV] && ~div_complete_i) ||
                         ((ctrl_e2_q[`PCINFO_LOAD] | ctrl_e2_q[`PCINFO_STORE]) & ~mem_complete_e2_w) ||
                         (ctrl_e2_q[`PCINFO_MUL] & ~mul_complete_e2_w);

`ifdef PERF_MONI
assign perf_stall_div_o = ctrl_e1_q[`PCINFO_DIV] & ~div_complete_i;
assign perf_stall_mem_o = (ctrl_e2_q[`PCINFO_LOAD] | ctrl_e2_q[`PCINFO_STORE]) & ~mem_complete_e2_w;
assign perf_stall_mul_o = ctrl_e2_q[`PCINFO_MUL] & ~mul_complete_e2_w;
`endif

reg [`EXCEPTION_W-1:0] exception_e2_r;
reg [5:0]              exception_ecode_e2_r;
always @ *
begin
    if (valid_e2_q && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]) && mem_complete_e2_w)
    begin
        exception_e2_r = mem_exception_e2_w;
        exception_ecode_e2_r = mem_exception_ecode_e2_w;
    end
    else
    begin
        exception_e2_r = exception_e2_q;
        exception_ecode_e2_r = exception_ecode_e2_q;
    end
end

wire exception_fetch_e2_w = (exception_e2_r == `EXCEPTION_FAULT_FETCH) ||
                            (exception_e2_r == `EXCEPTION_MISALIGNED_FETCH) ||
                            (exception_e2_r == `EXCEPTION_PAGE_FAULT_INST);
wire exception_control_e2_w = |exception_e2_q;
wire exception_wb_squash_w;

// Memory data stays bypassed in E2 for hit performance. Memory exceptions do
// not drive this current-cycle squash path; they launch from the registered WB
// sideband below.
assign squash_e1_e2_w = exception_control_e2_w;

reg squash_e1_e2_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    squash_e1_e2_q <= 1'b0;
else if (~issue_stall_i)
    squash_e1_e2_q <= squash_e1_e2_w;

assign squash_e1_e2_o = squash_e1_e2_w | squash_e1_e2_q | exception_wb_squash_w;

//-------------------------------------------------------------
// Writeback / Commit
//------------------------------------------------------------- 
reg                     valid_wb_q;
reg [`PCINFO_W-1:0]     ctrl_wb_q;
reg                     csr_wr_wb_q;
reg [31:0]              csr_wdata_wb_q;
reg [31:0]              result_wb_q;
reg [4:0]               rd_wb_q;
reg [15:0]              seq_wb_q;
reg [31:0]              pc_wb_q;
reg [31:0]              npc_wb_q;
reg [31:0]              opcode_wb_q;
reg [31:0]              operand_ra_wb_q;
reg [31:0]              operand_rb_wb_q;
reg [`EXCEPTION_W-1:0]  exception_wb_q;
reg [5:0]               exception_ecode_wb_q;
reg                     exception_wb_squash_hold_q;

wire exception_wb_pending_w = (exception_wb_q != `EXCEPTION_W'b0);
assign exception_wb_squash_w = exception_wb_pending_w | exception_wb_squash_hold_q;
assign flush_e1_e2_priority_w = exception_wb_squash_w | squash_e1_e2_i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    exception_wb_squash_hold_q <= 1'b0;
else if (!issue_stall_i)
    exception_wb_squash_hold_q <= 1'b0;
else if (exception_wb_pending_w)
    exception_wb_squash_hold_q <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    csr_wr_wb_q     <= 1'b0;
    csr_wdata_wb_q  <= 32'b0;
    rd_wb_q         <= 5'b0;
    seq_wb_q        <= 16'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_ra_wb_q <= 32'b0;
    operand_rb_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
    exception_ecode_wb_q <= 6'b0;
end
else if (exception_wb_squash_w)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    csr_wr_wb_q     <= 1'b0;
    csr_wdata_wb_q  <= 32'b0;
    rd_wb_q         <= 5'b0;
    seq_wb_q        <= 16'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_ra_wb_q <= 32'b0;
    operand_rb_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
    exception_ecode_wb_q <= 6'b0;
end
// Stall - no change in WB state
else if (issue_stall_i)
    ;
else if (squash_wb_i)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    csr_wr_wb_q     <= 1'b0;
    csr_wdata_wb_q  <= 32'b0;
    rd_wb_q         <= 5'b0;
    seq_wb_q        <= 16'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_ra_wb_q <= 32'b0;
    operand_rb_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
    exception_ecode_wb_q <= 6'b0;
end
else
begin
    // Squash instruction valid on memory faults
    case (exception_e2_r)
    `EXCEPTION_MISALIGNED_LOAD,
    `EXCEPTION_FAULT_LOAD,
    `EXCEPTION_MISALIGNED_STORE,
    `EXCEPTION_FAULT_STORE,
    `EXCEPTION_PAGE_FAULT_LOAD,
    `EXCEPTION_PAGE_FAULT_STORE:
        valid_wb_q      <= 1'b0;
    default:
        valid_wb_q      <= valid_e2_q;
    endcase

    csr_wr_wb_q     <= csr_wr_e2_q;  // TODO: Fault disable???
    csr_wdata_wb_q  <= csr_wdata_e2_q;

    // Exception - squash writeback
    if (|exception_e2_r)
        ctrl_wb_q       <= ctrl_e2_q & ~(1 << `PCINFO_RD_VALID);
    else
        ctrl_wb_q       <= ctrl_e2_q;

    pc_wb_q         <= exception_fetch_e2_w ? exception_addr_e2_q : pc_e2_q;
    rd_wb_q         <= rd_e2_q;
    seq_wb_q        <= seq_e2_q;
    npc_wb_q        <= npc_e2_q;
    opcode_wb_q     <= opcode_e2_q;
    operand_ra_wb_q <= operand_ra_e2_q;
    operand_rb_wb_q <= operand_rb_e2_q;
    exception_wb_q  <= exception_e2_r;
    exception_ecode_wb_q <= exception_ecode_e2_r;

    if (valid_e2_advance_w && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]))
        result_wb_q <= mem_result_e2_w;
    else if (exception_fetch_e2_w)
        result_wb_q <= exception_addr_e2_q;
    else if (valid_e2_advance_w && ctrl_e2_q[`PCINFO_MUL])
        result_wb_q <= mul_result_e2_w;
    else
        result_wb_q <= result_e2_q;
end

// Instruction completion (for debug)
wire complete_wb_w     = ctrl_wb_q[`PCINFO_COMPLETE] & ~issue_stall_i;
assign complete_wb_o   = ctrl_wb_q[`PCINFO_COMPLETE];

assign valid_wb_o      = valid_wb_q & ~issue_stall_i;
assign csr_wb_o        = ctrl_wb_q[`PCINFO_CSR] & ~issue_stall_i; // TODO: Fault disable???
wire   rf_wb_w         = valid_wb_q && ctrl_wb_q[`PCINFO_RD_VALID];
assign rd_wb_o         = {5{rf_wb_w}} & rd_wb_q;
assign seq_wb_o        = seq_wb_q;
assign result_wb_o     = result_wb_q;
assign pc_wb_o         = pc_wb_q;
assign opcode_wb_o     = opcode_wb_q;
assign operand_ra_wb_o = operand_ra_wb_q;
assign operand_rb_wb_o = operand_rb_wb_q;

assign exception_wb_o  = exception_wb_q;
assign exception_ecode_wb_o = exception_ecode_wb_q;

assign csr_write_wb_o  = ctrl_wb_q[`PCINFO_CSR] && csr_wr_wb_q &&
                         (exception_wb_q == `EXCEPTION_W'b0);
assign csr_waddr_wb_o  = opcode_wb_q[`LA_CSR_NUM_R];
assign csr_wdata_wb_o  = csr_wdata_wb_q;

`ifdef verilator
biloong_trace_sim
u_trace_d
(
     .valid_i(issue_valid_i)
    ,.pc_i(issue_pc_i)
    ,.opcode_i(issue_opcode_i)
);

biloong_trace_sim
u_trace_wb
(
     .valid_i(valid_wb_o)
    ,.pc_i(pc_wb_o)
    ,.opcode_i(opcode_wb_o)
);
`endif

endmodule
