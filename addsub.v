`include "defines.v"

module addsub
  #(parameter n = `DEFAULT_WIDTH)
   (output [n-1:0] sum,
    input [n-1:0]  a,
    input [n-1:0]  b,
    input 	   sub,
    input 	   cin,
    output 	   cout,
    output  	   ovf);

   wire   carry;
   assign ovf = carry ^ cout;

   adder #(.n(n-1)) value(.sum(sum[n-2:0]),
			  .a(a[n-2:0]),
			  .b(b[n-2:0] ^ {n-1{sub}}),
			  .cin(sub ^ cin),
			  .cout(carry));

   adder #(.n(1))   sign(.sum(sum[n-1]),
			 .a(a[n-1]),
			 .b(b[n-1] ^ sub),
			 .cin(carry),
			 .cout(cout));
endmodule
