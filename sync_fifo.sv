// sync_fifo.sv
// Simple, synthesizable synchronous FIFO (single clock).
// - Registered read (rd_data valid one cycle after successful read)
// - Power-of-two depth (DEPTH = 2**ADDR)
// - Full/empty via extra wrap bit on pointers.

module sync_fifo #(
  parameter int WIDTH = 32,
  parameter int ADDR  = 4   // DEPTH = 2**ADDR
) (
  input  logic                 clk,
  input  logic                 rst_n,

  // Write side
  input  logic                 wr_en,      // enqueue request
  input  logic [WIDTH-1:0]     wr_data,
  output logic                 full,

  // Read side
  input  logic                 rd_en,      // dequeue request
  output logic [WIDTH-1:0]     rd_data,
  output logic                 rd_valid,   // asserted for 1 cycle when rd_data updates
  output logic                 empty
);

  localparam int DEPTH = (1 << ADDR);

  // Memory
  logic [WIDTH-1:0] mem [DEPTH];

  // Pointers use one extra bit (wrap bit) to distinguish full vs empty
  typedef logic [ADDR:0] ptr_t; // ADDR+1 bits
  ptr_t wptr, rptr;
  ptr_t wptr_next, rptr_next;

  // Convenience: address fields (index) and wrap bits
  wire [ADDR-1:0] waddr = wptr[ADDR-1:0];
  wire [ADDR-1:0] raddr = rptr[ADDR-1:0];

  // Predict next pointers (only advance on successful op)
  wire do_write = wr_en && !full;
  wire do_read  = rd_en && !empty;

  assign wptr_next = wptr + ptr_t'(do_write);
  assign rptr_next = rptr + ptr_t'(do_read);

  // Full/Empty logic
  // Empty when pointers equal
  // Full when next write pointer catches read pointer with inverted MSB
  wire full_next  = ( (wptr_next[ADDR]     != rptr[ADDR]) &&
                      (wptr_next[ADDR-1:0] == rptr[ADDR-1:0]) );
  wire empty_next = (wptr_next == rptr_next) ? 1'b1 :
                    (do_write && !do_read)   ? 1'b0 :
                    (do_read  && !do_write)  ? ( (wptr == rptr_next) ) :
                                               (wptr == rptr);

  // Registered read data & valid
  logic [WIDTH-1:0] rd_data_r;
  logic             rd_valid_r;

  // WRITE: occurs when do_write
  always_ff @(posedge clk) begin
    if (do_write) begin
      mem[waddr] <= wr_data;
    end
  end

  // READ: registered output; capture at read address when do_read
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_data_r  <= '0;
      rd_valid_r <= 1'b0;
    end else begin
      rd_valid_r <= do_read;
      if (do_read) begin
        rd_data_r <= mem[raddr];
      end
    end
  end

  assign rd_data  = rd_data_r;
  assign rd_valid = rd_valid_r;

  // POINTER & FLAG REGISTERS
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      full  <= 1'b0;
      empty <= 1'b1;
    end else begin
      wptr  <= wptr_next;
      rptr  <= rptr_next;
      full  <= full_next;
      // robust empty update
      empty <= (wptr_next == rptr_next);
    end
  end

endmodule
