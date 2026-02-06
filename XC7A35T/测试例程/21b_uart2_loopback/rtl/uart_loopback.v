//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           uart_loopback
// Created by:          正点原子
// Created date:        2023年2月16日14:20:02
// Version:             V1.0
// Descriptions:        串口回环实验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module uart_loopback(
    input            sys_clk  ,   //外部50MHz时钟
    input            sys_rst_n,   //系外部复位信号，低有效
    
    //UART端口    
    input            uart_rxd ,   //UART接收端口
    output           uart_txd     //UART发送端口
    );

//parameter define
parameter CLK_FREQ = 50000000;    //定义系统时钟频率
parameter UART_BPS = 115200  ;    //定义串口波特率

//wire define
wire         uart_rx_done;    //UART接收完成信号
wire  [7:0]  uart_rx_data;    //UART接收数据

//*****************************************************
//**                    main code
//*****************************************************

//串口接收模块
uart_rx #(
    .CLK_FREQ  (CLK_FREQ),
    .UART_BPS  (UART_BPS)
    )    
    u_uart_rx(
    .clk           (sys_clk     ),
    .rst_n         (sys_rst_n   ),
    .uart_rxd      (uart_rxd    ),
    .uart_rx_done  (uart_rx_done),
    .uart_rx_data  (uart_rx_data)
    );

//串口发送模块
uart_tx #(
    .CLK_FREQ  (CLK_FREQ),
    .UART_BPS  (UART_BPS)
    )    
    u_uart_tx(
    .clk          (sys_clk     ),
    .rst_n        (sys_rst_n   ),
    .uart_tx_en   (uart_rx_done),
    .uart_tx_data (uart_rx_data),
    .uart_txd     (uart_txd    ),
    .uart_tx_busy (            )
    );
    
endmodule
