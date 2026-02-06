//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           key_led
// Created by:          正点原子
// Created date:        2023年2月22日14:17:02
// Version:             V1.0
// Descriptions:        按键控制LED灯实验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module key_led(
    //input
    input               sys_clk,
    input               sys_rst_n,
    input        [4:0]  key,
    //output        
    output  reg  [4:0]  led 
    );

ila_0 key_ila_0 (
	.clk(sys_clk), // input wire clk


	.probe0(key) // input wire [4:0] probe0
);
//参数
parameter CNT_MAX = 25'd25000000;    

//reg define
reg  [24:0]  cnt;
reg  [1:0]   led_flag;

//*****************************************************
//**                    main code
//*****************************************************

//计数器计时0.5s
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cnt <= 25'd0;
    else if(cnt < (CNT_MAX - 25'd1))
        cnt <= cnt + 25'd1;
    else
        cnt <= 25'd0;
end

//LED状态切换标志位
//  0  1  2  3
//  00 01 10 11
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        led_flag <= 2'd0;
    else if(cnt == (CNT_MAX - 25'd1))   
        led_flag <= led_flag + 2'd1;
    else
        led_flag <= led_flag;
end    
    
//LED控制(根据哪个KEY被按下，和led_flag，对LED进行赋值)
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        led <= 5'b0000;
    else begin
        case(key)
            5'b11111 : led <= 5'b0000;
            5'b11110 : begin 
                if(led_flag == 2'd0)
                    led <= 5'b00001;
                else
                    led <= 5'b00000; 
            end
            5'b11101 : begin 
                if(led_flag == 2'd0)
                    led <= 5'b00010;
                else
                    led <= 5'b00000; 
            end  
            5'b11011 : begin 
                if(led_flag == 2'd0)
                    led <= 5'b00100;
                else
                    led <= 5'b00000; 
            end        
            5'b10111 : begin
                if(led_flag == 2'd0)
                    led <= 5'b01000;
                else
                    led <= 5'b00000; 
            end
            5'b01111 : begin
                if(led_flag == 2'd0)
                    led <= 5'b10000;
                else
                    led <= 5'b00000; 
            end
            default : ;
        endcase    
    end
end      
    
endmodule
