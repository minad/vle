`include "binenc.v"

module binenc_tb;
   reg [7:0]  in;
   wire [2:0] out;

   binenc #(8) enc(.in(in), .out(out));

   integer i;

   initial begin
      $monitor("%b %d", in, out);
      in = 'b0;
      #520 $finish;
   end

   always begin
     #2 in = in+1;
   end
endmodule
