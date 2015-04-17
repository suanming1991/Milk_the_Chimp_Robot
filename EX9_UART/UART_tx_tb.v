//==================================================================================================
//  Filename      : UART_tx_tb.v
//  Created On    : 2015-03-01 20:50:45
//  Last Modified : 2015-03-01 20:50:45
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : University of Wisconsin-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module UART_tx_tb ();
	wire TX;
	wire tx_done;

	reg trmt;
	reg clk,rst_n;
	reg [7:0] tx_data;

	UART_tx iDUT(
		//output
		.TX(TX),
		.tx_done(tx_done),
		//input
		.trmt(trmt),
		.clk(clk),
		.rst_n(rst_n),
		.tx_data(tx_data));

	initial begin 
		clk = 0;
		rst_n = 0;
		trmt = 0;
		tx_data = 0;
		#5;
		rst_n = 1;
		#5;
		tx_data = 0'b10110011;
		#50;
		trmt = 1;
		#20;
		trmt = 0;
		#100;
		trmt = 1;
		#100;
		trmt = 0;
		#80000;
		rst_n = 0;
		#50;
		rst_n = 1;
		#50;
		tx_data = 0'b00101000;
		#5000;
		trmt = 1;
		#80000;
		$stop;
	end

	always begin
		#1 clk = ~clk;
	end


endmodule