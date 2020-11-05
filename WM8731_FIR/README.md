声音分类预处理代码
======
#### 声音分类预处理模块图
![PRE_PROCESS](https://gitee.com/meng_zi_jie/image-bed/raw/master/img/PRE_PROCESS.png)


简介
----
* 预处理模块完成配置WM8731，adc数据串并转换，降采样滤波并存入乒乓RAM等功能。


TOP_MODULE例化
----
```verilog
top_wm8731_fir u_top_wm8731(
    //input sys_clk,sys_rst
    .clk_100m(clk_100m),
    .rst_n(rst_n),
    //input from wm8731
    .ADCLRC(ADCLRC),
    .BCLK(BCLK),
    .ADCDAT(ADCDAT),
    //output to wm8731
    .I2C_SCLK(I2C_SCLK),
    .I2C_SDAT(I2C_SDAT),  
    //input from logmel_
    .addr_rd(addr_rd),                    
    .sound_data_ram_choose(sound_data_ram_choose),      
    //output to logmel_
    .sound_data_out_1(sound_data_out_1),
    .sound_data_out_2(sound_data_out_2),
    .pl_ram_1_full(pl_ram_1_full),
    .pl_ram_2_full(pl_ram_2_full),
    //input from ps_
    .sd_carry_done(sd_carry_done),
    //output from ps_
    .we_wr1(we_wr1),
    .we_wr2(we_wr2),
    .addr_wr(addr_wr),
    .ps_ram_1_full(ps_ram_1_full),
    .ps_ram_2_full(ps_ram_2_full),
    .fir_dout_out(fir_dout_out)
     );
```
----
PRE_PROCESS
----
### 1.1 IIC_CTRL 
* iic_ctrl部分包括时序控制部分和配置寄存器表部分。
* 程序初开始执行时会延迟1ms时间等待软件或者硬件初始化。
* 100M时钟分频为100KHZ（IIC要求100KHZ~400KHZ）
* 硬件地址通过parameter定义
* 寄存器数目，及寄存器配置bit数又parameter定义
* 使用同步复位
* 两根信号线，IIC_SDAT和IIC_SCLK

### 1.2 IIC_CTRL例化 
```verilog
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
	.i2c_config_done(config_done));


I2C_WM8731_Config u_I2C_WM8731_Config(
	.LUT_INDEX(LUT_INDEX),
	.LUT_DATA(LUT_DATA),
	.LUT_SIZE(LUT_SIZE));
```
----
### 2.1 ADC_READ 
* 工作时钟100Mhz，采集BCLK上升沿作为有效信号。
* BCLK为12Mhz时钟信号，WM8731模块晶振提供。
* ADCLRC为ADCDAT的有效信号，高有效，持续时间为BCLK一个时钟周期。
* ADCLRC拉高后，在BCLK上升沿，连续采集32个1bit数据，前16bit为左声道，后16bit为右声道。
* 输出16bit数据、有效信号和配置完成信号。
### 2.2 ADC_READ例化 
```verilog
adc_read_v2 u_adc_read_v2(
    .clk_100m(clk_100m),
    .ADCLRC(ADCLRC),
    .BCLK(BCLK),
    .ADCDAT(ADCDAT),
    .config_done(config_done),
    .rst_n(rst_n),

    .adc_data(adc_data),
    .adc_data_vld(adc_data_vld));
```
----
### 3.1 FIR 
* FIR模块包含FIR_CTRL和FIR部分。
* 1.61s的音频采样点为1.61*44100=71000。
* 只有在TREADY为高时才能输入数据。
* 数据速率约为44.1KHZ，主时钟100MHZ，所以每2267个100MHZ时钟周期采集一次数据，共采71000个。
* 输出数据速率为22.05KHZ，每35500个数据给以last信号。
### 3.2 FIR例化 
```verilog
Fir_Ctrl u_Fir_Ctrl(
    .clk_100m(clk_100m),                  
    .rst_n(rst_n),
    .fir_din_tready(fir_din_tready),
    .fir_din_vld(fir_din_vld),
    .fir_din_last(fir_din_last));

fir_dec2 U_fir_dec2(
	.aclk                 (clk_100m),
	.aresetn              (rst_n),
	.s_axis_data_tready   (fir_din_tready),
	.s_axis_data_tvalid   (fir_din_vld),
	.s_axis_data_tlast    (fir_din_last),     
	.s_axis_data_tdata    (adc_data_fix),

	.m_axis_data_tvalid   (fir_dout_vld),
	.m_axis_data_tlast    (fir_dout_last),   
	.m_axis_data_tdata    (fir_dout));
```
----
### 4.1 PINGPONG_RAM 
* PINGPONG_RAM模块包含PINGPONGRAM_CTRL和RAM部分。
* dir_dout_valid信号为输入使能信号，fir_dout_last信号为切换ram的标志信号。
* 写满ram之后，输出BUF_FULL信号给LOGMEL模块，持续3个100MHZ时钟周期。
* 写满ram之后，输出BUF_FULL信号给PS，直至PS端返回sd_carry_done信号则把BUF_FULL信号拉低。
### 4.2 PINGPONG_RAM例化 
```verilog
pingpong_ram u_pingpong_ram(
    .clk_100m(clk_100m),                               //100Mhz
    .rst_n(rst_n),                                          
    .fir_dout_vld(fir_dout_vld),                       
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
    .ps_ram_2_full(ps_ram_2_full));

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
```
----