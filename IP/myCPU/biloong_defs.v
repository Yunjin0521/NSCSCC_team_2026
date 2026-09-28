//-----------------------------------------------------------------
//                         Biloong CPU
//                            V0.8.1
//-----------------------------------------------------------------

//--------------------------------------------------------------------
// ALU Operations
//--------------------------------------------------------------------
`define ALU_NONE                                4'b0000
`define ALU_SHIFTL                              4'b0001
`define ALU_SHIFTR                              4'b0010
`define ALU_SHIFTR_ARITH                        4'b0011
`define ALU_ADD                                 4'b0100
`define ALU_SUB                                 4'b0110
`define ALU_AND                                 4'b0111
`define ALU_OR                                  4'b1000
`define ALU_XOR                                 4'b1001
`define ALU_LESS_THAN                           4'b1010
`define ALU_LESS_THAN_SIGNED                    4'b1011

//--------------------------------------------------------------------
// Execute predecode controls
//--------------------------------------------------------------------
`define EXEC_DIRECT_NONE                        4'd0
`define EXEC_DIRECT_NOR                         4'd1
`define EXEC_DIRECT_ORN                         4'd2
`define EXEC_DIRECT_ANDN                        4'd3
`define EXEC_DIRECT_LU12                        4'd4
`define EXEC_DIRECT_BDOT                        4'd5

`define EXEC_ALU_A_ZERO                         2'd0
`define EXEC_ALU_A_RA                           2'd1
`define EXEC_ALU_A_PC                           2'd2
`define EXEC_ALU_A_IMM                          2'd3

`define EXEC_ALU_B_ZERO                         2'd0
`define EXEC_ALU_B_RB                           2'd1
`define EXEC_ALU_B_IMM                          2'd2
`define EXEC_ALU_B_FOUR                         2'd3

`define EXEC_BRANCH_NONE                        4'd0
`define EXEC_BRANCH_B                           4'd1
`define EXEC_BRANCH_BL                          4'd2
`define EXEC_BRANCH_JIRL                        4'd3
`define EXEC_BRANCH_BEQ                         4'd4
`define EXEC_BRANCH_BNE                         4'd5
`define EXEC_BRANCH_BLT                         4'd6
`define EXEC_BRANCH_BGE                         4'd7
`define EXEC_BRANCH_BLTU                        4'd8
`define EXEC_BRANCH_BGEU                        4'd9

`define EXEC_INFO_W                             48

//--------------------------------------------------------------------
// LoongArch instruction fields
//--------------------------------------------------------------------
`define LA_RD_R                                 4:0
`define LA_RJ_R                                 9:5
`define LA_RK_R                                 14:10
`define LA_OP_19_15_R                           19:15
`define LA_OP_21_20_R                           21:20
`define LA_OP_25_22_R                           25:22
`define LA_OP_31_26_R                           31:26
`define LA_OP_31_15_R                           31:15
`define LA_CSR_NUM_R                            23:10

//--------------------------------------------------------------------
// Privilege levels
//--------------------------------------------------------------------
`define PRIV_USER                               2'd0
`define PRIV_SUPER                              2'd1
`define PRIV_MACHINE                            2'd3

//--------------------------------------------------------------------
// Internal exception codes
//--------------------------------------------------------------------
`define EXCEPTION_W                             6
`define EXCEPTION_MISALIGNED_FETCH              6'h10
`define EXCEPTION_FAULT_FETCH                   6'h11
`define EXCEPTION_ILLEGAL_INSTRUCTION           6'h12
`define EXCEPTION_BREAKPOINT                    6'h13
`define EXCEPTION_MISALIGNED_LOAD               6'h14
`define EXCEPTION_FAULT_LOAD                    6'h15
`define EXCEPTION_MISALIGNED_STORE              6'h16
`define EXCEPTION_FAULT_STORE                   6'h17
`define EXCEPTION_ECALL                         6'h18
`define EXCEPTION_ECALL_U                       6'h18
`define EXCEPTION_ECALL_S                       6'h19
`define EXCEPTION_ECALL_H                       6'h1a
`define EXCEPTION_ECALL_M                       6'h1b
`define EXCEPTION_PAGE_FAULT_INST               6'h1c
`define EXCEPTION_PAGE_FAULT_LOAD               6'h1d
`define EXCEPTION_PRIVILEGED_INSTRUCTION        6'h1e
`define EXCEPTION_PAGE_FAULT_STORE              6'h1f
`define EXCEPTION_EXCEPTION                     6'h10
`define EXCEPTION_INTERRUPT                     6'h20
`define EXCEPTION_ERET_U                        6'h30
`define EXCEPTION_ERET_S                        6'h31
`define EXCEPTION_ERET_H                        6'h32
`define EXCEPTION_ERET_M                        6'h33
`define EXCEPTION_FENCE                         6'h34
`define EXCEPTION_IDLE                          6'h35
`define EXCEPTION_TYPE_MASK                     6'h30
`define EXCEPTION_SUBTYPE_R                     3:0

//--------------------------------------------------------------------
// LoongArch architectural exception ecode values
//--------------------------------------------------------------------
`define LA_ECODE_PIL                            6'h01
`define LA_ECODE_PIS                            6'h02
`define LA_ECODE_PIF                            6'h03
`define LA_ECODE_PME                            6'h04
`define LA_ECODE_PPI                            6'h07
`define LA_ECODE_ADE                            6'h08
`define LA_ECODE_ALE                            6'h09
`define LA_ECODE_SYS                            6'h0b
`define LA_ECODE_BRK                            6'h0c
`define LA_ECODE_INE                            6'h0d
`define LA_ECODE_IPE                            6'h0e
`define LA_ECODE_TLBR                           6'h3f
 //`define CPU_REAL_MDU

`ifdef CPU_REAL_MDU
`ifndef MUL_DONE_LATENCY
`define MUL_DONE_LATENCY                        4
`endif
`endif
