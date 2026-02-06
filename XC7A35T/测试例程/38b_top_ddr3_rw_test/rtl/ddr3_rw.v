//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_rw
// Last modified Date:  2023/7/5 09:05:05
// Last Version:        V1.0
// Descriptions:        ddr3控制器读写模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_rw(          
    input           ui_clk               ,  //用户时钟
    input           ui_clk_sync_rst      ,  //复位,高有效
    input           init_calib_complete  ,  //DDR3初始化完成
    input           app_rdy              ,  //MIG IP核空闲
    input           app_wdf_rdy          ,  //MIG写数据空闲
    input           app_rd_data_valid    ,  //读数据有效
    input    [9:0]  wfifo_rcount         ,  //写端口FIFO中的数据量
    input    [9:0]  rfifo_wcount         ,  //读端口FIFO中的数据量
    input   [27:0]  app_addr_rd_min      ,  //读DDR3的起始地址
    input   [27:0]  app_addr_rd_max      ,  //读DDR3的结束地址
    input   [7:0]   rd_bust_len          ,  //从DDR3中读数据时的突发长度
    input   [27:0]  app_addr_wr_min      ,  //写DDR3的起始地址
    input   [27:0]  app_addr_wr_max      ,  //写DDR3的结束地址
    input   [7:0]   wr_bust_len          ,  //从DDR3中写数据时的突发长度
    input           ddr3_read_valid      ,  //DDR3 读使能  
             
    output          rfifo_wren           ,  //从ddr3读出数据的有效使能 
    output  [27:0]  app_addr             ,  //DDR3地址                 
    output          app_en               ,  //MIG IP核操作使能
    output          app_wdf_wren         ,  //用户写使能   
    output          app_wdf_end          ,  //突发写当前时钟最后一个数据 
    output  [2:0]   app_cmd                 //MIG IP核操作命令，读或者写       
    );
    
//localparam 
localparam IDLE        = 4'b0001;   //空闲状态
localparam DDR3_DONE   = 4'b0010;   //DDR3初始化完成状态
localparam WRITE       = 4'b0100;   //读FIFO保持状态
localparam READ        = 4'b1000;   //写FIFO保持状态

//reg define 
reg    [27:0] app_addr_rd;          //DDR3读地址
reg    [27:0] app_addr_wr;          //DDR3写地址
reg    [3:0]  state_cnt;            //状态计数器
reg    [23:0] rd_addr_cnt;          //用户读地址计数
reg    [23:0] wr_addr_cnt;          //用户写地址计数 
reg    [27:0] app_addr_rd_min_a;    //读DDR3的起始地址
reg    [27:0] app_addr_rd_max_a;    //读DDR3的结束地址
reg    [7:0]  rd_bust_len_a;        //从DDR3中读数据时的突发长度
reg    [27:0] app_addr_wr_min_a;    //写DDR3的起始地址
reg    [27:0] app_addr_wr_max_a;    //写DDR3的结束地址
reg    [7:0]  wr_bust_len_a;        //从DDR3中写数据时的突发长度

//wire define 
wire          rst_n;

 //*****************************************************
//**                    main code
//***************************************************** 

//将数据有效信号赋给wfifo写使能
assign rfifo_wren =  app_rd_data_valid;

assign rst_n = ~ui_clk_sync_rst;

//在写状态MIG空闲且写有效,或者在读状态MIG空闲，此时使能信号为高，其他情况为低
assign app_en = ((state_cnt == WRITE && (app_rdy && app_wdf_rdy))
                ||(state_cnt == READ && app_rdy)) ? 1'b1:1'b0;
                
//在写状态,MIG空闲且写有效，此时拉高写使能
assign app_wdf_wren = (state_cnt == WRITE && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;

//由于我们DDR3芯片时钟和用户时钟的分频选择4:1，突发长度为8，故两个信号相同
assign app_wdf_end = app_wdf_wren; 

//处于读的时候命令值为1，其他时候命令值为0
assign app_cmd = (state_cnt == READ) ? 3'd1 :3'd0; 

//将数据读写地址赋给ddr地址
assign app_addr = (state_cnt == READ) ? {3'b0,app_addr_rd[24:0]}:{3'b0,app_addr_wr[24:0]};

//对异步信号进行打拍处理
always @(posedge ui_clk or negedge rst_n)  begin
    if(~rst_n)begin
        app_addr_rd_min_a <= 28'd0;
        app_addr_rd_max_a <= 28'd0; 
        rd_bust_len_a <= 8'd0; 
        app_addr_wr_min_a <= 28'd0;  
        app_addr_wr_max_a <= 28'd0; 
        wr_bust_len_a <= 8'd0;                            
    end   
    else begin
        app_addr_rd_min_a <= app_addr_rd_min;
        app_addr_rd_max_a <= app_addr_rd_max; 
        rd_bust_len_a <= rd_bust_len; 
        app_addr_wr_min_a <= app_addr_wr_min;  
        app_addr_wr_max_a <= app_addr_wr_max; 
        wr_bust_len_a <= wr_bust_len;                    
    end    
end 
   
//DDR3读写逻辑实现
always @(posedge ui_clk or negedge rst_n) begin
    if(~rst_n) begin 
        state_cnt    <= IDLE;              
        wr_addr_cnt  <= 24'd0;      
        rd_addr_cnt  <= 24'd0;       
        app_addr_wr  <= app_addr_wr_min_a;   
        app_addr_rd  <= app_addr_rd_min_a;  
    end
    else begin
        case(state_cnt)
            IDLE:begin
                if(init_calib_complete)
                    state_cnt <= DDR3_DONE ;
                else
                    state_cnt <= IDLE;
            end
            DDR3_DONE:begin//当读到结束地址对读地址计数器清零
                if(app_addr_rd >= app_addr_rd_max_a - 4'd8)begin 
                    state_cnt <= DDR3_DONE;
                    rd_addr_cnt <= 24'd0; 
                    app_addr_rd <= app_addr_rd_min_a;
                end //当写到结束地址对写地址计数器清零
                else if(app_addr_wr >= app_addr_wr_max_a - 4'd8)begin 
                    state_cnt <= DDR3_DONE;
                    rd_addr_cnt <= 24'd0; 
                    app_addr_wr <= app_addr_wr_min_a;
                end
               else if(wfifo_rcount >= (wr_bust_len_a - 2'd2))begin  
                    state_cnt <= WRITE;              //跳到写操作
                    wr_addr_cnt  <= 24'd0;                       
                    app_addr_wr <= app_addr_wr;      //写地址保持不变
                end
                 //当rfifo存储数据少于一次突发长度
                else if(rfifo_wcount <= (rd_bust_len_a - 2'd2) && ddr3_read_valid )begin  
                    state_cnt <= READ;                              //跳到读操作
                    rd_addr_cnt <= 24'd0;
                    app_addr_rd <= app_addr_rd;      //读地址保持不变
                end 
                else begin
                    state_cnt <= state_cnt;   
                    wr_addr_cnt  <= 24'd0;      
                    rd_addr_cnt  <= 24'd0;                                      
                end
            end    
            WRITE:   begin 
                if((wr_addr_cnt >= (wr_bust_len_a - 1'b1)) && 
                   (app_rdy && app_wdf_rdy))begin    //写到设定的长度跳到等待状态                  
                    state_cnt    <= DDR3_DONE;                 
                    app_addr_wr <= app_addr_wr + 4'd8;  //一次性写进8个数，故加8
                end       
                else if(app_rdy && app_wdf_rdy)begin   //写条件满足
                    wr_addr_cnt  <= wr_addr_cnt + 1'd1;//写地址计数器自加
                    app_addr_wr  <= app_addr_wr + 4'd8;   //一次性写进8个数，故加8
                end
                else begin                             //写条件不满足，保持当前值     
                    wr_addr_cnt  <= wr_addr_cnt;
                    app_addr_wr  <= app_addr_wr; 
                end
            end
            READ:begin                      //读到设定的地址长度    
                if((rd_addr_cnt >= (rd_bust_len_a - 1'b1)) && app_rdy)begin
                    state_cnt   <= DDR3_DONE;          //则跳到空闲状态 
                    app_addr_rd <= app_addr_rd + 4'd8;
                end       
                else if(app_rdy)begin               //若MIG已经准备好,则开始读
                    rd_addr_cnt <= rd_addr_cnt + 1'b1; //用户地址计数器每次加一
                    app_addr_rd <= app_addr_rd + 4'd8; //一次性读出8个数,DDR3地址加8
                end
                else begin                         //若MIG没准备好,则保持原值
                    rd_addr_cnt <= rd_addr_cnt;
                    app_addr_rd <= app_addr_rd; 
                end
            end             
            default:begin
                state_cnt    <= IDLE;
                wr_addr_cnt  <= 24'd0;
                rd_addr_cnt  <= 24'd0;
            end
        endcase
    end
end          
                
endmodule