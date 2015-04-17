//==================================================================================================
//  Filename      : barcode_tb.v
//  Created On    : 2015-03-25 03:54:05
//  Last Modified : 2015-03-25 10:41:04
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module barcode_tb();

	reg clk, rst_n,clr_ID_vld, send;
	reg [21:0] period;
	reg [7:0] station_ID;
	wire [7:0] ID;
	wire ID_vld;
	wire BC, BC_done;

	barcode_mimic BARCODE_MIMIC(.clk(clk),.rst_n(rst_n), .period(period), .send(send), .station_ID(station_ID), 
		.BC_done(BC_done), .BC(BC));

	barcode BARCODE(.clk(clk), .rst_n(rst_n), .BC(BC), .clr_ID_vld(clr_ID_vld), 
		.ID_vld(ID_vld), .ID(ID));

	initial begin
		clk = 0;
		rst_n = 0;
		clr_ID_vld = 0;
		send = 0;
		period = 22'h001000;
		station_ID = 8'b11110010;

		@(negedge clk);
		rst_n = 1;
		@(posedge clk);
		@(negedge clk);
		send = 1;
		@(negedge clk);
		send = 0;
		#71000;
		clr_ID_vld = 1;
		#2000;
		clr_ID_vld = 0;

		@(posedge BC_done);

		$display("ID: %b, station_ID: %b, ID_vld: %b", ID, station_ID, ID_vld);


		$display("ID: %b, station_ID: %b, ID_vld: %b", ID, station_ID, ID_vld);

		$stop;
	end

	always
		#1 clk <= ~clk;

endmodule