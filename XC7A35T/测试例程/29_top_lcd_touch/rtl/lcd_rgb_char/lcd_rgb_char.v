//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lcd_rgb_char
// Created by:          正点原子
// Created date:        2023年5月24日14:17:02
// Version:             V1.0
// Descriptions:        RGB LCD顶层模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module  lcd_rgb_char(
    input              sys_clk   ,
    input              sys_rst_n ,
	
	input      [31:0]  data      ,
	//RGB LCD接口 
    output             lcd_hs    , //LCD 行同步信号
    output             lcd_vs    , //LCD 场同步信号
    output             lcd_de    , //LCD 数据输入使能
    inout      [23:0]  lcd_rgb   , //LCD RGB颜色数据
    output             lcd_bl    , //LCD 背光控制信号
    output             lcd_clk   , //LCD 采样时钟
    output             lcd_rst_n,  //LCD复位
    output     [15:0]  lcd_id
);

//wire define
wire  [10:0]  pixel_xpos_w ;
wire  [10:0]  pixel_ypos_w ;
wire  [23:0]  pixel_data_w ;
wire  [23:0]  lcd_rgb_o    ;
wire          lcd_pclk     ;
wire  [15:0]  bcd_data_x ;
wire  [15:0]  bcd_data_y ;

//*****************************************************
//**                    main code
//*****************************************************

//RGB565数据输出
assign lcd_rgb = lcd_de ? lcd_rgb_o : {24{1'bz}};

//读rgb lcd ID 模块
rd_id    u_rd_id(
    .clk          (sys_clk  ),
    .rst_n        (sys_rst_n),

    .lcd_rgb      (lcd_rgb  ),
    .lcd_id       (lcd_id   )
);

//分频模块，根据不同的LCD ID输出相应的频率的驱动时钟
clk_div  u_clk_div(
    .clk          (sys_clk  ),
    .rst_n        (sys_rst_n),

    .lcd_id       (lcd_id   ),
    .lcd_pclk     (lcd_pclk )
);

    
//二进制转BCD码X轴
binary2bcd u_binary2bcd_x(
    .sys_clk         (sys_clk),
    .sys_rst_n       (sys_rst_n),
    .data            (data[31:16]),

    .bcd_data        (bcd_data_x)    
);

//二进制转BCD码Y轴
binary2bcd u_binary2bcd_y(
    .sys_clk         (sys_clk),
    .sys_rst_n       (sys_rst_n),
    .data            (data[15:0]),

    .bcd_data        (bcd_data_y)    
); 

//lcd显示模块
lcd_display  u_lcd_display(          
    .lcd_pclk       (lcd_pclk    ),
    .sys_rst_n      (sys_rst_n   ),
    .data           ({bcd_data_x,bcd_data_y}),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
);

//lcd驱动模块
lcd_driver  u_lcd_driver(
    .lcd_pclk       (lcd_pclk    ),
    .rst_n          (sys_rst_n   ),

    .lcd_id         (lcd_id      ),

    .lcd_hs         (lcd_hs      ),
    .lcd_vs         (lcd_vs      ),
    .lcd_de         (lcd_de      ),
    .lcd_bl         (lcd_bl      ),
    .lcd_clk        (lcd_clk     ),
    .lcd_rgb        (lcd_rgb_o   ),
    .lcd_rst        (lcd_rst_n   ),
    .data_req       (),
    .h_disp         (),
    .v_disp         (),
    .pixel_data     (pixel_data_w),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w)
); 

endmodule
