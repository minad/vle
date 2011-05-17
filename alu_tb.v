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

   wire signed [n-1:0] sa = a;
   wire signed [n-1:0] sb = b;
   wire signed [n-1:0] sc = c;

   initial begin
      #1 /////////// UNSIGNED ADD
      cin = 0;
      op = `ALU_ADD;

      $monitor("unsigned %d + %d = %d (zero=%b, carry=%b)", a, b, c, zero, cout);

      #1
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
      a = 255;
      b = 255;

      #1
      a = 127;
      b = 1;

      #1 /////////// SIGNED ADD
      cin = 0;
      op = `ALU_ADD;

      $monitor("signed %d + %d = %d (zero=%b, sign=%d, overflow=%b)", sa, sb, sc, zero, sign, overflow);

      #1
      a = 1;
      b = 1;

      #1
      a = -1;
      b = 1;

      #1
      a = -1;
      b = 2;

      #1
      a = 127;
      b = 127;

      #1
      a = -1;
      b = -1;

      #1
      a = 127;
      b = 1;

      #1 /////////// UNSIGNED SUB
      cin = 0;
      op = `ALU_SUB;

      $monitor("unsigned %d - %d = %d (zero=%b, carry=%b)", a, b, c, zero, cout);

      #1
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
      a = 255;
      b = 255;

      #1
      a = 1;
      b = 2;

      #1 /////////// SIGNED SUB
      cin = 0;
      op = `ALU_SUB;

      $monitor("signed %d - %d = %d (zero=%b, sign=%d, overflow=%b)", sa, sb, sc, zero, sign, overflow);

      #1
      a = 1;
      b = 1;

      #1
      a = -1;
      b = 1;

      #1
      a = -1;
      b = 2;

      #1
      a = 127;
      b = 127;

      #1
      a = -1;
      b = -1;

      #1
      a = -128;
      b = 1;
   end
endmodule
