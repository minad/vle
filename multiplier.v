`include "defines.v"

module multiplier
  #(parameter n = `DEFAULT_WIDTH)
   (output [2*n-1:0] prod,
    input [n-1:0]    a,
    input [n-1:0]    b,
    input            sign);

   wire 	     as = sign & a[n-1];
   wire 	     bs = sign & b[n-1];
   wire [n-1:0]      av = as ? -a : a;
   wire [n-1:0]      bv = bs ? -b : b;
   wire [2*n-1:0]    p[n:0];

   assign p[0] = 0;
   assign prod = as ^ bs ? -p[n] : p[n];

   generate
      genvar i;
      for (i = 0; i < n; i = i + 1) begin
	 assign p[i+1] = (p[i] << 1) + (bv[n-i-1] ? av : 0);
      end
   endgenerate
endmodule
