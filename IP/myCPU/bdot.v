module bdot (
    input  wire [31:0] src_a_i,
    input  wire [31:0] src_b_i,
    output reg signed [31:0] result_o  
);

    integer i;
    reg signed [31:0] sum;   

    always @(*) begin
        sum = 0;
        for (i = 0; i < 32; i = i + 1) begin
            if (src_a_i[i] == src_b_i[i])
                sum = sum + 32'sb1;   
            else
                sum = sum - 32'sb1;   
        end
        result_o = sum;              
end

endmodule