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
      /////////// UNSIGNED ADD
      cin = 0;
      op = `ALU_ADD;

      $monitor("unsigned %d + %d = %d (zero=%b, carry=%b)", a, b, c, zero, cout);

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

      $monitor("signed %d + %d = %d (zero=%b, sign=%d, overflow=%b)", sa, sb, sc, zero, sign, overflow);

      cin = 0;
      op = `ALU_ADD;
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

      $monitor("unsigned %d - %d = %d (zero=%b, carry=%b)", a, b, c, zero, cout);

      cin = 0;
      op = `ALU_SUB;
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

      #1 //////////// LSL

      $monitor("lsl %b << %d = %b", a, b, c);

      op = `ALU_LSL;
      a = 8'b00111010;
      b = 2;

      #1 //////////// LSR

      $monitor("lsr %b >> %d = %b", a, b, c);

      op = `ALU_LSR;
      a = 8'b00111010;
      b = 2;

      #1 //////////// ASR

      $monitor("asr %b >> %d = %b", a, b, c);

      op = `ALU_ASR;
      a = 8'b10111010;
      b = 2;

      #1 //////////// MUL

      $monitor("unsigned %d * %d = %d (overflow=%b)", a, b, c, overflow);

      op = `ALU_MUL;
      a = 10;
      b = 12;

      #1
      a = 20;
      b = 30;

      #1 //////////// SMUL

      $monitor("signed %d * %d = %d (overflow=%b)", sa, sb, sc, overflow);

      op = `ALU_SMUL;
      a = -3;
      b = 7;

   end
endmodule
