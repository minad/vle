`include "binenc.v"

module generic_n_way_cache #( 	parameter DATA_WIDTH=8,
				parameter ENTRIES=8,
				parameter WAYS=2,
				parameter ADDR_WIDTH=8)
				(
				input wire clk, rst, re, we,
				input wire [ADDR_WIDTH-1:0] read_addr, write_addr,
				input wire [DATA_WIDTH-1:0] in,
				output reg [DATA_WIDTH-1:0] out,
				output reg hit				
				);

	//parameters
	localparam SETS 	= ENTRIES/WAYS;
	localparam SET_WIDTH    = $clog2(SETS);
	localparam TAG_WIDTH	= ADDR_WIDTH-SET_WIDTH;
	localparam HISTORY_WIDTH = $clog2(WAYS);

	//functions
	function cmp;
	input [TAG_WIDTH-1:0] a,b;
	begin
		//cmp = ~(|(a[TAG_WIDTH-1:0]^b[TAG_WIDTH-1:0]));
		cmp = a == b;
	end
	endfunction
	
	//regs & wires
	reg [WAYS-1:0] ram_valid [SETS-1:0];
	reg [WAYS*TAG_WIDTH-1:0] ram_tag [SETS-1:0];
	reg [WAYS*DATA_WIDTH-1:0] ram_data [SETS-1:0];
	reg [WAYS*HISTORY_WIDTH-1:0] ram_history [SETS-1:0];
	
	reg [WAYS-1:0] ram_valid_next [SETS-1:0];
	reg [WAYS*TAG_WIDTH-1:0] ram_tag_next [SETS-1:0];
	reg [WAYS*DATA_WIDTH-1:0] ram_data_next [SETS-1:0];
	reg [WAYS*HISTORY_WIDTH-1:0] ram_history_next [SETS-1:0];
	reg hit_next;
	reg [DATA_WIDTH-1:0] out_next;

	reg [TAG_WIDTH-1:0] read_tag, write_tag;
	reg [SET_WIDTH-1:0] read_set, write_set;
	reg [DATA_WIDTH-1:0] line_data [WAYS-1:0];
	reg [HISTORY_WIDTH-1:0] line_history [WAYS-1:0];
	reg [HISTORY_WIDTH-1:0] wrline_history [WAYS-1:0];
	reg [TAG_WIDTH-1:0] line_tag [WAYS-1:0];
	reg [WAYS-1:0] line_valid;
	reg [WAYS-1:0] wrline_valid;
	reg [WAYS-1:0] tag_hit_vect, wr_tag_hit_vect;
	reg [TAG_WIDTH-1:0] wrline_tag [WAYS-1:0];
	reg [$clog2(WAYS)-1:0] override_addr;
	wire [$clog2(WAYS)-1:0] read_mpx_addr, wr_hit_addr, invalid_entry_addr;
	reg [$clog2(WAYS)-1:0] true_write_addr;
	reg [DATA_WIDTH-1:0] out_wire;
	reg hit_wire, wr_hit_wire;
	reg [HISTORY_WIDTH-1:0] read_history, history_inc, minimum_history;
	reg read_history_full;
	reg [WAYS-1:0] hist_msb_vect;
	reg all_hist_msb;
	reg wrline_invalid_entry;

	//assignments

	integer i,j;

	always @* begin
		read_tag = read_addr[ADDR_WIDTH-1:SET_WIDTH];
		read_set = read_addr[SET_WIDTH-1:0];

		write_tag = write_addr[ADDR_WIDTH-1:SET_WIDTH];
		write_set = write_addr[SET_WIDTH-1:0];
		
	
		for (i=0; i<SETS; i=i+1) begin
			line_data[i][DATA_WIDTH-1:0] = ram_data[read_set][WAYS*DATA_WIDTH-1:0]>>(i*DATA_WIDTH);
			line_tag[i][TAG_WIDTH-1:0] = ram_tag[read_set][WAYS*TAG_WIDTH-1:0]>>(i*TAG_WIDTH);
			wrline_tag[i][TAG_WIDTH-1:0] = ram_tag[write_set][WAYS*TAG_WIDTH-1:0]>>(i*TAG_WIDTH);
			line_history[i][HISTORY_WIDTH-1:0] = ram_history[read_set][WAYS*HISTORY_WIDTH-1:0]>>(i*HISTORY_WIDTH);
			wrline_history[i][HISTORY_WIDTH-1:0] = ram_history[write_set][WAYS*HISTORY_WIDTH-1:0]>>(i*HISTORY_WIDTH);
			line_valid [i] = ram_valid[read_set][WAYS-1:0]>>i;
			wrline_valid [i] = ram_valid[write_set][WAYS-1:0]>>i;
			tag_hit_vect[i] = cmp(line_tag[i][TAG_WIDTH-1:0], read_tag[TAG_WIDTH-1:0])&line_valid[i];
			wr_tag_hit_vect[i] = cmp(wrline_tag[i][TAG_WIDTH-1:0], write_tag[TAG_WIDTH-1:0])&wrline_valid[i];
			hist_msb_vect[i] = line_history[i][HISTORY_WIDTH-1];
		end
	
		hit_wire = |tag_hit_vect[WAYS-1:0];
		wr_hit_wire = |wr_tag_hit_vect[WAYS-1:0];
		out_wire[DATA_WIDTH-1:0] = line_data[read_mpx_addr][DATA_WIDTH-1:0];
		read_history[HISTORY_WIDTH-1:0] = line_history[read_mpx_addr][HISTORY_WIDTH-1:0];
		read_history_full = &read_history;
		history_inc = read_history + (~read_history_full);	
		all_hist_msb = & hist_msb_vect; 	
		wrline_invalid_entry = ~(&wrline_valid);	
	
		if (wr_hit_wire)
			true_write_addr = wr_hit_addr;
		else if (wrline_invalid_entry)
			true_write_addr = invalid_entry_addr;
		else 
			true_write_addr = override_addr;

		//TEMPORARY
		override_addr = 'b0;
		minimum_history = 'b0;
	end

	//modules
	binenc #(.n(WAYS)) get_read_mpx_addr (.in(tag_hit_vect), .out(read_mpx_addr)); 
	binenc #(.n(WAYS)) get_wr_hit_addr (.in(wr_tag_hit_vect), .out(wr_hit_addr));
	binenc #(.n(WAYS)) get_invalid_entry_addr (.in(~wrline_valid), .out(invalid_entry_addr));
//	min #(.n(WAYS), .WIDTH(HISTORY_WIDTH)) get_override_addr (.in(wrline_history), .addr(override_addr), .value(minimum_history);

	//next state logic
	always @* begin
		for (j=0; j<SETS; j=j+1) begin
			ram_data_next[j][WAYS*DATA_WIDTH-1:0]= ram_data[j][WAYS*DATA_WIDTH-1:0];
			ram_valid_next[j][WAYS-1:0] = ram_valid[j][WAYS-1:0];
			ram_tag_next[j][WAYS*TAG_WIDTH-1:0] = ram_tag[j][WAYS*TAG_WIDTH-1:0];
			ram_history_next[j][WAYS*HISTORY_WIDTH-1:0] = ram_history[j][WAYS*HISTORY_WIDTH-1:0];
		end	
		if (we) begin
			for (j=0; j<DATA_WIDTH; j=j+1)
				ram_data_next[write_set][true_write_addr*DATA_WIDTH+j] = in[j];
			if (~wr_hit_wire) begin
				ram_valid_next[write_set][true_write_addr] = 1'b1;
				for (j=0; j<TAG_WIDTH; j=j+1)
					ram_tag_next[write_set][true_write_addr*TAG_WIDTH+j] = write_tag[j];
				for (j=0; j<HISTORY_WIDTH; j=j+1)
					ram_history_next[write_set][true_write_addr*HISTORY_WIDTH+j] = minimum_history[j];
			end 
		end 
		if (re) begin
			hit_next = hit_wire;
			out_next = hit_wire ? out_wire : 'b0;
			if (line_valid[read_mpx_addr]) for (j=0; j<HISTORY_WIDTH; j=j+1)
				ram_history_next[read_set][read_mpx_addr*HISTORY_WIDTH+j] =  history_inc[j];
			if (all_hist_msb) for (j=0; j<WAYS; j=j+1)
				ram_history_next[read_set][(j+1)*HISTORY_WIDTH] = 1'b0;
		end else begin
			hit_next = 'b0;
			out_next = 'b0;
		end	
	end

	//registers
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			hit <= 'b0;
			out <= 'b0;
			for (j=0; j<SETS; j=j+1) begin
				ram_valid[j][WAYS-1:0] <= 'b0;
				ram_data[j][WAYS*DATA_WIDTH-1:0] <= 'b0;
				ram_tag[j][WAYS*TAG_WIDTH-1:0] <= 'b0;
				ram_history[j][WAYS*HISTORY_WIDTH-1:0] <= 'b0;
			end
		
		end else begin
			for (j=0; j<SETS; j=j+1) begin
				ram_data[j][WAYS*DATA_WIDTH-1:0] <= ram_data_next[j][WAYS*DATA_WIDTH-1:0];
				ram_valid[j][WAYS-1:0] <= ram_valid_next[j][WAYS-1:0];
				ram_tag[j][WAYS*TAG_WIDTH-1:0] <= ram_tag_next[j][WAYS*TAG_WIDTH-1:0];
				ram_history[j][WAYS*HISTORY_WIDTH-1:0] <= ram_history_next[j][WAYS*HISTORY_WIDTH-1:0];
			end
			hit <= hit_next;
			out[DATA_WIDTH-1:0] <= out_next[DATA_WIDTH-1:0];
		end
	end	
endmodule
