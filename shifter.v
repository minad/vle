`include "defines.v"

module shifter
  #(parameter n = `DEFAULT_WIDTH)
   (output [n-1:0]        out,
    input [n-1:0] 	  a,
    input [$clog2(n)-1:0] b,
    input 		  rot,
    input 		  left,
    input 		  sign);

   wire [n-1:0] s[$clog2(n)+1:0];
   assign s[0] = a;
   assign out = s[$clog2(n)];

   generate
      genvar i;
      for (i = 0; i < $clog2(n); i = i + 1) begin
	 localparam j = 1<<i;

	 wire [n-1:0] t = left ?
	  	      {s[i][n-j-1:0], rot ? s[i][n-1:n-j] : {j{sign}}} :
	  	      {rot ? s[i][j-1:0] : {j{sign}}, s[i][n-1:j]};

	 assign s[i+1] = b[i] ? t : s[i];
      end
   endgenerate
endmodule
