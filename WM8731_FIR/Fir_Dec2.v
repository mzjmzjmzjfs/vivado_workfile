`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/10 11:32:06
// Design Name: 
// Module Name: Fir_Dec2
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


module Fir_Ctrl(
    input           clk_100m,                  //FPGA系统时钟--100Mhz
    input           rst_n,
    //input from fir
    input           fir_din_tready,
    //output to fir
    output          fir_din_vld,
    output          fir_din_last
);
   
    parameter         INPUT_DATA_RATE = 12'd2267;       //2267个100mhz时钟周期送一个数据
    parameter         INPUT_DATA_NUM  = 18'd7100;      //71000个数据给一个last

    //__________________________________clk_cnt_______________________________________
    reg [12:0] clk_cnt;
    always@(posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                       clk_cnt <= 12'b0;
        else if (fir_din_tready == 1'b1)
        begin
            if(clk_cnt == (INPUT_DATA_RATE - 1))         clk_cnt <= 12'b0;
            else                                         clk_cnt <= clk_cnt + 1'b1;
        end 
        else                                             clk_cnt <= 12'b0;
    end
    //_____________________________________valid_______________________________________
    //100MHZ → 2267clk → 44.111khz
    reg       fir_din_vld_reg;
    always@(posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                                               fir_din_vld_reg <= 1'b0;
        else if (clk_cnt == (INPUT_DATA_RATE - 1) && fir_din_tready == 1'b1)     fir_din_vld_reg <= 1'b1;
        else                                                                     fir_din_vld_reg <= 1'b0;
    end
    
    //_____________________________________valid_cnt_______________________________________
    //44100 * 2267 =  99 974 700
    //1.61 * 44100 ≈ 71000   44100hz采样率输入1.61s的声音片段
    //2^18 = 131 072
    reg [17:0] clk_valid_cnt;
    always@(posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                          clk_valid_cnt <= 1'b0;
        else if(clk_valid_cnt == (INPUT_DATA_NUM - 1))      clk_valid_cnt <= 1'b0;
        else if(fir_din_vld == 1'b1)                        clk_valid_cnt <= clk_valid_cnt + 1'b1;
        else                                                clk_valid_cnt <= clk_valid_cnt;
    end
    //_____________________________________last____________________________________________
    reg fir_din_last_reg;
    always@(posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                                                                                          fir_din_last_reg <= 1'b0;
        else if (clk_valid_cnt == (INPUT_DATA_NUM - 2) && clk_cnt == (INPUT_DATA_RATE - 1) && fir_din_tready == 1'b1)       fir_din_last_reg <= 1'b1;
        else                                                                                                                fir_din_last_reg <= 1'b0;
    end
    //_____________________________________last____________________________________________
    assign fir_din_vld = fir_din_vld_reg;
    assign fir_din_last = fir_din_last_reg;
    
endmodule
