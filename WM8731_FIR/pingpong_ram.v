`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/12 16:25:58
// Design Name: 
// Module Name: pingpong_ram
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
//////////////////////////////////////////////////////////////////////////////////
module pingpong_ram(
    input                   clk_100m,                  //100Mhz,FIR输出数据的频率是2Mhz
    input                   rst_n,
    //input from fir     
    input                   fir_dout_vld,              //FIR输出数据有效信号
    input                   fir_dout_last,           
    //output to logmel_
    output    wire          pl_ram_1_full,
    output    wire          pl_ram_2_full,
    //pingpong_ram_ctrl
    output    wire          we_wr1,we_wr2,
    output    wire          en_wr1,en_wr2,
    output    [15:0]         addr_wr,
    // input from ps
    input                   sd_carry_done,
    // input from ps
    output    wire          ps_ram_1_full,
    output    wire          ps_ram_2_full
    );
    reg [15:0] addr_wr_reg;
    reg we_wr1_reg,we_wr2_reg;
    reg en_wr1_reg,en_wr2_reg;
    assign we_wr1 = we_wr1_reg;
    assign we_wr2 = we_wr2_reg;
    assign en_wr1 = en_wr1_reg;
    assign en_wr2 = en_wr2_reg;
    assign addr_wr = addr_wr_reg;
    //_________________________________wr_contol_________________________________________
    //en口不用去掉，不输出
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)
        begin                       
            en_wr1_reg <= 1'b1;we_wr1_reg <= 1'b1;
            en_wr2_reg <= 1'b0;we_wr2_reg <= 1'b0;
        end
        else if (fir_dout_last == 1'b1) 
        begin
            en_wr1_reg <= ~en_wr1_reg; we_wr1_reg <= ~we_wr1_reg;
            en_wr2_reg <= ~en_wr2_reg; we_wr2_reg <= ~we_wr2_reg;
        end
        else
        begin
            en_wr1_reg <= en_wr1_reg; we_wr1_reg <= we_wr1_reg;
            en_wr2_reg <= en_wr2_reg; we_wr2_reg <= we_wr2_reg;
        end                           
    end
    //_________________________________wr_addr_______________________________________
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                              addr_wr_reg = 16'b0;
        else if (fir_dout_last == 1'b1)         addr_wr_reg <= 1'b0;
        else if (fir_dout_vld == 1'b1)          
        begin
            if (addr_wr_reg == 35499)           addr_wr_reg <= 1'b0;
            else                                addr_wr_reg <= addr_wr_reg + 1'b1;
        end
        else                                    addr_wr_reg <= addr_wr_reg;
    end
    //_______________________________________PL_BUF_FULL______________________________
    reg       PL_full;
    reg [3:0] full_cnt;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n) 
        begin
            PL_full <= 1'b0;
            full_cnt  <= 2'b0;
        end
        else if (fir_dout_last == 1'b1)
        begin
            PL_full <= 1'b1;
            full_cnt  <= 2'b0;
        end
        else if (PL_full == 1'b1)
        begin
            if(full_cnt == 10)
            begin
                PL_full <= 1'b0;
                full_cnt  <= 1'b0;
            end
            else
            begin
                PL_full <= PL_full;
                full_cnt  <= full_cnt + 1'b1;
            end
        end
        else
        begin
            PL_full <= PL_full;
            full_cnt  <= full_cnt ;
        end
    end
    assign pl_ram_1_full = PL_full && en_wr2;
    assign pl_ram_2_full = PL_full && en_wr1;
    //____________________________________________PS_BUF_FULL____________________________________
    //________________________________取ready信号上升沿__________________________________________
    reg [1:0] sd_carry_done_flag;
    wire sd_carry_done_pos;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)  sd_carry_done_flag <= 2'b0;
        else        sd_carry_done_flag <= {sd_carry_done_flag[0],sd_carry_done};
    end
    assign sd_carry_done_pos = sd_carry_done_flag[0] && ~sd_carry_done_flag[1];
    //________________________________BUF_FULL___________________________________________________
    reg       PS_full;
    always @ (posedge clk_100m or negedge rst_n)
    begin
        if(!rst_n)                                 PS_full <= 1'b0;
        else if (fir_dout_last == 1'b1)            PS_full <= 1'b1;
        else if (sd_carry_done_pos == 1'b1)        PS_full <= 1'b0;
        else                                       PS_full <= PS_full;
    end
    //保证full信号只在写另一个ram写使能期间持续
    assign ps_ram_1_full = PS_full && en_wr2;
    assign ps_ram_2_full = PS_full && en_wr1;
endmodule
