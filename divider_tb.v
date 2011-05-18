`include "divider.v"

module divider_tb;
   reg signed [7:0]   a, b;
   wire signed [7:0]  c, d;

   divider #(8) div(.a(a), .b(b), .quotient(c), .reminder(d), .sign(1));

   initial begin
      $monitor("%d / %d = %d (reminder %d)", a, b, c, d);

      a = 1;
      b = 1;

      #1
      a = 42;
      b = 42;

      #1
      a = 42;
      b = 7;

      #1
      a = -42;
      b = 7;

      #1
      a = 7;
      b = -42;

      #1
      a = 10;
      b = 12;

      #1
      a = 127;
      b = 37;
   end
endmodule
