module motion_cntrl_tb ();
	reg clk, rst_n;
    reg strt_cnv;
    reg [2:0]chnnl;
    reg go;

    wire cnv_cmplt;
    wire [11:0]A2D_res;
    wire IR_in_en, IR_mid_en, IR_out_en;
    wire rev_rht, rev_lft, fwd_rht, fwd_lft;
    wire a2d_SS_n, SCLK, MISO, MOSI;
    wire [10:0]lft;
    wire [10:0]rht;


	motion_cntrl imotion_contrl (.IR_in_en(IR_in_en), .IR_mid_en(IR_mid_en), .IR_out_en(IR_out_en), .strt_cnv(strt_cnv), 
		        .lft(lft), .rht(rht), .clk(clk), .rst_n(rst_n), .go(go), .cnv_cmplt(cnv_cmplt), .res(A2D_res));

    motor_cntrl iMTR(.clk(clk), .rst_n(rst_n), .lft(lft), .rht(rht), .fwd_lft(fwd_lft),
                   .rev_lft(rev_lft), .fwd_rht(fwd_rht), .rev_rht(rev_rht));

    A2D_intf iA2D(.clk(clk),.rst_n(rst_n),.strt_cnv(strt_cnv),.cnv_cmplt(cnv_cmplt),.chnnl(chnnl),
                .res(A2D_res),.a2d_SS_n(a2d_SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));

    ADC128S ADC128C_iDUT(.clk(clk),.rst_n(rst_n),.SS_n(a2d_SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

    initial begin
    	clk = 0;
        rst_n = 0;
        go = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
        go = 1;

        


    end

endmodule
