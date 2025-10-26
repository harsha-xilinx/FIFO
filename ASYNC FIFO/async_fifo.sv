module async_fifo #(parameter WIDTH=32, ADDR=4) (
// wr signals
input wire clk_wr, 
input wire rst_n_wr,
input wire [WIDTH-1:0] w_data,
input wire wr_en,
output reg fifo_full,

//rd signals
input wire clk_rd, 
input wire rst_n_rd,
input wire [WIDTH-1:0] r_data,
input wire rd_en,
output reg fifo_empty,

localparam DEPTH= (1 << ADDR); // DEPTH Calculation
reg [WIDTH-1:0] mem [0:DEPTH-1]; // Memory for FIFO

// read and wr pointers
reg [ADDR:0] wr_ptr_bin, wr_ptr_bin_nxt;
reg [ADDR:0] rd_ptr_bin, rd_ptr_bin_nxt;

//read and wr pntr in gray code
wire [ADDR:0] wr_ptr_gray, wr_ptr_gray_nxt;
wire [ADDR:0] rd_ptr_gray, rd_ptr_gray_nxt;

// fifo full and empty registers
wire fifo_full_next, fifo_empty_next ;

// Crossed/synchronized pointers
  reg [ADDR:0] rq1_rgray, rq2_rgray;
  reg [ADDR:0] wq1_wgray, wq2_wgray;

// Functions: bin<->gray
  function [ADDR:0] bin2gray;
    input [ADDR:0] b;
    begin
      bin2gray = (b >> 1) ^ b;
    end
  endfunction

  function [ADDR:0] gray2bin;
    input [ADDR:0] g;
    integer i;
    reg [ADDR:0] b;
    begin
      for (i = ADDR; i >= 0; i = i - 1)
        b[i] = ^g[ADDR:i];  // XOR folding
      gray2bin = b;
    end
  endfunction

// handling wr pointer //
    assign wr_ptr_bin_nxt  = wr_ptr_bin + (wr_en && !fifo_full);
    assign wr_ptr_gray_nxt = bin2gray(wr_ptr_bin_nxt);

// handling rd pointer //
    assign rd_ptr_bin_nxt  = rd_ptr_bin + (rd_en && !fifo_empty);
    assign rd_ptr_gray_nxt = bin2gray(rd_ptr_bin_nxt);

// FIFO FULL logic 
// If both pointers were in binary form, detecting full is easy:
// full = (wptr_next[ADDR] != rptr[ADDR]) && (wptr_next[ADDR-1:0] == rptr[ADDR-1:0]);
// Now we need an equivalent full condition in Gray code form.
//Gray code = binary ^ (binary >> 1)
//Let’s say our binary write pointer (wbin) and read pointer (rbin) are both 5 bits (ADDR+1 bits).
//For simplicity, assume rbin = 00000.
//Then:
//	•	The Gray code for rbin = 00000
//	•	The binary value one full FIFO depth ahead = 10000
//	•	The Gray code for that = 11000
//Notice:
//→ The Gray code 11000 = original 00000 with the top two bits inverted.
//That’s the key pattern:
//When the write pointer is exactly one full FIFO cycle ahead of the read pointer,
//the top two Gray bits are inverted, and the rest are identical.

always @(*) 
  begin
    rgray_mod  = {~rq2_rgray[ADDR:ADDR-1], rq2_rgray[ADDR-2:0]};
    full_next  = (wgray_next == rgray_mod);
end


// Synchronize READ gray pointer into WRITE domain
  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      rq1_rgray <= { (ADDR+1){1'b0} };
      rq2_rgray <= { (ADDR+1){1'b0} };
    end else begin
      rq1_rgray <= rd_ptr_gray;
      rq2_rgray <= rq1_rgray;
    end
  end

// write domain registers
  always @(posedge clk_wr or negedge rst_n_wr) 
   begin
    if (!rst_n_wr) 
     begin
      wr_ptr_bin  <= { (ADDR+1){1'b0} };
      wr_ptr_gray <= { (ADDR+1){1'b0} };
      full  <= 1'b0;
     end 
    else 
     begin
      wr_ptr_bin  <= wr_ptr_bin_nxt;
      wr_ptr_gray <= wr_ptr_gray_nxt;
      full  <= full_next;
      if (wr_en && !fifo_full)
        mem[w_ptr_bin [ADDR-1:0]] <= wdata;
     end
   end

// READ LOGIC WRITINGS

// Synchronize WR gray pointer into READ domain
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      wr1_rgray <= { (ADDR+1){1'b0} };
      wr2_rgray <= { (ADDR+1){1'b0} };
    end else begin
      wr1_rgray <= wr_ptr_gray;
      wr2_rgray <= wr1_rgray;
    end
  end

// FIFO EMPTY LOGIC
always @(*) 
  begin
    fifo_empty_next = (rd_ptr_gray_nxt == wr2_wgray); // wr2_gray is nothing but wr_ptr_gray but sampled at clk_rd 
  end

// read domain registers
  always @(posedge clk_wr or negedge rst_n_wr) 
   begin
    if (!rst_n_rd) 
     begin
      rd_ptr_bin  <= { (ADDR+1){1'b0} };
      rd_ptr_gray <= { (ADDR+1){1'b0} };
      fifo_empty  <= 1'b0;
     end 
    else 
     begin
      rd_ptr_bin  <= rd_ptr_bin_nxt;
      rd_ptr_gray <= rd_ptr_gray_nxt;
      fifo_empty  <= fifo_empty_next;
      if (rd_en && !fifo_empty)
        rdata <= mem[rd_ptr_bin[ADDR-1:0]];
     end
   end

endmodule
