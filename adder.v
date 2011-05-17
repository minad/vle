`include "defines.v"

module adder
  #(parameter n = `DEFAULT_WIDTH)
   (output [n-1:0] sum,
    input [n-1:0]  a,
    input [n-1:0]  b,
    input 	   cin,
    output 	   cout);
   assign {cout, sum} = a + b + cin;
endmodule
