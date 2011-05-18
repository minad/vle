`include "defines.v"

//binary encoder
module binenc
  #(parameter n = `DEFAULT_WIDTH)
  (input [n-1:0]          in,
   output [$clog2(n)-1:0] out);
   
   wire [$clog2(n)-1:0] o[n:0];
   wire [n-1:0] in_hot_one;
   assign o[0] = 0;
   assign out = o[n];
   assign in_hot_one[n-1] = in[n-1];
   generate
      genvar i;
      for (i = 0; i < n; i = i + 1)
	assign o[i+1] = o[i] | (in_hot_one & (1 << i) ? i : 0);
      for (i=0; i<n-1; i=i+1)
	assign in_hot_one[i] = in[i]&(~in_hot_one[i+1]);
   endgenerate
endmodule
