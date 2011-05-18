

///////////////////////////////////////////////////////////////////////////

module generic_n_way_cache #(
	parameter CACHE_DATA_WIDTH	= 8,
	parameter CACHE_ADDR_WIDTH	= 8,
	parameter ENTRIES		= 8,
	parameter N			= 2;	// degree of associative
	)(	
	input wire 				clk, rstn, re, we,
	input wire 	[CACHE_ADDR_WIDTH-1:0]	read_addr,
	input wire	[CACHE_ADDR_WIDTH-1:0]	write_addr,
	input wire	[CACHE_DATA_WIDTH-1:0]	in,
	output reg	[CACHE_DATA_WIDTH-1:0]	out,
	output	reg				hit
	);


	///////////////////////////////////////////////////////////////////////////

	localparam SETS 		= ENTRIES/N;
	localparam SET_WIDTH 		= $clog2(SETS);
	localparam TAG_WIDTH 		= CACHE_ADDR_WIDTH - SET_WIDTH;
	localparam HISTORY_WIDTH 	= $clog2(N);
	///////////////////////////////////////////////////////////////////////////


	reg	[CACHE_DATA_WIDTH-1:0]	out;
	reg				hit;					

	///////////////////////////////////////////////////////////////////////////

	function automatic logic cmp(wire [TAG_WIDTH-1:0] a,b);
	begin
		if (a == b)
			return 1'b1;
		else
			return 1'b0;
	end
	endfunction;
	
	reg [N-1:0] ram_valid [SETS-1:0];
	reg [N*TAG_WIDTH-1:0] ram_tag [SETS-1:0];
	reg [N*HISTORY_WIDTH-1:0] ram_history [SETS-1:0];
	reg [N*CACHE_DATA_WIDTH-1:0] ram_data [SETS-1:0];

	///////////////////////////////////////////////////////////////////////////
	/*
	typedef struct packed { 
		logic [CACHE_DATA_WIDTH-1:0] 	data;
		logic [TAG_WIDTH-1:0]			tag;
		logic [HISTORY_WIDTH-1:0]		history;
		logic							valid;
	}cache_entry_storage_type;

	typedef cache_entry_storage_type [N-1:0] cache_type [0:SETS-1];
	
	///////////////////////////////////////////////////////////////////////////

	cache_type ram;*/

	reg	[SET_WIDTH-1:0]			read_set, write_set, read_set_reg;
	reg	[TAG_WIDTH-1:0]			read_tag, write_tag;
	reg	[N-1:0]					mux_ctrl, write_ctrl, valid_entries;
	reg 	[CACHE_DATA_WIDTH-1:0]	out_wire;
	reg							set_not_full, history_inc;
	reg	[$clog2(N)-1:0] 			empty_write_addr, overwrite_addr, actual_write_addr, read_index, write_index;
	reg	[$clog2(N):0] 				read_index_tmp, write_index_tmp;
	reg	[HISTORY_WIDTH-1:0] 	min_history;
	reg							read_miss, write_miss;

	integer j,k;

	///////////////////////////////////////////////////////////////////////////

	assign read_tag = read_addr[CACHE_ADDR_WIDTH-1:SET_WIDTH];
	assign read_set = read_addr[SET_WIDTH-1:0];

	assign write_tag = write_addr[CACHE_ADDR_WIDTH-1:SET_WIDTH];
	assign write_set = write_addr[SET_WIDTH-1:0];

	///////////////////////////////////////////////////////////////////////////

	reg	[N*HISTORY_WIDTH-1:0]	history_vector;
	reg	[N-1:0]					history_all_msb;
	reg							all_hist_msb_ones;
	genvar i;
	generate
		for (i = 0; i < N; i = i+1) begin
			assign history_vector[((i+1)*HISTORY_WIDTH-1):(i*HISTORY_WIDTH)] = ram_history[write_set][((i+1)*HISTORY_WIDTH-1):(i*HISTORY_WIDTH)];
		end
		for (i = 0; i < N; i = i+1) begin
			assign history_all_msb[i] = ram_history[read_set_reg][((i+1)*HISTORY_WIDTH-1)];
		end
	endgenerate
	assign all_hist_msb_ones = &history_all_msb;

	///////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < N; i = i+1) begin
			assign mux_ctrl[i] 		= cmp(ram_tag[read_set][((i+1)*TAG_WIDTH-1):(i*TAG_WIDTH)], read_tag) & ram_valid[read_set][i];
			assign write_ctrl[i] 	= cmp(ram_tag[write_set],[((i+1)*TAG_WIDTH-1):(i*TAG_WIDTH]) write_tag) & ram_valid[write_set][i];
			assign valid_entries[i] = ram_valid[write_set][i].valid;
		end
	endgenerate

	assign set_not_full = ~&valid_entries[N-1:0];
	assign read_miss 	= ~|mux_ctrl[N-1:0];
	assign write_miss 	= ~|write_ctrl[N-1:0];

	assign out_wire 	= ram_data[read_set][((read_index+1)*CACHE_DATA_WIDTH-1):(read_index*CACHE_DATA_WIDTH)];
	assign history_inc	= ~&ram_history[read_set][((read_index+1)*HISTORY_WIDTH-1):(read_index*HISTORY_WIDTH)];

	/////////////////////////////////////////////////////////////////////////

	DW01_binenc #(N, cld(N)) get_hit_addr (.A(~valid_entries), .ADDR(empty_write_addr));
	DW01_binenc #(N, cld(N)+1) get_read_index (.A(mux_ctrl), .ADDR(read_index_tmp));
	DW01_binenc #(N, cld(N)+1) get_write_index (.A(write_ctrl), .ADDR(write_index_tmp));
	DW_minmax #(cld(N), N) get_least_recently_used (.a(history_vector), .tc(1'b0), .min_max(1'b0), .value(min_history), .index(overwrite_addr));

	assign read_index = read_index_tmp[cld(N)-1:0];
	assign write_index = write_index_tmp[cld(N)-1:0];								// if ~write_miss
	assign actual_write_addr = set_not_full ? empty_write_addr : overwrite_addr; 	// if write_miss

	/////////////////////////////////////////////////////////////////////////

// synopsys translate_off

	function automatic integer get_ones (logic[N-1:0] a);
	begin
		integer i, n;
		n=0;
		for (i=0;i<N;i+=1) begin
			if (a[i]==1)
				n+=1;
		end
		return n;
	end
	endfunction;

	assert property (@(posedge clk) get_ones(mux_ctrl) <= 1)
		else $error("N_WAY_CACHE: two tag hits in one read cycle");

	assert property (@(posedge clk) get_ones(write_ctrl) <= 1)
		else $error("N_WAY_CACHE: two tag hits in one write cycle");

// 	assert property (@(posedge clk) not ((read_addr == write_addr) and we and re))
// 		else $warning("N_WAY_CACHE: read and write on same addr");

// synopsys translate_on

	/////////////////////////////////////////////////////////////////////////

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			for (j = 0; j < SETS; j += 1)
				for (k = 0; k < N; k += 1) begin
					ram[j][k].valid		<= 1'b0;
					ram[j][k].history	<=  'b0;
				end
			out			<= 'b0;
			hit			<= 'b0;
		end else begin
			read_set_reg 	<= read_set;
			if (we) begin
				if (write_miss) begin
					ram[write_set][actual_write_addr].data 		<= in;
					ram[write_set][actual_write_addr].tag 		<= write_tag;
					ram[write_set][actual_write_addr].valid 	<= 1'b1;
					ram[write_set][actual_write_addr].history 	<= min_history + 1'b1;
				end else begin
					ram[write_set][write_index].data 			<= in;
				end
			end 
			if (re) begin
				out 		<= read_miss ? 'b0 : out_wire;
				hit		 	<= re & ~read_miss;
				if (!read_miss)
					ram[read_set][read_index].history 	<= ram[read_set][read_index].history + history_inc;
				for (j = 0; j < N; j += 1) begin
					if (all_hist_msb_ones)
						ram[read_set_reg][j].history[HISTORY_WIDTH-1] <= 1'b0;
				end
			end else begin
				out			<=  'b0;
				hit			<= 1'b0;
			end
		end
	end

	///////////////////////////////////////////////////////////////////////////

endmodule
