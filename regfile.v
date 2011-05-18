`include "defines.v"

module regfile
  #(parameter n = `DEFAULT_WIDTH,
    parameter bits = 3)
   (input            clock,
    input 	     write_enable,
    input [bits-1:0] write_addr, read_addr,
    input [n-1:0]    write_data,
    output [n-1:0]   read_data);

   reg [n-1:0] file[2**bits-1:0];

   always @(posedge clock)
     if (write_enable)
       file[write_addr] <= write_data;

   assign read_data = file[read_addr];
endmodule // regfile
