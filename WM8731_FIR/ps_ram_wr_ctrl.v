`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/22 14:41:58
// Design Name: 
// Module Name: ps_ram_wr_ctrl
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


module ps_ram_wr_ctrl(
    input               clk_100m,                  //100m
    input               rst_n,
    //input from fir
    input               fir_dout_vld,            //FIRÊä³öÊý¾ÝÓÐÐ§ÐÅºÅ
    input               fir_dout_last,           
    // input from ps
    input               sd_carry_done,
    //output to ps_ram
    output wire         we_wr1_out,we_wr2_out,
    output wire         en_wr1_out,en_wr2_out,
    output wire [15:0]  addr_wr_out,
    output wire         ram_1_full_out,ram_2_full_out   
    );
    //__________________________________________________________________________________
    reg [15:0] addr_wr;
    reg we_wr1,we_wr2;
    reg en_wr1,en_wr2;
    assign we_wr1_out = we_wr1;
    assign we_wr2_out = we_wr2;
    assign en_wr1_out =en_wr1;
    assign en_wr2_out = en_wr2;
    assign addr_wr_out = addr_wr;
    //_________________________________wr_contol_________________________________________
    //en¿ÚÈ¥µô
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)
        begin                       
            en_wr1 <= 1'b1;we_wr1 <= 1'b1;
            en_wr2 <= 1'b0;we_wr2 <= 1'b0;
        end
        else if (fir_dout_last == 1'b1) 
        begin
            en_wr1 <= ~en_wr1; we_wr1 <= ~we_wr1;
            en_wr2 <= ~en_wr2; we_wr2 <= ~we_wr2;
        end
        else
        begin
            en_wr1 <= en_wr1; we_wr1 <= we_wr1;
            en_wr2 <= en_wr2; we_wr2 <= we_wr2;
        end                           
    end
    //_________________________________wr_addr_______________________________________
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                              addr_wr = 16'b0;
        else if (fir_dout_last == 1'b1)         addr_wr <= 1'b0;
        else if (fir_dout_vld == 1'b1)          
        begin
            if (addr_wr == 35499)               addr_wr <= 1'b0;
            else                                addr_wr <= addr_wr + 1'b1;
        end
        else                                    addr_wr <= addr_wr;
    end
    //________________________________ȡready�ź�������__________________________________________
    reg [1:0] sd_carry_done_flag;
    wire sd_carry_done_pos;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)  sd_carry_done_flag <= 2'b0;
        else        sd_carry_done_flag <= {sd_carry_done_flag[0],sd_carry_done};
    end
    assign sd_carry_done_pos = sd_carry_done_flag[0] && ~sd_carry_done_flag[1];
    //________________________________BUF_FULL__________________________________________
    reg       full;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                 full <= 1'b0;
        else if (fir_dout_last == 1'b1)            full <= 1'b1;
        else                                       full <= full;
    end
    assign ram_1_full_out = full && en_wr2 &&  ~sd_carry_done_pos;
    assign ram_2_full_out = full && en_wr1 &&  ~sd_carry_done_pos;
endmodule
