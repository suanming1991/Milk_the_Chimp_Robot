//==================================================================================================
//  Filename      : IR_SENSOR_PI_MATH.sv
//  Created On    : 2015-04-22 14:54:29
//  Last Modified : 2015-04-27 11:20:09
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

module IR_SENSOR_PI_MATH (/*autoport*/
//output
			IR_in_en,
			IR_mid_en,
			IR_out_en,
			strt_cnv,
			lft,
			rht,
//input
			clk,
			rst_n,
			go,
			cnv_cmplt);

	output logic IR_in_en,IR_mid_en,IR_out_en;	// PWM based enables to various IR sensors
	output logic strt_cnv;						// used to initiate a Round Robing conversion on IR sensors
	output logic [10:0] lft,rht;				// 11-bit signed left and right motor controls
	output logic [2:0] chnnl;					// chnnl telling the addr of IR. Refer to p18 of spec

	input clk,rst_n;			// 50MHz clock and active low asynch reset
	input go;	//go command from cmd processing state machine
	input cnv_cmplt;	//indicates A2D conversion is ready
	input [11:0] res;	//IR readings from A2D conversion

	logic [15:0] Accum;
	logic [2:0] chnnl_counter;	//channel counter for IR sensor pairing
	logic enable_timer;	//enable timer to run
	logic [12:0] timer;	//timer to keep track of time
	logic initiate_Accum_calc; //tell ALU addition of Accum
	logic incr_chnnl_counter;	//set to increment chnnl_counter counter
	logic clr_timer;	//set to clear the timer
	logic Accum_right_select; //tell ALU the operation of right IR reading
	logic Accum_left_select;	//tell ALU the operation of left IR reading
	logic clr_chnnl_counter;	//set to clr_chnnl_counter
								//also I am going to use it to clear accum_ff for now

	logic PWM_output;	//need to instantiate PWM8 module, this is the output
	logic [7:0] PWM_duty_cycle;	//PWM duty cycle. Set to be a constant 0x8C

	logic [15:0] dst;	//should it be signed?
	logic [15:0] Pcomp; 	
	logic [13:0] Pterm;	//constant
	logic [11:0] Fwd,A2d_res, Error, Intgrl, Icomp, Iterm;
	logic [2:0] src1sel, src0sel; 
	logic multiply, mult2, mult4, sub, saturate;
	//Iterm is constant
	assign Pterm = 14’h3680;
	assign Iterm = 12’h500;

	logic [15:0] dst2accum;	//store dst so that it can be used to update next Accum 
	//logic load_dst_2_accum;	//set when dst is ready to load to Accum for next Accum update

	logic dst2accum_complt;	//assert to assign dst to Accum
	logic dst2intgrl_complt;//assert to assign dst to Intgrl
	logic dst2icomp_complt;//assert to assign dst to Icomp
	logic dst2pcomp_complt;//assert to assign dst to Pcom
	logic dst2rht_reg_complt;//assert to assign dst to rht_reg
	logic dst2lft_reg_complt;//assert to assign dst to lft_reg

	typedef enum reg [3:0] {IDLE,B,C,D,E,F,INTEGRAL,ICOMP,PCOMP,ACCUMCALC,RHT_REG,ACCUMCALC2,LFT_REG} state_t;
	state_t state, nxt_state;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin : proc_grande_state_machine
		//default values
		Accum = 0;
		enable_timer = 0;
		incr_chnnl_counter = 0;
		strt_cnv = 0;
		Accum_right_select = 0;
		Accum_left_select = 0;
		clr_timer = 0;
		clr_chnnl_counter = 0;

		nxt_state = IDLE;

		case (state)
			IDLE:	if(go) begin
						incr_chnnl_counter = 0;
						clr_chnnl_counter = 1;
						Accum = 0;
						clr_timer = 0;	//need to verify
						enable_timer = 1;
						//enable PWM to selected IR sensor pair

						nxt_state = B;

					end else begin 
						incr_chnnl_counter = 0;
						clr_chnnl_counter = 0;
						Accum = 0;
						enable_timer = 0;

						nxt_state = IDLE;
					end

			B:	if(timer < 4096) begin
					enable_timer = 1;
					clr_chnnl_counter = 0;

					nxt_state = B;
				end else if(timer == 4096) begin
					strt_cnv = 1;	//need to verify that
					clr_chnnl_counter = 0; 
					enable_timer = 0;

					nxt_state = C;
				end
	
			C:	if(cnv_cmplt == 0) begin
					strt_cnv = 0;	//strt_cnv is knocked down right away. Verify that it triggers the conversion
					
					nxt_state = C;
				end else begin
					strt_cnv = 0; 
					Accum_right_select = 1;
					incr_chnnl_counter = 1;	//increment chnnl_counter counter
					clr_timer = 1;	//set clear timer signal
					enable_timer = 1;	//enable the timer

					nxt_state = D;
				end

			D:	if(timer < 32) begin
					enable_timer = 1;
					Accum_right_select = 0; //need to verify
					incr_chnnl_counter = 0;
					/* store dst to Accum flip flop */
					dst2accum_complt = 1;

					nxt_state = D;
				end else if(timer == 32) begin
					enable_timer = 1;
					strt_cnv = 1;	//need to verify
					Accum_right_select = 0;
					incr_chnnl_counter = 0;
					/* do not update Accum flip flop */
					dst2accum_complt = 0;

					nxt_state = E;
				end

			E: if(cnv_cmplt == 0) begin
					strt_cnv = 0;

					nxt_state = E;
				end else begin 
					strt_cnv = 0;
					Accum_left_select = 1;
					incr_chnnl_counter = 1;	//increment chnnl_counter counter
					clr_timer = 1;	//set clear timer signal
					/* store dst to Accum flip flop */
					/* need to verify because I don't know if dst 
					calculation takes less than one clock cycle*/
					dst2accum_complt = 1;

					nxt_state = F;
				end

			F:	if(chnnl_counter < 6) begin
					enable_timer = 1;	//enable the timer
					//enable PWM to selected IR sensor pair. Need to verify
					//As long as go is asserted, sensor pair selection is enabled?

					nxt_state = B;
				end else if(chnnl_counter == 6) begin
					//start doing calculation in ALU



					nxt_state = INTEGRAL;
				end

				default:	nxt_state = IDLE;
		endcase
	end

	PWM8 PWM8_enable_IR(/*autoport*/
//output
			.PWM_sig(PWM_output),
//input
			.duty(PWM_duty_cycle),
			.clk(clk),
			.rst_n(rst_n));

	assign PWM_duty_cycle = 8'h8C;

	/* enable IR sensor pairs with chnnl_counter counter as selection, see the backside of FSM */
	assign {IR_in_en, IR_mid_en, IR_out_en} =
	//	/* outer pair is selected */
		(chnnl_counter[2:1] == 2'b10)?	{2'b00, go&PWM_output}:
		/* middle pair is selected */
		(chnnl_counter[2:1] == 2'b01)?	{1'b0, go&PWM_output, 1'b0}:
		/* inner pair is selected */
		(chnnl_counter[2:1] == 2'b00)?	{go&PWM_output, 2'b00}:
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

	/* sudo code for Error term calculation
		if (Accum_right_select == 1)
			if (chnnl_counter = 0)
				Accum = IR_in_rht
			else if (chnnl_counter = 1)
				Accum = Accum - IR_in_lft
			else if (chnnl_counter = 2)
				Accum = Accum + IR_mid_rht * 2
			else if (chnnl_counter = 3)
				Accum = Accum - IR_mid_lft * 2
			else if (chnnl_counter = 4)
				Accum = Accum + IR_out_rht * 4
			else if (chnnl_counter = 5)
				Error = Accum - IR_out_lft * 4
	*/

	/* src1sel select localparams */
	localparam ACCUM = 3'b000;
	localparam ITERM     = 3'b001;
	localparam ERROR_12_2_16     = 3'b010;
	localparam ERROR_8_2_16  = 3'b011;
	localparam FWD  = 3'b100;

	/* src0sel select localparams */
	localparam A2D_RES = 3'b000;
	localparam INTGRL     = 3'b001;
	localparam ICOMP     = 3'b010;
	localparam PCOMP  = 3'b011;
	localparam PTERM  = 3'b100;

	always_comb begin : proc_update_Accum	

		case (chnnl_counter)
			0	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;

			end

			1	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;

			end

			2	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
			end

			3	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
			end
			
			4	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
			end

			5	:	begin 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 1;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
			end

			default : 
				src1sel = ACCUM;
				src0sel = A2D_RES;
				multiply = 0;
				sub = 0;
				mult2 = 0;
				mult4 = 0;
				saturate = 0;
		endcase
	
	end

	/*	flip flop store value of Accum */
	always_ff @(posedge clk or negedge rst_n) begin : proc_dst2accum
		if(~rst_n) begin
			accum_ff <= 0;
		end else if(clr_chnnl_counter) begin
			accum_ff <= 0;
		end else if(dst2accum_complt) begin
			accum_ff <= dst;
		end else begin
			accum_ff <= accum_ff;
		end
	end



endmodule