//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           sd_read
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        SD卡读模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sd_read(
    input                clk_ref       ,        //时钟信号
    input                clk_ref_180deg,  //时钟信号,与clk_ref相位相差180度
    input                rst_n         ,       //复位信号,低电平有效
    //SD卡接口
    input                   sd_miso       ,   //SD卡SPI串行输入数据信号
    output  reg          sd_cs         ,    //SD卡SPI片选信号
    output  reg          sd_mosi       ,  //SD卡SPI串行输出数据信号
       //用户读接口    
    input                   rd_start_en   ,      //开始读SD卡数据信号
    input        [31:0]   rd_sec_addr   ,  //读数据扇区地址                        
    output  reg          rd_busy       ,  //读数据忙信号
    output  reg          rd_val_en     ,  //读数据有效信号
    output  reg  [15:0]rd_val_data   //读数据
    );

//reg define
reg            rd_en_d0      ;            //rd_start_en信号延时打拍
reg            rd_en_d1      ;                                
reg            res_en        ;            //接收SD卡返回数据有效信号      
reg    [7:0]  res_data      ;            //接收SD卡返回数据                  
reg            res_flag      ;            //开始接收返回数据的标志            
reg    [5:0]  res_bit_cnt   ;            //接收位数据计数器                  
                             
reg            rx_en_t       ;            //接收SD卡数据使能信号
reg    [15:0]rx_data_t     ;            //接收SD卡数据
reg            rx_flag       ;            //开始接收的标志
reg    [3:0]  rx_bit_cnt    ;            //接收数据位计数器
reg    [8:0]  rx_data_cnt   ;            //接收的数据个数计数器
reg            rx_finish_en  ;            //接收完成使能信号
                             
reg    [3:0]   rd_ctrl_cnt   ;            //读控制计数器
reg    [47:0] cmd_rd        ;            //读命令
reg    [5:0]   cmd_bit_cnt   ;            //读命令位计数器
reg              rd_data_flag  ;            //准备读取数据的标志

//wire define
wire             pos_rd_en     ;            //开始读SD卡数据信号的上升沿

//*****************************************************
//**                    main code
//*****************************************************

assign  pos_rd_en = (~rd_en_d1) & rd_en_d0;

//rd_start_en信号延时打拍
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        rd_en_d0 <= 1'b0;
        rd_en_d1 <= 1'b0;
    end    
    else begin
        rd_en_d0 <= rd_start_en;
        rd_en_d1 <= rd_en_d0;
    end        
end  

//接收sd卡返回的响应数据
//在clk_ref_180deg(sd_clk)的上升沿锁存数据
always @(posedge clk_ref_180deg or negedge rst_n) begin
    if(!rst_n) begin
        res_en <= 1'b0;
        res_data <= 8'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else begin
        //sd_miso = 0 开始接收响应数据
        if(sd_miso == 1'b0 && res_flag == 1'b0) begin
            res_flag <= 1'b1;
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_en <= 1'b0;
        end    
        else if(res_flag) begin
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd7) begin
                res_flag <= 1'b0;
                res_bit_cnt <= 6'd0;
                res_en <= 1'b1; 
            end                
        end  
        else
            res_en <= 1'b0;        
    end
end 

//接收SD卡有效数据
//在clk_ref_180deg(sd_clk)的上升沿锁存数据
always @(posedge clk_ref_180deg or negedge rst_n) begin
    if(!rst_n) begin
        rx_en_t <= 1'b0;
        rx_data_t <= 16'd0;
        rx_flag <= 1'b0;
        rx_bit_cnt <= 4'd0;
        rx_data_cnt <= 9'd0;
        rx_finish_en <= 1'b0;
    end    
    else begin
        rx_en_t <= 1'b0; 
        rx_finish_en <= 1'b0;
        //数据头0xfe 8'b1111_1110，所以检测0为起始位
        if(rd_data_flag && sd_miso == 1'b0 && rx_flag == 1'b0)    
            rx_flag <= 1'b1;   
        else if(rx_flag) begin
            rx_bit_cnt <= rx_bit_cnt + 4'd1;
            rx_data_t <= {rx_data_t[14:0],sd_miso};
            if(rx_bit_cnt == 4'd15) begin 
                rx_data_cnt <= rx_data_cnt + 9'd1;
                //接收单个BLOCK共512个字节 = 256 * 16bit 
                if(rx_data_cnt <= 9'd255)                        
                    rx_en_t <= 1'b1;  
                else if(rx_data_cnt == 9'd257) begin   //接收两个字节的CRC校验值
                    rx_flag <= 1'b0;
                    rx_finish_en <= 1'b1;              //数据接收完成
                    rx_data_cnt <= 9'd0;               
                    rx_bit_cnt <= 4'd0;
                end    
            end                
        end       
        else
            rx_data_t <= 16'd0;
    end    
end    

//寄存输出数据有效信号和数据
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        rd_val_en <= 1'b0;
        rd_val_data <= 16'd0;
    end
    else begin
        if(rx_en_t) begin
            rd_val_en <= 1'b1;
            rd_val_data <= rx_data_t;
        end    
        else
            rd_val_en <= 1'b0;
    end
end              

//读命令
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1;        
        rd_ctrl_cnt <= 4'd0;
        cmd_rd <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        rd_busy <= 1'b0;
        rd_data_flag <= 1'b0;
    end   
    else begin
        case(rd_ctrl_cnt)
            4'd0 : begin
                rd_busy <= 1'b0;
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;
                if(pos_rd_en) begin
                    cmd_rd <= {8'h51,rd_sec_addr,8'hff};    //写入单个命令块CMD17
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;      //控制计数器加1
                    //开始执行读取数据,拉高读忙信号
                    rd_busy <= 1'b1;                      
                end    
            end
            4'd1 : begin
                if(cmd_bit_cnt <= 6'd47) begin              //开始按位发送读命令
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_rd[6'd47 - cmd_bit_cnt]; //先发送高字节
                end    
                else begin                                  
                    sd_mosi <= 1'b1;
                    if(res_en) begin                        //SD卡响应
                        rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;  //控制计数器加1 
                        cmd_bit_cnt <= 6'd0;
                    end    
                end    
            end    
            4'd2 : begin
                //拉高rd_data_flag信号,准备接收数据
                rd_data_flag <= 1'b1;                       
                if(rx_finish_en) begin                      //数据接收完成
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1; 
                    rd_data_flag <= 1'b0;
                    sd_cs <= 1'b1;
                end
            end        
            default : begin
                //进入空闲状态后,拉高片选信号,等待8个时钟周期
                sd_cs <= 1'b1;   
                rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
            end    
        endcase
    end         
end

endmodule