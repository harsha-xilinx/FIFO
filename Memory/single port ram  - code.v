          +------------------------------+
 addr --->|                              |
 we   --->|        Single-Port RAM       |--> dout
 din  --->|                              |
 clk  --->|                              |
          +------------------------------+


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2025 16:43:31
// Design Name: 
// Module Name: single_port_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

Below is code for synchronous READ , interviewer may ask for asynchronous READ, where you have to move out the read logic from always block and keepp in continuous assignment. Basically it's not sync with CLK.

module single_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk, rst,
    input  wire                   we,      // write enable
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout
);

reg [DATA_WIDTH-1:0] memory_sram [0:(1<<ADDR_WIDTH)-1];

always@(posedge clk, posedge rst)
begin
 if(rst)
   dout <= {DATA_WIDTH{1'b0}};
 else
  begin
      if (we)
      begin
      memory_sram[addr] <= din;
      end
      else
      dout <= memory_sram[addr];
      begin
      end
  end
end
endmodule
