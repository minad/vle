`include "defines.v"

module register
  #(parameter n = `DEFAULT_WIDTH)
   (input              clock,
    input 	       reset,
    input 	       load,
    input [1:0]        select,
    output reg [n-1:0] out,
    input [n-1:0]      in0,
    input [n-1:0]      in1,
    input [n-1:0]      in2,
    input [n-1:0]      in3);

   always @ (posedge clock, posedge reset)
     if(reset)
       out <= 0;
     else if (load)
       case (select)
	 2'd0: out <= in0;
	 2'd1: out <= in1;
	 2'd2: out <= in2;
	 2'd3: out <= in3;
       endcase
endmodule
