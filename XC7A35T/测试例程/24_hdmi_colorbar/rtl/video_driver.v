//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           video_driver
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        视频显示驱动模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module video_driver(
    input           	pixel_clk	,
    input           	sys_rst_n	,
		
    //RGB接口	
    output          	video_hs	,     //行同步信号
    output          	video_vs	,     //场同步信号
    output          	video_de	,     //数据使能
    output  	[23:0]  video_rgb	,    //RGB888颜色数据
    output	reg			data_req 	,
	
    input   	[23:0]  pixel_data	,   //像素点数据
    output  reg	[10:0]  pixel_xpos	,   //像素点横坐标
    output  reg	[10:0]  pixel_ypos    //像素点纵坐标
);

//parameter define

//1280*720 分辨率时序参数
parameter  H_SYNC   =  11'd40;   //行同步
parameter  H_BACK   =  11'd220;  //行显示后沿
parameter  H_DISP   =  11'd1280; //行有效数据
parameter  H_FRONT  =  11'd110;  //行显示前沿
parameter  H_TOTAL  =  11'd1650; //行扫描周期

parameter  V_SYNC   =  11'd5;    //场同步
parameter  V_BACK   =  11'd20;   //场显示后沿
parameter  V_DISP   =  11'd720;  //场有效数据
parameter  V_FRONT  =  11'd5;    //场显示前沿
parameter  V_TOTAL  =  11'd750;  //场扫描周期

//1920*1080分辨率时序参数
//parameter  H_SYNC   =  12'd44;   //行同步
//parameter  H_BACK   =  12'd148;  //行显示后沿
//parameter  H_DISP   =  12'd1920; //行有效数据
//parameter  H_FRONT  =  12'd88;  //行显示前沿
//parameter  H_TOTAL  =  12'd2200; //行扫描周期
//
//parameter  V_SYNC   =  12'd5;    //场同步
//parameter  V_BACK   =  12'd36;   //场显示后沿
//parameter  V_DISP   =  12'd1080;  //场有效数据
//parameter  V_FRONT  =  12'd4;    //场显示前沿
//parameter  V_TOTAL  =  12'd1125;  //场扫描周期

//reg define
reg  [11:0] cnt_h;
reg  [11:0] cnt_v;
reg       	video_en;

//*****************************************************
//**                    main code
//*****************************************************

assign video_de  = video_en;
assign video_hs  = ( cnt_h < H_SYNC ) ? 1'b0 : 1'b1;  //行同步信号赋值
assign video_vs  = ( cnt_v < V_SYNC ) ? 1'b0 : 1'b1;  //场同步信号赋值

//使能RGB数据输出
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		video_en <= 1'b0;
	else
		video_en <= data_req;
end

//RGB888数据输出
assign video_rgb = video_de ? pixel_data : 24'd0;

//请求像素点颜色数据输入
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		data_req <= 1'b0;
	else if(((cnt_h >= H_SYNC + H_BACK - 2'd2) && (cnt_h < H_SYNC + H_BACK + H_DISP - 2'd2))
                  && ((cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK+V_DISP)))
		data_req <= 1'b1;
	else
		data_req <= 1'b0;
end

//像素点x坐标
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_xpos <= 11'd0;
    else if(data_req)
        pixel_xpos <= cnt_h + 2'd2 - H_SYNC - H_BACK ;
    else 
        pixel_xpos <= 11'd0;
end
    
//像素点y坐标	
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_ypos <= 11'd0;
    else if((cnt_v >= (V_SYNC + V_BACK)) && (cnt_v < (V_SYNC + V_BACK + V_DISP)))
        pixel_ypos <= cnt_v + 1'b1 - (V_SYNC + V_BACK) ;
    else 
        pixel_ypos <= 11'd0;
end

//行计数器对像素时钟计数
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_h <= 11'd0;
    else begin
        if(cnt_h < H_TOTAL - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else 
            cnt_h <= 11'd0;
    end
end

//场计数器对行计数
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_v <= 11'd0;
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else 
            cnt_v <= 11'd0;
    end
end

endmodule