`include "defines.v"

//binary encoder
module binenc
  #(parameter n = `DEFAULT_WIDTH)
  (input [n-1:0]          in,
   output [$clog2(n)-1:0] out);

   wire [$clog2(n)-1:0] o[n:0];
   wire [n:0]      	h;

   assign o[n] = 0;
   assign h[n] = 0;
   assign out = o[0];

   generate
      genvar i;
      for (i = n - 1; i >= 0; i = i - 1)
	begin
	   assign h[i] = in[i] & ~h[i + 1];
	   assign o[i] = o[i + 1] | (h[i] ? i : 0);
	end
   endgenerate
endmodule
