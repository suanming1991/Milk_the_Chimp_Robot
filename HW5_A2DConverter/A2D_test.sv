module A2D_test(clk,RST_n,nxt_chnnl,LEDs,a2d_SS_n,MOSI,MISO,SCLK);

	input clk,RST_n;		// 50MHz clock and active low unsynchronized reset from push button
	input nxt_chnnl;		// unsynchronized push button.  Advances to convert next chnnl
	output [7:0] LEDs;		// upper bits of conversion displayed on LEDs
	output a2d_SS_n;		// Active low slave select to A2D (part of SPI bus)
	output MOSI;			// Master Out Slave In to A2D (part of SPI bus)
	input MISO;				// Master In Slave Out from A2D (part of SPI bus)
	output SCLK;			// Serial clock of SPI bus

	logic rst_n;
	logic q;
	logic button_rise_edge;
	logic nxt_chnnl1;
	logic nxt_chnnl2;
	logic nxt_chnnl3;
	logic [2:0] chnnl;
	logic strt_cnv;

///////////////////////////////////////////////////
// Declare any registers or wires you need here //
/////////////////////////////////////////////////
	wire [11:0] res;		// result of A2D conversion

/////////////////////////////////////
// Instantiate Reset synchronizer //
///////////////////////////////////
	reset_synch iRST(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

////////////////////////////////
// Instantiate A2D Interface //
//////////////////////////////
	A2D_intf iA2D(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .cnv_cmplt(), .chnnl(chnnl),
              .res(res), .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));


////////////////////////////////////////
// Synchronize nxt_chnnl push button //
//////////////////////////////////////
 

	always @(negedge rst_n or negedge clk)
	begin
			if(!rst_n) begin
			nxt_chnnl1 <= 1;
			nxt_chnnl2 <= 1;
			nxt_chnnl3 <= 1;
			//button_rise_edge = nxt_chnnl2 & ~nxt_chnnl3;
		end 
		else begin
			nxt_chnnl1 <= nxt_chnnl;
			nxt_chnnl2 <= nxt_chnnl1;
			nxt_chnnl3 <= nxt_chnnl2;
			//button_rise_edge = nxt_chnnl2 & ~nxt_chnnl3;
		end
	end

	assign button_rise_edge = nxt_chnnl2 & ~nxt_chnnl3;



///////////////////////////////////////////////////////////////////
// Implement method to increment channel and start a conversion //
// with every release of the nxt_chnnl push button.            //
////////////////////////////////////////////////////////////////
 always @(negedge rst_n or negedge clk) begin
	if(!rst_n) 
		strt_cnv <= 0;
	else if(button_rise_edge) begin
		
		if (chnnl < 6 )begin
   			chnnl <= chnnl +1;
   			strt_cnv <= 1;
		end
		else begin  
    		chnnl <=0;
			strt_cnv <= 0;
        end
	end
	else begin
        chnnl <= chnnl;
        strt_cnv <= 0;
	end
end 



	
	
assign LEDs = res[11:4];

endmodule
    
