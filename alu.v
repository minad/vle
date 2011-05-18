`include "defines.v"
`include "addsub.v"
`include "shifter.v"
`include "multiplier.v"
`include "divider.v"

// ALU Opcode format
// 2 modificator bits
// 4 opcode bits
`define ALU_MOD_MASK     6'b11_0000
`define ALU_OPCODE_MASK  6'b00_1111

// Modificator for nop, or, xor, and
`define ALU_INV          6'b01_0000
`define ALU_INVB         6'b10_0000

// Modificator for mul, div, mod
`define ALU_SIGNED       6'b01_0000

// Opcodes
`define ALU_NOP          6'b00_0000

`define ALU_AND          6'b00_0001
`define ALU_OR           6'b00_0010
`define ALU_XOR          6'b00_0011

`define ALU_ADD          6'b00_0100
`define ALU_SUB          6'b00_0101

`define ALU_LSR          6'b00_0110
`define ALU_LSL          6'b00_0111
`define ALU_ASR          `ALU_LSR | `ALU_SIGNED
`define ALU_ROR          6'b01_1000
`define ALU_ROL          6'b00_1001

`define ALU_MUL          6'b00_1010
`define ALU_DIV          6'b00_1011
`define ALU_MOD          6'b00_1100

`define ALU_NOT          6'b00_1101

// Arithmetic logic unit
module alu
  #(parameter n = `DEFAULT_WIDTH)
   (input [n-1:0]      a,
    input [n-1:0]      b,
    output reg [n-1:0] out,
    input [5:0]        op,
    input 	       cin,
    output 	       cout,
    output reg 	       overflow,
    output 	       sign,
    output 	       zero);

   wire [n-1:0]    sum;
   wire [n-1:0]    shifted;
   wire [2*n-1:0]  product;
   wire [n-1:0]    quotient;
   wire [n-1:0]    reminder;
   wire 	   sum_overflow;

   assign zero = out == 0 ? 1'b1 : 1'b0;
   assign sign = out[n-1];

   addsub #(n) add(.sum(sum),
		   .a(a),
		   .b(b),
		   .sub(op[0]), // Subtraction is selected by bit 0
		   .cin(cin),
		   .cout(cout),
		   .overflow(sum_overflow));

   multiplier #(n) mul(.product(product),
		       .a(a),
		       .b(b),
		       .sign(op[4])); // Signed bit

   divider #(n) div(.quotient(quotient),
		    .reminder(reminder),
		    .a(a),
		    .b(b),
		    .sign(op[4])); // Signed bit

   shifter #(n) shift(.out(shifted),
		      .a(a),
		      .b(b[$clog2(n)-1:0]),
		      .rot(op[3]),            // Rotation is selected by bit 3
		      .left(op[0]),           // Left is selected by bit 0
		      .sign(op[4] & a[n-1])); // Signed bit

   // Logic operations
   reg [n-1:0] 	   logic_tmp;
   wire [n-1:0]    logic_out = op & `ALU_INV ? ~logic_tmp : logic_tmp;
   wire [n-1:0]    logic_b = op & `ALU_INVB ? ~b : b;

   always @*
      case (op & `ALU_OPCODE_MASK)
	`ALU_NOP:
	  logic_tmp = a;
        `ALU_AND:
	  logic_tmp = a & logic_b;
        `ALU_OR:
	  logic_tmp = a | logic_b;
	`ALU_XOR:
	  logic_tmp = a ^ logic_b;
      endcase

   always @* begin
      overflow = 0;
      out = {n{1'b0}};
      case (op)
	`ALU_NOP, `ALU_AND, `ALU_OR, `ALU_XOR:
	  out = logic_out;
	`ALU_NOT:
	  out = !a;
	`ALU_LSR, `ALU_LSL, `ALU_ASR:
	  out = b >= $clog2(n) ? {n{op[1] & a[0]}} : shifted;
	`ALU_ROL, `ALU_ROR:
	  out = shifted;
	`ALU_SUB, `ALU_ADD:
	  begin
	     out = sum;
	     overflow = sum_overflow;
	  end
	`ALU_DIV:
	  out = quotient;
	`ALU_MOD:
	  out = reminder;
	`ALU_MUL:
	  begin
	     out = product;
	     overflow = (product[2*n-1] ? ~product[2*n-1:n] : product[2*n-1:n]) != {n{1'b0}};
	  end
      endcase
   end
endmodule
