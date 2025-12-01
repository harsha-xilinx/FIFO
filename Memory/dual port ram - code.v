What is a Dual-Port RAM (brief)

A dual-port RAM has two independent access ports (commonly called A and B). Each port can read or write simultaneously to the memory array. Useful for FIFOs, caches, interconnects, multi-master buffers, etc.

Important variations:

True dual-port (TDP): both ports can read or write any address independently, possibly same address at same time.

Simple dual-port: typically one port write, other read (single read/write port + read-only port).

Single-clock vs. dual-clock: both ports use same clk (simpler) or independent clocks (useful crossing clock domains).

  1) Parameterizable single-clock true dual-port (SystemVerilog / Verilog style)

  // dual_port_ram.sv
// Single-clock True Dual-Port RAM (parameterized)
// Synchronous write and synchronous read (registered outputs)
// READ_FIRST / WRITE_FIRST controlled by parameter.

module dual_port_ram #(
  parameter integer DATA_WIDTH = 32,
  parameter integer DEPTH      = 1024,
  // addr width calculated from DEPTH; small helper
  parameter integer ADDR_WIDTH = $clog2(DEPTH),
  // 0 => READ_FIRST (return old data on read-during-write),
  // 1 => WRITE_FIRST (return newly written data on read-during-write)
  parameter integer WRITE_FIRST = 1
)(
  input  wire                      clk,
  // Port A
  input  wire                      we_a,
  input  wire [ADDR_WIDTH-1:0]     addr_a,
  input  wire [DATA_WIDTH-1:0]     din_a,
  output reg  [DATA_WIDTH-1:0]     dout_a,
  // Port B
  input  wire                      we_b,
  input  wire [ADDR_WIDTH-1:0]     addr_b,
  input  wire [DATA_WIDTH-1:0]     din_b,
  output reg  [DATA_WIDTH-1:0]     dout_b
);

  // memory
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Optional: synthesis pragmas for FPGAs can be added (vendor-specific).

  // Port A operation (synchronous)
  always @(posedge clk) begin
    if (we_a) begin
      mem[addr_a] <= din_a;
      if (WRITE_FIRST)
        dout_a <= din_a;      // write-first: return new data  -> return same data on read bus , what you are writing
      else
        dout_a <= mem[addr_a]; // read-first: return old data (note: mem[addr_a] is old)
    end else begin
      dout_a <= mem[addr_a];
    end
  end

  // Port B operation (synchronous)
  always @(posedge clk) begin
    if (we_b) begin
      mem[addr_b] <= din_b;
      if (WRITE_FIRST)
        dout_b <= din_b;   // write-first: return new data  -> return same data on read bus , what you are writing
      else
        dout_b <= mem[addr_b];
    end else begin
      dout_b <= mem[addr_b];
    end
  end

endmodule



========================================================================================================================================
USING DUAL CLOCK - ASYNCHRONOUS CLOCK
------------------------------------------------------------------------------------------------------------------------------------------
// dual_port_ram_asyncclk.sv
// True dual-port RAM with independent clocks (clk_a, clk_b).
// Synchronous write and synchronous read on each port (registered outputs).

module dual_port_ram_asyncclk #(
  parameter integer DATA_WIDTH = 32,
  parameter integer DEPTH      = 1024,
  parameter integer ADDR_WIDTH = $clog2(DEPTH),
  parameter integer WRITE_FIRST = 1
)(
  // Port A
  input  wire                      clk_a,
  input  wire                      we_a,
  input  wire [ADDR_WIDTH-1:0]     addr_a,
  input  wire [DATA_WIDTH-1:0]     din_a,
  output reg  [DATA_WIDTH-1:0]     dout_a,
  // Port B
  input  wire                      clk_b,
  input  wire                      we_b,
  input  wire [ADDR_WIDTH-1:0]     addr_b,
  input  wire [DATA_WIDTH-1:0]     din_b,
  output reg  [DATA_WIDTH-1:0]     dout_b
);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Port A
  always @(posedge clk_a) begin
    if (we_a) begin
      mem[addr_a] <= din_a;
      if (WRITE_FIRST) dout_a <= din_a;
      else             dout_a <= mem[addr_a];
    end else begin
      dout_a <= mem[addr_a];
    end
  end

  // Port B
  always @(posedge clk_b) begin
    if (we_b) begin
      mem[addr_b] <= din_b;
      if (WRITE_FIRST) dout_b <= din_b;
      else             dout_b <= mem[addr_b];
    end else begin
      dout_b <= mem[addr_b];
    end
  end

endmodule

