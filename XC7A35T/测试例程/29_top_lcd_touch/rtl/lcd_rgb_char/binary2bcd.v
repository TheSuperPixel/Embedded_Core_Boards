//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           binary2bcd
// Created by:          正点原子
// Created date:        2023年2月3日14:17:02
// Version:             V1.0
// Descriptions:        binary2bcd
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module binary2bcd(
    input   wire             sys_clk,
    input   wire             sys_rst_n,
    input   wire    [15:0]   data,
    
    output  reg     [15:0]   bcd_data       //数字的位数
);
//parameter define
parameter   CNT_SHIFT_NUM = 5'd16;  //由data的位宽决定
//reg define
reg [4:0]       cnt_shift;         //移位判断计数器
reg [31:0]      data_shift;        //移位判断数据寄存器，由data和bcddata的位宽之和决定。
reg             shift_flag;        //移位判断标志信号

//*****************************************************
//**                    main code                      
//*****************************************************

//cnt_shift计数
always@(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        cnt_shift <= 5'd0;
    else if((cnt_shift == CNT_SHIFT_NUM + 5'd1) && (shift_flag))
        cnt_shift <= 5'd0;
    else if(shift_flag)
        cnt_shift <= cnt_shift + 5'b1;
    else
        cnt_shift <= cnt_shift;
end

//data_shift 计数器为0时赋初值，计数器为1~CNT_SHIFT_NUM时进行移位操作
always@(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        data_shift <= 32'd0;
    else if(cnt_shift == 5'd0)
        data_shift <= {16'b0,data};
    else if((cnt_shift <= CNT_SHIFT_NUM) && (!shift_flag))begin
        data_shift[19:16] <= (data_shift[19:16] > 4) ? (data_shift[19:16] + 2'd3):(data_shift[19:16]);
        data_shift[23:20] <= (data_shift[23:20] > 4) ? (data_shift[23:20] + 2'd3):(data_shift[23:20]);
        data_shift[27:24] <= (data_shift[27:24] > 4) ? (data_shift[27:24] + 2'd3):(data_shift[27:24]);
        data_shift[31:28] <= (data_shift[31:28] > 4) ? (data_shift[31:28] + 2'd3):(data_shift[31:28]);
        end
    else if((cnt_shift <= CNT_SHIFT_NUM) && (shift_flag))
        data_shift <= data_shift << 1;
    else
        data_shift <= data_shift;
end

//shift_flag 移位判断标志信号，用于控制移位判断的先后顺序
always@(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        shift_flag <= 1'b0;
    else
        shift_flag <= ~shift_flag;
end

//当计数器等于CNT_SHIFT_NUM时，移位判断操作完成，整体输出
always@(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        bcd_data <= 16'd0;
    else if(cnt_shift == CNT_SHIFT_NUM + 5'b1)
        bcd_data <= data_shift[31:16];
    else
        bcd_data <= bcd_data;
end

endmodule
