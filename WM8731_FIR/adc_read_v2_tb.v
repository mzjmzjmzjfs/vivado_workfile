`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/23 23:53:22
// Design Name: 
// Module Name: adc_read_v2_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adc_read_v2_tb();
    reg 		clk_100m;
    reg 		ADCLRC;
    reg 		BCLK;
    reg 		ADCDAT;
    reg 		config_done;
    reg 		rst_n;

    wire [15:0] adc_data;
    wire 		adc_data_vld;
    initial
    begin
    	clk_100m = 1'b1;
		ADCLRC = 1'b0;
		BCLK = 1'b0;
		ADCDAT = 1'b0;
		config_done = 1'b1;
		rst_n = 1'b1;

		#20 rst_n = 1'b0;
		#20 rst_n =	1'b1;
    end
    //________________________________________clk_____________________
    always #5 		clk_100m = ~clk_100m;
    always #41.6 	BCLK = ~BCLK;
    always #41.6    ADCDAT = ~ADCDAT;
    //__________________________________________________________________
    adc_read_v2 u_adc_read_v2(
    .clk_100m(clk_100m),
    .ADCLRC(ADCLRC),
    .BCLK(BCLK),
    .ADCDAT(ADCDAT),
    .config_done(config_done),
    .rst_n(rst_n),

    .adc_data(adc_data),
    .adc_data_vld(adc_data_vld)
    );
    //________________________________________ADCLRC_____________________
    reg [9:0] ADCLRC_cnt;
    always @ (posedge BCLK or negedge rst_n)
    begin
        if(!rst_n) 				    ADCLRC_cnt = 9'b0;
        else if(ADCLRC_cnt == 271) 	ADCLRC_cnt = 9'b0;
        else 						ADCLRC_cnt = ADCLRC_cnt + 1'b1;
    end
    always @ (posedge BCLK or negedge rst_n)
    begin
        if(!rst_n) 				ADCLRC = 1'b0;
        else if (ADCLRC_cnt == 271) ADCLRC = 1'b1;
        else 						ADCLRC = 1'b0;
    end
endmodule
