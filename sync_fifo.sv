/*Verilog code for FIFO
*/

module #(parameter WIDTH=32, ADDR=4) sync_fifo(
  input clk, rst,
  
  input wr_en, 
  input [WIDTH-1:0] wdata,
  
  input rd_en,
  output reg [WIDTH-1:0] rdata,

  //status flags
  output reg fifo_empty, fifo_full
);
  //DEPTH OF FIFO
  localparam DEPTH = 2**ADDR ;
  reg [WIDTH-1:0] mem [0:DEPTH-1];

  // Address pointer
  reg [ADDR:0] wr_ptr, rd_ptr;
  wire [ADDR:0] wr_ptr_nxt, rd_ptr_nxt;

  wire   fifo_empty_nxt, fifo_full_nxt;
  assign wr_ptr_nxt = wr_en  & ~fifo_full ? wr_ptr + 1'b1 : wr_ptr ;
  assign rd_ptr_nxt = rd_en  & ~fifo_empty ? rd_ptr + 1'b1 : rd_ptr ;

//Logic for FIFO Full and FIFO Empty
    assign fifo_full_nxt =  (wr_ptr_nxt[ADDR-1:0] == rd_ptr_nxt[ADDR-1:0]) && (wr_ptr_nxt[ADDR] != rd_ptr_nxt[ADDR]);
    assign fifo_empty_nxt = (wr_ptr_nxt == rd_ptr_nxt);

    
// Reset and withoyt RESET logic
  always@ (posedge clk, negedge rst)
    if (~rst)
      begin
        fifo_empty<=1'b1;
        fifo_full<=1'b0;
        rd_ptr<=1'b0;
        wr_ptr<=1'b0;
      end
    else
      begin
        fifo_empty <= fifo_empty_nxt;
        fifo_full <= fifo_full_nxt;
        rd_ptr <= rd_ptr_nxt;
        wr_ptr <= wr_ptr_nxt;
      end

  always@ (posedge clk, negedge rst)
    begin //always
      if (~rst)
        rdata <= 0;
      else
        begin
          if (wr_en==1 && rd_en==1)
            begin
              mem[wr_ptr[ADDR-1:0]] <= wdata;
              rdata <= mem[rd_ptr[ADDR-1:0]];
            end
          else if (wr_en)
            mem[wr_ptr[ADDR-1:0]] <= wdata;
          else if (rd_en)
              rdata <= mem[rd_ptr[ADDR-1:0]];
        end
    end //always

endmodule
