//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_controler
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3控制器顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_controler(
    inout   [15:0]      ddr3_dq          ,   //ddr3 数据
    inout   [1:0]       ddr3_dqs_n       ,   //ddr3 dqs负
    inout   [1:0]       ddr3_dqs_p       ,   //ddr3 dqs正  
    output  [13:0]      ddr3_addr        ,   //ddr3 地址   
    output  [2:0]       ddr3_ba          ,   //ddr3 banck 选择
    output              ddr3_ras_n       ,   //ddr3 行选择
    output              ddr3_cas_n       ,   //ddr3 列选择
    output              ddr3_we_n        ,   //ddr3 读写选择
    output              ddr3_reset_n     ,   //ddr3 复位
    output  [0:0]       ddr3_ck_p        ,   //ddr3 时钟正
    output  [0:0]       ddr3_ck_n        ,   //ddr3 时钟负
    output  [0:0]       ddr3_cke         ,   //ddr3 时钟使能
    output  [0:0]       ddr3_cs_n        ,   //ddr3 片选
    output  [1:0]       ddr3_dm          ,   //ddr3_dm
    output  [0:0]       ddr3_odt         ,   //ddr3_odt  
    output              init_calib_complete,
    input               sys_clk_i,
    input               clk_ref_i,
    input               ddr3_read_valid  ,  //DDR3 读使能 
    
    input               rst_n            ,  //复位信号 
    input [27:0]        app_addr_rd_min  ,
    input [27:0]        app_addr_rd_max  , 
    input [7:0]         rd_bust_len      , 
    input [27:0]        app_addr_wr_min  , 
    input [27:0]        app_addr_wr_max  , 
    input [7:0]         wr_bust_len      ,    
    
    input               wr_clk           ,  //写fifo写时钟
    input               rd_clk           ,  //读fifo读时钟
    input               rd_req           ,  //读数据请求使能                                                                    
    input               wr_en            ,  //写数据使能信号
    input  [15:0]       wrdata           ,  //写有效数据 
    output [15:0]       rddata              //读有效数据 
    );
    
//wire define  
wire                  app_rdy              ;   //MIG IP核空闲
wire                  app_wdf_rdy          ;   //MIG写数据空闲
wire                  app_rd_data_valid    ;   //读数据有效
wire [27:0]           app_addr             ;   //ddr3 地址
wire [2:0]            app_cmd              ;   //用户读写命令
wire                  app_en               ;   //MIG IP核使能
wire [127:0]          app_rd_data          ;   //用户读数据
wire                  app_rd_data_end      ;   //突发读当前时钟最后一个数据 
wire [127:0]          app_wdf_data         ;   //用户写数据 
wire                  app_wdf_end          ;   //突发写当前时钟最后一个数据 
wire [15:0]           app_wdf_mask         ;   //写数据屏蔽                           
wire                  app_sr_active        ;   //保留                                 
wire                  app_ref_ack          ;   //刷新请求                             
wire                  app_zq_ack           ;   //ZQ 校准请求                                                
wire                  ui_clk               ;   //用户时钟                   
wire                  ui_clk_sync_rst      ;   //用户复位信号    
wire [9:0]            wfifo_rcount         ;  //wfifo写进数据计数                    
wire [9:0]            rfifo_wcount         ;  //rfifo剩余数据计数

//*****************************************************
//** main code
//***************************************************** 

//读写模块                                                                            
 ddr3_rw u_ddr3_rw(                                                                   
    .ui_clk               (ui_clk)              ,                                     
    .ui_clk_sync_rst      (ui_clk_sync_rst | ~rst_n),                                      
    //MIG 接口                                                                        
    .init_calib_complete  (init_calib_complete) ,   //ddr3初始化完成信号                                   
    .app_rdy              (app_rdy)             ,   //MIG IP核空闲                                   
    .app_wdf_rdy          (app_wdf_rdy)         ,   //写空闲                                   
    .app_rd_data_valid    (app_rd_data_valid)   ,   //读数据有效                                   
    .app_addr             (app_addr)            ,   //ddr3 地址                                   
    .app_en               (app_en)              ,   //MIG IP核使能                                   
    .app_wdf_wren         (app_wdf_wren)        ,   //ddr3 写使能                                    
    .app_wdf_end          (app_wdf_end)         ,   //突发写当前时钟最后一个数据                                   
    .app_cmd              (app_cmd)             ,   //用户读写命令                                                                                                                         
    //DDR3 地址参数                                                                   
    .app_addr_rd_min      (app_addr_rd_min)     ,   //读ddr3的起始地址                                  
    .app_addr_rd_max      (app_addr_rd_max)     ,   //读ddr3的结束地址                                  
    .rd_bust_len          (rd_bust_len)         ,   //从ddr3中读数据时的突发长度                                  
    .app_addr_wr_min      (app_addr_wr_min)     ,   //写ddr3的起始地址                                  
    .app_addr_wr_max      (app_addr_wr_max)     ,   //写ddr3的结束地址                                  
    .wr_bust_len          (wr_bust_len)         ,   //从ddr3中写数据时的突发长度                                  
    //用户接口                                                 
    .rfifo_wren           (rfifo_wren)          ,   //从ddr3读出数据的有效使能 
    .ddr3_read_valid      (ddr3_read_valid)     ,   //DDR3 读使能
    .wfifo_rcount         (wfifo_rcount)        ,   //wfifo写进数据计数                 
    .rfifo_wcount         (rfifo_wcount)            //rfifo剩余数据计数
    );
    
//MIG IP核模块
mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr           (ddr3_addr)            ,         
    .ddr3_ba             (ddr3_ba)              ,            
    .ddr3_cas_n          (ddr3_cas_n)           ,         
    .ddr3_ck_n           (ddr3_ck_n)            ,        
    .ddr3_ck_p           (ddr3_ck_p)            ,          
    .ddr3_cke            (ddr3_cke)             ,            
    .ddr3_ras_n          (ddr3_ras_n)           ,         
    .ddr3_reset_n        (ddr3_reset_n)         ,      
    .ddr3_we_n           (ddr3_we_n)            ,        
    .ddr3_dq             (ddr3_dq)              ,            
    .ddr3_dqs_n          (ddr3_dqs_n)           ,        
    .ddr3_dqs_p          (ddr3_dqs_p)           ,                                                       
	.ddr3_cs_n           (ddr3_cs_n)            ,                         
    .ddr3_dm             (ddr3_dm)              ,    
    .ddr3_odt            (ddr3_odt)             ,          
    // Application interface ports                                        
    .app_addr            (app_addr)             ,         
    .app_cmd             (app_cmd)              ,          
    .app_en              (app_en)               ,        
    .app_wdf_data        (app_wdf_data)         ,      
    .app_wdf_end         (app_wdf_end)          ,       
    .app_wdf_wren        (app_wdf_wren)         ,           
    .app_rd_data         (app_rd_data)          ,       
    .app_rd_data_end     (app_rd_data_end)      ,                                        
    .app_rd_data_valid   (app_rd_data_valid)    ,     
    .init_calib_complete (init_calib_complete)  ,                                                                
    .app_rdy             (app_rdy)              ,      
    .app_wdf_rdy         (app_wdf_rdy)          ,          
    .app_sr_req          (0)                    ,                    
    .app_ref_req         (0)                    ,              
    .app_zq_req          (0)                    ,             
    .app_sr_active       (app_sr_active)        ,        
    .app_ref_ack         (app_ref_ack)          ,         
    .app_zq_ack          (app_zq_ack)           ,             
    .ui_clk              (ui_clk)               ,                
    .ui_clk_sync_rst     (ui_clk_sync_rst)      ,                                               
    .app_wdf_mask        (16'b0)                ,    
    // System Clock Ports                            
    .sys_clk_i           (sys_clk_i)            ,    
    // Reference Clock Ports                         
    .clk_ref_i           (clk_ref_i )           ,    
    .sys_rst             (rst_n)                 
    );                                               
                                                     
ddr3_fifo_ctrl u_ddr3_fifo_ctrl (
    .rst_n               (rst_n)          ,  
    //输入源接口
    .wr_clk              (wr_clk)         ,
    .rd_clk              (rd_clk)         ,
    .ui_clk              (ui_clk)         ,   
    .wr_en               (wr_en)          ,
    .wrdata              (wrdata      )   ,
    .rfifo_din           (app_rd_data   ) ,
    .rdata_req           (rd_req     )    ,
    .rfifo_wren          (rfifo_wren  )   ,
    .wfifo_rden          (app_wdf_wren  ) ,  
    .wfifo_dout          (app_wdf_data  ) ,
    .wfifo_rcount        (wfifo_rcount)   ,
    .rfifo_wcount        (rfifo_wcount)   ,
    .rddata              (rddata      ) 
    );

endmodule
