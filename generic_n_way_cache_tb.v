`include "generic_n_way_cache.v"

`define DATA_WIDTH 8
`define ADDR_WIDTH 8
`define WAYS 2
`define ENTRIES 8

module generic_n_way_cache_tb ();
	reg clk, rst, we, re;
	reg [`DATA_WIDTH-1:0] in;
	wire [`DATA_WIDTH-1:0] out;
	reg [`ADDR_WIDTH-1:0] read_addr, write_addr;
	wire hit;
	integer cnt;		
	generic_n_way_cache #(	.DATA_WIDTH(`DATA_WIDTH),
				.ADDR_WIDTH(`ADDR_WIDTH),
				.ENTRIES(`ENTRIES),
				.WAYS(`WAYS))
			 DUT (	.clk(clk),
				.rst(rst),
				.re(re),
				.we(we),
				.read_addr(read_addr),
				.write_addr(write_addr),
				.in(in),
				.out(out),
				.hit(hit)
			);

	integer i, j;
	always #1 clk = ~clk;
	always #2 cnt = cnt+1;	

	initial begin
		$monitor("CNT:%d we:%b w_addr:%b in:%b re:%b r_addr:%b hit:%b out:%b twa:%b", cnt, we, write_addr, in, re, read_addr, hit, out, DUT.true_write_addr);
		cnt = 0;
		rst = 1'b1;
		in = 'b0;
		read_addr = 'b0;
		write_addr = 'b0;
		re = 1'b0;
		we = 1'b0;
		clk = 1'b1;
		#2050 $stop;
	end
	
	always #2 begin
		if (cnt<513) begin
			we = 1'b1;
			write_addr = write_addr +1;
			in = in+1;
		end else begin
			re = 1'b1;
			we = 1'b0;
			read_addr = read_addr +1;
		end
	end	

	always #2 for (i=0; i<`ENTRIES/`WAYS; i=i+1) begin
//		$display("%b", DUT.ram_history[i][`WAYS*$clog2(`WAYS)-1:0]);
//		$display("%b", DUT.ram_valid[i][`WAYS-1:0]);
//		$display("%b", DUT.ram_data[i][`WAYS*`DATA_WIDTH-1:0]);
//		$display("%b", DUT.ram_tag[i][`WAYS*(`ADDR_WIDTH-`ENTRIES/`WAYS)-1:0]);

	end
	

endmodule
