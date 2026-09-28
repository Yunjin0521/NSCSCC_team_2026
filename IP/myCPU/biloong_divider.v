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

module biloong_divider
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

    // Outputs
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_value_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg          valid_q;
reg  [31:0]  wb_result_q;

//-------------------------------------------------------------
// Divider
//-------------------------------------------------------------
wire [5:0] op_31_26_w = opcode_opcode_i[`LA_OP_31_26_R];
wire [3:0] op_25_22_w = opcode_opcode_i[`LA_OP_25_22_R];
wire [1:0] op_21_20_w = opcode_opcode_i[`LA_OP_21_20_R];
wire [4:0] op_19_15_w = opcode_opcode_i[`LA_OP_19_15_R];

wire inst_div_w     = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                      (op_21_20_w == 2'h2) && (op_19_15_w == 5'h00);
wire inst_mod_w     = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                      (op_21_20_w == 2'h2) && (op_19_15_w == 5'h01);
wire inst_div_wu_w  = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                      (op_21_20_w == 2'h2) && (op_19_15_w == 5'h02);
wire inst_mod_wu_w  = (op_31_26_w == 6'h00) && (op_25_22_w == 4'h0) &&
                      (op_21_20_w == 2'h2) && (op_19_15_w == 5'h03);

wire div_rem_inst_w = inst_div_w || inst_mod_w || inst_div_wu_w || inst_mod_wu_w;
wire div_signed_w   = inst_div_w || inst_mod_w;
wire div_select_q_w = inst_div_w || inst_div_wu_w;
wire div_start_w    = opcode_valid_i & div_rem_inst_w;

wire [31:0] divider_quot_w;
wire [31:0] divider_rem_w;
wire        divider_complete_w;
wire        divider_signed_w;

reg         div_select_q;
reg         div_signed_q;
reg         divisor_zero_q;
reg [31:0] dividend_q;

assign divider_signed_w = div_start_w ? div_signed_w : div_signed_q;

divider
u_divider
(
     .div_clk    (clk_i)
    ,.reset      (rst_i)
    ,.div        (div_start_w)
    ,.div_signed (divider_signed_w)
    ,.x          (opcode_ra_operand_i)
    ,.y          (opcode_rb_operand_i)
    ,.s          (divider_quot_w)
    ,.r          (divider_rem_w)
    ,.complete   (divider_complete_w)
);

always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    div_select_q   <= 1'b0;
    div_signed_q   <= 1'b0;
    divisor_zero_q <= 1'b0;
    dividend_q     <= 32'b0;
end
else if (div_start_w)
begin
    div_select_q   <= div_select_q_w;
    div_signed_q   <= div_signed_w;
    divisor_zero_q <= (opcode_rb_operand_i == 32'b0);
    dividend_q     <= opcode_ra_operand_i;
end

reg [31:0] div_result_r;
always @ *
begin
    if (divisor_zero_q && div_select_q)
        div_result_r = 32'hffff_ffff;
    else if (divisor_zero_q)
        div_result_r = dividend_q;
    else if (div_select_q)
        div_result_r = divider_quot_w;
    else
        div_result_r = divider_rem_w;
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    valid_q <= 1'b0;
else
    valid_q <= divider_complete_w;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    wb_result_q <= 32'b0;
else if (divider_complete_w)
    wb_result_q <= div_result_r;

assign writeback_valid_o = valid_q;
assign writeback_value_o  = wb_result_q;



endmodule
