`include "defines.v"

module divider
  #(parameter n = `DEFAULT_WIDTH)
   (output [n-1:0] quotient,
    output [n-1:0] reminder,
    input [n-1:0]  a,
    input [n-1:0]  b,
    input 	   sign);

   wire 	     as = sign & a[n-1];
   wire 	     bs = sign & b[n-1];
   wire              s  = as ^ bs;
   wire [n-1:0]      av = as ? -a : a;
   wire [n-1:0]      bv = bs ? -b : b;
   wire [n-1:0]      q, r;

   assign quotient = s ? -q : q;
   assign reminder  = s ? -r : r;

`ifdef USE_DIVIDE
   assign q = av / bv;
   assign r = av % bv;
`else
   wire [n-1:0] u[n:0];
   assign u[n] = av;
   assign r = u[0];

   generate
      genvar i;
      for (i = n - 1; i >= 0; i = i - 1) begin
	 wire [2*n-1:0] t = u[i+1] - (bv << i);
	 assign q[i] = ~t[2*n-1];
	 assign u[i] = q[i] ? t : u[i+1];
      end
   endgenerate
`endif

endmodule
