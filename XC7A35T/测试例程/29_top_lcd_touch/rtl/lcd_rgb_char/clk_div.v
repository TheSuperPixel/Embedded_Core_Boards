//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           clk_div
// Created by:          正点原子
// Created date:        2023年5月18日14:17:02
// Version:             V1.0
// Descriptions:        时钟分频模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module clk_div(
    input               clk,          //50Mhz
    input               rst_n,
    input       [15:0]  lcd_id,
    output  reg         lcd_pclk
    );

reg          clk_25m;
reg          clk_12_5m;
reg          div_4_cnt;

//*****************************************************
//**                    main code
//*****************************************************

//时钟2分频 输出25MHz时钟 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_25m <= 1'b0;
    else
        clk_25m <= ~clk_25m;
end

//时钟4分频 输出12.5MHz时钟 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_4_cnt <= 1'b0;
        clk_12_5m <= 1'b0;
    end    
    else begin
        div_4_cnt <= div_4_cnt + 1'b1;
        if(div_4_cnt == 1'b1)
            clk_12_5m <= ~clk_12_5m;
        else
            clk_12_5m <= clk_12_5m;
    end        
end

always @(*) begin
    case(lcd_id)
        16'h4342 : lcd_pclk = clk_12_5m;
        16'h7084 : lcd_pclk = clk_25m;
        16'h7016 : lcd_pclk = clk;
        16'h4384 : lcd_pclk = clk_25m;
        16'h1018 : lcd_pclk = clk;
        default :  lcd_pclk = 1'b0;
    endcase
end

endmodule
