`ifndef MUL_DONE_LATENCY
`define MUL_DONE_LATENCY 4
`endif

module mul (
    input  wire        clk,
    input  wire        reset,
    input  wire        mult,
    input  wire [9:0]  mul_div_op,
    input  wire [31:0] alu_src1,
    input  wire [31:0] alu_src2,
    output reg  [31:0] mul_result,
    output wire        done
);

    localparam integer MUL_DONE_LATENCY_C = `MUL_DONE_LATENCY;

    wire [63:0] mul_res64;
    wire        top_done;
    wire        signed_op;
    reg  [2:0]  op_pipe [0:MUL_DONE_LATENCY_C];
    integer     op_i;

    assign signed_op = mul_div_op[0] || mul_div_op[1];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (op_i = 0; op_i <= MUL_DONE_LATENCY_C; op_i = op_i + 1) begin
                op_pipe[op_i] <= 3'b0;
            end
        end else begin
            op_pipe[0] <= mult ? mul_div_op[2:0] : 3'b0;
            for (op_i = 1; op_i <= MUL_DONE_LATENCY_C; op_i = op_i + 1) begin
                op_pipe[op_i] <= op_pipe[op_i - 1];
            end
        end
    end

    TopMultiplier u_topmul (
        .clk        (clk),
        .reset      (reset),
        .mult       (mult),
        .x_in       (alu_src1),
        .y_in       (alu_src2),
        .signed_op  (signed_op),
        .result_out (mul_res64),
        .done       (top_done)
    );

    assign done = top_done;

    always @(*) begin
        case (op_pipe[MUL_DONE_LATENCY_C])
            3'b001: mul_result = mul_res64[31:0];
            3'b010: mul_result = mul_res64[63:32];
            3'b100: mul_result = mul_res64[63:32];
            default: mul_result = 32'b0;
        endcase
    end

endmodule
