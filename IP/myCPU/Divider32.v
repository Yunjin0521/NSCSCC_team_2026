module Divider32 (
    input  wire        clk,
    input  wire        reset,
    input  wire        div,
    input  wire        div_signed,
    input  wire [31:0] x,
    input  wire [31:0] y,
    output reg  [31:0] q,
    output reg  [31:0] r,
    output reg         busy,
    output reg         done
);

    reg [63:0] dividend_reg;
    reg [63:0] shifted_next;
    reg [31:0] divisor_reg;
    reg [5:0]  count;
    reg        x_neg;
    reg        y_neg;

    wire [31:0] x_abs = (div_signed && x[31]) ? -x : x;
    wire [31:0] y_abs = (div_signed && y[31]) ? -y : y;

    always @(*) begin
        shifted_next = {dividend_reg[62:0], 1'b0};
        if (shifted_next[63:32] >= divisor_reg) begin
            shifted_next[63:32] = shifted_next[63:32] - divisor_reg;
            shifted_next[0]     = 1'b1;
        end else begin
            shifted_next[0]     = 1'b0;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q            <= 32'd0;
            r            <= 32'd0;
            busy         <= 1'b0;
            done         <= 1'b0;
            count        <= 6'd0;
            dividend_reg <= 64'd0;
            divisor_reg  <= 32'd0;
            x_neg        <= 1'b0;
            y_neg        <= 1'b0;
        end else if (div && !busy) begin
            dividend_reg <= {32'd0, x_abs};
            divisor_reg  <= y_abs;
            busy         <= 1'b1;
            done         <= 1'b0;
            count        <= 6'd0;
            x_neg        <= div_signed && x[31];
            y_neg        <= div_signed && y[31];
        end else if (busy) begin
            if (count < 6'd32) begin
                dividend_reg <= shifted_next;
                count        <= count + 6'd1;
            end else begin
                busy <= 1'b0;
                done <= 1'b1;
                if (div_signed) begin
                    q <= (x_neg ^ y_neg) ? -dividend_reg[31:0] : dividend_reg[31:0];
                    r <= x_neg ? -dividend_reg[63:32] : dividend_reg[63:32];
                end else begin
                    q <= dividend_reg[31:0];
                    r <= dividend_reg[63:32];
                end
            end
        end else begin
            done <= 1'b0;
        end
    end

endmodule
