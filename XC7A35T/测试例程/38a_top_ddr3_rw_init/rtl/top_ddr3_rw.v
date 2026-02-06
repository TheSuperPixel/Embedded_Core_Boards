//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top_ddr3_rw
// Last modified Date:  2023/7/5 09:04:34
// Last Version:        V1.0
// Descriptions:        ddr3读写测试顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top_ddr3_rw(
    input              sys_clk             ,   //系统时钟，50MHz
    input              sys_rst_n           ,   //复位,低有效        
    // DDR3 IO接口 
    inout   [15:0]     ddr3_dq             ,   //ddr3 数据
    inout   [1:0]      ddr3_dqs_n          ,   //ddr3 dqs负
    inout   [1:0]      ddr3_dqs_p          ,   //ddr3 dqs正  
    output  [13:0]     ddr3_addr           ,   //ddr3 地址   
    output  [2:0]      ddr3_ba             ,   //ddr3 banck 选择
    output             ddr3_ras_n          ,   //ddr3 行选择
    output             ddr3_cas_n          ,   //ddr3 列选择
    output             ddr3_we_n           ,   //ddr3 读写选择
    output             ddr3_reset_n        ,   //ddr3 复位
    output  [0:0]      ddr3_ck_p           ,   //ddr3 时钟正
    output  [0:0]      ddr3_ck_n           ,   //ddr3 时钟负
    output  [0:0]      ddr3_cke            ,   //ddr3 时钟使能
    output  [0:0]      ddr3_cs_n           ,   //ddr3 片选
    output  [1:0]      ddr3_dm             ,   //ddr3_dm
    output  [0:0]      ddr3_odt            ,   //ddr3_odt      
    //用户
    output  [1:0]      led                     //led灯
    );                
                      
//wire define  
wire                  clk_50m                    ;
wire                  clk_200m                  ;                                          
wire                  init_calib_complete  ;   //ddr3初始化完成信号 
wire                  error;   
wire [15:0]           rd_data              ;   //读取DDR3的数据
wire [15:0]           wr_data              ;   //写入DDR3的数据
wire [27:0]           app_addr_rd_min     ;
wire [27:0]           app_addr_rd_max     ;  
wire [7:0]            rd_bust_len         ;  
wire [27:0]           app_addr_wr_min     ;  
wire [27:0]           app_addr_wr_max     ;  
wire [7:0]            wr_bust_len         ;  
wire                  wr_en                        ;  
wire                  locked                        ;   
                                                                                                                                       
//*****************************************************                               
//**                    main code                                                     
//*****************************************************     
                          
assign app_addr_rd_min = 28'd0;
assign app_addr_rd_max = 28'd1024;
assign rd_bust_len     = 8'd64;
assign app_addr_wr_min = 28'd0;
assign app_addr_wr_max = 28'd1024;
assign wr_bust_len     = 8'd64; 

//复位信号
assign rst_n =  locked && sys_rst_n; 
                                                                                  
//读写模块                                                                            
 ddr3_controler u_ddr3_controler(                                                                               
    //MIG 接口                                                                        
    .init_calib_complete  (init_calib_complete),   //ddr3初始化完成信号                                                                                                                                                            
    //DDR3 地址参数                                                                  
    .app_addr_rd_min      (app_addr_rd_min)    ,   //读ddr3的起始地址                                  
    .app_addr_rd_max      (app_addr_rd_max)    ,   //读ddr3的结束地址                                  
    .rd_bust_len          (rd_bust_len)        ,   //从ddr3中读数据时的突发长度                                  
    .app_addr_wr_min      (app_addr_wr_min)    ,   //写ddr3的起始地址                                  
    .app_addr_wr_max      (app_addr_wr_max)    ,   //写ddr3的结束地址                                  
    .wr_bust_len          (wr_bust_len)        ,   //从ddr3中写数据时的突发长度                                  
    // Memory interface port
    .ddr3_addr           (ddr3_addr)           ,         
    .ddr3_ba             (ddr3_ba)             ,            
    .ddr3_cas_n          (ddr3_cas_n)          ,         
    .ddr3_ck_n           (ddr3_ck_n)           ,        
    .ddr3_ck_p           (ddr3_ck_p)           ,          
    .ddr3_cke            (ddr3_cke)            ,            
    .ddr3_ras_n          (ddr3_ras_n)          ,         
    .ddr3_reset_n        (ddr3_reset_n)        ,      
    .ddr3_we_n           (ddr3_we_n)           ,        
    .ddr3_dq             (ddr3_dq)             ,            
    .ddr3_dqs_n          (ddr3_dqs_n)          ,        
    .ddr3_dqs_p          (ddr3_dqs_p)          ,                                                       
	.ddr3_cs_n           (ddr3_cs_n)           ,                         
    .ddr3_dm             (ddr3_dm)             ,    
    .ddr3_odt            (ddr3_odt)            ,
    // System Clock Ports                            
    .sys_clk_i           (clk_200m)            ,
    .rst_n               (rst_n)               ,   
    // Reference Clock Ports                         
    .clk_ref_i           (clk_200m )           ,       
    .ddr3_read_valid     (1'b1)                   ,   //DDR3 读使能
    //用户接口                                                                      
    .rd_req              (rd_req)              ,   //读fifo读使能
    .wr_clk              (clk_50m)             ,
    .rd_clk              (clk_50m)             ,
    .wr_en               (wr_en)               ,
    .wrdata              (wr_data      )       ,
    .rddata              (rd_data      ) 
    );

test_data u_test_data(
    .clk_50m             (clk_50m      ),      
    .rst_n               (rst_n        ),
    .init_calib_complete (init_calib_complete) ,   //ddr3初始化完成信号                
    .rd_data             (rd_data      ),   
    .rd_req              (rd_req       ),  
    .wr_data             (wr_data      ),      
    .wr_en               (wr_en        ),                                                           
    .error               (error        )
);   

led_disp u_led_disp(
    .clk_50m (clk_50m),
    .rst_n (rst_n),
    //DDR3初始化失败或者读写错误都认为是实验失败
    .error_flag (error),
    .init_calib_complete (init_calib_complete) , 
    .led (led) 
);

clk_wiz_0 u_clk_wiz(
  // Clock out ports
  .clk_out1(clk_200m),// output clk_out1
  .clk_out2(clk_50m), // output clk_out2
  // Status and control signals
  .reset(~sys_rst_n),  // input reset
  .locked(locked),    // output locked
 // Clock in ports
  .clk_in1(sys_clk)   // input clk_in1
);      

endmodule