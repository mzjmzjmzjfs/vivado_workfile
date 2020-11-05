`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/02 21:41:48
// Design Name: 
// Module Name: ADC_read
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


module ADC_read(
    input ADCLRC,
    input BCLK,
    input ADCDAT,
    input config_done,
    input rst_n,

    output wire [15:0] out_adc_data_out,
    output wire out_adc_data_valid

    );
    
    
    reg [2:0] config_done_d;
    always @ (posedge BCLK or negedge rst_n)
        if (!rst_n)
        begin
            config_done_d <= 3'b0;//异步时钟 打两拍
        end
        else
        begin
            config_done_d <= {config_done_d[1:0], config_done};
        end
    /////////////////////////read_adc_dspmode///////////////////////////////////////////
    reg [4:0]  num;
    reg        rd_state;
	reg        rd_end;
	reg        rd_end_flag;
	
    always@(posedge BCLK or negedge rst_n)
	begin
	   if(!rst_n)
	   begin
          rd_state <= 1'b0;
          rd_end <= 1'b0;
	   end
	   else if(ADCLRC == 1 && config_done_d[2] == 1'b1)
	   begin
	       rd_state <= 1;
	   end
	   else if (num == 0)
	   begin
	       rd_state <= 0;
	       rd_end <= 1;
	   end
	   else if(rd_end_flag == 1)
	   begin
	       rd_end <= 0;
	   end
	end
	
	always @(negedge BCLK or negedge rst_n)
    begin
        if (!rst_n)
        begin
            num <= 5'd31;
        end
        else if(rd_state == 1 && ADCLRC != 1)
        begin
            num <= num - 1;
        end
        else if(num == 0)
        begin
            num <= 5'd31;
        end
    end
	
	reg [31:0]data;
	always@(posedge BCLK or negedge rst_n)
		begin
			if(!rst_n)
				begin
				    data <= 32'b0;
				end
			else if(rd_state == 1 && ADCLRC != 1)
				begin
					data[ num ] <= ADCDAT;
                end
            else
            begin
                data <= data;
            end
		end
	
	reg [15:0] out_adc_data;
	assign out_adc_data_out = out_adc_data;
	assign out_adc_data_valid = rd_end_flag;
	always @(negedge BCLK or negedge rst_n)
    begin
        if (!rst_n)
        begin
            out_adc_data <= 16'b0;
            rd_end_flag <= 0;
        end
        else if (rd_end == 1)
        begin
            out_adc_data <= data[31:16];
            rd_end_flag <= 1;
        end
        else
        begin
            rd_end_flag <= 0;
        end
    end 
endmodule
