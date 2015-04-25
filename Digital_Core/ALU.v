//==================================================================================================
//  Filename      : ALU.v
//  Created On    : 2015-02-15 10:06:17
//  Last Modified : 2015-03-22 22:19:04
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : UW-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module ALU(/*autoport*/
	//output
	dst,
	//input
	Accum,
	Pcomp,
	Pterm,
	Fwd,
	A2d_res,
	Error,
	Intgrl,
	Icomp,
	Iterm,
	src1sel,
	src0sel,
	multiply,
	mult2,
	mult4,
	sub,
	saturate);

	output signed [15:0] dst;
	input [15:0] Accum, Pcomp; 
	input [13:0] Pterm;
	input [11:0] Fwd,A2d_res, Error, Intgrl, Icomp, Iterm;
	input [2:0] src1sel, src0sel; 
	input multiply, mult2, mult4, sub, saturate;

	wire [15:0] src1, src0;
	wire [15:0] pre_src0;

	localparam ACCUM = 3'b000;
	localparam ITERM     = 3'b001;
	localparam ERROR_12_2_16     = 3'b010;
	localparam ERROR_8_2_16  = 3'b011;
	localparam FWD  = 3'b100;

	// MUX selected by src1sel
	assign src1 = 
		(src1sel==ACCUM) 	? 	Accum : 
		(src1sel==ITERM) 	? 	{4'b0000, Iterm} :
		(src1sel==ERROR_12_2_16) 	? 	{{4{Error[11]}}, Error} :
		(src1sel==ERROR_8_2_16) 	? 	{{8{Error[11]}}, Error[11:4]} :
		(src1sel==FWD) 	? 	{4'b0000, Fwd} :
		16'h0000;

	localparam A2D_RES = 3'b000;
	localparam INTGRL     = 3'b001;
	localparam ICOMP     = 3'b010;
	localparam PCOMP  = 3'b011;
	localparam PTERM  = 3'b100;

	// MUX selected by src0sel
	assign pre_src0 = 
		(src0sel==A2D_RES) 	? 	{4'b0000, A2d_res} : 
		(src0sel==INTGRL) 	? 	{{4{Intgrl[11]}}, Intgrl} :
		(src0sel==ICOMP) 	? 	{{4{Icomp[11]}}, Icomp} :
		(src0sel==PCOMP) 	? 	Pcomp :
		(src0sel==PTERM) 	? 	{{2'b00,Pterm}} :
		16'h0000;

	wire [15:0] pre_src0_mult4;
	wire [15:0] pre_src0_mult2;

	assign pre_src0_mult2 = pre_src0 << 1;
	assign pre_src0_mult4 = pre_src0 << 2;

	wire [15:0] scaled_src0;

	assign scaled_src0 =
		(mult4==1)	?	pre_src0_mult4	:
		(mult4==0 & mult2 == 1)	?	pre_src0_mult2 :
		pre_src0;

	wire [15:0] scaled_src0_inverted;
	assign scaled_src0_inverted = ~ scaled_src0;

	assign src0 = 
		(sub == 1)	?	scaled_src0_inverted	:
		scaled_src0;

	wire signed [15:0] adder_result;
	assign adder_result = sub + src0 + src1;

	wire signed [15:0] saturate_input;

	assign saturate_input = 
		(adder_result > 2047)	?	16'h07FF	:
		(adder_result < -2048)	?	16'hF800	:
		adder_result;	//this is not working in hex, why?

	wire signed [15:0] saturate_result;
	assign saturate_result = 
		(saturate == 1)	?	saturate_input	:
		adder_result;

	/* convert src0[14:0], src1[14:0] to signed */
	wire signed [14:0] signed_src1;
	wire signed [14:0] signed_src0;

	assign signed_src1 = src1[14:0];
	assign signed_src0 = src0[14:0];

	wire signed [29:0] multer_result;
	assign multer_result = signed_src1 * signed_src0;

	wire signed [15:0] temp;
	assign temp =
		(multer_result[29] == 0)	?	((|(multer_result[28:26]) == 0)	?	multer_result[27:12]	: 16'h3FFF)	:
		((&(multer_result[28:26]) == 1)	?	multer_result[27:12]	:	16'hC000);

	assign dst = 
		(multiply == 1)	?	temp	:
		saturate_result;

	







endmodule

