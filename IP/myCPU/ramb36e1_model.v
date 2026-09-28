`timescale 1ns / 1ps
`include "rtl_debug.vh"

// Simulation-only behavioral model for the subset of Xilinx RAMB36E1 used here.
module RAMB36E1 #(
    parameter         RAM_MODE             = "SDP",
    parameter integer READ_WIDTH_A         = 36,
    parameter integer WRITE_WIDTH_B        = 36,
    parameter integer DOA_REG              = 0,
    parameter         WRITE_MODE_A         = "READ_FIRST",
    parameter         WRITE_MODE_B         = "READ_FIRST",
    parameter         INIT_FILE            = "NONE",
    parameter         SIM_COLLISION_CHECK  = "ALL",
    parameter         RAM_EXTENSION_A      = "NONE",
    parameter         RAM_EXTENSION_B      = "NONE",
    parameter         RDADDR_COLLISION_HWCONFIG = "DELAYED_WRITE",
    parameter         RSTREG_PRIORITY_A    = "RSTREG",
    parameter         RSTREG_PRIORITY_B    = "RSTREG",
    parameter         SIM_DEVICE           = "7SERIES",
    parameter [35:0]  DOA_REG_INIT         = 36'h000000000,
    parameter [35:0]  DOB_REG_INIT         = 36'h000000000
) (
    input  wire        CLKARDCLK,
    input  wire        ENARDEN,
    input  wire        RSTRAMARSTRAM,
    input  wire        RSTREGARSTREG,
    input  wire        REGCEAREGCE,
    input  wire [3:0]  WEA,
    input  wire [14:0] ADDRARDADDR,
    input  wire [31:0] DIADI,
    input  wire [3:0]  DIPADIP,
    output wire [31:0] DOADO,
    output wire [31:0] DOBDO,
    output wire [3:0]  DOPADOP,
    output wire [3:0]  DOPBDOP,

    input  wire        CLKBWRCLK,
    input  wire        ENBWREN,
    input  wire [7:0]  WEBWE,
    input  wire [14:0] ADDRBWRADDR,
    input  wire [31:0] DIBDI,
    input  wire [3:0]  DIPBDIP,

    input  wire        CASCADEINA,
    input  wire        CASCADEINB,
    output wire        CASCADEOUTA,
    output wire        CASCADEOUTB,

    input  wire        INJECTDBITERR,
    input  wire        INJECTSBITERR,
    output wire        DBITERR,
    output wire        SBITERR,
    output wire [7:0]  ECCPARITY,
    output wire [8:0]  RDADDRECC
);

    reg [31:0] mem [0:1023];

    wire [9:0] rd_addr = ADDRARDADDR[14:5];
    wire [9:0] wr_addr = ADDRBWRADDR[14:5];

    always @(posedge CLKBWRCLK) begin
        if (ENBWREN) begin
            if (WEBWE[0]) mem[wr_addr][7:0]   <= DIBDI[7:0];
            if (WEBWE[1]) mem[wr_addr][15:8]  <= DIBDI[15:8];
            if (WEBWE[2]) mem[wr_addr][23:16] <= DIBDI[23:16];
            if (WEBWE[3]) mem[wr_addr][31:24] <= DIBDI[31:24];
        end
    end

    reg [31:0] rd_stage1_q;
    always @(posedge CLKARDCLK) begin
        if (ENARDEN)
            rd_stage1_q <= mem[rd_addr];
    end

    generate
        if (DOA_REG == 1) begin : gen_output_reg
            reg [31:0] rd_stage2_q;
            always @(posedge CLKARDCLK) begin
                if (REGCEAREGCE)
                    rd_stage2_q <= rd_stage1_q;
            end
            assign DOADO = rd_stage2_q;
        end else begin : gen_no_output_reg
            assign DOADO = rd_stage1_q;
        end
    endgenerate

    assign DOBDO = 32'h0;
    assign DOPADOP = 4'h0;
    assign DOPBDOP = 4'h0;
    assign CASCADEOUTA = 1'b0;
    assign CASCADEOUTB = 1'b0;
    assign DBITERR = 1'b0;
    assign SBITERR = 1'b0;
    assign ECCPARITY = 8'h0;
    assign RDADDRECC = 9'h0;

`ifdef VERILATOR
    always @(posedge CLKBWRCLK) begin
        if (ENBWREN && |WEBWE) begin
            `CPU_TB_DEBUG_LVL(3, $sformatf("[BRAM][RAMB36E1][WRITE] addr=%0d we=0x%0x data=0x%08x", wr_addr, WEBWE[3:0], DIBDI));
        end
    end

    always @(posedge CLKARDCLK) begin
        if (ENARDEN && $test$plusargs("RAMB_DEBUG")) begin
            `CPU_TB_DEBUG_LVL(3, $sformatf("[BRAM][RAMB36E1][READ] addr=%0d data=0x%08x doa_reg=%0d", rd_addr, DOADO, DOA_REG));
        end
    end
`endif

endmodule
