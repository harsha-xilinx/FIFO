/*
This is slave side AXI5 based synchronous FIFO code
So, here we are writingbasic code of AXI5 based, and we need to write logic of AXI5 based VALID and READY signals here then
*/

module axi5_fifo_slave #(parameter WIDTH=32, ADDR=4, AXI_ADDR_WIDTH=32, AXI_ID_WIDTH=4) (
  input clk, rst,
  // WRITE ADDRESS Signals
  input [AXI_ADDR_WIDTH-1:0] AWADDR,
  input [AXI_ID_WIDTH-1:0] AWID,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWVALID,
  output reg AWREADY,

  //READ ADDRESS SIGNALS
  input [AXI_ADDR_WIDTH-1:0] ARADDR,
  input [AXI_ID_WIDTH-1:0] ARID,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARVALID,
  output reg ARREADY,

  //WRITE DATA SIGNALS
  input [WIDTH-1:0] W_DATA,
  input WVALID,
  input WLAST,
  output reg WVALID,

  //READ DATA SIGNALS
  input RREADY,
  output reg [WIDTH-1:0] R_DATA,
  output reg RVALID,
  output reg [1:0] RRESP,
  output reg RLAST,
);

//------------------- Internal FIFO Signals -------------------//
wire fifo_empty, fifo_full;
reg fifo_wr_en, fifo_rd_en;
reg [WIDTH-1:0] fifo_wdata;
wire [WIDTH-1:0] fifo_rdata;
  
//------------------- FIFO Instance --------------------------//

sync_fifo #(
.WIDTH(WIDTH),
.ADDR(ADDR)
) u_fifo (
.clk(clk),
.rst(rstn),
.clr(1'b0),
.wr_en(fifo_wr_en),
.wdata(fifo_wdata),
.rd_en(fifo_rd_en),
.rdata(fifo_rdata),
.fifo_empty(fifo_empty),
.fifo_full(fifo_full)
);


/////////////// FSM FOR WRITE DATA /////////////////////////
always @(posedge clk or negedge rstn) begin
if (!rstn) 
begin //1
  AWREADY <= 1'b1;
  WREADY <= 1'b0;
  BVALID <= 1'b0;
  write_cnt <= 0;
  write_active <= 0;
  fifo_wr_en <= 0;
end //1
else 
begin //2
  if(AWVALID && AWREADY)
    begin
      awid_reg <= AWID;
      write_cnt <= AWLEN;
      AWREADY <= 1'b0;
      WREADY <= 1'b1;
      write_cnt <= AWLEN;
    end

  if (WVALID && WREADY & ~fifo_full)   // write
    begin
      fifo_wr_en <= 1'b1;
      fifo_wdata <= WDATA
    end
    if (write_cnt) //write_cnt
      begin
        WREADY <= 1'b0;
        BVALID <= 1'b1;
        BRESP <= 2'b00; // OKAY
        BID <= awid_reg;
      end
    else // write_cnt
       begin
        write_cnt <= write_cnt-1; 
       end
  else  // write
    begin
      fifo_wr_en <= 1'b0;      
    end

if (BVALID && BREADY) 
  begin
    BVALID <= 1'b0;
    AWREADY <= 1'b1;
  end
end   //2

/////////////// FSM FOR READ DATA /////////////////////////
always @(posedge clk or negedge rstn) begin
if (!rstn) 
begin //1
  ARREADY <= 1'b1;
  RVALID <= 1'b0;
  RLAST <= 1'b0;
  read_cnt <= 0;
  fifo_rd_en <= 0;
end //1 
else
begin
  if (ARVALID && ARREADY) 
    begin
    arid_reg <= ARID;
    read_cnt <= ARLEN;
    ARREADY <= 1'b0;
    end
  else

    // Generate Read Data
if (!fifo_empty && RREADY && !RVALID) 
  begin
    RDATA <= fifo_rdata;
    RID <= arid_reg;
    RVALID <= 1'b1;
    RRESP <= 2'b00;
    RLAST <= (read_cnt == 0);
    fifo_rd_en <= 1'b1;
  end 
else 
  begin
    fifo_rd_en <= 1'b0;
  end

if (RVALID && RREADY) 
begin
RVALID <= 1'b0;
if (read_cnt == 0) 
  begin
    ARREADY <= 1'b1; // if read count is 0, it's ready to accept another address
  end 
else 
  begin
    read_cnt <= read_cnt - 1;
  end
end
end
end //2
  
