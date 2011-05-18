`include "binenc.v"

module binenc_tb;
   reg [7:0]  in;
   wire [2:0] out;

   binenc #(8) enc(.in(in), .out(out));

   integer i;

   initial begin
      $monitor("%b %d", in, out);

      for (i = 0; i < 8; i = i + 1) begin
	 in = 1 << i;
	 #1;
      end
   end
endmodule