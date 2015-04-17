//==================================================================================================
//  Filename      : ALU_tb.v
//  Created On    : 2015-03-20 10:14:40
//  Last Modified : 2015-03-22 22:13:55
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module ALU_tb ();

	wire [15:0] dst;
	reg [15:0] Accum, Pcomp; 
	reg [13:0] Pterm;
	reg [11:0] Fwd,A2d_res, Error, Intgrl, Icomp, Iterm;
	reg [2:0] src1sel, src0sel; 
	reg multiply, mult2, mult4, sub, saturate;

	/* reg [(width of vector - 1):0] var_name[0:(row - 1)]; */
	/* reg [(width of vector - 1):0] var_name[0:(row - 1)][(column - 1):0];*/
	reg [128:0] mem_stim[0:999];
	reg [15:0] mem_response[0:999];




	ALU iDUT(/*autoport*/
		//output
		.dst(dst),
		//input
		.Accum(Accum),
		.Pcomp(Pcomp),
		.Pterm(Pterm),
		.Fwd(Fwd),
		.A2d_res(A2d_res),
		.Error(Error),
		.Intgrl(Intgrl),
		.Icomp(Icomp),
		.Iterm(Iterm),
		.src1sel(src1sel),
		.src0sel(src0sel),
		.multiply(multiply),
		.mult2(mult2),
		.mult4(mult4),
		.sub(sub),
		.saturate(saturate));
	integer i;
	/* set red_flag if the output has a mismatch compared to expected output */
	integer red_flag;

	reg [15:0] crtExptOutput;

	initial begin 

		$readmemh("ALU_stim.hex", mem_stim);
		$readmemh("ALU_resp.hex", mem_response); 
		#10;
		red_flag = 0;
		for (i = 0; i < 1000; i = i + 1) begin : testing
			$display("\n");
			$display("index = %d",i);
			$display("data = %h", mem_stim[i]);
			Accum = mem_stim[i][128:113];
			Pcomp = mem_stim[i][112:97];
			Pterm = mem_stim[i][96:83];
			Fwd = mem_stim[i][82:71];
			A2d_res = mem_stim[i][70:59];
			Error = mem_stim[i][58:47];
			Intgrl = mem_stim[i][46:35];
			Icomp = mem_stim[i][34:23];
			Iterm = mem_stim[i][22:11];
			src1sel = mem_stim[i][10:8];
			case (src1sel)
				3'b000	:	$display("src1 selecting Accum...");
				3'b001	:	$display("src1 selecting Iterm...");
				3'b010	:	$display("src1 selecting Error, 4 bits extended...");
				3'b011	:	$display("src1 selecting Error, 8 bits extended...");
				3'b100 	:	$display("src1 selecting Fwd...");
				default : 	$display("src1: Nothing is selected");
			endcase
			src0sel = mem_stim[i][7:5];
			case (src0sel)
				3'b000	:	$display("src0 selecting A2d_res...");
				3'b001 	:	$display("src0 selecting Intgrl...");
				3'b010 	:	$display("src0 selecting Icomp...");
				3'b011	:	$display("src0 selecting Pcomp...");
				3'b100 	:	$display("src0 selecting Pterm...");
				default : 	$display("src0: Nothing is selected");
			endcase

			multiply = mem_stim[i][4];

			sub = mem_stim[i][3];

			mult2 = mem_stim[i][2];

			mult4 = mem_stim[i][1];

			saturate = mem_stim[i][0];
			crtExptOutput = mem_response[i];
			#30;
			$display("src1 is %h",iDUT.src1);
			$display("pre_src0 is %h",iDUT.pre_src0);
			$display("src0 is %h",iDUT.src0);

			if(multiply) begin
				$display("we are multiplying...");
				$display("src1[14:0] is %h", iDUT.src1[14:0]);
				$display("src1[14:0] is %b", iDUT.src1[14:0]);
				$display("src0[14:0] is %h", iDUT.src0[14:0]);
				$display("src0[14:0] is %b", iDUT.src0[14:0]);
				$display("multiplication result is %b", iDUT.multer_result);
				$display("top 4 bits are %b", iDUT.multer_result[29:26]);
				$display("multer_result[27:12] is %h", iDUT.multer_result[27:12]);
				$display("multer_result[27:12] is %b", iDUT.multer_result[27:12]);
			end else begin 
				$display("we are adding...",);
				$display("src1 is %h",iDUT.src1);
				$display("pre_src0 is %h",iDUT.pre_src0);
				if(mult4) begin
					$display("multiply by 4 is on...");
				end

				if(mult2) begin
					$display("multiply by 2 is on...");
				end 

				if(sub) begin
					$display("substract is on...");
				end

				$display("adder result is %h", iDUT.adder_result);
				$display("Saturated result is %h", iDUT.saturate_input);

				if(saturate) begin
					$display("saturate is on...");
				end
			end

			//crtExptOutput = mem_response[i];
			if(dst == crtExptOutput) begin
				$display("expected response %h",mem_response[i]);
				$display("real response %h",dst);
				$display("It's a match");
				$display("\n");
			end else begin 
				$display("expected response %h",mem_response[i]);
				$display("expected response %b",mem_response[i]);
				$display("real response %h",dst);
				$display("output mismatch!!!!");
				$display("\n");
				red_flag = 1;
			end
			#10;
		end
		if(red_flag) begin
			$display("Test not passed!!");
		end else begin 
			$display("Test passed!!");
		end
		$stop;
	end

endmodule