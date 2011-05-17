`include "alu.v"

module alu_tb;
   localparam n = 8;

   reg [n-1:0]  a;
   reg [n-1:0] 	b;
   reg [6:0] 	op;
   reg 		cin;
   wire [n-1:0] c;
   wire		cout, overflow, sign, zero;

   alu #(n) u(.a(a), .b(b), .out(c), .op(op), .cin(cin), .cout(cout),
	      .overflow(overflow), .sign(sign), .zero(zero));

   initial begin
      $monitor("%d + %d = %d (overflow=%b, sign=%b, zero=%b, carry=%b)", a, b, c, overflow, sign, zero, cout);

      cin = 0;

      op = `ALU_ADD;
      a = 1;
      b = 1;

      #1
      a = 255;
      b = 1;

      #1
      a = 255;
      b = 2;

      #1
      a = 127;
      b = 127;

      #1
      a = -1;
      b = -1;

      #1
      $monitor("%d - %d = %d (overflow=%b, sign=%b, zero=%b, carry=%b)", a, b, c, overflow, sign, zero, cout);
      op = `ALU_SUB;
      a = 10;
      b = 3;

   end
endmodule
