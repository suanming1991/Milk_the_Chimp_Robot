//==================================================================================================
//  Filename      : motion_cntrl.sv
//  Created On    : 2015-04-22 14:54:29
//  Last Modified : 2015-05-03 17:32:12
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : Part of the Digital Core elements. It implements the state 
//					machine for IR Sensors $ PI math
//
//
//==================================================================================================

/* memo:
	1. need to give descriptive names to the states
	2. finish ALU part */

module motion_cntrl(/*autoport*/
//output
			IR_in_en,
			IR_mid_en,
			IR_out_en,
			strt_cnv,
			lft,
			rht,
			chnnl,
//input
			clk,
			rst_n,
			go,
			cnv_cmplt,
			res);

	output logic IR_in_en,IR_mid_en,IR_out_en;	// PWM based enables to various IR sensors
	output logic strt_cnv;						// used to initiate a Round Robing conversion on IR sensors
	output logic [10:0] lft,rht;				// 11-bit signed left and right motor controls
	output logic [2:0] chnnl;					// chnnl telling the addr of IR. Refer to p18 of spec

	input clk,rst_n;			// 50MHz clock and active low asynch reset
	input go;	//go command from cmd processing state machine
	input cnv_cmplt;	//indicates A2D conversion is ready
	input [11:0] res;	//IR readings from A2D conversion

	
	logic [2:0] chnnl_counter;	//channel counter for IR sensor pairing
	logic enable_timer;	//enable timer to run
	logic [12:0] timer;	//timer to keep track of time
	logic initiate_Accum_calc; //tell ALU addition of Accum
	logic incr_chnnl_counter;	//set to increment chnnl_counter counter
	logic clr_timer;	//set to clear the timer
	//logic Accum_right_select; //tell ALU the operation of right IR reading
	//logic Accum_left_select;	//tell ALU the operation of left IR reading
	logic clr_chnnl_counter;	//set to clr_chnnl_counter
								//also I am going to use it to clear accum_ff for now

	logic PWM_output8;//need to instantiate PWM8 module, this is the output
	logic [7:0] PWM_duty_cycle;	//PWM duty cycle. Set to be a constant 0x8C

	logic [15:0] dst;	//should it be signed?
	logic [15:0] Accum;
	logic [15:0] Pcomp; 	
	logic [13:0] Pterm;	//constant
	logic [11:0] Fwd,A2d_res, Error, Intgrl, Icomp, Iterm;
	logic [2:0] src1sel, src0sel; 
	logic multiply, mult2, mult4, sub, saturate;
	//Iterm is constant
	


	//logic [15:0] dst2accum;	//store dst so that it can be used to update next Accum 
	//logic load_dst_2_accum;	//set when dst is ready to load to Accum for next Accum update

	logic dst2accum_complt;	//assert to assign dst to Accum
	logic res2a2D_compt;	//assert to assign res to A2d
	logic dst2error_complt;	//assert to assign dst to Error
	logic dst2intgrl_complt;//assert to assign dst to Intgrl
	logic dst2icomp_complt;//assert to assign dst to Icomp
	logic dst2pcomp_complt;//assert to assign dst to Pcom
	logic dst2rht_reg_complt;//assert to assign dst to rht_reg
	logic dst2lft_reg_complt;//assert to assign dst to lft_reg

	logic [1:0] int_dec;	//intgrl happens every four cycles. This counter keeps track of that
	logic enable_int_dec;	//enable int_dec
	logic Icomp_timer;	//a one bit timer that allows Icomp multiplication to last two cycles
	logic enable_Icomp_timer;	//enable Icomp_timer

	logic [11:0] rht_reg;
	logic [11:0] lft_reg;

	typedef enum reg [5:0] {IDLE,WAIT4096, CHECK_CNV_CMPLT,ACCUM_RHT_IN, 
	ACCUM_RHT_MID, ACCUM_RHT_OUT, WAIT32, CHECK_CNV_CMPLT2,ACCUM_LFT_IN, 
	ACCUM_LFT_MID, ACCUM_LFT_OUT,CHECK_CHNNL, INTEGRAL,ICOMP,PCOMP,
	ACCUMCALC,RHT_REG,ACCUMCALC2,LFT_REG} state_t;
	state_t state, nxt_state;

	/* src1sel select localparams */
	localparam ALU_SEL_ACCUM = 3'b000;
	localparam ALU_SEL_ITERM     = 3'b001;
	localparam ALU_SEL_ERROR_SIGN_EXTND     = 3'b010;
	localparam ALU_SEL_ERROR_RHT_SHFT_FOUR  = 3'b011;
	localparam ALU_SEL_FWD  = 3'b100;

	/* src0sel select localparams */
	localparam ALU_SEL_A2D_RES = 3'b000;
	localparam ALU_SEL_INTGRL     = 3'b001;
	localparam ALU_SEL_ICOMP     = 3'b010;
	localparam ALU_SEL_PCOMP  = 3'b011;
	localparam ALU_SEL_PTERM  = 3'b100;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin : proc_grande_state_machine
		//default values
		enable_timer = 0;
		incr_chnnl_counter = 0;
		strt_cnv = 0;
		//Accum_right_select = 0;
		//Accum_left_select = 0;
		clr_timer = 0;
		clr_chnnl_counter = 0;
		enable_int_dec = 0;

		dst2accum_complt = 0;	//assert to assign dst to Accum
		res2a2D_compt = 0;	//assert to assign res to A2d
		dst2error_complt = 0;	//assert to assign dst to Error
		dst2intgrl_complt = 0;//assert to assign dst to Intgrl
		dst2icomp_complt = 0;//assert to assign dst to Icomp
		dst2pcomp_complt = 0;//assert to assign dst to Pcom
		dst2rht_reg_complt = 0;//assert to assign dst to rht_reg
		dst2lft_reg_complt = 0;//assert to assign dst to lft_reg		

		nxt_state = IDLE;

		case (state)
			IDLE:	if(go) begin
						incr_chnnl_counter = 0;
						clr_chnnl_counter = 1;
						clr_timer = 0;	//need to verify
						enable_timer = 1;
						//enable PWM to selected IR sensor pair

						nxt_state = WAIT4096;

					end else begin 
						incr_chnnl_counter = 0;
						clr_chnnl_counter = 0;
						enable_timer = 0;

						nxt_state = IDLE;
					end

			WAIT4096:	if(timer < 4096) begin
					enable_timer = 1;
					clr_chnnl_counter = 0;

					nxt_state = WAIT4096;
				end else if(timer == 4096) begin
					strt_cnv = 1;	//need to verify that
					clr_chnnl_counter = 0; 
					enable_timer = 0;

					nxt_state = CHECK_CNV_CMPLT;
				end
	
			CHECK_CNV_CMPLT:	if(cnv_cmplt == 0) begin
					strt_cnv = 0;	//strt_cnv is knocked down right away. Verify that it triggers the conversion
					
					nxt_state = CHECK_CNV_CMPLT;
				end else begin
					strt_cnv = 0; 
					//Accum_right_select = 1;
					incr_chnnl_counter = 1;	//increment chnnl_counter counter
					clr_timer = 1;	//set clear timer signal
					enable_timer = 1;	//enable the timer

					//nxt_state = ACCUM_RHT_IN;

					if(chnnl_counter == 0) begin
						nxt_state = ACCUM_RHT_IN;
					end else if(chnnl_counter == 2) begin
						nxt_state = ACCUM_RHT_MID;
					end else begin 
						nxt_state = ACCUM_RHT_OUT;
					end
				end

			ACCUM_RHT_IN:	begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
				dst2accum_complt = 1;	//need to verify

				nxt_state = WAIT32;
			end

			ACCUM_RHT_MID: begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 1;
				mult4 = 0;
				saturate = 0;

				dst2accum_complt = 1;	//need to verify

				nxt_state = WAIT32;
			end

			ACCUM_RHT_OUT: begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 1;
				saturate = 0;

				dst2accum_complt = 1;	//need to verify

				nxt_state = WAIT32;
			end

			WAIT32:	if(timer < 32) begin
					enable_timer = 1;
					//Accum_right_select = 0; //need to verify
					incr_chnnl_counter = 0;
					/* store dst to Accum flip flop */
					dst2accum_complt = 0;	//need to verify

					nxt_state = WAIT32;
				end else if(timer == 32) begin
					enable_timer = 1;
					strt_cnv = 1;	//need to verify
					//Accum_right_select = 0;
					incr_chnnl_counter = 0;
					/* do not update Accum flip flop */
					dst2accum_complt = 0;

					nxt_state = CHECK_CNV_CMPLT2;
				end

			CHECK_CNV_CMPLT2: if(cnv_cmplt == 0) begin
					strt_cnv = 0;

					nxt_state = CHECK_CNV_CMPLT2;
				end else begin 
					strt_cnv = 0;
					//Accum_left_select = 1;
					incr_chnnl_counter = 1;	//increment chnnl_counter counter
					clr_timer = 1;	//set clear timer signal
					/* store dst to Accum flip flop */
					/* need to verify because I don't know if dst 
					calculation takes less than one clock cycle*/
					

					//nxt_state = CHECK_CHNNL;
					if(chnnl_counter == 1) begin
						nxt_state = ACCUM_LFT_IN;
					end else if(chnnl_counter == 3) begin
						nxt_state = ACCUM_LFT_MID;
					end else begin 
						nxt_state = ACCUM_LFT_OUT;
					end
				end

			ACCUM_LFT_IN: begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;

				dst2accum_complt = 1;	//need to verify

				nxt_state = CHECK_CHNNL;
			end

			ACCUM_LFT_MID:	begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 1;
				mult4 = 0;
				saturate = 0;

				dst2accum_complt = 1;	//need to verify

				nxt_state = CHECK_CHNNL;
			end

			ACCUM_LFT_OUT:	begin
				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 0;
				mult4 = 1;
				saturate = 1;

				dst2error_complt = 1;//need to verify
	
				nxt_state = CHECK_CHNNL;	
			end

			// need to verify, might not need this state
			CHECK_CHNNL:	if(chnnl_counter < 6) begin
					enable_timer = 1;	//enable the timer
					//enable PWM to selected IR sensor pair. Need to verify
					//As long as go is asserted, sensor pair selection is enabled?

					nxt_state = WAIT4096;
				end else if(chnnl_counter == 6) begin
					//start doing calculation in ALU
					enable_timer = 0;
					dst2error_complt = 1;

					nxt_state = INTEGRAL;
				end

			INTEGRAL:	begin
				dst2intgrl_complt = &int_dec;
				enable_int_dec = 1;
				enable_Icomp_timer = 1;

				src1sel = ALU_SEL_ERROR_RHT_SHFT_FOUR;
				src0sel = ALU_SEL_INTGRL;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 1;


				nxt_state = ICOMP;
			end

			ICOMP:	begin
				if(Icomp_timer != 0) begin
					enable_Icomp_timer = 1;

					src1sel = ALU_SEL_ITERM;
					src0sel = ALU_SEL_INTGRL;
					multiply = 1;
					sub = 0;
					mult2 = 0;
					mult4 = 0;
					saturate = 1;

					dst2icomp_complt = 0;

					nxt_state = ICOMP;
				end else begin 
					enable_Icomp_timer = 1;

					src1sel = ALU_SEL_ITERM;
					src0sel = ALU_SEL_INTGRL;
					multiply = 1;
					sub = 0;
					mult2 = 0;
					mult4 = 0;
					saturate = 1;

					dst2icomp_complt = 1;

					nxt_state = PCOMP;
				end
			end

			PCOMP:
				if(Icomp_timer != 0) begin
					enable_Icomp_timer = 1;

					src1sel = ALU_SEL_ERROR_SIGN_EXTND;
					src0sel = ALU_SEL_PTERM;
					multiply = 1;
					sub = 0;
					mult2 = 0;
					mult4 = 0;
					saturate = 0;

					dst2pcomp_complt = 0;

					nxt_state = PCOMP;
				end else begin 
					enable_Icomp_timer = 0;

					//src1sel = ALU_SEL_ITERM;
					//src0sel = ALU_SEL_INTGRL;
					src1sel = ALU_SEL_ERROR_SIGN_EXTND;
					src0sel = ALU_SEL_PTERM;
					multiply = 1;
					sub = 0;
					mult2 = 0;
					mult4 = 0;
					//saturate =1;
					saturate =0;

					dst2pcomp_complt = 1;

					nxt_state = ACCUMCALC;
				end

			ACCUMCALC: begin
				dst2accum_complt = 1;

				src1sel = ALU_SEL_FWD;
				src0sel = ALU_SEL_PCOMP;
				multiply =0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;

				nxt_state = RHT_REG;
			end

			RHT_REG:	begin
				dst2rht_reg_complt = 1;

				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_ICOMP;
				multiply =0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 1;

				nxt_state = ACCUMCALC2;

			end

			ACCUMCALC2:	begin
				dst2accum_complt = 1;

				src1sel = ALU_SEL_FWD;
				src0sel = ALU_SEL_PCOMP;
				multiply =0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;

				nxt_state = LFT_REG;
			end

			LFT_REG: begin
				dst2lft_reg_complt = 1;

				src1sel = ALU_SEL_ACCUM;
				src0sel = ALU_SEL_ICOMP;
				multiply =0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 1;

				nxt_state = IDLE;
			end

			default:	begin 
				nxt_state = IDLE;
			end
				

		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_Icomp_timer
		if(~rst_n) begin
			Icomp_timer <= 0;
		end else if(enable_Icomp_timer == 1) begin
			Icomp_timer <= Icomp_timer + 1;
		end else begin
			Icomp_timer <= 0;
		end
	end

	PWM8 PWM8_enable_IR(/*autoport*/
//output
			.PWM_sig(PWM_output8),
//input
			.duty(PWM_duty_cycle),
			.clk(clk),
			.rst_n(rst_n));

	assign PWM_duty_cycle = 8'h8C;

	/* enable IR sensor pairs with chnnl_counter counter as selection, see the backside of FSM */
	assign {IR_in_en, IR_mid_en, IR_out_en} =
	//	/* outer pair is selected */
		(chnnl_counter[2:1] == 2'b10)?	{2'b00, go&PWM_output8}:
		/* middle pair is selected */
		(chnnl_counter[2:1] == 2'b01)?	{1'b0, go&PWM_output8, 1'b0}:
		/* inner pair is selected */
		(chnnl_counter[2:1] == 2'b00)?	{go&PWM_output8, 2'b00}:
		3'b000; 

	/* assign chnnl based on the chnnl_counter. chnnl is the same as ADC channel addr.
	   refer to spec p18 */
	assign chnnl = 
		(chnnl_counter == 0)?	3'b001:
		(chnnl_counter == 1)?	3'b000:
		(chnnl_counter == 2)?	3'b100:
		(chnnl_counter == 3)?	3'b010:
		(chnnl_counter == 4)?	3'b011:
		3'b111;
	

	/* timer */
	always_ff @(posedge clk or negedge rst_n) begin : proc_timer
		if(~rst_n) begin
			timer <= 0;
		end else if(clr_timer == 1) begin
			timer <= 0;
		end else if(enable_timer == 1) begin
			timer <= timer + 1;
		end else begin
			timer <= timer;
		end
	end

	/* channel */
	always_ff @(posedge clk or negedge rst_n) begin : proc_chnnl_counter
		if(~rst_n) begin
			chnnl_counter <= 0;
		end else if(clr_chnnl_counter == 1) begin
			chnnl_counter <= 0;
		end else if({clr_chnnl_counter,incr_chnnl_counter} == 2'b01) begin
			chnnl_counter <= chnnl_counter + 1;
		end else begin
			chnnl_counter <= chnnl_counter;
		end
	end

	/* instantiate ALU to do all the calculations */
	ALU iALU(/*autoport*/
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

	/* All ALU input flip flops */
	assign Pterm = 14'h37e0;
	assign Iterm = 12'h380;

	/*	flip flop store value of Accum */
	always_ff @(posedge clk or negedge rst_n) begin : proc_dst2accum
		if(~rst_n) begin
			Accum <= 0;
		end else if(clr_chnnl_counter) begin
			Accum <= 0;
		end else if(dst2accum_complt) begin
			Accum <= dst;
		end else begin
			Accum <= Accum;
		end
	end	

	/* Pcomp flip flop*/
	always_ff @(posedge clk or negedge rst_n) begin : proc_Pcomp
		if(~rst_n) begin
			Pcomp <= 0;
		end else if(dst2pcomp_complt) begin
			Pcomp <= dst;
		end else begin
			Pcomp <= Pcomp;
		end
	end

	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			Fwd<= 12'h000;
		else if(~go)// if go deassertedFwdknocked down so
			Fwd<= 12'b000;// we accelerate from zero on next start.
		else if (dst2intgrl_complt & (~&Fwd[10:8])) // 43.75% full speed
			Fwd<= Fwd+ 1'b1;// only write back 1 of 4 calccycles

	always_ff @(posedge clk or negedge rst_n) begin : proc_A2d_res
		if(~rst_n) begin
			A2d_res <= 0;
		end else if(cnv_cmplt) begin
			A2d_res <= res;
		end else begin
			A2d_res <= A2d_res;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_Error
		if(~rst_n) begin
			Error <= 0;
		end else if(dst2error_complt) begin
			Error <=dst;
		end else begin
			Error <= Error;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_Intgrl
		if(~rst_n) begin
			Intgrl <= 0;
		end else if(dst2intgrl_complt) begin
			Intgrl <= dst;
		end else begin
			Intgrl <= Intgrl;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_Icomp
		if(~rst_n) begin
			Icomp <= 0;
		end else if(dst2icomp_complt) begin
			Icomp <= dst;
		end else begin
			Icomp <= Icomp;
		end
	end

	/* timer for intgrl */
	always_ff @(posedge clk or negedge rst_n) begin : proc_int_dec
		if(~rst_n) begin
			int_dec <= 0;
		end else if(enable_int_dec == 1) begin
			int_dec <= int_dec + 1;
		end else begin
			int_dec <= int_dec;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_rht_reg
		if(~rst_n) begin
			rht_reg <= 0;
		end else if(!go) begin
			rht_reg <= 0;
		end else if(dst2rht_reg_complt) begin
			rht_reg <= dst[11:0];
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_lft_reg
		if(~rst_n) begin
			lft_reg <= 0;
		end else if(!go) begin
			lft_reg <= 0;
		end else if(dst2lft_reg_complt) begin
			lft_reg <= dst[11:0];
		end
	end

	assign rht = rht_reg[11:1];
	assign lft = lft_reg[11:1];

endmodule