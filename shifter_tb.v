`include "shifter.v"

module shifter_tb;
   reg [7:0] a;
   reg [2:0] b;
   wire [7:0] rol_out, ror_out, lsl_out, lsr_out;
   shifter #(8) rol(.a(a), .b(b), .out(rol_out), .rot(1'b1), .left(1'b1), .sign(1'b0));
   shifter #(8) ror(.a(a), .b(b), .out(ror_out), .rot(1'b1), .left(1'b0), .sign(1'b0));
   shifter #(8) lsl(.a(a), .b(b), .out(lsl_out), .rot(1'b0), .left(1'b1), .sign(1'b0));
   shifter #(8) lsr(.a(a), .b(b), .out(lsr_out), .rot(1'b0), .left(1'b0), .sign(1'b1));

   initial begin
      $display("Shifter Test Bench");
      $monitor("%b rol %d = %b | %b ror %d = %b | %b << %d = %b | %b >> %d = %b",
	       a, b, rol_out, a, b, ror_out, a, b, lsl_out, a, b, lsr_out);
   end

   genvar i;
   generate
      for (i = 0; i < 8; i = i + 1) begin
	 initial begin
	    #i
	    a = 8'b10000111;
	    b = i;
	 end
      end
   endgenerate
endmodule
