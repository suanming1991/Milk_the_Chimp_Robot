module motion_cntrl_tb ();
	reg clk, rst_n;
    wire cnv_cmplt;
    reg go;
    wire [11:0]A2D_res;


    wire [2:0]chnnl;
    wire strt_cnv;
    wire IR_in_en, IR_mid_en, IR_out_en;
    wire a2d_SS_n, SCLK, MISO, MOSI;
    wire [10:0]lft;
    wire [10:0]rht;

    //wire rev_rht, rev_lft, fwd_rht, fwd_lft;


	/*motion_cntrl imotion_contrl (.IR_in_en(IR_in_en), .IR_mid_en(IR_mid_en), .IR_out_en(IR_out_en), .strt_cnv(strt_cnv), 
		        .lft(lft), .rht(rht), .chnnl(chnnl), .clk(clk), .rst_n(rst_n), .go(go), .cnv_cmplt(cnv_cmplt), .res(A2D_res));
    */
    motion_cntrl imotion_contrl(/*autoport*/
//output
            .IR_in_en(IR_in_en),
            .IR_mid_en(IR_mid_en),
            .IR_out_en(IR_out_en),
            .strt_cnv(strt_cnv),
            .lft(lft),
            .rht(rht),
            .chnnl(chnnl),
//input
            .clk(clk),
            .rst_n(rst_n),
            .go(go),
            .cnv_cmplt(cnv_cmplt),
            .res(A2D_res));

    motor_cntrl iMTR(.clk(clk), .rst_n(rst_n), .lft(lft), .rht(rht), .fwd_lft(fwd_lft),
                   .rev_lft(rev_lft), .fwd_rht(fwd_rht), .rev_rht(rev_rht));

    A2D_intf iA2D(.clk(clk),.rst_n(rst_n),.strt_cnv(strt_cnv),.cnv_cmplt(cnv_cmplt),.chnnl(chnnl),
                .res(A2D_res),.a2d_SS_n(a2d_SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));

    ADC128S ADC128C_iDUT(.clk(clk),.rst_n(rst_n),.SS_n(a2d_SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

    //integer i;
    /* set red_flag if the output has a mismatch compared to expected output */
    //integer red_flag;

    //reg [63:0] mem[0:60][2:0];


    initial begin
        //$readmemh("ALU_stim.hex", mem_stim);

    	clk = 0;
        rst_n = 0;
        go = 0;
        red_flag = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
        go = 1;
        if(chnnl == 3'b111) begin
            $display("shit, I wanna see result");
        end

    end

    always
        #1 clk = ~clk;

endmodule
