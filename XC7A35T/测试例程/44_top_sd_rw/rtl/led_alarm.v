//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           led_alarm
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LED常亮表示实验成功，LED闪烁表示实验失败SD卡读写错误
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module led_alarm #(parameter    L_TIME = 25'd25_000_000  // 控制led闪烁时间（此为500ms）
    )(
        //system clock
        input             clk       ,  // 时钟信号
        input             rst_n     ,  // 复位信号
        //led interface
        output   [3:0]    led       ,  // LED 灯
        //user interface
        input             error_flag   // 错误标志
);

//reg define
reg                 led_t  ;             // 使用的led灯
reg    [24:0]     led_cnt;             // led计数

//*****************************************************
//**                    main code
//*****************************************************

//led输出
assign  led = {3'b000,led_t};

//错误标志为1时led闪烁，否则，LED0常亮
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        led_cnt <= 25'd0;
        led_t <= 1'b0;
    end
    else begin
        if(error_flag) begin                  // 读到的值错误
            if(led_cnt == L_TIME - 1'b1) begin       // 数据错误时LED灯每隔L_TIME时间闪烁一次
                led_cnt <= 25'd0;
                led_t <= ~led_t;
            end
            else
                led_cnt <= led_cnt + 25'd1;
        end
        else begin                            // 读完且读到的值正确
            led_cnt <= 25'd0;
            led_t <= 1'b1;                    // led灯常亮
        end
    end
end

endmodule