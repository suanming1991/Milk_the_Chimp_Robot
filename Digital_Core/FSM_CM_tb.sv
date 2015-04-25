module FSM_CM_tb ();
	reg clk, rst_n, trmt, send;
	reg [7:0] station_ID;
	reg [21:0] period;
	reg [7:0] tx_data;
	reg OK2Move;

	wire TX, rdy, tx_done, clr_rdy; //UART
	wire [7:0] cmd;
	wire BC, BC_done, ID_vld, clr_ID_vld; //Barcode
	wire [7:0] ID;
	wire in_transit, go; //Command FSM
	wire buzz, buzz_n; //??right now do nothing

	UART_tx transmitter(.TX(TX),.tx_done(tx_done),.trmt(trmt),.clk(clk),.rst_n(rst_n),.tx_data(tx_data));
    UART_rx receiver(.rdy(rdy),.cmd(cmd),.clk(clk),.rst_n(rst_n),.RX(TX),.clr_rdy(clr_rdy));

//??station_ID is equal to cmd[5:0] or {00,cmd[5:0]}
    barcode BARCODE(.clk(clk), .rst_n(rst_n), .BC(BC), .clr_ID_vld(clr_ID_vld),.ID_vld(ID_vld), .ID(ID));
    barcode_mimic BARCODE_MIMIC(.clk(clk),.rst_n(rst_n), .period(period), .send(send), .station_ID(station_ID), .BC_done(BC_done), .BC(BC));
    
//??is that cmd_rdy == rdy?
	FSM_CM iCommand_FSM(.clr_cmd_rdy(clr_rdy), .clr_ID_vld(clr_ID_vld), .buzz(buzz), .buzz_n(buzz_n), .go(go),  .in_transit(in_transit), 
		.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(rdy), .ID(ID),  .ID_vld(ID_vld),	.OK2Move(OK2Move) );

	task send_cmd(input [7:0] data);
       begin
 		tx_data = data;

 		@(posedge clk)
 		trmt = 1;
 		@(posedge clk)
 		trmt = 0;
 	    @(posedge tx_done);
 	    	$display("tx_done is done");
 		@(posedge clk);
 		@(negedge clk);
 		@(posedge clk);
 		@(negedge clk);

       end
	endtask

	task ID_read(input [7:0] xdata);
       begin
       	period=22'h001000; //??copy from my barcode_tb.v ??
 		station_ID = xdata;
 		@(posedge clk)
 		send = 1;
 		@(posedge clk)
 		send = 0;
       end
	endtask

initial begin
    clk = 0;
    rst_n = 0;
    OK2Move=1;
    station_ID=8'h28;
    period = 1024;
    send = 0;

   @(negedge clk);
   @(posedge clk);
   @(negedge clk);
       rst_n = 1;
       send = 1;
   @(negedge clk);
   @(posedge clk);
//test 1
//command go, station ID = 000100
  send_cmd(8'b01000100);

  @(posedge rdy) begin
	$display("good !, 2nd Command is recieved.. ROBOT on the right track");
  end

  @(posedge go) begin
	$diapaly("good !, Go is asserted..ROBOT on the right track");
  end
  
  //repeat (10000) @(negedge clk);
//test 2
//command stop, station ID = 000100
  send_cmd(8'b00000100);

  @(posedge rdy) begin
	$display("good !, 2nd Command STOP is recieved.. ROBOT on the right track");
  end

  @(negedge go) begin
	$diapaly("good !, Go is deasserted..ROBOT Stopped now");
  end


//tset 3(valid ID, upper two bits is 00)
//station ID !== ID
 /* send_cmd(8'b01000100);
  repeat (100) @(negedge clk);

  ID_read(8'b00000111);

  @(posedge ID_vld) begin
	$display("good !, ID read from barcode is valid");
  end


  @(posedge go) begin
	$diapaly("good !, ID is not equal station ID, Go is still asserted");
  end

//tset 4(valid ID, upper two bits is 00)
//station ID ==ID
  ID_read(8'b00000100);

  @(posedge ID_vld) begin
	$display("good !, ID read from barcode is valid");
  end

  @(negedge go) begin
	$diapaly("good !, Go is deasserted..ROBOT Stopped now");
  end

//test 5(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b11000100);

  @(posedge ID_vld) begin
	$display("good !, ID read from barcode is invalid");
  end

  @(posedge go) begin
	$diapaly("good !, invalid ID is readed..ROBOT is still on the right track");
  end

//test 6(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b10000100);

  @(posedge ID_vld) begin
	$display("good !, ID read from barcode is invalid");
  end

  @(posedge go) begin
	$diapaly("good !, invalid ID is readed..ROBOT is still on the right track");
  end

//test 7(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b10000100);

  @(posedge ID_vld) begin
	$display("good !, ID read from barcode is invalid");
  end

  @(posedge go) begin
	$diapaly("good !, invalid ID is readed..ROBOT is still on the right track");
  end

//test 8(OK2Move)
*/
$stop;
end

always 
	# 1 clk =~ clk;

endmodule
