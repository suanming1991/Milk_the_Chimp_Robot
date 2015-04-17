//==================================================================================================
//  Filename      : PWMPeripheral_tb.v
//  Created On    : 2015-02-28 16:34:18
//  Last Modified : 2015-02-28 16:34:18
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : UW-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module PWMPeripheral_tb ();

	wire PWM_sig;
	reg [9:0]	duty;
	reg clk,rst_n;

	PWMPeripheral iDUT(
		.PWM_sig(PWM_sig),
		.duty(duty),
		.clk(clk),
		.rst_n(rst_n));

	initial begin 
		duty = 0;
		clk = 0;
		rst_n = 1;
		#8;
		rst_n = 0;
		#3;
		rst_n = 1;
		#3;
		duty = 10'b00_0011_0000;
		#10000;
		rst_n = 1;
		#4;
		rst_n = 0;
		#2;
		rst_n = 1;
		#2;
		duty = 10'b11_0000_0000;
		#10000;
		$stop;
	end

	always begin
		#1 clk = ~clk;
	end

endmodule