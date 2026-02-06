//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mdio_rw_test
// Last modified Date:  2020/2/6 17:25:36
// Last Version:        V1.0
// Descriptions:        MDIO接口测试
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/6 17:25:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module mdio_rw_test(
    input          sys_clk  ,
    input          sys_rst_n,
    //MDIO接口
    output         eth_mdc  , //PHY管理接口的时钟信号
    inout          eth_mdio , //PHY管理接口的双向数据信号
    output         eth_rst_n, //以太网复位信号
    
    input          touch_key, //触摸按键
    output  [1:0]  led        //LED连接速率指示
    );
    
//wire define
wire          op_exec    ;  //触发开始信号
wire          op_rh_wl   ;  //低电平写，高电平读
wire  [4:0]   op_addr    ;  //寄存器地址
wire  [15:0]  op_wr_data ;  //写入寄存器的数据
wire          op_done    ;  //读写完成
wire  [15:0]  op_rd_data ;  //读出的数据
wire          op_rd_ack  ;  //读应答信号 0:应答 1:未应答
wire          dri_clk    ;  //驱动时钟

//硬件复位
assign eth_rst_n = sys_rst_n;

//MDIO接口驱动
mdio_dri #(
    .PHY_ADDR    (5'h04),    //PHY地址 3'b100
    .CLK_DIV     (6'd10)     //分频系数
    )
    u_mdio_dri(
    .clk        (sys_clk),
    .rst_n      (sys_rst_n),
    .op_exec    (op_exec   ),
    .op_rh_wl   (op_rh_wl  ),   
    .op_addr    (op_addr   ),   
    .op_wr_data (op_wr_data),   
    .op_done    (op_done   ),   
    .op_rd_data (op_rd_data),   
    .op_rd_ack  (op_rd_ack ),   
    .dri_clk    (dri_clk   ),  
                 
    .eth_mdc    (eth_mdc   ),   
    .eth_mdio   (eth_mdio  )   
);      

//MDIO接口读写控制    
mdio_ctrl  u_mdio_ctrl(
    .clk           (dri_clk),  
    .rst_n         (sys_rst_n ),  
    .soft_rst_trig (touch_key ),  
    .op_done       (op_done   ),  
    .op_rd_data    (op_rd_data),  
    .op_rd_ack     (op_rd_ack ),  
    .op_exec       (op_exec   ),  
    .op_rh_wl      (op_rh_wl  ),  
    .op_addr       (op_addr   ),  
    .op_wr_data    (op_wr_data),  
    .led           (led       )
);      

endmodule