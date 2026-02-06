//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           test_data
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3数据测试模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module test_data(
    input               clk_50m,
    input               rst_n,
    input               init_calib_complete  ,  //DDR3初始化完成
    input [15:0]        rd_data,
    
    output reg          rd_req,
    output reg [15:0]   wr_data,
    output reg          wr_en,
    output reg          error
    );

//parameter
//定义写入的数据最大值
parameter TEST_LENGTH = 12'd1024;

//reg define
reg [11:0] rd_cnt;
reg [11:0] rd_cnt_d0;
reg        wr_finish;
reg        init_done_d0; 
reg        init_done_d1;
reg        rd_valid;

//同步 ddr3 初始化完成信号
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0;
        init_done_d1 <= 1'b0;
    end
    else begin
        init_done_d0 <= init_calib_complete;
        init_done_d1 <= init_done_d0;
    end
end 

//同步数据来临
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        rd_cnt_d0 <= 1'b0;
    else 
        rd_cnt_d0 <= rd_cnt;
end

//写入数据完成后，读取读fifo数据，读使能
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n)
        rd_req <= 1'b0;
    else if(wr_finish)
        rd_req <= 1'b1;
    else
        rd_req <= rd_req;
end 

//写数据操作完成
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n) 
        wr_finish <= 1'b0;
    else if(wr_data >= TEST_LENGTH - 1'b1)//写数据完成
        wr_finish <= 1'b1;
    else 
        wr_finish <= wr_finish;
end 

//写fifo写使能，写入数据（1~1024）
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n) begin
        wr_data <= 16'd0;
        wr_en <= 1'b0;
    end
    else if((wr_data <= TEST_LENGTH - 1'b1) && init_done_d1 && !wr_finish)begin
        wr_data <= wr_data + 1'b1;//写入数据（1~1024）
        wr_en <= 1'b1;            //写fifo写使能
    end
    else begin
        wr_data <= 16'b0;
        wr_en <= 1'b0;
    end
end 

//对读操作进行计数
always @(posedge clk_50m or negedge rst_n) begin
    if(~rst_n)
        rd_cnt <= 1'b1;
    else if(rd_req)begin
        if(rd_cnt >= TEST_LENGTH )
            rd_cnt <= 1'b1;
        else 
            rd_cnt <= rd_cnt + 1'b1; 
    end
end  

//第一次读取的数据无效，后续读操作所读取的数据才有效
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n)
        rd_valid <= 1'b0;
    else if(rd_cnt_d0 == TEST_LENGTH)//等待第一次读操作结束
        rd_valid <= 1'b1;//后续读取的数据有效
    else
        rd_valid <= rd_valid;
end 

//读数据有效时,若读取数据错误,给出标志信号
always @(posedge clk_50m or negedge rst_n) begin
    if(~rst_n)
        error <= 1'b0; 
    else if(rd_valid)
        if(rd_cnt_d0 != rd_data )
            error <= 1'b1; 
        else
            error <= error;
    else 
        error <= error;
end  

endmodule