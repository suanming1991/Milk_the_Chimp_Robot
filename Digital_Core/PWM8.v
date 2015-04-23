//==================================================================================================
//  Filename      : PWM8.v
//  Created On    : 2015-02-22 21:57:40
//  Last Modified : 2015-04-22 23:34:26
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : UW-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module PWM8 (/*autoport*/
//output
			PWM_sig,
//input
			duty,
			clk,
			rst_n);
	output reg PWM_sig;

	input [7:0]	duty;	//duty cycle
	input clk,rst_n;
	reg [7:0] cntr;		//counter

	/* This is a 7-bit counter. It will be used to determine on/off state of PWM */
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			cntr <= 0;
		end else begin
			cntr <= cntr + 1;
		end
	end

	/* PWM_sig is configured */
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			PWM_sig <= 0;

		/* if 10 bits of cntr are all 1's, or break mode is 1, PWM_sig is set */
		end else if( (&cntr == 1) || (duty == 0) ) begin
			PWM_sig <= 1;

		/* if cntr is equal to duty cycle, PWM_sig is reset */
		end else if( duty == cntr ) begin
			PWM_sig <= 0;

		/* otherwise, keep current state */
		end else begin
			PWM_sig <= PWM_sig;
		end
	end


endmodule