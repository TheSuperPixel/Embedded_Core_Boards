//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3控制器fifo控制模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input               rst_n            ,  //复位信号
    input               wr_clk           ,  //写fifo写时钟
    input               rd_clk           ,  //读fifo读时钟
    input               ui_clk           ,  //用户时钟
    input               wr_en            ,  //数据有效使能信号
    input  [15:0]       wrdata           ,  //写有效数据
    input  [127:0]      rfifo_din        ,  //用户读数据
    input               rdata_req        ,  //读数据请求信号 
    input               rfifo_wren       ,  //从ddr3读出数据的有效使能
    input               wfifo_rden       ,  //wfifo读使能       

    output [127:0]      wfifo_dout       ,  //用户写数据
    output [9:0]        rfifo_wcount     ,  //rfifo剩余数据计数
    output [9:0]        wfifo_rcount     ,  //wfifo写进数据计数
    output reg [15:0]   rddata              //读有效数据     	
    );
           
//reg define
reg  [127:0] wrdata_t          ;  //由16bit输入源数据移位拼接得到   
reg  [3:0]   byte_cnt          ;  //写数据移位计数器
reg  [3:0]   i                 ;  //读数据移位计数器
reg          wfifo_wren        ;  //wfifo写使能信号

//wire define 
wire [127:0] rfifo_dout        ;  //rfifo输出数据    
wire [127:0] wfifo_din         ;  //wfifo写数据
wire [15:0]  dataout[0:15]     ;  //定义输出数据的二维数组
wire         rfifo_rden        ;  //rfifo的读使能

//*****************************************************
//**                    main code
//*****************************************************  
assign wfifo_din = wrdata_t ;

//移位寄存器计满时，从rfifo读出一个数据
assign rfifo_rden = (rdata_req && (i == 4'd7)) ? 1'b1 : 1'b0; 

//rfifo输出的数据存到二维数组
assign dataout[0] = rfifo_dout[127:112];
assign dataout[1] = rfifo_dout[111:96];
assign dataout[2] = rfifo_dout[95:80];
assign dataout[3] = rfifo_dout[79:64];
assign dataout[4] = rfifo_dout[63:48];
assign dataout[5] = rfifo_dout[47:32];
assign dataout[6] = rfifo_dout[31:16];
assign dataout[7] = rfifo_dout[15:0];

//16位数据转128位数据        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        wrdata_t <= 16'd0;
        byte_cnt <= 4'd0;
    end
    else if(wr_en) begin
        if(byte_cnt == 4'd7)begin
            byte_cnt <= 4'd0;
            wrdata_t <= {wrdata_t[111:0],wrdata};
        end
        else begin
            byte_cnt <= byte_cnt + 1'b1;
            wrdata_t <= {wrdata_t[111:0],wrdata};
        end
    end
    else begin
        byte_cnt <= 4'd0;
        wrdata_t <= wrdata_t;
    end    
end 

//wfifo写使能产生
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 1'b0;
    else if(wfifo_wren == 1'b1)
        wfifo_wren <= 1'b0;
    else if(byte_cnt == 4'd7 && wr_en)  //输入源数据传输8次，写使能拉高一次
        wfifo_wren <= 1'b1;
    else 
        wfifo_wren <= 1'b0;
 end   

//对rfifo出来的128bit数据拆解成8个16bit数据
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        rddata <= 16'b0;
        i <= 5'd0;
    end
    else if(rdata_req) begin
        if(i == 4'd7)begin
            rddata <= dataout[i];
            i <= 4'd0;
        end
        else begin
            rddata <= dataout[i];
            i <= i + 1'b1;
        end
    end 
    else begin
       rddata <= rddata;
       i <= 4'b0;
   end
end  

rd_fifo u_rd_fifo (
  .rst               (~rst_n),                    
  .wr_clk            (ui_clk),   
  .rd_clk            (rd_clk),    
  .din               (rfifo_din), 
  .wr_en             (rfifo_wren),
  .rd_en             (rfifo_rden),
  .dout              (rfifo_dout),
  .full              (),          
  .empty             (),          
  .rd_data_count     (),  
  .wr_data_count     (rfifo_wcount),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()      
);

wr_fifo u_wr_fifo (
  .rst               (~rst_n),
  .wr_clk            (wr_clk),            
  .rd_clk            (ui_clk),           
  .din               (wfifo_din),         
  .wr_en             (wfifo_wren),        
  .rd_en             (wfifo_rden),        
  .dout              (wfifo_dout),       
  .full              (),                  
  .empty             (),                  
  .rd_data_count     (wfifo_rcount),  
  .wr_data_count     (),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()    
);

endmodule 