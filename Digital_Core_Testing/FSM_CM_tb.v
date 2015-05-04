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
    @(posedge rdy);
 	
       end
	endtask

	task ID_read(input [7:0] xdata);
       begin
       	period=1024; 
 		station_ID = xdata;
 		@(posedge clk)
 		send = 1;
 		@(posedge clk)
 		send = 0;
    @(posedge BC_done);
       end
	endtask

initial begin
    clk = 0;
    rst_n = 0;
    OK2Move=1;
    station_ID=8'h00;
    period = 1024;
    send=0;
    

   @(negedge clk);
   @(posedge clk);
   @(negedge clk);
       rst_n = 1;
//test 1
//command go, station ID = 000100
  send_cmd(8'b01000100);
  
//test 2
//command stop, station ID = 000100
  send_cmd(8'b00000100);

 $stop;
//go command again!!!
  send_cmd(8'b01000100);

//tset 3(valid ID, upper two bits is 00)
//wrong but valid ID
  ID_read(8'b00000111);
  
//tset 4(valid ID, upper two bits is 00)
//stop ID
  ID_read(8'b00000100);
repeat (1000) @(negedge clk);

$stop;
//go command again!!!different dest_ID

  send_cmd(8'b01000110);

//test 5(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b11000100);


//test 6(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b10000100);


//test 7(invalid ID, upper two bits is 11 or 01 or 10)
  ID_read(8'b01000100);

//test 8(valid ID)
//stop ID
  ID_read(8'b00000110);
$stop;
//test 9(OK2Move)
 send_cmd(8'b01001111);
 OK2Move=0;

end

always 
	# 1 clk =~ clk;

endmodule