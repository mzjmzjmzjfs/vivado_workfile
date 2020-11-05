`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/23 23:02:37
// Design Name: 
// Module Name: adc_read_v2
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


module adc_read_v2(
    input 				clk_100m,
    input 				ADCLRC,
    input 				BCLK,
    input 				ADCDAT,
    input 				config_done,
    input 				rst_n,

    output wire [15:0] adc_data,
    output wire 		adc_data_vld
    );
	//___________________________________config_done_____________________________________
    reg 		[2:0] 	config_done_d;
    always @ (posedge BCLK or negedge rst_n)
        if (!rst_n)
        begin
            config_done_d <= 3'b0;
        end
        else
        begin
            config_done_d <= {config_done_d[1:0], config_done};
        end
	//______________________________________BCLK_____________________________________
	wire 				BCLK_pos;
	wire               BCLK_neg;
	reg 		[2:0] 	BCLK_reg;
	assign BCLK_pos =  ~BCLK_reg[2] && BCLK_reg[1];
	assign BCLK_neg =   BCLK_reg[2] && ~BCLK_reg[1];
	
	always @ (posedge clk_100m or negedge rst_n)
	begin
		if (!rst_n) BCLK_reg <= 3'b0;
		else 		BCLK_reg <= {BCLK_reg[1:0],BCLK};
	end
	//____________________________________
	reg                 rd_flag;
	reg 		[5:0]	data_cnt;
	always @ (posedge clk_100m or negedge rst_n)
    begin
        if (!rst_n) 														rd_flag <= 1'b0;
       	else if (BCLK_pos == 1'b1 && ADCLRC == 1'b1 && config_done_d[2])	rd_flag <= 1'b1;
        else if (data_cnt == 1'b0 && BCLK_pos)								rd_flag <= 1'b0;
       	else 																rd_flag <= rd_flag;
    end
    //______________________________________data_cnt_____________________________________
    always @ (posedge clk_100m or negedge rst_n)
    begin
    	if (!rst_n) 														data_cnt <= 6'd32;
    	else if (rd_flag == 1'b1 && BCLK_neg && ADCLRC != 1'b1)				data_cnt <= data_cnt - 1'b1;
    	else if (data_cnt == 1'b0 && BCLK_neg)								data_cnt <= 6'd32;
    	else  																data_cnt <= data_cnt;
    end
    //_______________________________________ADCDAT______________________________________
    reg 		[31:0]	data_reg;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if (!rst_n) 														data_reg <= 31'b0;
        else if (BCLK_pos == 1'b1 && rd_flag == 1'b1 && ADCLRC != 1'b1)		data_reg[data_cnt] <= ADCDAT;
        else 																data_reg <= data_reg;
    end
    //_______________________________________valid_______________________________________
    //在cnt为0时，过三个时钟周期后，给valid
    reg 		[6:0] 	data_vld_reg;
    assign adc_data_vld = ~data_vld_reg[6] && data_vld_reg[5];
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if (!rst_n)	 				                        data_vld_reg <= 3'b0;
        else if (data_cnt == 6'd32 ) 	                    data_vld_reg <= {data_vld_reg[5:0],1'b1};
        else 						                        data_vld_reg <= 3'b0;
    end
    //_______________________________________data_______________________________________
    reg         [15:0]  adc_data_reg;
    assign adc_data = adc_data_reg;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if (!rst_n)	 				                            adc_data_reg <= 16'b0;
        else if (data_cnt == 6'd32 && data_vld_reg[0] == 1'b1) 	adc_data_reg <= data_reg[31:16];
        else 						                            adc_data_reg <= adc_data_reg;
    end
 	
endmodule
