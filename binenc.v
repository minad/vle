`include "defines.v"

// One hot binary encoder
module binenc
  #(parameter n = `DEFAULT_WIDTH)
  (input [n-1:0]          in,
   output [$clog2(n)-1:0] out);

   wire [$clog2(n)-1:0] o[n:0];
   assign o[0] = 0;
   assign out = o[n];

   generate
      genvar i;
      for (i = 0; i < n; i = i + 1)
	assign o[i+1] = o[i] | (in & (1 << i) ? i : 0);
   endgenerate
endmodule
