//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           sd_write
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        SD卡写模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//


module sd_write(
    input                clk_ref       ,  //时钟信号
    input                clk_ref_180deg,  //时钟信号,与clk_ref相位相差180度
    input                rst_n         ,  //复位信号,低电平有效
    //SD卡接口
    input                   sd_miso       ,  //SD卡SPI串行输入数据信号
    output  reg          sd_cs         ,   //SD卡SPI片选信号  
    output  reg          sd_mosi       ,  //SD卡SPI串行输出数据信号
    //用户写接口    
    input                  wr_start_en   ,    //开始写SD卡数据信号
    input        [31:0]  wr_sec_addr   ,  //写数据扇区地址
    input        [15:0]  wr_data       ,    //写数据                          
    output  reg          wr_busy       ,  //写数据忙信号
    output  reg          wr_req           //写数据请求信号
    );

//parameter define
parameter  HEAD_BYTE = 8'hfe    ;         //数据头
                             
//reg define                    
reg            wr_en_d0         ;          //wr_start_en信号延时打拍
reg            wr_en_d1         ;   
reg            res_en           ;            //接收SD卡返回数据有效信号      
reg    [7:0]  res_data         ;           //接收SD卡返回数据                 
reg            res_flag         ;            //开始接收返回数据的标志
reg    [5:0]  res_bit_cnt      ;            //接收位数据计数器                   
                                
reg    [3:0]   wr_ctrl_cnt      ;           //写控制计数器
reg    [47:0] cmd_wr           ;          //写命令
reg    [5:0]   cmd_bit_cnt      ;         //写命令位计数器
reg    [3:0]   bit_cnt          ;             //写数据位计数器
reg    [8:0]   data_cnt         ;           //写入数据数量
reg    [15:0] wr_data_t        ;           //寄存写入的数据，防止发生改变
reg             detect_done_flag ;       //检测写空闲信号的标志
reg    [7:0]   detect_data      ;         //检测到的数据

//wire define
wire           pos_wr_en        ;         //开始写SD卡数据信号的上升沿

//*****************************************************
//**                    main code
//*****************************************************

assign  pos_wr_en = (~wr_en_d1) & wr_en_d0;

//wr_start_en信号延时打拍
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        wr_en_d0 <= 1'b0;
        wr_en_d1 <= 1'b0;
    end    
    else begin
        wr_en_d0 <= wr_start_en;
        wr_en_d1 <= wr_en_d0;
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

//写完数据后检测SD卡是否空闲
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n)
        detect_data <= 8'd0;   
    else if(detect_done_flag)
        detect_data <= {detect_data[6:0],sd_miso};
    else
        detect_data <= 8'd0;    
end        

//SD卡写入数据
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1; 
        wr_ctrl_cnt <= 4'd0;
        wr_busy <= 1'b0;
        cmd_wr <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        bit_cnt <= 4'd0;
        wr_data_t <= 16'd0;
        data_cnt <= 9'd0;
        wr_req <= 1'b0;
        detect_done_flag <= 1'b0;
    end
    else begin
        wr_req <= 1'b0;
        case(wr_ctrl_cnt)
            4'd0 : begin
                wr_busy <= 1'b0;                          //写空闲
                sd_cs <= 1'b1;                                 
                sd_mosi <= 1'b1;                               
                if(pos_wr_en) begin                            
                    cmd_wr <= {8'h58,wr_sec_addr,8'hff};    //写入单个命令块CMD24
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      //控制计数器加1
                    //开始执行写入数据,拉高写忙信号
                    wr_busy <= 1'b1;                      
                end                                            
            end   
            4'd1 : begin
                if(cmd_bit_cnt <= 6'd47) begin              //开始按位发送写命令
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_wr[6'd47 - cmd_bit_cnt]; //先发送高字节                 
                end    
                else begin
                    sd_mosi <= 1'b1;
                    if(res_en) begin                        //SD卡响应
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //控制计数器加1 
                        cmd_bit_cnt <= 6'd0;
                        bit_cnt <= 4'd1;
                    end    
                end     
            end                                                                                                     
            4'd2 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;     
                //bit_cnt = 0~7 等待8个时钟周期
                //bit_cnt = 8~15,写入命令头8'hfe        
                if(bit_cnt>=4'd8 && bit_cnt <= 4'd15) begin
                    sd_mosi <= HEAD_BYTE[4'd15-bit_cnt];    //先发送高字节
                    if(bit_cnt == 4'd14)                       
                        wr_req <= 1'b1;                   //提前拉高写数据请求信号
                    else if(bit_cnt == 4'd15)                  
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //控制计数器加1   
                end                                            
            end                                                
            4'd3 : begin                                    //写入数据
                bit_cnt <= bit_cnt + 4'd1;                     
                if(bit_cnt == 4'd0) begin                      
                    sd_mosi <= wr_data[4'd15-bit_cnt];      //先发送数据高位     
                    wr_data_t <= wr_data;                   //寄存数据   
                end                                            
                else                                           
                    sd_mosi <= wr_data_t[4'd15-bit_cnt];    //先发送数据高位
                if((bit_cnt == 4'd14) && (data_cnt <= 9'd255)) 
                    wr_req <= 1'b1;                          
                if(bit_cnt == 4'd15) begin                     
                    data_cnt <= data_cnt + 9'd1;  
                    //写入单个BLOCK共512个字节 = 256 * 16bit             
                    if(data_cnt == 9'd255) begin
                        data_cnt <= 9'd0;            
                        //写入数据完成,控制计数器加1          
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      
                    end                                        
                end                                            
            end       
            //写入2个字节CRC校验,由于SPI模式下不检测校验值,此处写入两个字节的8'hff                                         
            4'd4 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;                  
                sd_mosi <= 1'b1;                 
                //crc写入完成,控制计数器加1              
                if(bit_cnt == 4'd15)                           
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;            
            end                                                
            4'd5 : begin                                    
                if(res_en)                                  //SD卡响应   
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
            end                                                
            4'd6 : begin                                    //等待写完成           
                detect_done_flag <= 1'b1;                   
                //detect_data = 8'hff时,SD卡写入完成,进入空闲状态
                if(detect_data == 8'hff) begin              
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
                    detect_done_flag <= 1'b0;                  
                end         
            end    
            default : begin
                //进入空闲状态后,拉高片选信号,等待8个时钟周期
                sd_cs <= 1'b1;   
                wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;
            end     
        endcase
    end
end            

endmodule