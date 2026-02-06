//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ov5640_dri
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        OV5640摄像头驱动
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_dri (
    input           clk             ,  //时钟
    input           rst_n           ,  //复位信号,低电平有效
    //摄像头接口 
    input           cam_pclk        ,  //cmos 数据像素时钟
    input           cam_vsync       ,  //cmos 场同步信号
    input           cam_href        ,  //cmos 行同步信号
    input    [7:0]  cam_data        ,  //cmos 数据  
    output          cam_rst_n       ,  //cmos 复位信号，低电平有效
    output          cam_pwdn        ,  //cmos 电源休眠模式选择信号
    output          cam_scl         ,  //cmos SCCB_SCL线
    inout           cam_sda         ,  //cmos SCCB_SDA线
    
    //摄像头分辨率配置接口
    input    [12:0] cmos_h_pixel    ,  //水平方向分辨率
    input    [12:0] cmos_v_pixel    ,  //垂直方向分辨率
    input    [12:0] total_h_pixel   ,  //水平总像素大小
    input    [12:0] total_v_pixel   ,  //垂直总像素大小
    input    [12:0] y_addr_st       ,
    input    [12:0] y_addr_end      ,
    input           capture_start   ,  //图像采集开始信号
    output          cam_init_done   ,  //摄像头初始化完成
    
    //用户接口
    output          cmos_frame_vsync,  //帧有效信号    
    output          cmos_frame_href ,  //行有效信号
    output          cmos_frame_valid,  //数据有效使能信号
    output  [15:0]  cmos_frame_data    //有效数据  
);

//parameter define
parameter SLAVE_ADDR = 7'h3c          ; //OV5640的器件地址7'h3c
parameter BIT_CTRL   = 1'b1           ; //OV5640的字节地址为16位  0:8位 1:16位
parameter CLK_FREQ   = 27'd50_000_000 ; //i2c_dri模块的驱动时钟频率 
parameter I2C_FREQ   = 18'd250_000    ; //I2C的SCL时钟频率,不超过400KHz

//wire difine
wire        i2c_exec       ;  //I2C触发执行信号
wire [23:0] i2c_data       ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire        i2c_done       ;  //I2C寄存器配置完成信号
wire        i2c_dri_clk    ;  //I2C操作时钟
wire [ 7:0] i2c_data_r     ;  //I2C读出的数据
wire        i2c_rh_wl      ;  //I2C读写控制信号

//*****************************************************
//**                    main code                      
//*****************************************************

//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn  = 1'b0;
assign  cam_rst_n = 1'b1;
    
//I2C配置模块
i2c_ov5640_rgb565_cfg u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (rst_n),
            
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .i2c_rh_wl          (i2c_rh_wl),        //I2C读写控制信号
    .i2c_done           (i2c_done), 
    .i2c_data_r         (i2c_data_r),   
                
    .cmos_h_pixel       (cmos_h_pixel),     //CMOS水平方向像素个数
    .cmos_v_pixel       (cmos_v_pixel) ,    //CMOS垂直方向像素个数
    .total_h_pixel      (total_h_pixel),    //水平总像素大小
    .total_v_pixel      (total_v_pixel),    //垂直总像素大小
    .y_addr_st          (y_addr_st), 
    .y_addr_end         (y_addr_end),
       
    .init_done          (cam_init_done) 
    );    

//I2C驱动模块
i2c_dri #(
    .SLAVE_ADDR         (SLAVE_ADDR),       //参数传递
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  ) 
    )
u_i2c_dri(
    .clk                (clk),
    .rst_n              (rst_n     ),

    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (i2c_rh_wl),        //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr           (i2c_data[23:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (i2c_data_r),   
    .i2c_done           (i2c_done  ),
    
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   

    .dri_clk            (i2c_dri_clk)       //I2C操作时钟
    );

//CMOS图像数据采集模块
cmos_capture_data u_cmos_capture_data(      //系统初始化完成之后再开始采集数据 
    .rst_n              (rst_n & capture_start),
    
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),         
    
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href ),
    .cmos_frame_valid   (cmos_frame_valid), //数据有效使能信号
    .cmos_frame_data    (cmos_frame_data )  //有效数据 
    );

endmodule 