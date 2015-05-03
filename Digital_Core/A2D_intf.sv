//==================================================================================================
//  Filename      : A2D_intf.sv
//  Created On    : 2015-04-10 10:49:27
//  Last Modified : 2015-04-24 13:25:27
//  Revision      : 
//  Author        : milk_the_chimp, by Hua Shao, Shiyi Zhou, Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================

// SCLK waits 32 clock cycles

module A2D_intf (/*autoport*/
	//output
	cnv_cmplt,
	res,
	a2d_SS_n,
	SCLK,
	MOSI,
	//input
	clk,
	rst_n,
	strt_cnv,
	MISO,
	chnnl);

	output logic cnv_cmplt;
	output logic [11:0] res;
	output logic a2d_SS_n;
	output logic SCLK;
	output logic MOSI;

	input clk,rst_n;
	input strt_cnv;
	input MISO;
	input [2:0] chnnl;

	logic load;	//if set, initialize the data and reset all counters
	logic transmitting;	//if in TRANS state, tells the system to keep transmitting
	/* bit_cnt might be too big */
	logic [6:0] bit_cnt;	//count if 16 bits are shifted
	/* baud_cnt might be too big */
	logic [8:0] baud_cnt;	//count for clock cycle
	logic [15:0] shft_reg;	//shift register
	logic shift;	//baud_cnt control when one bit should be shifted
	logic strt_waiting;	//wait half cycle to make transmitting at negedge of SCLK
	logic still_waiting_post; //wait SCLK to complete before a2d_SS_n
	logic second_cycle;

	typedef enum reg [2:0] {IDLE,WAIT,TRANS,RELOAD,FINISH} state_t;
	state_t state, nxt_state;		// declare state and nxt_state signals

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin : proc_state_machine
		a2d_SS_n = 1;
		cnv_cmplt = 1;
		transmitting = 0;
		load = 0;
		strt_waiting = 0;
		still_waiting_post = 0;
		second_cycle = 0;

		nxt_state = IDLE;

		case (state)
		
			IDLE:	if(strt_cnv) begin
				a2d_SS_n = 0;
				cnv_cmplt = 0;
				load = 1;
				strt_waiting = 1;

				nxt_state = WAIT;
			end else begin 

				nxt_state = IDLE;
			end

			WAIT:	if(baud_cnt < 32) begin
				strt_waiting = 1;
				load = 0;
				transmitting = 1;
				cnv_cmplt = 0;
				a2d_SS_n = 0;

				nxt_state = WAIT;
			end else if (baud_cnt == 32) begin
				load = 1;
				transmitting = 1;
				strt_waiting = 0;
				cnv_cmplt = 0;
				a2d_SS_n = 0;

				nxt_state = TRANS;
			end


			TRANS:	if(bit_cnt < 16) begin
				cnv_cmplt = 0;
				a2d_SS_n = 0;
				transmitting = 1;
				load = 0;

				nxt_state = TRANS;
			end else if(bit_cnt == 16) begin
				cnv_cmplt = 0;
				a2d_SS_n = 0;
				load = 1;
				transmitting = 1;
				still_waiting_post = 0;
				second_cycle = 1;

				nxt_state = RELOAD;
			end

			RELOAD:	if(bit_cnt < 16) begin
				cnv_cmplt = 0;
				a2d_SS_n = 0;
				load = 0;
				transmitting = 1;
				still_waiting_post = 0;
				second_cycle = 1;

				nxt_state = RELOAD;
			end else if(bit_cnt == 16) begin
				cnv_cmplt = 0;
				a2d_SS_n = 0;
				load = 0;
				transmitting = 1;
				still_waiting_post = 1;
				second_cycle = 0;

				nxt_state = FINISH;
			end

			FINISH:	if(baud_cnt < 32) begin
				a2d_SS_n = 0;
				cnv_cmplt = 0;
				load = 0;
				transmitting = 1;
				still_waiting_post = 1;

				nxt_state = FINISH;
			end else if(baud_cnt == 32) begin
				a2d_SS_n = 1;
				cnv_cmplt = 1;
				load = 0;
				transmitting = 0;
				still_waiting_post = 0;

				nxt_state = IDLE;
			end

			default : nxt_state = IDLE;
		endcase
	
	end

	/* baud_cnt aims to count 32 clock cycles for SCLK*/
	always_ff @(posedge clk or negedge rst_n) begin : proc_baud_cnt
		if(~rst_n) begin
			baud_cnt <= 0;
		end else if(strt_waiting == 1 && baud_cnt == 32) begin
			baud_cnt <= 0;
		end else if(load == 1 || baud_cnt == 64 || (cnv_cmplt == 1 && still_waiting_post == 0)) begin	//baut_cnt == 32 before
			baud_cnt <= 0;
		end else if({load,transmitting} == 2'b01) begin 
			baud_cnt <= baud_cnt + 1;
		end else begin
			baud_cnt <= baud_cnt;
		end
	end

	assign shift = 
		(baud_cnt == 64)	?	1:
		0;


	always_ff @(posedge clk or negedge rst_n) begin : proc_SCLK
		if(~rst_n) begin
			SCLK <= 1;
		end else if (cnv_cmplt == 1 && still_waiting_post == 0) begin 
			SCLK <= 1;
		end else if(baud_cnt == 32 || baud_cnt == 64) begin	//baut_cnt == 32 only
			SCLK <= ~SCLK;
		end else begin
			SCLK <= SCLK;
		end
	end


	always_ff @(posedge clk or negedge rst_n) begin : proc_bit_cnt
		if(~rst_n) begin
			bit_cnt <= 0;
		end else if(load == 1) begin
			bit_cnt <= 0;
		end else if({load,shift} == 2'b01) begin
			bit_cnt <= bit_cnt + 1;
		end else begin 
			bit_cnt <= bit_cnt;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_shft_reg
		if(~rst_n) begin
			shft_reg <= 0;
		end else if(load == 1) begin
			shft_reg <= {2'b00,chnnl,11'b000};
		end else if({load,shift} == 2'b01) begin
			shft_reg <= {shft_reg[14:0],MISO};
		end else begin
			shft_reg <= shft_reg;
		end
	end

	assign MOSI = shft_reg[15];
	assign res = ~shft_reg[11:0];

endmodule