//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           tb_key_led
// Created by:          正点原子
// Created date:        2023年2月19日11:12:36
// Version:             V1.0
// Descriptions:        按键控制LED灯闪烁激励文件
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ns / 1ns        //仿真单位/仿真精度

module tb_key_led();

//parameter define
parameter  CLK_PERIOD = 20; //时钟周期 20ns

//reg define
reg           sys_clk;
reg           sys_rst_n;
reg   [1:0]   key;

//wire define
wire  [1:0]   led;

//信号初始化
initial begin
    sys_clk <= 1'b0;
    sys_rst_n <= 1'b0;
    key <= 2'b11;
    #200
    sys_rst_n <= 1'b1;
//key信号变化
    #200
    key <= 2'b11;
    #1000
    key <= 2'b10;
    #2000
    key <= 2'b11;  
    #1000
    key <= 2'b01;
end

//产生时钟
always #(CLK_PERIOD/2) sys_clk = ~sys_clk;

//例化待测设计
key_led  u_key_led(
    .sys_clk      (sys_clk),
    .sys_rst_n    (sys_rst_n),
    .key          (key),
    .led          (led)
    );

endmodule

