`ifndef RTL_DEBUG_VH
`define RTL_DEBUG_VH

`ifndef CPU_DEBUG_CYCLE_DIV
`define CPU_DEBUG_CYCLE_DIV 1
`endif

`ifndef CPU_DEBUG_WATCHDOG_LIMIT
`define CPU_DEBUG_WATCHDOG_LIMIT 1024
`endif

`define CPU_DEBUG_LEVEL_GE2 \
    ($test$plusargs("DEBUG_VERBOSE") || $test$plusargs("DEBUG_LEVEL=2") || \
     $test$plusargs("DEBUG_LEVEL=3") || $test$plusargs("DEBUG_LEVEL=4") || \
     $test$plusargs("DEBUG_LEVEL=5") || $test$plusargs("DEBUG_LEVEL=6") || \
     $test$plusargs("DEBUG_LEVEL=7") || $test$plusargs("DEBUG_LEVEL=8") || \
     $test$plusargs("DEBUG_LEVEL=9") || $test$plusargs("DEBUG_LEVEL=10"))

`define CPU_DEBUG_LEVEL_GE3 \
    ($test$plusargs("DEBUG_VERBOSE") || $test$plusargs("DEBUG_LEVEL=3") || \
     $test$plusargs("DEBUG_LEVEL=4") || $test$plusargs("DEBUG_LEVEL=5") || \
     $test$plusargs("DEBUG_LEVEL=6") || $test$plusargs("DEBUG_LEVEL=7") || \
     $test$plusargs("DEBUG_LEVEL=8") || $test$plusargs("DEBUG_LEVEL=9") || \
     $test$plusargs("DEBUG_LEVEL=10"))

`define CPU_DEBUG_LEVEL_OK(LVL) \
    (((LVL) <= 1) || (((LVL) <= 2) && `CPU_DEBUG_LEVEL_GE2) || \
     (((LVL) <= 3) && `CPU_DEBUG_LEVEL_GE3))

`ifdef VERILATOR
`define CPU_DEBUG_HAS_RUNTIME
`else
`ifdef TB_DEBUG
`define CPU_DEBUG_HAS_RUNTIME
`endif
`endif

`define CPU_DEBUG_EMIT(TAG, PLUSARG, LVL, MSG) \
    if ($test$plusargs(PLUSARG) && `CPU_DEBUG_LEVEL_OK(LVL)) \
        $display("[%s][cycle=%0d time=%0t][%m] %s", TAG, \
                 ($time / `CPU_DEBUG_CYCLE_DIV), $time, MSG);

`ifdef VERILATOR
`ifndef TB_DEBUG
`define CPU_VERILATOR_DEBUG_LVL(LVL, MSG) \
    `CPU_DEBUG_EMIT("RTL-VDBG", "RTL_LOG", LVL, MSG)
`else
`define CPU_VERILATOR_DEBUG_LVL(LVL, MSG)
`endif
`else
`define CPU_VERILATOR_DEBUG_LVL(LVL, MSG)
`endif

`ifdef TB_DEBUG
`define CPU_TB_DEBUG_LVL(LVL, MSG) \
    `CPU_DEBUG_EMIT("RTL-TBDBG", "TB_DEBUG", LVL, MSG)
`else
`define CPU_TB_DEBUG_LVL(LVL, MSG)
`endif

`define CPU_VERILATOR_DEBUG(MSG) `CPU_VERILATOR_DEBUG_LVL(1, MSG)
`define CPU_TB_DEBUG(MSG)        `CPU_TB_DEBUG_LVL(1, MSG)

`define CPU_DEBUG_LVL(LVL, MSG) \
    begin \
        `CPU_VERILATOR_DEBUG_LVL(LVL, MSG) \
        `CPU_TB_DEBUG_LVL(LVL, MSG) \
    end

`define CPU_DEBUG(MSG) \
    `CPU_DEBUG_LVL(1, MSG)

`ifdef CPU_DEBUG_HAS_RUNTIME
`define CPU_ASSERT(NAME, COND, MSG) \
    begin \
        if (!(COND)) begin \
            $display("[RTL-ASSERT][cycle=%0d time=%0t][%m] name=%s cond=\"%s\" detail=%s", \
                     ($time / `CPU_DEBUG_CYCLE_DIV), $time, NAME, `"COND`", MSG); \
            if ($test$plusargs("DEBUG_FATAL")) \
                $fatal(1, "[RTL-ASSERT-FATAL] %s", NAME); \
        end \
    end
`else
`define CPU_ASSERT(NAME, COND, MSG)
`endif

`ifdef CPU_DEBUG_HAS_RUNTIME
`define CPU_DEBUG_WATCHDOG(ID, CLK, RST_N, ACTIVE, PROGRESS, LIMIT, MSG) \
    reg [31:0] ID``_debug_wait_q; \
    always @(posedge CLK) begin \
        if (!(RST_N) || !(ACTIVE) || (PROGRESS)) begin \
            ID``_debug_wait_q <= 32'd0; \
        end else begin \
            ID``_debug_wait_q <= ID``_debug_wait_q + 32'd1; \
            if (ID``_debug_wait_q == (LIMIT)) begin \
                $display("[RTL-DEADLOCK][cycle=%0d time=%0t][%m] name=%s wait_cycles=%0d detail=%s", \
                         ($time / `CPU_DEBUG_CYCLE_DIV), $time, `"ID`", ID``_debug_wait_q, MSG); \
                if ($test$plusargs("DEBUG_FATAL")) \
                    $fatal(1, "[RTL-DEADLOCK-FATAL] %s", `"ID`"); \
            end \
        end \
    end
`else
`define CPU_DEBUG_WATCHDOG(ID, CLK, RST_N, ACTIVE, PROGRESS, LIMIT, MSG)
`endif

`ifdef CPU_DEBUG_HAS_RUNTIME
`define CPU_DEBUG_MODULE(MODNAME) \
    initial begin \
        `CPU_DEBUG_LVL(2, {"[MOD] module=", MODNAME, " elaborated"}); \
    end
`else
`define CPU_DEBUG_MODULE(MODNAME)
`endif

`endif
