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

module biloong_multiplier
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
    ,input           hold_i

`ifdef CPU_REAL_MDU
    ,input           opcode_pipe1_i
    ,input           opcode1_valid_i
    ,input  [ 31:0]  opcode1_opcode_i
    ,input  [ 31:0]  opcode1_ra_operand_i
    ,input  [ 31:0]  opcode1_rb_operand_i
`endif

    // Outputs
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_value_o
`ifdef CPU_REAL_MDU
    ,output          writeback_pipe1_o
    ,output          accept_one_o
    ,output          accept_two_o
`endif
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

localparam MULT_STAGES = 2; // 2 or 3

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg  [31:0]  result_e2_q;
reg  [31:0]  result_e3_q;

wire [5:0] op_31_26_w = opcode_opcode_i[`LA_OP_31_26_R];
wire [3:0] op_25_22_w = opcode_opcode_i[`LA_OP_25_22_R];
wire [1:0] op_21_20_w = opcode_opcode_i[`LA_OP_21_20_R];
wire [4:0] op_19_15_w = opcode_opcode_i[`LA_OP_19_15_R];

wire inst_3r_base_w = (op_31_26_w == 6'h00) &&
                      (op_25_22_w == 4'h0) &&
                      (op_21_20_w == 2'h1);
wire inst_mul_w     = inst_3r_base_w && (op_19_15_w == 5'h18);
wire inst_mulh_w    = inst_3r_base_w && (op_19_15_w == 5'h19);
wire inst_mulh_wu_w = inst_3r_base_w && (op_19_15_w == 5'h1a);
wire mult_inst_w    = inst_mul_w || inst_mulh_w || inst_mulh_wu_w;

`ifdef CPU_REAL_MDU
localparam integer MUL_DONE_LATENCY_C = `MUL_DONE_LATENCY;

wire [5:0] op1_31_26_w = opcode1_opcode_i[`LA_OP_31_26_R];
wire [3:0] op1_25_22_w = opcode1_opcode_i[`LA_OP_25_22_R];
wire [1:0] op1_21_20_w = opcode1_opcode_i[`LA_OP_21_20_R];
wire [4:0] op1_19_15_w = opcode1_opcode_i[`LA_OP_19_15_R];

wire inst1_3r_base_w = (op1_31_26_w == 6'h00) &&
                       (op1_25_22_w == 4'h0) &&
                       (op1_21_20_w == 2'h1);
wire inst1_mul_w     = inst1_3r_base_w && (op1_19_15_w == 5'h18);
wire inst1_mulh_w    = inst1_3r_base_w && (op1_19_15_w == 5'h19);
wire inst1_mulh_wu_w = inst1_3r_base_w && (op1_19_15_w == 5'h1a);
wire mult1_inst_w    = inst1_mul_w || inst1_mulh_w || inst1_mulh_wu_w;

localparam REQ_DEPTH = 8;
localparam REQ_COUNT_W = 4;
localparam [REQ_COUNT_W-1:0] REQ_DEPTH_C = REQ_DEPTH;

wire [9:0] mul_div_op_w  = {7'b0, inst_mulh_wu_w,  inst_mulh_w,  inst_mul_w};
wire [9:0] mul_div_op1_w = {7'b0, inst1_mulh_wu_w, inst1_mulh_w, inst1_mul_w};
wire       mul_done_w;
wire [31:0] mul_result_w;
wire       req0_valid_w = opcode_valid_i  && mult_inst_w  && !hold_i;
wire       req1_valid_w = opcode1_valid_i && mult1_inst_w && !hold_i;

reg        ing0_valid_q;
reg        ing1_valid_q;
reg [9:0]  ing0_op_q;
reg [9:0]  ing1_op_q;
reg [31:0] ing0_a_q;
reg [31:0] ing1_a_q;
reg [31:0] ing0_b_q;
reg [31:0] ing1_b_q;
reg        ing0_pipe1_q;
reg        ing1_pipe1_q;
reg [REQ_COUNT_W-1:0]  req_count_q;
reg [9:0]  req_op_q[0:REQ_DEPTH-1];
reg [31:0] req_a_q[0:REQ_DEPTH-1];
reg [31:0] req_b_q[0:REQ_DEPTH-1];
reg        req_pipe1_q[0:REQ_DEPTH-1];
reg [REQ_COUNT_W-1:0]  req_count_r;
reg [9:0]  req_op_r[0:REQ_DEPTH-1];
reg [31:0] req_a_r[0:REQ_DEPTH-1];
reg [31:0] req_b_r[0:REQ_DEPTH-1];
reg        req_pipe1_r[0:REQ_DEPTH-1];
integer req_i;

wire       queue_launch_w = (req_count_q != {REQ_COUNT_W{1'b0}});
wire       ingress_pending_w = ing0_valid_q || ing1_valid_q;
wire       direct_ing0_w = (req_count_q == {REQ_COUNT_W{1'b0}}) && ing0_valid_q;
wire       direct_ing1_w = (req_count_q == {REQ_COUNT_W{1'b0}}) && !ing0_valid_q && ing1_valid_q;
wire       direct_req0_w = (req_count_q == {REQ_COUNT_W{1'b0}}) &&
                           !ingress_pending_w && req0_valid_w;
wire       direct_req1_w = (req_count_q == {REQ_COUNT_W{1'b0}}) &&
                           !ingress_pending_w && !req0_valid_w && req1_valid_w;
wire       direct_launch_w = direct_req0_w || direct_req1_w;
wire       ingress_launch_w = direct_ing0_w || direct_ing1_w;
wire       mul_launch_w = queue_launch_w || ingress_launch_w || direct_launch_w;
wire [9:0] mul_launch_op_w = queue_launch_w ? req_op_q[0] :
                              direct_ing0_w  ? ing0_op_q :
                              direct_ing1_w  ? ing1_op_q :
                              direct_req0_w  ? mul_div_op_w : mul_div_op1_w;
wire [31:0] mul_launch_a_w = queue_launch_w ? req_a_q[0] :
                              direct_ing0_w  ? ing0_a_q :
                              direct_ing1_w  ? ing1_a_q :
                              direct_req0_w  ? opcode_ra_operand_i : opcode1_ra_operand_i;
wire [31:0] mul_launch_b_w = queue_launch_w ? req_b_q[0] :
                              direct_ing0_w  ? ing0_b_q :
                              direct_ing1_w  ? ing1_b_q :
                              direct_req0_w  ? opcode_rb_operand_i : opcode1_rb_operand_i;
wire       mul_launch_pipe1_w = queue_launch_w ? req_pipe1_q[0] :
                                direct_ing0_w  ? ing0_pipe1_q :
                                direct_ing1_w  ? ing1_pipe1_q :
                                direct_req0_w  ? opcode_pipe1_i : 1'b1;
wire       req0_ingress_w = req0_valid_w && !direct_req0_w;
wire       req1_ingress_w = req1_valid_w && !direct_req1_w;

always @ *
begin
    for (req_i = 0; req_i < REQ_DEPTH; req_i = req_i + 1)
    begin
        req_op_r[req_i]    = req_op_q[req_i];
        req_a_r[req_i]     = req_a_q[req_i];
        req_b_r[req_i]     = req_b_q[req_i];
        req_pipe1_r[req_i] = req_pipe1_q[req_i];
    end

    req_count_r = req_count_q;

    if (queue_launch_w)
    begin
        req_count_r = req_count_q - {{(REQ_COUNT_W-1){1'b0}}, 1'b1};
        for (req_i = 0; req_i < REQ_DEPTH-1; req_i = req_i + 1)
        begin
            req_op_r[req_i]    = req_op_q[req_i + 1];
            req_a_r[req_i]     = req_a_q[req_i + 1];
            req_b_r[req_i]     = req_b_q[req_i + 1];
            req_pipe1_r[req_i] = req_pipe1_q[req_i + 1];
        end
        req_op_r[REQ_DEPTH-1]    = 10'b0;
        req_a_r[REQ_DEPTH-1]     = 32'b0;
        req_b_r[REQ_DEPTH-1]     = 32'b0;
        req_pipe1_r[REQ_DEPTH-1] = 1'b0;
    end

    if (ing0_valid_q && !direct_ing0_w && (req_count_r < REQ_DEPTH_C))
    begin
        req_op_r[req_count_r]    = ing0_op_q;
        req_a_r[req_count_r]     = ing0_a_q;
        req_b_r[req_count_r]     = ing0_b_q;
        req_pipe1_r[req_count_r] = ing0_pipe1_q;
        req_count_r              = req_count_r + {{(REQ_COUNT_W-1){1'b0}}, 1'b1};
    end

    if (ing1_valid_q && !direct_ing1_w && (req_count_r < REQ_DEPTH_C))
    begin
        req_op_r[req_count_r]    = ing1_op_q;
        req_a_r[req_count_r]     = ing1_a_q;
        req_b_r[req_count_r]     = ing1_b_q;
        req_pipe1_r[req_count_r] = ing1_pipe1_q;
        req_count_r              = req_count_r + {{(REQ_COUNT_W-1){1'b0}}, 1'b1};
    end
end

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    ing0_valid_q <= 1'b0;
    ing1_valid_q <= 1'b0;
    ing0_op_q    <= 10'b0;
    ing1_op_q    <= 10'b0;
    ing0_a_q     <= 32'b0;
    ing1_a_q     <= 32'b0;
    ing0_b_q     <= 32'b0;
    ing1_b_q     <= 32'b0;
    ing0_pipe1_q <= 1'b0;
    ing1_pipe1_q <= 1'b0;
    req_count_q <= {REQ_COUNT_W{1'b0}};
    for (req_i = 0; req_i < REQ_DEPTH; req_i = req_i + 1)
    begin
        req_op_q[req_i]    <= 10'b0;
        req_a_q[req_i]     <= 32'b0;
        req_b_q[req_i]     <= 32'b0;
        req_pipe1_q[req_i] <= 1'b0;
    end
end
else
begin
    ing0_valid_q <= req0_ingress_w;
    ing1_valid_q <= req1_ingress_w;
    if (req0_ingress_w)
    begin
        ing0_op_q    <= mul_div_op_w;
        ing0_a_q     <= opcode_ra_operand_i;
        ing0_b_q     <= opcode_rb_operand_i;
        ing0_pipe1_q <= opcode_pipe1_i;
    end
    if (req1_ingress_w)
    begin
        ing1_op_q    <= mul_div_op1_w;
        ing1_a_q     <= opcode1_ra_operand_i;
        ing1_b_q     <= opcode1_rb_operand_i;
        ing1_pipe1_q <= 1'b1;
    end

    req_count_q <= req_count_r;
    for (req_i = 0; req_i < REQ_DEPTH; req_i = req_i + 1)
    begin
        req_op_q[req_i]    <= req_op_r[req_i];
        req_a_q[req_i]     <= req_a_r[req_i];
        req_b_q[req_i]     <= req_b_r[req_i];
        req_pipe1_q[req_i] <= req_pipe1_r[req_i];
    end
end

reg [MUL_DONE_LATENCY_C:0] pipe1_q;
integer pipe_i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    pipe1_q <= {(MUL_DONE_LATENCY_C+1){1'b0}};
end
else
begin
    pipe1_q[0] <= mul_launch_w ? mul_launch_pipe1_w : 1'b0;
    for (pipe_i = 1; pipe_i <= MUL_DONE_LATENCY_C; pipe_i = pipe_i + 1)
    begin
        pipe1_q[pipe_i] <= pipe1_q[pipe_i - 1];
    end
end

mul
u_mul
(
     .clk        (clk_i)
    ,.reset      (rst_i)
    ,.mult       (mul_launch_w)
    ,.mul_div_op (mul_launch_op_w)
    ,.alu_src1   (mul_launch_a_w)
    ,.alu_src2   (mul_launch_b_w)
    ,.mul_result (mul_result_w)
    ,.done       (mul_done_w)
);

assign writeback_value_o = mul_result_w;
assign writeback_valid_o = mul_done_w;
assign writeback_pipe1_o = pipe1_q[MUL_DONE_LATENCY_C];
wire [REQ_COUNT_W:0] ing_count_w =
            {{REQ_COUNT_W{1'b0}}, ing0_valid_q} +
            {{REQ_COUNT_W{1'b0}}, ing1_valid_q};
wire [REQ_COUNT_W:0] req_after_launch_count_w =
            (req_count_q != {REQ_COUNT_W{1'b0}}) ?
            ({1'b0, req_count_q} - {{REQ_COUNT_W{1'b0}}, 1'b1} + ing_count_w) :
            ((ing_count_w != {(REQ_COUNT_W+1){1'b0}}) ?
             (ing_count_w - {{REQ_COUNT_W{1'b0}}, 1'b1}) :
             {(REQ_COUNT_W+1){1'b0}});
assign accept_one_o      = (req_after_launch_count_w <=
                            {1'b0, REQ_DEPTH_C});
assign accept_two_o      = (req_after_launch_count_w <=
                            {1'b0, (REQ_DEPTH_C - {{(REQ_COUNT_W-1){1'b0}}, 1'b1})});

wire unused_real_mdu_w = |{opcode_pc_i, opcode_invalid_i, opcode_rd_idx_i,
                          opcode_ra_idx_i, opcode_rb_idx_i};

`else
reg [32:0]   operand_a_e1_q;
reg [32:0]   operand_b_e1_q;
reg          mulhi_sel_e1_q;

//-------------------------------------------------------------
// Multiplier
//-------------------------------------------------------------
wire [64:0]  mult_result_w;
reg  [32:0]  operand_b_r;
reg  [32:0]  operand_a_r;
reg  [31:0]  result_r;

always @ *
begin
    // The low 32 bits are independent of signed-high multiply selection.
    // Keep the opcode decode on the sign extension bit only.
    operand_a_r[31:0] = opcode_ra_operand_i;
    operand_a_r[32]   = inst_mulh_w ? opcode_ra_operand_i[31] : 1'b0;
end

always @ *
begin
    operand_b_r[31:0] = opcode_rb_operand_i;
    operand_b_r[32]   = inst_mulh_w ? opcode_rb_operand_i[31] : 1'b0;
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end
else if (hold_i)
    ;
else if (opcode_valid_i && mult_inst_w)
begin
    operand_a_e1_q <= operand_a_r;
    operand_b_e1_q <= operand_b_r;
    mulhi_sel_e1_q <= ~inst_mul_w;
end
// Keep the previous operands while the multiplier is idle.  The result is
// only consumed for a multiply instruction, so clearing these registers here
// only adds a wide D-input mux controlled by issue/exception signals.

assign mult_result_w = {{32{operand_a_e1_q[32]}}, operand_a_e1_q} *
                       {{32{operand_b_e1_q[32]}}, operand_b_e1_q};

always @ *
begin
    result_r = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e2_q <= 32'b0;
else if (~hold_i)
    result_e2_q <= result_r;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e3_q <= 32'b0;
else if (~hold_i)
    result_e3_q <= result_e2_q;

assign writeback_value_o  = (MULT_STAGES == 3) ? result_e3_q : result_e2_q;
assign writeback_valid_o  = 1'b1;
`endif


endmodule
