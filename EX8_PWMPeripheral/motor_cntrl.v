//==================================================================================================
//  Filename      : motor_cntrl.v
//  Created On    : 2015-02-23 10:52:27
//  Last Modified : 2015-04-23 14:57:42
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : UW-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module motor_cntrl (/*autoport*/
//output
			fwd_lft,
			rev_lft,
			fwd_rht,
			rev_rht,
//input
			lft,
			rht,
			clk,
			rst_n);

	output fwd_lft, rev_lft, fwd_rht, rev_rht;
	input [10:0] lft, rht;
	input clk,rst_n;

	wire [9:0] mag_lft, mag_rht; // inputs of 10-bit PWM, they are duty[9:0] for peripheral
	wire [9:0] pwm_signal_lft, pwm_signal_rht; //ouputs of 10-bit PWM

	/* if MSB is 1, we need to invert the signal and plus 1 to get its magnitude */
	/* assign mag_lft = 
		(lft[10] == 1)	?	(~lft[9:0] + 1):
		lft[9:0]; */

	/* get the magnitude of 11 bit lft or rht signal. If 11'b100_0000_0000 is fed, convert
	it into 11'b100_0000_0001. Otherwise, invert the signal nad add 1 to get the magnitude
	if MSB is 1 */
	assign mag_lft = 
		(lft[10] == 1)	?	((lft[9:0] == 10'b00_0000_0000)	?	10'b11_1111_1111:
																(~lft[9:0] + 1)):
		lft[9:0];

	assign mag_rht =
		(rht[10] == 1)	?	((rht[9:0] == 10'b00_0000_0000)	?	10'b11_1111_1111:
																(~rht[9:0] + 1)):
		rht[9:0];

	PWMPeripheral PWMPeripheral_lft(
		.PWM_sig(pwm_signal_lft),
		.duty(mag_lft),
		.clk(clk),
		.rst_n(rst_n)
		);

	PWMPeripheral PWMPeripheral_rht(
		.PWM_sig(pwm_signal_rht),
		.duty(mag_rht),
		.clk(clk),
		.rst_n(rst_n)
		);

	assign fwd_lft = 
		(lft == 11'b000_0000_0000)	?	1:
		(lft[10] == 1)	?	0:
		//mag_lft;
		pwm_signal_lft;

	assign rev_lft =
		(lft == 11'b000_0000_0000)	?	1:
		(lft[10] == 0)	?	0:
		mag_lft;
		pwm_signal_lft;

	assign fwd_rht = 
		(rht == 11'b000_0000_0000)	?	1:
		(rht[10] == 1)	?	0:
		//mag_rht;
		pwm_signal_rht;

	assign rev_rht = 
		(rht == 11'b000_0000_0000)	?	1:
		(rht[10] == 0)	?	0:
		//mag_rht;
		pwm_signal_rht;

endmodule
