//==================================================================================================
//  Filename      : FSM_CM.sv
//  Created On    : 2015-04-22 12:10:58
//  Last Modified : 2015-04-22 16:24:42
//  Revision      : 
//  Author        : milk_the_chimp, by Hua Shao, Shiyi Zhou, Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : szhou69@wisc.edu
//  Description   : 
//
//
//==================================================================================================
module FSM_CM (
	//output
	clr_cmd_rdy, 
	clr_ID_vld, 
	buzz, buzz_n, 
	go,   
	in_transit, 
	//input
	clk, rst_n, 
	cmd,   
	cmd_rdy,
	ID,  
	ID_vld,	
	OK2Move  
);
  output clr_ID_vld; // used to knock down ID_vld once station ID digested
  output clr_cmd_rdy; // used to knock down cmd_rdy signal after command processed
  output buzz,buzz_n; // optional piezo buzzer
  output logic go;	// Go signal to motion controller
  output logic in_transit; // forms enable to proximity sensor
  
  input clk,rst_n; // 50MHz clock and active low asynch reset
  input ID_vld; // indicates ID value from BC unit is valid
  input [7:0] ID; // station ID from BC unit
  input cmd_rdy;  // indicates command from BLE112 is ready
  input [7:0] cmd; // command from BLE112
  input OK2Move; // input from proximity sensor

  logic [5:0]dest_ID;  //from UART, cmd[5:0]
  logic [7:0] ID_reg;   //register use to store the value of ID read from BC unit
  logic set_in_transit; //if is 1, set the in_transit flop, if is 0, clear the in_transit flop
  logic capture_ID;  //if is 1, reload the ID into ID_reg
  logic en; //use for buzz???

typedef enum reg [2:0] {IDLE,Second,Third,Fourth,Fifth,Sixth} state_t;
	state_t state, nxt_state; // declare state and nxt_state signals


always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;


always_comb begin : FSM_CM
		//initial all value
        clr_ID_vld=0;
        clr_cmd_rdy=0;
        set_in_transit=0;
        capture_ID=0;

		nxt_state = IDLE;

		case (state)
		
			IDLE:	if(cmd_rdy && cmd[7:6]==2'b01) begin
				clr_cmd_rdy=1;
				//set in_transit flop
				set_in_transit = 1;
                 
				//Capture ID 
                 capture_ID = 1;

				nxt_state = Second;
			end else begin 

				nxt_state = IDLE;
			end

			Second:	if(cmd_rdy) begin
				clr_cmd_rdy=1;

				nxt_state = Sixth;
			end else begin

				nxt_state = Third;
			end


			Third:	if(ID_vld) begin
				clr_ID_vld=1;

				nxt_state = Fourth;
			end else begin
				
				nxt_state = Second;
			end

			Fourth:	if(ID_reg[5:0] == dest_ID) begin
			
			    //clr in_transit flop
                set_in_transit = 0;

				nxt_state = IDLE;
			end else begin

				nxt_state = Second;
			end

			Fifth:	if(cmd[7:6]==2'b00/*stop command*/) begin
				
				nxt_state = IDLE;
			end else begin
				
				nxt_state = Third;
			end

			Sixth:	if(cmd[7:6]==2'b01) begin
				
                 //set in_transit
                 set_in_transit = 1; 
                 //capture ID
                 capture_ID = 1; 

				nxt_state = Sixth;
			end else begin
				
				nxt_state = Fifth;
			end

			default : nxt_state = IDLE;
		endcase
	
	end


always_ff @(posedge clk or negedge rst_n) begin : in_transit_ff
		if(~rst_n) begin
			in_transit <= 0;
		end else if(set_in_transit) begin
			in_transit <= 1;
		end else if(~set_in_transit) begin
			in_transit <= 0;
		end else begin
			in_transit <= in_transit;
		end
	end


always_ff @(posedge clk or negedge rst_n) begin : ID_ff
		if(~rst_n) begin
			ID_reg <= 0;
		end else if(capture_ID) begin
			ID_reg <= ID;
		end else begin
			ID_reg <= ID_reg;
		end
	end

assign dest_ID = cmd[5:0];

assign go =OK2Move & in_transit;
assign en = ~OK2Move & in_transit;

//buzz output, buzz_n output how??




endmodule
