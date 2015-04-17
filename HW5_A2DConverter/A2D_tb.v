//==================================================================================================
//  Filename      : A2D_tb.v
//  Created On    : 2015-04-12 20:45:40
//  Last Modified : 2015-04-14 22:52:29
//  Revision      : 
//  Author        : milk_the_chimp, by Hua Shao, Shiyi Zhou, Zexi Liu
//  Company       : ECE Department, University of Wisconsin–Madison
//  Email         : zliu79@wisc.edu
//
//  Description   : 
//
//
//==================================================================================================
module A2D_tb();

reg clk, rst_n;
reg strt_cnv;
reg [2:0]chnnl;
wire cnv_cmplt;
wire [11:0]res;

ADC128S ADC128C_iDUT(.clk(clk),.rst_n(rst_n),.SS_n(a2d_SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

A2D_intf A2D_intf_iDUT(.cnv_cmplt(cnv_cmplt),.res(res),.a2d_SS_n(a2d_SS_n),.SCLK(SCLK),.MOSI(MOSI),.clk(clk),.rst_n(rst_n),.strt_cnv(strt_cnv),.MISO(MISO),.chnnl(chnnl));
	

always
#1 clk <= ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    strt_cnv = 0;
    chnnl = 3'b101;
 
    @(negedge clk);
       rst_n = 1;
    @(posedge clk);
    repeat (8) @(negedge clk);
       strt_cnv = 1;
    @(negedge clk);
       strt_cnv = 0;
    @(posedge cnv_cmplt);
        $display("check");
        chnnl = 3'b001;
	  repeat (10) @(negedge clk);
      strt_cnv = 1;
    @(negedge clk);
       strt_cnv = 0;
    @(posedge cnv_cmplt);
        $display("check");
$stop;
end

endmodule