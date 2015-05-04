//==================================================================================================
//  Filename      : barcode.sv
//  Created On    : 2015-03-18 14:14:57
//  Last Modified : 2015-04-27 11:19:36
//  Revision      : 
//  Author        : Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================

module barcode (/*autoport*/
	//output
	ID_vld,
	ID,
	//input
	BC,
	clk,
	rst_n,
	clr_ID_vld);

	output logic ID_vld;
	output logic [7:0] ID;

	input BC, clk, rst_n;
	input clr_ID_vld;

	logic Q1, Q2, Q3, Q4, BC_filtered;

	/* use 4 cascaded flip flops to filter BC signal*/
	always @(posedge clk) begin
		Q1 <= BC;
		Q2 <= Q1;
		Q3 <= Q2;
		Q4 <= Q3;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			BC_filtered <= 1;
		end else if(Q2 == 1 && Q3 == 1 && Q4 == 1) begin
			BC_filtered <= 1;
		end else if(Q2 == 0 && Q3 == 0 && Q4 ==0 ) begin
			BC_filtered <= 0;
		end else begin 
			BC_filtered <= BC_filtered;
		end
	end

	typedef enum reg [1:0] {IDLE,IDENTIFY,RECEIV} state_t;
	state_t state, nxt_state;

	logic load;	//initialize everything
	logic receiving;	//control the counters
	logic time_info_cnt;	//flag to start recording time info for the start bit
	logic [3:0] bit_cnt;	//count if there's eight bits received
	logic shift; //signal to make it shift
	logic [27:0] baud_cnt; //timer to count to time_reg once falling edge of BC is detected
	logic [27:0] time_reg; //store time info from start bit
	logic negedge_flag; //flat that detects the falling edge of BC
	logic pre_BC_edge; //internal signal of edge detector. see http://fpgacenter.com/examples/basic/edge_detector.php
	logic valid_flag; //output of state machine telling it's valid BC input, this value will be flopped to be ID_vld

	//logic finish_start_bit_flag;
	//logic keep_finish_start_bit;
	logic [22:0] time_reg_twice;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

	always_comb begin : proc_state_machine
		load = 0;
		receiving = 0;
		time_info_cnt = 0;
		valid_flag = 0;

		nxt_state = IDLE;

		case (state)
			IDLE:	if(BC_filtered == 0 && negedge_flag == 1) begin
				load = 1;
				time_info_cnt = 1;
				valid_flag = 0;

				nxt_state = IDENTIFY;
			end else begin 
				load = 0;
				time_info_cnt = 0;
				valid_flag = 0;

				nxt_state = IDLE;
			end

			IDENTIFY:	if(BC_filtered == 0) begin
				load = 0;
				receiving = 1;
				time_info_cnt = 1;
				valid_flag = 0;  
				nxt_state = IDENTIFY;
			end else begin 
				load = 0;
				time_info_cnt = 0;
				receiving = 1; //need to verify
				valid_flag = 0;   
				nxt_state = RECEIV;
			end

			RECEIV:		if(bit_cnt < 8) begin
				receiving = 1;
				valid_flag = 0;
				nxt_state = RECEIV;
			end else if(bit_cnt ==8) begin
				receiving = 0;
				if(ID[7:6] == 2'b00) begin
					valid_flag = 1;
				end
				nxt_state = IDLE;
			end

			/*RECEIV:		
			if(finish_start_bit_flag == 0) begin
				keep_finish_start_bit = 1;
			end else begin 
				if(bit_cnt < 8) begin
					receiving = 1;
					valid_flag = 0;
					nxt_state = RECEIV;
				end else if(bit_cnt == 8) begin
					receiving = 0;
					if(ID[7:6] == 2'b00) begin
						valid_flag = 1;
					end
					nxt_state = IDLE;
				end
			end */


			default : nxt_state = IDLE;
		endcase

	end

	/* flip flop to track bits received */
	always @(posedge clk or negedge rst_n) begin
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

	/* register to store time info from start bit */
	always_ff @(posedge clk or negedge rst_n) begin : proc_time_reg
		if(~rst_n) begin
			time_reg <= 0;
			time_reg_twice <= 0;
		end else if(load == 1) begin
			time_reg <= 0;
			time_reg_twice <= 0;
		end else if(time_info_cnt == 1) begin
			time_reg <= time_reg + 1;
			time_reg_twice <= time_reg_twice + 1;
		end else begin 
			time_reg <= time_reg;
			if(time_reg_twice < time_reg * 2) begin
				time_reg_twice <= time_reg_twice + 1;
			end else begin 
				time_reg_twice <= time_reg_twice;
			end
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : proc_baud_cnt
		if(~rst_n) begin
			baud_cnt <= 0;
		end else if(load == 1 || negedge_flag == 1) begin
			baud_cnt <= 0;
		end else if ({load,receiving} == 2'b01 && time_info_cnt == 0 && (time_reg_twice == time_reg * 2)) begin 
			baud_cnt <= baud_cnt + 1;
		end else begin
			baud_cnt <= baud_cnt;
		end
	end

	//added
	//assign finish_start_bit_flag = 

	assign shift =
		((time_info_cnt == 0) && (baud_cnt == time_reg) && (time_reg > 0))	?	1:
		0; 

	/* edge detector */
	always_ff @(posedge clk or negedge rst_n) begin : proc_pre_BC_edge
		if(~rst_n) begin
			pre_BC_edge <= 0;
		end else begin
			pre_BC_edge <= BC_filtered;
		end
	end

	assign negedge_flag = ~BC_filtered & pre_BC_edge;

	always_ff @(posedge clk or negedge rst_n) begin : proc_ID
		if(~rst_n) begin
			ID <= 8'b0000_0000;
		end else if (load == 1) begin 
			ID <= 8'b0000_0000;
		end else if ({load,shift} == 2'b01) begin 
			ID <= ((ID << 1) | {7'b000_0000, BC_filtered});
		end else begin
			ID <= ID;
		end
	end

	/* flip flop ID_vld */
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n || clr_ID_vld == 1) begin
			ID_vld <= 0;
		end else if (valid_flag)begin
			ID_vld <= 1;
		end else begin
			ID_vld <= ID_vld;
		end
	end

endmodule