`include "defines.v"

module rotate
  #(parameter n = `DEFAULT_WIDTH,
    parameter left = 1)
   (output [n-1:0] out,
    input [n-1:0] a,
    input [$clog2(n)-1:0] b);

   wire [n-1:0] s[$clog2(n)+1:0];
   assign s[0] = a;
   assign out = s[$clog2(n)];

   generate
      genvar i;
      for (i = 0; i < $clog2(n); i = i + 1) begin
	 localparam j = left ? 1<<i : n - (1<<i);
	 assign s[i+1] = b[i] ? {s[i][n-j-1:0], s[i][n-1:n-j]} : s[i];
      end
   endgenerate
endmodule

module rotate_tb;
   reg [7:0] a;
   reg [2:0] b;
   wire [7:0] left, right;
   rotate #(.n(8))           rol(.a(a), .b(b), .out(left));
   rotate #(.n(8), .left(0)) ror(.a(a), .b(b), .out(right));

   initial begin
      $display("Rotate");
      $monitor("%b << %d = %b | %b >> %d = %b", a, b, left, a, b, right);

      a = 8'b10000111;
      b = 0;

      #1
      a = 8'b10000111;
      b = 1;

      #1
      a = 8'b10000111;
      b = 2;

      #1
      a = 8'b10000111;
      b = 3;

      #1
      a = 8'b10000111;
      b = 4;

      #1
      a = 8'b10000111;
      b = 5;

      #1
      a = 8'b10000111;
      b = 6;

      #1
      a = 8'b10000111;
      b = 7;

      #1
      a = 8'b10000111;
      b = 8;
   end
endmodule
