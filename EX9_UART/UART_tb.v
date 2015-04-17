//==================================================================================================
//  Filename      : UART_tb.v
//  Created On    : 2015-03-02 14:42:00
//  Last Modified : 2015-03-02 17:13:19
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : University of Wisconsin-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module UART_tb ();

	//transmitter parameters
	wire TX;
	wire tx_done;

	reg trmt;
	reg clk,rst_n;
	reg [7:0] tx_data;

	//receiver parameters
	wire [7:0] rx_data;
	wire rdy;

	reg clr_rdy;

	UART_tx transmitter(
		//output
		.TX(TX),
		.tx_done(tx_done),
		//input
		.trmt(trmt),
		.clk(clk),
		.rst_n(rst_n),
		.tx_data(tx_data));

	UART_rx receiver(/*autoport*/
		//output
		.rdy(rdy),
		.cmd(rx_data),
		//input
		.clk(clk),
		.rst_n(rst_n),
		.RX(TX),
		.clr_rdy(clr_rdy));

	initial begin 
		trmt = 0;
		clk = 0;
		rst_n = 0;
		clr_rdy = 0;
		#5;
		rst_n = 1;
		#5;
		tx_data = 8'hFF;
		#10000;
		trmt = 1;
		#5000;
		trmt = 0;
		#40000;
		clr_rdy = 1;
		#10000;
		clr_rdy = 0;
		#30000;
		tx_data = 8'hAC;
		#10000;
		trmt = 1;
		#100000;
		$stop;
	end

	always begin 
			#1 clk = ~clk;
	end

endmodule