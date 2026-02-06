//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mdio_ctrl
// Last modified Date:  2020/2/6 17:25:36
// Last Version:        V1.0
// Descriptions:        MDIO接口读写控制
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/6 17:25:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module mdio_ctrl(
    input                clk           ,
    input                rst_n         ,
    input                soft_rst_trig , //软复位触发信号
    input                op_done       , //读写完成
    input        [15:0]  op_rd_data    , //读出的数据
    input                op_rd_ack     , //读应答信号 0:应答 1:未应答
    output  reg          op_exec       , //触发开始信号
    output  reg          op_rh_wl      , //低电平写，高电平读
    output  reg  [4:0]   op_addr       , //寄存器地址
    output  reg  [15:0]  op_wr_data    , //写入寄存器的数据
    output       [1:0]   led             //LED灯指示以太网连接状态
    );

parameter TIME_CNT = 24'd1_000_000;

//reg define
reg          rst_trig_d0;    
reg          rst_trig_d1;  
reg			 rst_trig_d2; 
reg          rst_trig_flag;   //soft_rst_trig信号触发标志
reg  [23:0]  timer_cnt;       //定时计数器 
reg          timer_done;      //定时完成信号
reg          start_next;      //开始读下一个寄存器标致
reg          read_next;       //处于读下一个寄存器的过程
reg          link_error;      //链路断开或者自协商未完成
reg  [2:0]   flow_cnt;        //流程控制计数器 
reg  [1:0]   speed_status;    //连接速率 

//wire define
wire         pos_rst_trig;    //soft_rst_trig信号上升沿

//采soft_rst_trig信号上升沿
assign pos_rst_trig = ~rst_trig_d2 & rst_trig_d1;
//未连接或连接失败时led赋值00
// 01:10Mbps  10:100Mbps  11:1000Mbps 00：其他情况
assign led = link_error ? 2'b00: speed_status;
//对soft_rst_trig信号延时打拍
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rst_trig_d0 <= 1'b0;
        rst_trig_d1 <= 1'b0;
		rst_trig_d2 <= 1'b0;
    end
    else begin
        rst_trig_d0 <= soft_rst_trig;
        rst_trig_d1 <= rst_trig_d0;
		rst_trig_d2 <= rst_trig_d1;
    end
end

//定时计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        timer_cnt <= 1'b0;
        timer_done <= 1'b0;
    end
    else begin
        if(timer_cnt == TIME_CNT - 1'b1) begin
            timer_done <= 1'b1;
            timer_cnt <= 1'b0;
        end
        else begin
            timer_done <= 1'b0;
            timer_cnt <= timer_cnt + 1'b1;
        end
    end
end    

//根据软复位信号对MDIO接口进行软复位,并定时读取以太网的连接状态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        flow_cnt <= 3'd0;
        rst_trig_flag <= 1'b0;
        speed_status <= 2'b00;
        op_exec <= 1'b0; 
        op_rh_wl <= 1'b0; 
        op_addr <= 5'h0; 
        op_wr_data <= 16'h0; 
        start_next <= 1'b0; 
        read_next <= 1'b0; 
        link_error <= 1'b0;
    end
    else begin
        op_exec <= 1'b0; 
        if(pos_rst_trig)                      
            rst_trig_flag <= 1'b1;             //拉高软复位触发标志
        case(flow_cnt)
            2'd0 : begin
                if(rst_trig_flag) begin        //开始对MDIO接口进行软复位
                    op_exec <= 1'b1; 
                    op_rh_wl <= 1'b0; 
					op_addr <= 5'h0;
                    op_wr_data <= 16'h9140;    //Bit[15]=1'b1,表示软复位  
                    flow_cnt <= 3'd1;
                end
                else if(timer_done) begin      //定时完成,获取以太网连接状态
                    op_exec <= 1'b1; 
                    op_rh_wl <= 1'b1;
//					op_addr <= 5'h05; 		   //用于仿真
                    op_addr <= 5'h01; 			   //地址
                    flow_cnt <= 3'd2;
                end
                else if(start_next) begin      //开始读下一个寄存器，获取以太网通信速度
                    op_exec <= 1'b1; 
                    op_rh_wl <= 1'b1; 
                    op_addr <= 5'h11;		  //寄存器地址
//					op_addr <= 5'h06;		   //用于仿真
                    flow_cnt <= 3'd2;
                    start_next <= 1'b0; 
                    read_next <= 1'b1; 
                end
            end    
            2'd1 : begin
                if(op_done) begin              //MDIO接口软复位完成
                    flow_cnt <= 3'd0;
                    rst_trig_flag <= 1'b0;
                end
            end
            2'd2 : begin                       
                if(op_done) begin              //MDIO接口读操作完成
                    if(op_rd_ack == 1'b0 && read_next == 1'b0) //读第一个寄存器，接口成功应答，
                        flow_cnt <= 3'd3;                      //读第下一个寄存器，接口成功应答
                    else if(op_rd_ack == 1'b0 && read_next == 1'b1)begin 
                        read_next <= 1'b0;
                        flow_cnt <= 3'd4;
                    end
                    else begin
                        flow_cnt <= 3'd0;
                     end
                end    
            end
            2'd3 : begin                     
                flow_cnt <= 3'd0;          //链路正常并且自协商完成
                if(op_rd_data[5] == 1'b1 && op_rd_data[2] == 1'b1)begin
                    start_next <= 1;
                    link_error <= 0;
                end
                else begin
                    link_error <= 1'b1;  
               end           
            end
            3'd4: begin
                flow_cnt <= 3'd0;
                if(op_rd_data[15:14] == 2'b10)
                    speed_status <= 2'b11; //1000Mbps
                else if(op_rd_data[15:14] == 2'b01) 
                    speed_status <= 2'b10; //100Mbps 
                else if(op_rd_data[15:14] == 2'b00) 
                    speed_status <= 2'b01; //10Mbps
                else
                    speed_status <= 2'b00; //其他情况  
            end
        endcase
    end    
end    

endmodule
