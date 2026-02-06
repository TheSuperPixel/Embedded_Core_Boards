//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           rd_id
// Last modified Date:  2019/8/07 10:41:06
// Last Version:        V1.0
// Descriptions:        读取LCD ID模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/8/07 10:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rd_id(
    input                   clk    ,    //时钟
    input                   rst_n  ,    //复位，低电平有效
    input           [23:0]  lcd_rgb,    //RGB LCD像素数据,用于读取ID
    output   reg    [15:0]  lcd_id     //LCD屏ID
    );

//reg define
reg            rd_flag;  //读ID标志

//*****************************************************
//**                    main code
//*****************************************************

//获取LCD ID   M2:B7  M1:G7  M0:R7
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_flag <= 1'b0;
        lcd_id <= 16'd0;
    end    
    else begin
        if(rd_flag == 1'b0) begin
            rd_flag <= 1'b1; 
            case({lcd_rgb[7],lcd_rgb[15],lcd_rgb[23]})
                3'b000 : lcd_id <= 16'h4342;    //4.3' RGB LCD  RES:480x272
                3'b001 : lcd_id <= 16'h7084;    //7'   RGB LCD  RES:800x480
                3'b010 : lcd_id <= 16'h7016;    //7'   RGB LCD  RES:1024x600
                3'b100 : lcd_id <= 16'h4384;    //4.3' RGB LCD  RES:800x480
                3'b101 : lcd_id <= 16'h1018;    //10'  RGB LCD  RES:1280x800
                default : lcd_id <= 16'd0;
            endcase    
        end
    end    
end

endmodule
