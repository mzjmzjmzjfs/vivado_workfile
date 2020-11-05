`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/11 19:31:01
// Design Name: 
// Module Name: top
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


module top_wm8731_fir(
    //input sys_clk,sys_rst
    input                           clk_100m,
    input                           rst_n,
    //input from wm8731
    input                           ADCLRC,
    input                           BCLK,
    input                           ADCDAT,
    //output to wm8731
    output                          I2C_SCLK,
    inout                           I2C_SDAT,  
    //input from logmel_
    input     [15:0]                addr_rd,                    //输出数据的地址
    input                           sound_data_ram_choose,      //ram_输出口使能控制信号
    //output to logmel_
    output   wire        [15:0]    sound_data_out_1,
    output   wire        [15:0]    sound_data_out_2,
    output   wire                  pl_ram_1_full,
    output   wire                  pl_ram_2_full,
    //input from ps_
    input                           sd_carry_done,
    //output from ps_
    output   wire                   we_wr1,we_wr2,
    output   wire        [15:0]     addr_wr,
    output   wire                   ps_ram_1_full,ps_ram_2_full,
    output   wire        [15:0]     fir_dout_out
    
     );
    //_____________________________________I2C_config_table__________________________________
    //WM8731寄存器配置信息
    wire [3:0]  LUT_INDEX;
    wire [23:0] LUT_DATA;
    wire [3:0]  LUT_SIZE;
    I2C_WM8731_Config u_I2C_WM8731_Config(
	.LUT_INDEX(LUT_INDEX),
	.LUT_DATA(LUT_DATA),
	.LUT_SIZE(LUT_SIZE)
	);
	//______________________________________I2C_CONTROL______________________________________
    wire config_done;
    wire bir_en_test;
    //I2C时序控制 
    i2c_timing_ctrl u_i2c_timing_ctrl(
	.clk(clk_100m),		            //100MHz
	.rst_n(rst_n),		            //system reset
	//i2c interface
	.i2c_sclk(I2C_SCLK),	        //i2c clock
	.i2c_sdat(I2C_SDAT),	        //i2c data for bidirection
	//user interface
	.i2c_config_size(LUT_SIZE),	    //i2c config data counte
	.i2c_config_index(LUT_INDEX),	//i2c config reg index, read 2 reg and write xx reg
	.i2c_config_data(LUT_DATA),	    //i2c config data
	.i2c_config_done(config_done)
	);
	//______________________________________ADC_READ______________________________________
    wire [15:0] adc_data;
    wire [15:0] adc_data_fix;
    wire adc_data_vld;
    //ADC采集数据输出，100M采12M
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
    //直流分量修正
    assign adc_data_fix = (adc_data[15] == 1'b1) ? adc_data[15:0] +  16'b0000_0010_1101_1010 : adc_data[15:0] +  16'b0000_0010_1101_1010;
    //________________________________________fir__________________________________________
    wire fir_din_vld;
    wire fir_din_last;
    wire fir_din_tready;
    //FIR_控制模块
    Fir_Ctrl u_Fir_Ctrl(
    .clk_100m(clk_100m),                  //FPGA系统时钟--100Mhz
    .rst_n(rst_n),
    .fir_din_tready(fir_din_tready),
    .fir_din_vld(fir_din_vld),
    .fir_din_last(fir_din_last));
    //_____________________________________fir_dec2_________________________________________
    wire        fir_dout_last;
    wire        fir_dout_last_out;
    wire        fir_dout_vld;
    wire [33:0] fir_dout;
    //FIR_44.1khz降采样至22.050khz
    fir_dec2 U_fir_dec2
    (
        .aclk                 (clk_100m),
        .aresetn              (rst_n),
        .s_axis_data_tready   (fir_din_tready),
        .s_axis_data_tvalid   (fir_din_vld),
        .s_axis_data_tlast    (fir_din_last),     
        .s_axis_data_tdata    (adc_data_fix),
        
        .m_axis_data_tvalid   (fir_dout_vld),
        .m_axis_data_tlast    (fir_dout_last),   
        .m_axis_data_tdata    (fir_dout)
    );
    assign fir_dout_out =  fir_dout[31:16];                                     //FIR输出数据
    assign fir_dout_last_out = fir_dout_last && fir_dout_vld;                   //保证last信号持续1个clk
    //________________________________pingpong_ram_ctrl________________________________
    wire                 en_wr1,en_wr2;                //使能信号不输出
    //宽度16bit，深度35500ram核例化
    pingpong_ram u_pingpong_ram(
    .clk_100m(clk_100m),                               //100Mhz
    .rst_n(rst_n),                                          
    .fir_dout_vld(fir_dout_vld),                       //FIR输出数据有效信号
    .fir_dout_last(fir_dout_last_out),           
    //output to logmel_
    .pl_ram_1_full(pl_ram_1_full),
    .pl_ram_2_full(pl_ram_2_full),
    //pingpong_ram_wr_ctrl
    .we_wr1(we_wr1),
    .we_wr2(we_wr2),
    .en_wr1(en_wr1),
    .en_wr2(en_wr2),
    .addr_wr(addr_wr),
    //ps_ram_ctrl
    .sd_carry_done(sd_carry_done),
    .ps_ram_1_full(ps_ram_1_full),
    .ps_ram_2_full(ps_ram_2_full)     
    );
    //_________________________________RAM_________________________________________
    wire signed [15:0] sound_data_out_1_reg;
    wire signed [15:0] sound_data_out_2_reg;
    assign sound_data_out_1 = ~sound_data_ram_choose ? sound_data_out_1_reg : 16'd0;
    assign sound_data_out_2 =  sound_data_ram_choose ? sound_data_out_2_reg : 16'd0;
    bram_35500 ram_1 (
    .clka(clk_100m),    // input wire clka
    .ena(en_wr1),      // input wire ena
    .wea(we_wr1),      // input wire [0 : 0] wea
    .addra(addr_wr),  // input wire [15 : 0] addra
    .dina(fir_dout_out),    // input wire [15 : 0] dina
    .clkb(clk_100m),    // input wire clkb
    .enb(~sound_data_ram_choose),      // input wire enb
    .addrb(addr_rd),  // input wire [15 : 0] addrb
    .doutb(sound_data_out_1_reg)  // output wire [15 : 0] doutb     
    );
    bram_35500 ram_2 (
    .clka(clk_100m),    // input wire clka
    .ena(en_wr2),      // input wire ena
    .wea(we_wr2),      // input wire [0 : 0] wea
    .addra(addr_wr),  // input wire [15 : 0] addra
    .dina(fir_dout_out),    // input wire [15 : 0] dina
    .clkb(clk_100m),    // input wire clkb
    .enb(sound_data_ram_choose),      // input wire enb
    .addrb(addr_rd),  // input wire [15 : 0] addrb
    .doutb(sound_data_out_2_reg)  // output wire [15 : 0] doutb
    );
    //_________________________________ILA__________________________________________
    ila_0 your_instance_name (
	.clk(clk_100m), // input wire clk

	.probe0(pl_ram_1_full), // input wire [0:0]  probe0  
	.probe1(pl_ram_2_full), // input wire [0:0]  probe1 
	.probe2(fir_din_tready), // input wire [0:0]  probe2 
	.probe3(fir_din_vld), // input wire [0:0]  probe3 
	.probe4(fir_dout_last), // input wire [0:0]  probe4 
	.probe5(fir_din_last), // input wire [0:0]  probe5 
	.probe6(en_wr1), // input wire [0:0]  probe6 
	.probe7(en_wr2), // input wire [0:0]  probe7 
	.probe8(ps_ram_1_full), // input wire [0:0]  probe8 
	.probe9(ps_ram_2_full), // input wire [0:0]  probe9 
	.probe10(sound_data_out_1), // input wire [15:0]  probe10 
	.probe11(sound_data_out_2), // input wire [15:0]  probe11 
	.probe12(addr_wr), // input wire [15:0]  probe12 
	.probe13(fir_dout_out), // input wire [15:0]  probe13 
	.probe14(adc_data), // input wire [15:0]  probe14 
	.probe15(adc_data_vld), // input wire [0:0]  probe15 
	.probe16(fir_dout_vld) // input wire [0:0]  probe16
);  
endmodule
