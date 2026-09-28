// ---- Auto-generated one-bit adders ----
module HalfAdder(a, b, sum, cout);
  input a, b;
  output sum, cout;
  assign sum = a ^ b;
  assign cout = a & b;
endmodule

module FullAdder(a, b, cin, sum, cout);
  input a, b, cin;
  output sum, cout;
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule
