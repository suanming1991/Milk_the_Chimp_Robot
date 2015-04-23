//==================================================================================================
//  Filename      : IR_SENSOR_PI_MATH.sv
//  Created On    : 2015-04-22 14:54:29
//  Last Modified : 2015-04-23 00:19:22
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

	input clk,rst_n;			// 50MHz clock and active low asynch reset
	input go;	//go command from cmd processing state machine
	input cnv_cmplt;	// indicates A2D conversion is ready

	logic [15:0] Accum;
	logic [2:0] chnnl;	//channel counter for IR sensor pairing
	logic enable_timer;	//enable timer to run
	logic [12:0] timer;	//timer to keep track of time
	logic initiate_Accum_calc; //tell ALU addition of Accum
	logic incr_chnnl;	//set to increment chnnl counter
	logic clr_timer;	//set to clear the timer
	logic Accum_right_select; //tell ALU the operation of right IR reading
	logic Accum_left_select;	//tell ALU the operation of left IR reading
	logic clr_chnnl;	//set to clr_chnnl

	logic PWM_output;	//need to instantiate PWM8 module, this is the output
	logic [7:0] PWM_duty_cycle;	//PWM duty cycle. Set to be a constant 0x8C

	typedef enum reg [3:0] {IDLE,B,C,D,E,F,INTEGRAL,ICOMP,PCOMP,ACCUM,RHT_REG,ACCUM2,LFT_REG} state_t;
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
		incr_chnnl = 0;
		strt_cnv = 0;
		Accum_right_select = 0;
		Accum_left_select = 0;
		clr_timer = 0;
		clr_chnnl = 0;

		nxt_state = IDLE;

		case (state)
			IDLE:	if(go) begin
						incr_chnnl = 0;
						clr_chnnl = 1;
						Accum = 0;
						clr_timer = 0;	//need to verify
						enable_timer = 1;
						//enable PWM to selected IR sensor pair

						nxt_state = B;

					end else begin 
						incr_chnnl = 0;
						clr_chnnl = 0;
						Accum = 0;
						enable_timer = 0;

						nxt_state = IDLE;
					end

			B:	if(timer < 4096) begin
					enable_timer = 1;
					clr_chnnl = 0;

					nxt_state = B;
				end else if(timer == 4096) begin
					strt_cnv = 1;	//need to verify that
					clr_chnnl = 0; 
					enable_timer = 0;

					nxt_state = C;
				end
	
			C:	if(cnv_cmplt == 0) begin
					strt_cnv = 0;	//strt_cnv is knocked down right away. Verify that it triggers the conversion
					
					nxt_state = C;
				end else begin
					strt_cnv = 0; 
					Accum_right_select = 1;
					incr_chnnl = 1;	//increment chnnl counter
					clr_timer = 1;	//set clear timer signal
					enable_timer = 1;	//enable the timer

					nxt_state = D;
				end

			D:	if(timer < 32) begin
					enable_timer = 1;
					Accum_right_select = 0; //need to verify
					incr_chnnl = 0;

					nxt_state = D;
				end else if(timer == 322) begin
					enable_timer = 1;
					strt_cnv = 1;	//need to verify
					Accum_right_select = 0;
					incr_chnnl = 0;

					nxt_state = E;
				end

			E: if(cnv_cmplt == 0) begin
					strt_cnv = 0;

					nxt_state = E;
				end else begin 
					strt_cnv = 0;
					Accum_left_select = 1;
					incr_chnnl = 1;	//increment chnnl counter
					clr_timer = 1;	//set clear timer signal


					nxt_state = F;
				end

			F:	if(chnnl < 6) begin
					enable_timer = 1;	//enable the timer
					//enable PWM to selected IR sensor pair. Need to verify

					nxt_state = B;
				end else if(chnnl == 6) begin
					//start doing calculation in ALU



					nxt_state = IDLE;
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

	/* enable IR sensor pairs with chnnl counter as selection, see the backside of FSM */
	assign {IR_in_en, IR_mid_en, IR_out_en} =
		/* outer pair is selected */
		(chnnl[2:1] == 2'b10)?	{2'b00, go&PWM_output}:
		/* middle pair is selected */
		(chnnl[2:1] == 2'b01)?	{1'b0, go&PWM_output, 1'b0}:
		/* inner pair is selected */
		(chnnl[2:1] == 2'b00)?	{go&PWM_output, 2'b00}:
		3'b000;
	
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
	always_ff @(posedge clk or negedge rst_n) begin : proc_chnnl
		if(~rst_n) begin
			chnnl <= 0;
		end else if(clr_chnnl == 1) begin
			chnnl <= 0;
		end else if({clr_chnnl,incr_chnnl} == 2'b01) begin
			chnnl <= chnnl + 1;
		end else begin
			chnnl <= chnnl;
		end
	end

endmodule