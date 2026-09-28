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

module biloong_exec
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
    ,input  [  3:0]  opcode_alu_func_i
    ,input  [  1:0]  opcode_alu_a_sel_i
    ,input  [  1:0]  opcode_alu_b_sel_i
    ,input  [  3:0]  opcode_direct_func_i
    ,input  [  3:0]  opcode_branch_func_i
    ,input  [ 31:0]  opcode_imm_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input           hold_i

    // Outputs
    ,output          branch_request_o
    ,output          branch_is_taken_o
    ,output          branch_is_not_taken_o
    ,output [ 31:0]  branch_source_o
    ,output          branch_is_call_o
    ,output          branch_is_ret_o
    ,output          branch_is_jmp_o
    ,output [ 31:0]  branch_pc_o
    ,output          branch_d_request_o
    ,output [ 31:0]  branch_d_pc_o
    ,output [  1:0]  branch_d_priv_o
    ,output [ 31:0]  writeback_value_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biloong_defs.v"
wire [31:0] bdot_result_w;

bdot u_bdot
(
     .src_a_i(opcode_ra_operand_i)
    ,.src_b_i(opcode_rb_operand_i)
    ,.result_o(bdot_result_w)
);
//-------------------------------------------------------------
// Execute - ALU operations
//-------------------------------------------------------------
reg [3:0]  alu_func_r;
reg [31:0] alu_input_a_r;
reg [31:0] alu_input_b_r;
reg        alu_direct_r;
reg [31:0] alu_direct_result_r;

always @ *
begin
    alu_func_r          = opcode_alu_func_i;
    alu_input_a_r       = 32'b0;
    alu_input_b_r       = 32'b0;
    alu_direct_r        = 1'b0;
    alu_direct_result_r = 32'b0;

    case (opcode_alu_a_sel_i)
    `EXEC_ALU_A_RA:  alu_input_a_r = opcode_ra_operand_i;
    `EXEC_ALU_A_PC:  alu_input_a_r = opcode_pc_i;
    `EXEC_ALU_A_IMM: alu_input_a_r = opcode_imm_i;
    default:         alu_input_a_r = 32'b0;
    endcase

    case (opcode_alu_b_sel_i)
    `EXEC_ALU_B_RB:   alu_input_b_r = opcode_rb_operand_i;
    `EXEC_ALU_B_IMM:  alu_input_b_r = opcode_imm_i;
    `EXEC_ALU_B_FOUR: alu_input_b_r = 32'd4;
    default:          alu_input_b_r = 32'b0;
    endcase

    case (opcode_direct_func_i)
    `EXEC_DIRECT_BDOT:
    begin
        alu_direct_r        = 1'b1;
        alu_direct_result_r = bdot_result_w;
    end
    `EXEC_DIRECT_NOR:
    begin
        alu_direct_r        = 1'b1;
        alu_direct_result_r = ~(opcode_ra_operand_i | opcode_rb_operand_i);
    end
    `EXEC_DIRECT_ORN:
    begin
        alu_direct_r        = 1'b1;
        alu_direct_result_r = opcode_ra_operand_i | ~opcode_rb_operand_i;
    end
    `EXEC_DIRECT_ANDN:
    begin
        alu_direct_r        = 1'b1;
        alu_direct_result_r = opcode_ra_operand_i & ~opcode_rb_operand_i;
    end
    `EXEC_DIRECT_LU12:
    begin
        alu_direct_r        = 1'b1;
        alu_direct_result_r = opcode_imm_i;
    end
    default: ;
    endcase
end


//-------------------------------------------------------------
// ALU
//-------------------------------------------------------------
wire [31:0]  alu_p_w;
biloong_alu
u_alu
(
    .alu_op_i(alu_func_r),
    .alu_a_i(alu_input_a_r),
    .alu_b_i(alu_input_b_r),
    .alu_p_o(alu_p_w)
);

wire [31:0] alu_result_w = alu_direct_r ? alu_direct_result_r : alu_p_w;

//-------------------------------------------------------------
// Flop ALU output
//-------------------------------------------------------------
reg [31:0] result_q;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    result_q  <= 32'b0;
else if (~hold_i)
begin
    result_q <= alu_result_w;
end

assign writeback_value_o  = result_q;

//-----------------------------------------------------------------
// less_than_signed: Less than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x < (int)y
//-----------------------------------------------------------------
function [0:0] less_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (x - y);
    if (x[31] != y[31])
        less_than_signed = x[31];
    else
        less_than_signed = v[31];
end
endfunction

//-----------------------------------------------------------------
// greater_than_signed: Greater than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x > (int)y
//-----------------------------------------------------------------
function [0:0] greater_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (y - x);
    if (x[31] != y[31])
        greater_than_signed = y[31];
    else
        greater_than_signed = v[31];
end
endfunction

//-------------------------------------------------------------
// Execute - Branch operations
//-------------------------------------------------------------
reg        branch_r;
reg        branch_taken_r;
reg [31:0] branch_target_r;
reg        branch_call_r;
reg        branch_ret_r;
reg        branch_jmp_r;

always @ *
begin
    branch_r        = 1'b0;
    branch_taken_r  = 1'b0;
    branch_call_r   = 1'b0;
    branch_ret_r    = 1'b0;
    branch_jmp_r    = 1'b0;
    branch_target_r = opcode_pc_i + opcode_imm_i;

    case (opcode_branch_func_i)
    `EXEC_BRANCH_B:
    begin
        branch_r       = 1'b1;
        branch_taken_r = 1'b1;
        branch_jmp_r   = 1'b1;
    end
    `EXEC_BRANCH_BL:
    begin
        branch_r       = 1'b1;
        branch_taken_r = 1'b1;
        branch_call_r  = 1'b1;
        branch_jmp_r   = 1'b1;
    end
    `EXEC_BRANCH_JIRL:
    begin
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = opcode_ra_operand_i + opcode_imm_i;
        branch_ret_r    = (opcode_ra_idx_i == 5'd1) && (opcode_rd_idx_i == 5'd0) && (opcode_imm_i == 32'd0);
        branch_call_r   = ~branch_ret_r && (opcode_rd_idx_i == 5'd1);
        branch_jmp_r    = ~(branch_call_r | branch_ret_r);
    end
    `EXEC_BRANCH_BEQ:
    begin
        branch_r       = 1'b1;
        branch_taken_r = (opcode_ra_operand_i == opcode_rb_operand_i);
    end
    `EXEC_BRANCH_BNE:
    begin
        branch_r       = 1'b1;
        branch_taken_r = (opcode_ra_operand_i != opcode_rb_operand_i);
    end
    `EXEC_BRANCH_BLT:
    begin
        branch_r       = 1'b1;
        branch_taken_r = less_than_signed(opcode_ra_operand_i, opcode_rb_operand_i);
    end
    `EXEC_BRANCH_BGE:
    begin
        branch_r       = 1'b1;
        branch_taken_r = greater_than_signed(opcode_ra_operand_i, opcode_rb_operand_i) |
                         (opcode_ra_operand_i == opcode_rb_operand_i);
    end
    `EXEC_BRANCH_BLTU:
    begin
        branch_r       = 1'b1;
        branch_taken_r = (opcode_ra_operand_i < opcode_rb_operand_i);
    end
    `EXEC_BRANCH_BGEU:
    begin
        branch_r       = 1'b1;
        branch_taken_r = (opcode_ra_operand_i >= opcode_rb_operand_i);
    end
    default: ;
    endcase
end

reg        branch_taken_q;
reg        branch_ntaken_q;
reg [31:0] pc_x_q;
reg [31:0] pc_m_q;
reg        branch_call_q;
reg        branch_ret_q;
reg        branch_jmp_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    branch_taken_q   <= 1'b0;
    branch_ntaken_q  <= 1'b0;
    pc_x_q           <= 32'b0;
    pc_m_q           <= 32'b0;
    branch_call_q    <= 1'b0;
    branch_ret_q     <= 1'b0;
    branch_jmp_q     <= 1'b0;
end
else if (~hold_i)
begin
    branch_taken_q   <= opcode_valid_i && branch_r && branch_taken_r;
    branch_ntaken_q  <= opcode_valid_i && branch_r && ~branch_taken_r;
    pc_x_q           <= branch_taken_r ? branch_target_r : opcode_pc_i + 32'd4;
    branch_call_q    <= opcode_valid_i && branch_r && branch_call_r;
    branch_ret_q     <= opcode_valid_i && branch_r && branch_ret_r;
    branch_jmp_q     <= opcode_valid_i && branch_r && branch_jmp_r;
    pc_m_q           <= opcode_pc_i;
end

assign branch_request_o   = branch_taken_q | branch_ntaken_q;
assign branch_is_taken_o  = branch_taken_q;
assign branch_is_not_taken_o = branch_ntaken_q;
assign branch_source_o    = pc_m_q;
assign branch_pc_o        = pc_x_q;
assign branch_is_call_o   = branch_call_q;
assign branch_is_ret_o    = branch_ret_q;
assign branch_is_jmp_o    = branch_jmp_q;

assign branch_d_request_o = (branch_r && opcode_valid_i && branch_taken_r);
assign branch_d_pc_o      = branch_target_r;
assign branch_d_priv_o    = 2'b0; // don't care



endmodule
