`include "defines.v"
`include "addsub.v"
`include "shifter.v"
`include "multiplier.v"

`define ALU_AND     7'b0000000
`define ALU_OR      7'b0000001
`define ALU_XOR     7'b0000010
`define ALU_NOT     7'b0000011
`define ALU_LSR     7'b0000100
`define ALU_LSL     7'b0000101
`define ALU_ASR     7'b0000110
`define ALU_MUL     7'b0000111
`define ALU_SMUL    7'b0001000
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

   wire [n-1:0]    sum;
   wire [n-1:0]    shifted;
   wire [2*n-1:0]  prod;
   wire 	   sum_overflow;
   reg 		   overflow;
   reg [n-1:0] 	   result;
   wire [n-1:0]    x = op & `ALU_INV_A ? ~a : a;
   wire [n-1:0]    y = op & `ALU_INV_B ? ~b : b;

   assign zero = out == 0 ? 1'b1 : 1'b0;
   assign sign = out[n-1];
   assign out = op & `ALU_INV_OUT ? ~result : result;

   // Arithmethic unit
   addsub #(n) add(.sum(sum),
		   .a(a),
		   .b(b),
		   .sub(op[0]), // Subtraction is selected by bit 0
		   .cin(cin),
		   .cout(cout),
		   .overflow(sum_overflow));

   multiplier #(n) mul(.prod(prod),
		       .a(a),
		       .b(b),
		       .sign(op[3]));

   // Shifter
   shifter #(n) shift(.out(shifted),
		      .a(a),
		      .b(b[$clog2(n)-1:0]),
		      .rot(op[3]),            // Rotation is selected by bit 0
		      .left(op[0]),           // Left is selected by bit 0
		      .sign(op[1] & a[n-1])); // ASR sign

   always @* begin
      overflow = 0;
      case (op)
	`ALU_AND:
	  result = x & y;
	`ALU_OR:
	  result = x | y;
	`ALU_XOR:
	  result = x ^ y;
	`ALU_NOT:
	  result = !x;
	`ALU_LSR, `ALU_LSL, `ALU_ASR:
	  result = y >= $clog2(n) ? {n{op[1] & a[0]}} : shifted;
	`ALU_ROL, `ALU_ROR:
	  result = shifted;
	`ALU_SUB, `ALU_ADD:
	  begin
	     result = sum;
	     overflow = sum_overflow;
	  end
	`ALU_MUL, `ALU_SMUL:
	  begin
	     result = prod;
	     overflow = (prod[2*n-1] ? ~prod[2*n-1:n] : prod[2*n-1:n]) != {n{1'b0}};
	  end
	default:
	  result = {n{1'b0}};
      endcase
   end
endmodule
