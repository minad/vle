`include "defines.v"
`include "addsub.v"
`include "shifter.v"

`define ALU_AND     7'b0000000
`define ALU_OR      7'b0000001
`define ALU_XOR     7'b0000010
`define ALU_NOT     7'b0000011
`define ALU_LSR     7'b0000100
`define ALU_LSL     7'b0000101
`define ALU_ASR     7'b0000110
`define ALU_SUB     7'b0001001
`define ALU_ADD     7'b0001010
`define ALU_ROL     7'b0001011
`define ALU_ROR     7'b0001100
`define ALU_INV_OUT 7'b0010000
`define ALU_INV_A   7'b0100000
`define ALU_INV_B   7'b1000000

// Arithmetic logic unit
module alu
  #(parameter n = `DEFAULT_WIDTH)
   (input [n-1:0]  a,
    input [n-1:0]  b,
    output [n-1:0] out,
    input [6:0]    op,
    input 	   cin,
    output 	   cout,
    output 	   overflow,
    output 	   sign,
    output 	   zero);

   wire [n-1:0]    add_out;
   wire [n-1:0]    shifter_out;
   reg [n-1:0] 	   o;
   wire [n-1:0]    x = op & `ALU_INV_A ? ~a : a;
   wire [n-1:0]    y = op & `ALU_INV_B ? ~b : b;

   assign zero = out == 0 ? 1'b1 : 1'b0;
   assign sign = out[n-1];
   assign out = op & `ALU_INV_OUT ? ~o : o;

   // Arithmethic unit
   addsub #(n) add(.sum(add_out),
		   .a(a),
		   .b(b),
		   .sub(op[0]),
		   .cin(cin),
		   .cout(cout),
		   .overflow(overflow));

   // Shifter
   shifter #(n) shift(.out(shifter_out),
		      .a(a),
		      .b(b[$clog2(n)-1:0]),
		      .rot(op[3]),
		      .left(op[0]),
		      .sign(op[1] & a[0]));

   always @*
     case (op)
       `ALU_AND:
	 o = x & y;
       `ALU_OR:
	 o = x | y;
       `ALU_XOR:
	 o = x ^ y;
       `ALU_NOT:
	 o = !x;
       `ALU_LSR, `ALU_LSL, `ALU_ASR:
	 o = y >= $clog2(n) ? {n{op[1] & a[0]}} : shifter_out;
       `ALU_ROL, `ALU_ROR:
	 o = shifter_out;
       `ALU_SUB, `ALU_ADD:
	 o = add_out;
       default:
	 o = {n{1'b0}};
     endcase
endmodule
