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
		cmp = ~(|(a[TAG_WIDTH-1:0]^b[TAG_WIDTH-1:0]));
	end
	endfunction
	
	//regs & wires
	reg [WAYS-1:0] ram_valid [SETS-1:0];
	reg [WAYS*TAG_WIDTH-1:0] ram_tag [SETS-1:0];
	reg [WAYS*DATA_WIDTH-1:0] ram_data [SETS-1:0];
	reg [WAYS*HISTORY_WIDTH-1:0] ram_history [SETS-1:0];

	wire [TAG_WIDTH-1:0] read_tag, write_tag;
	wire [SET_WIDTH-1:0] read_set, write_set;
	wire [DATA_WIDTH-1:0] line_data [WAYS-1:0];
	wire [HISTORY_WIDTH-1:0] line_history [WAYS-1:0];
	wire [HISTORY_WIDTH-1:0] wrline_history [WAYS-1:0];
	wire [TAG_WIDTH-1:0] line_tag [WAYS-1:0];
	wire [WAYS-1:0] line_valid;
	wire [WAYS-1:0] wrline_valid;
	wire [WAYS-1:0] tag_hit_vect, wr_tag_hit_vect;
	wire [TAG_WIDTH-1:0] wrline_tag [WAYS-1:0];
	wire [$clog2(WAYS)-1:0] read_mpx_addr, wr_hit_addr, invalid_entry_addr, override_addr;
	reg [$clog2(WAYS)-1:0] true_write_addr;
	wire [DATA_WIDTH-1:0] out_wire;
	wire hit_wire, wr_hit_wire;
	wire [HISTORY_WIDTH-1:0] read_history, history_inc, minimum_history;
	wire read_history_full;
	wire [WAYS-1:0] hist_msb_vect;
	wire all_hist_msb;
	wire wrline_invalid_entry;

	//assignments
	assign read_tag = read_addr[ADDR_WIDTH-1:SET_WIDTH];
	assign read_set = read_addr[SET_WIDTH-1:0];

	assign write_tag = write_addr[ADDR_WIDTH-1:SET_WIDTH];
	assign write_set = write_addr[SET_WIDTH-1:0];

	genvar i;
	integer j,k;
	generate for (i=0; i<WAYS; i=i+1)
	begin
		assign line_data[i][DATA_WIDTH-1:0] = ram_data[read_set][(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
		assign line_tag[i][TAG_WIDTH-1:0] = ram_tag[read_set][(i+1)*TAG_WIDTH-1:i*TAG_WIDTH];
		assign wrline_tag[i][TAG_WIDTH-1:0] = ram_tag[write_set][(i+1)*TAG_WIDTH-1:i*TAG_WIDTH];
		assign line_history[i][HISTORY_WIDTH-1:0] = ram_history[read_set][(i+1)*HISTORY_WIDTH-1:i*HISTORY_WIDTH];
		assign wrline_history[i][HISTORY_WIDTH-1:0] = ram_history[write_set][(i+1)*HISTORY_WIDTH-1:i*HISTORY_WIDTH];
		assign line_valid [i] = ram_valid[read_set][i];
		assign wrline_valid [i] = ram_valid[write_set][i];
		assign tag_hit_vect[i] = cmp(line_tag[i][TAG_WIDTH-1:0], read_tag[TAG_WIDTH-1:0])&line_valid[i];
		assign wr_tag_hit_vect[i] = cmp(wrline_tag[i][TAG_WIDTH-1:0], write_tag[TAG_WIDTH-1:0])&wrline_valid[i];
		assign hist_msb_vect[i] = line_history[i][HISTORY_WIDTH-1];
	end
	endgenerate
	
	assign hit_wire = |tag_hit_vect[WAYS-1:0];
	assign wr_hit_wire = |wr_tag_hit_vect[WAYS-1:0];
	assign out_wire[DATA_WIDTH-1:0] = line_data[read_mpx_addr][DATA_WIDTH-1:0];

	assign read_history[HISTORY_WIDTH-1:0] = line_history[read_mpx_addr][HISTORY_WIDTH-1:0];
	assign read_history_full = &read_history;
	assign history_inc = read_history + (~read_history_full);	
	assign all_hist_msb = & hist_msb_vect; 	
	assign wrline_invalid_entry = &wrline_valid;	
	always @*
	begin
		if (wr_hit_wire)
			true_write_addr = wr_hit_addr;
		else if (wrline_invalid_entry)
			true_write_addr = invalid_entry_addr;
		else 
			true_write_addr = override_addr;
	end

	//TEMPORARY
	assign override_addr = 'b0;
	assign minimum_history = 'b0;

	//modules
	binenc #(.n(WAYS)) get_read_mpx_addr (.in(tag_hit_vect), .out(read_mpx_addr)); 
	binenc #(.n(WAYS)) get_wr_hit_addr (.in(wr_tag_hit_vect), .out(wr_hit_addr));
	binenc #(.n(WAYS)) get_invalid_entry_addr (.in(~wrline_valid), .out(invalid_entry_addr));
//	min #(.n(WAYS), .WIDTH(HISTORY_WIDTH)) get_override_addr (.in(wrline_history), .addr(override_addr), .value(minimum_history);
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
			if (we) begin
				for (j=0; j<DATA_WIDTH; j=j+1)
					ram_data[write_set][true_write_addr*DATA_WIDTH+j] <= in[j];
				if (~wr_hit_wire) begin
					ram_valid[write_set][true_write_addr] <= 1'b1;
					for (j=0; j<TAG_WIDTH; j=j+1)
						ram_tag[write_set][true_write_addr*TAG_WIDTH+j] <= write_tag[j];
					for (j=0; j<HISTORY_WIDTH; j=j+1)
						ram_history[write_set][true_write_addr*HISTORY_WIDTH+j] <= minimum_history[j];
				end 
			end 
			if (re) begin
				hit <= hit_wire;
				out <= hit_wire ? out_wire : 'b0;
				if (line_valid[read_mpx_addr]) for (j=0; j<HISTORY_WIDTH; j=j+1)
					ram_history[read_set][read_mpx_addr*HISTORY_WIDTH+j] <=  history_inc[j];
				if (all_hist_msb) for (j=0; j<WAYS; j=j+1)
					ram_history[read_set][(j+1)*HISTORY_WIDTH] <= 1'b0;
			end else begin
				hit <= 'b0;
				out <= 'b0;
			end
		end
	end
endmodule
