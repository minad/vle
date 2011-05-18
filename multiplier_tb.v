module multiplier_tb;
   reg signed [7:0]   a, b;
   wire signed [15:0] c;

   multiplier #(8) mul(.a(a), .b(b), .product(c), .sign(1));

   initial begin
      $monitor("%d * %d = %d", a, b, c);

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

   end
endmodule
