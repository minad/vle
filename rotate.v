`include "defines.v"

module shifter
  #(parameter n = `DEFAULT_WIDTH)
   (output [n-1:0]      out,
    input [n-1:0] 	a,
    input [$clog2(n)-1:0] b,
    input 		rot,
    input 		left,
    input 		sign);

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

	 // wire [n-1:0] rl = {s[i][n-j-1:0], s[i][n-1:n-j]};
	 // wire [n-1:0] rr = {s[i][j-1:0], s[i][n-1:j]};
	 // wire [n-1:0] sl = {s[i][n-j-1:0], {j{sign}}};
	 // wire [n-1:0] sr = {{j{sign}}, s[i][n-1:j]};
	 // wire [n-1:0] t = left ? (rot ? rl : sl) : (rot ? rr : sr);

	 assign s[i+1] = b[i] ? t : s[i];
      end
   endgenerate
endmodule

module shifter_tb;
   reg [7:0] a;
   reg [2:0] b;
   wire [7:0] rol_out, ror_out, lsl_out, lsr_out;
   shifter #(8) rol(.a(a), .b(b), .out(rol_out), .rot(1), .left(1), .sign(0));
   shifter #(8) ror(.a(a), .b(b), .out(ror_out), .rot(1), .left(0), .sign(0));
   shifter #(8) lsl(.a(a), .b(b), .out(lsl_out), .rot(0), .left(1), .sign(0));
   shifter #(8) lsr(.a(a), .b(b), .out(lsr_out), .rot(0), .left(0), .sign(0));

   initial begin
      $display("Shifter Test Bench");
      $monitor("%b rol %d = %b | %b ror %d = %b | %b << %d = %b | %b >> %d = %b",
	       a, b, rol_out, a, b, ror_out, a, b, lsl_out, a, b, lsr_out);

      a = 8'b10000111;
      b = 0;

      #1
      a = 8'b10000111;
      b = 1;

      #1
      a = 8'b10000111;
      b = 2;

      #1
      a = 8'b10000111;
      b = 3;

      #1
      a = 8'b10000111;
      b = 4;

      #1
      a = 8'b10000111;
      b = 5;

      #1
      a = 8'b10000111;
      b = 6;

      #1
      a = 8'b10000111;
      b = 7;

      #1
      a = 8'b10000111;
      b = 8;
   end
endmodule
