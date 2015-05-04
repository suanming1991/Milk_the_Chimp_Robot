//==================================================================================================
//  Filename      : UART_rx.sv
//  Created On    : 2015-03-01 21:10:48
//  Last Modified : 2015-04-27 10:55:20
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : University of Wisconsin-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module UART_rx (/*autoport*/
	//output
	rdy,
	cmd,
	//input
	clk,
	rst_n,
	RX,
	clr_rdy);

	output logic rdy;
	output logic [7:0] cmd;

	input clk,rst_n;
	input RX;
	input clr_rdy;

	logic load;
	logic receiving;
	logic shift;
	logic [11:0] baud_cnt;
	logic [3:0] bit_cnt; //count if it's 8 bits

	/* variables that are not seen in UART_tx.sv*/
	logic baud_id;	//check if it's counting half cycle or full. set if it's checking half
	logic idle_state; //corresponds to set_done except it's 1 when idle


	typedef enum reg [1:0] {IDLE,IDENTIFY,RECEIV} state_t;
	state_t state, nxt_state;


	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin
		load = 0;
		receiving = 0;
		idle_state =0;
		baud_id = 0;

		nxt_state = IDLE;

		case (state)
			IDLE:	if(RX == 0) begin
				idle_state = 0;
				load = 1;
				baud_id = 1;
				nxt_state = IDENTIFY;
			end else begin 
				load = 0;
				idle_state = 0;
				nxt_state = IDLE;
			end

			IDENTIFY:	if(baud_cnt < 1302) begin
				load = 0;
				baud_id = 1;
				receiving = 1; //need to verify
				idle_state = 0;
				nxt_state = IDENTIFY;
			end else if(baud_cnt == 1302) begin 
				load = 0;
				baud_id = 1;
				receiving = 1; //need to verify
				idle_state = 0;
				nxt_state = RECEIV;
			end

			RECEIV:	if(bit_cnt < 9) begin
				baud_id = 0;
				idle_state = 0;
				receiving = 1;
				load = 0;
				nxt_state = RECEIV;
			end else if(bit_cnt == 9) begin
				baud_id = 0;
				idle_state = 1;
				receiving = 0;
				nxt_state = IDLE;
			end

			default :	nxt_state = IDLE;
		endcase
	end


	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			bit_cnt <= 0;
		end else if (load == 1) begin 
			bit_cnt <= 0;
		end else if({load,shift} == 2'b01) begin
			bit_cnt <= bit_cnt + 1;
		end else begin
			bit_cnt <= bit_cnt;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n || (baud_cnt == 1302 && baud_id == 1)) begin
			baud_cnt <= 0;
		end else if(load == 1 || baud_cnt == 12'hA2C) begin
			baud_cnt <= 0;
		end else if({load,receiving} == 2'b01) begin
			baud_cnt <= baud_cnt + 1;
		end else begin 
			baud_cnt <= baud_cnt;
		end
	end

	assign shift =
		(baud_id == 0 && baud_cnt == 12'hA2C)	?	1:
		0;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			cmd <= 0;
		end else if(load == 1) begin
			cmd <= 8'b0000_0000;
		end else if({load,shift} == 2'b01 && (bit_cnt < 8)) begin
			cmd <= ((cmd >> 1) | {RX,7'b000_0000});
		end else begin
			cmd <= cmd;
		end
	end

	
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n || clr_rdy == 1) begin
			rdy <= 0;
		end else if (idle_state)begin
			rdy <= 1;
		end else begin
			rdy <= rdy;
		end
	end

endmodule