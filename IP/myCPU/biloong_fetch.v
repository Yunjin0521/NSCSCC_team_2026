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

module biloong_fetch
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MMU      = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch_accept_i
    ,input           icache_accept_i
    ,input           icache_valid_i
    ,input           icache_error_i
    ,input  [ 63:0]  icache_inst_i
    ,input           icache_page_fault_i
    ,input  [  5:0]  icache_fault_ecode_i
    ,input           fetch_invalidate_i
    ,input           idle_i
    ,input           idle_wake_i
    ,input           branch_request_i
    ,input  [ 31:0]  branch_pc_i
    ,input  [  1:0]  branch_priv_i
    ,input  [ 31:0]  next_pc_f_i
    ,input  [  1:0]  next_taken_f_i

    // Outputs
    ,output          fetch_valid_o
    ,output [ 63:0]  fetch_instr_o
    ,output [  1:0]  fetch_pred_branch_o
    ,output [ 31:0]  fetch_pred_pc_o
    ,output          fetch_fault_fetch_o
    ,output          fetch_fault_page_o
    ,output [  5:0]  fetch_fault_ecode_o
    ,output [ 31:0]  fetch_fault_addr_o
    ,output [ 31:0]  fetch_pc_o
    ,output          icache_rd_o
    ,output          icache_flush_o
    ,output          icache_invalidate_o
    ,output [ 31:0]  icache_pc_o
    ,output [  1:0]  icache_priv_o
    ,output [ 31:0]  pc_f_o
    ,output          pc_accept_o
);



//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg         active_q;
reg         idle_lock_q;

wire        icache_busy_w;
wire        stall_w       = !fetch_accept_i || icache_busy_w || !icache_accept_i;

//-------------------------------------------------------------
// Buffered branch
//-------------------------------------------------------------
reg         branch_q;
reg [31:0]  branch_pc_q;
reg [1:0]   branch_priv_q;

wire        branch_w;
wire [31:0] branch_pc_w;
wire [1:0]  branch_priv_w;

generate
if (SUPPORT_MMU)
begin
    assign branch_w      = branch_q;
    assign branch_pc_w   = branch_pc_q;
    assign branch_priv_w = branch_priv_q;
    
    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
        branch_priv_q  <= `PRIV_MACHINE;
    end
    else if (branch_request_i)
    begin
        branch_q       <= 1'b1;
        branch_pc_q    <= branch_pc_i;
        branch_priv_q  <= branch_priv_i;
    end
    else if (icache_rd_o && icache_accept_i)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
end
else
begin
    assign branch_w      = branch_q || branch_request_i;
    assign branch_pc_w   = (branch_q & !branch_request_i) ? branch_pc_q   : branch_pc_i;
    assign branch_priv_w = `PRIV_MACHINE; // don't care

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
    else if (branch_request_i && (icache_busy_w || !active_q || idle_i || idle_lock_q))
    begin
        branch_q       <= branch_w;
        branch_pc_q    <= branch_pc_w;
    end
    else if (~icache_busy_w)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end

end
endgenerate

//-------------------------------------------------------------
// Active flag
//-------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    active_q    <= 1'b0;
else if (SUPPORT_MMU && branch_w && ~stall_w)
    active_q    <= 1'b1;
else if (!SUPPORT_MMU && branch_w)
    active_q    <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    idle_lock_q <= 1'b0;
else if (idle_wake_i)
    idle_lock_q <= 1'b0;
else if (idle_i)
    idle_lock_q <= 1'b1;

//-------------------------------------------------------------
// Stall flag
//-------------------------------------------------------------
reg stall_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    stall_q    <= 1'b0;
else
    stall_q    <= stall_w;

//-------------------------------------------------------------
// Request tracking
//-------------------------------------------------------------
reg icache_fetch_q;
reg icache_invalidate_q;

// ICACHE fetch tracking
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_fetch_q <= 1'b0;
else if (icache_rd_o && icache_accept_i)
    icache_fetch_q <= 1'b1;
else if (icache_valid_i)
    icache_fetch_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_invalidate_q <= 1'b0;
else if (icache_invalidate_o && !icache_accept_i)
    icache_invalidate_q <= 1'b1;
else
    icache_invalidate_q <= 1'b0;

//-------------------------------------------------------------
// PC
//-------------------------------------------------------------
reg [31:0]  pc_f_q;
// NPC-facing copy keeps prediction fanout separate without changing fetch timing.
(* max_fanout = 16 *) reg [31:0]  pc_npc_q;
reg [31:0]  pc_d_q;
reg [31:0]  pred_pc_d_q;
reg [1:0]   pred_d_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_f_q  <= 32'b0;
// Branch request
else if (SUPPORT_MMU && branch_w && ~stall_w)
    pc_f_q  <= branch_pc_w;
else if (!SUPPORT_MMU && (stall_w || !active_q || stall_q) && branch_w)
    pc_f_q  <= branch_pc_w;
// NPC
else if (!stall_w)
    pc_f_q  <= next_pc_f_i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_npc_q  <= 32'b0;
// Branch request
else if (SUPPORT_MMU && branch_w && ~stall_w)
    pc_npc_q  <= branch_pc_w;
else if (!SUPPORT_MMU && (stall_w || !active_q || stall_q) && branch_w)
    pc_npc_q  <= branch_pc_w;
// NPC
else if (!stall_w)
    pc_npc_q  <= next_pc_f_i;

wire [31:0] icache_pc_w;
wire [1:0]  icache_priv_w;
wire        fetch_resp_drop_w;

generate
if (SUPPORT_MMU)
begin
    reg [1:0] priv_f_q;
    reg       branch_d_q;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        priv_f_q  <= `PRIV_MACHINE;
    // Branch request
    else if (branch_w && ~stall_w)
        priv_f_q  <= branch_priv_w;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        branch_d_q  <= 1'b0;
    // Branch request
    else if (branch_w && ~stall_w)
        branch_d_q  <= 1'b1;
    // NPC
    else if (!stall_w)
        branch_d_q  <= 1'b0;

    assign icache_pc_w       = pc_f_q;
    assign icache_priv_w     = priv_f_q;
    assign fetch_resp_drop_w = branch_w | branch_d_q;
end
else
begin
    assign icache_pc_w       = (branch_w & ~stall_q) ? branch_pc_w : pc_f_q;
    assign icache_priv_w     = `PRIV_MACHINE; // Don't care
    assign fetch_resp_drop_w = branch_w;
end
endgenerate

// Last fetch address
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_d_q <= 32'b0;
else if (icache_rd_o && icache_accept_i)
    pc_d_q <= icache_pc_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pred_d_q <= 2'b0;
else if (icache_rd_o && icache_accept_i)
    pred_d_q <= next_taken_f_i;
else if (icache_valid_i)
    pred_d_q <= 2'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pred_pc_d_q <= 32'b0;
else if (icache_rd_o && icache_accept_i)
    pred_pc_d_q <= next_pc_f_i;
else if (icache_valid_i)
    pred_pc_d_q <= 32'b0;

//-------------------------------------------------------------
// Outputs
//-------------------------------------------------------------
assign icache_rd_o         = active_q & fetch_accept_i & !icache_busy_w &
                             !(idle_lock_q || idle_i);
assign icache_pc_o         = {icache_pc_w[31:3],3'b0};
assign icache_priv_o       = icache_priv_w;
assign icache_flush_o      = fetch_invalidate_i | icache_invalidate_q;
assign icache_invalidate_o = 1'b0;

assign icache_busy_w       =  icache_fetch_q && !icache_valid_i;

//-------------------------------------------------------------
// Response Buffer
//-------------------------------------------------------------
reg [169:0] skid_buffer_q;
reg         skid_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    skid_buffer_q  <= 170'b0;
    skid_valid_q   <= 1'b0;
end 
// Instruction output back-pressured - hold in skid buffer
else if (fetch_valid_o && !fetch_accept_i)
begin
    skid_valid_q  <= 1'b1;
    skid_buffer_q <= {fetch_fault_ecode_o, fetch_fault_page_o, fetch_fault_fetch_o, fetch_fault_addr_o,
                      fetch_pred_pc_o, fetch_pred_branch_o, fetch_pc_o, fetch_instr_o};
end
else
begin
    skid_valid_q  <= 1'b0;
    skid_buffer_q <= 170'b0;
end

assign fetch_valid_o       = (icache_valid_i || skid_valid_q) & !fetch_resp_drop_w;
assign fetch_pc_o          = skid_valid_q ? skid_buffer_q[95:64] : {pc_d_q[31:3],3'b0};
assign fetch_instr_o       = skid_valid_q ? skid_buffer_q[63:0]  : icache_inst_i;
assign fetch_pred_branch_o = skid_valid_q ? skid_buffer_q[97:96] : pred_d_q;
assign fetch_pred_pc_o     = skid_valid_q ? skid_buffer_q[129:98] : pred_pc_d_q;

// Faults
wire fetch_misaligned_w = |pc_d_q[1:0];

assign fetch_fault_fetch_o = skid_valid_q ? skid_buffer_q[162]     : (icache_error_i | fetch_misaligned_w);
assign fetch_fault_page_o  = skid_valid_q ? skid_buffer_q[163]     : icache_page_fault_i;
assign fetch_fault_ecode_o = skid_valid_q ? skid_buffer_q[169:164] : icache_fault_ecode_i;
assign fetch_fault_addr_o  = skid_valid_q ? skid_buffer_q[161:130] : pc_d_q;

assign pc_f_o              = SUPPORT_MMU ? pc_npc_q : icache_pc_w;
assign pc_accept_o         = ~stall_w;



endmodule
