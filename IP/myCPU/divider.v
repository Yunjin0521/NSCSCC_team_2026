module divider (
    input  wire        div_clk,
    input  wire        reset,
    input  wire        div,
    input  wire        div_signed,
    input  wire [31:0] x,
    input  wire [31:0] y,
    output wire [31:0] s,
    output wire [31:0] r,
    output wire        complete
);

    wire busy;

    Divider32 u_divider32 (
        .clk        (div_clk),
        .reset      (reset),
        .div        (div),
        .div_signed (div_signed),
        .x          (x),
        .y          (y),
        .q          (s),
        .r          (r),
        .busy       (busy),
        .done       (complete)
    );

    wire unused_busy = busy;

endmodule
