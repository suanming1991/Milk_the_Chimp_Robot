//==================================================================================================
//  Filename      : UART_tx.sv
//  Created On    : 2015-02-25 10:23:32
//  Last Modified : 2015-03-02 22:29:16
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : UW-Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module UART_tx (/*autoport*/
	//output
	TX,
	tx_done,
	//input
	trmt,
	clk,
	rst_n,
	tx_data);

	output logic TX;
	output logic tx_done;

	input trmt;
	input clk,rst_n;
	input [7:0]	tx_data;

	typedef enum reg { IDLE, TRANS } state_t;
	state_t state, nxt_state;		// declare state and nxt_state signals

	logic load;	//if set, initialize the data and reset all counters
	logic transmitting;	//if in TRANS state, tells the system to keep transmitting
	logic set_done;	//tell if transmission is completed
	logic shift;	//baud_cnt control when one bit should be shifted
	logic [11:0] baud_cnt;	//count for clock cycle
	logic [3:0] bit_cnt;	//count if 10 bits are shifted

	logic [9:0] tx_shft_reg;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin
		load = 0;
		transmitting = 0;
		set_done = 1;	//change to 1

		nxt_state = IDLE;

		case (state)
			IDLE:	if(trmt) begin
				load = 1;
				set_done = 0;
				nxt_state = TRANS;
			end else begin 
				load = 0;
				nxt_state = IDLE;
			end

			TRANS:	if(bit_cnt < 4'b1001) begin
				load = 0;
				set_done = 0;
				transmitting = 1;
				nxt_state = TRANS;
			end else if(bit_cnt == 4'b1001) begin
				load = 0;
				set_done = 1;
				transmitting = 0;
				nxt_state = IDLE;
			end

			default:	nxt_state = IDLE;
		endcase
	end

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n || load == 1) begin
			bit_cnt <= 0;
		end else if({load,shift} == 2'b01) begin
			bit_cnt <= bit_cnt + 1;
		end else begin
			bit_cnt <= bit_cnt;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n || load == 1 || baud_cnt == 12'hA2C) begin
			baud_cnt <= 0;
		end else if({load,transmitting} == 2'b01) begin
			baud_cnt <= baud_cnt + 1;
		end else begin 
			baud_cnt <= baud_cnt;
		end
	end

	assign shift = 
		(baud_cnt == 12'hA2C)	?	1:
		0;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n || set_done == 1) begin
			tx_shft_reg <= 10'b11_1111_1111;	//set to all 1's when at idle
		end else if(load == 1) begin
			tx_shft_reg <= {1'b1,tx_data,1'b0};
		end else if({load,shift} == 2'b01) begin
			tx_shft_reg <= (tx_shft_reg >> 1);
		end else begin
			tx_shft_reg <= tx_shft_reg;
		end
	end


	assign TX = tx_shft_reg[0];

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			tx_done <= 0;
		end else begin
			tx_done <= set_done;
		end
	end

endmodule