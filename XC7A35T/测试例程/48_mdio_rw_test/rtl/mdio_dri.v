//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mdio_dri
// Last modified Date:  2020/2/6 17:25:36
// Last Version:        V1.0
// Descriptions:        MDIO接口驱动
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/6 17:25:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module mdio_dri #(
    parameter  PHY_ADDR = 5'b00100,//PHY地址
    parameter  CLK_DIV  = 6'd10    //分频系数
   )
    (
    input                clk       , //时钟信号
    input                rst_n     , //复位信号,低电平有效
    input                op_exec   , //触发开始信号
    input                op_rh_wl  , //低电平写，高电平读
    input        [4:0]   op_addr   , //寄存器地址
    input        [15:0]  op_wr_data, //写入寄存器的数据
    output  reg          op_done   , //读写完成
    output  reg  [15:0]  op_rd_data, //读出的数据
    output  reg          op_rd_ack , //读应答信号 0:应答 1:未应答
    output  reg          dri_clk   , //驱动时钟
    
    output  reg          eth_mdc   , //PHY管理接口的时钟信号
    inout                eth_mdio    //PHY管理接口的双向数据信号
    );

//parameter define
localparam st_idle    = 6'b00_0001;  //空闲状态
localparam st_pre     = 6'b00_0010;  //发送PRE(前导码)
localparam st_start   = 6'b00_0100;  //开始状态,发送ST(开始)+OP(操作码)
localparam st_addr    = 6'b00_1000;  //写地址,发送PHY地址+寄存器地址
localparam st_wr_data = 6'b01_0000;  //TA+写数据
localparam st_rd_data = 6'b10_0000;  //TA+读数据

//reg define
reg    [5:0]  cur_state ;
reg    [5:0]  next_state;

reg    [5:0]  clk_cnt   ;  //分频计数                      
reg   [15:0]  wr_data_t ;  //缓存写寄存器的数据
reg    [4:0]  addr_t    ;  //缓存寄存器地址
reg    [6:0]  cnt       ;  //计数器
reg           st_done   ;  //状态开始跳转信号
reg    [1:0]  op_code   ;  //操作码  2'b01(写)  2'b10(读)                  
reg           mdio_dir  ;  //MDIO数据(SDA)方向控制
reg           mdio_out  ;  //MDIO输出信号
reg   [15:0]  rd_data_t ;  //缓存读寄存器数据

//wire define
wire          mdio_in    ; //MDIO数据输入
wire   [5:0]  clk_divide ; //PHY_CLK的分频系数

assign eth_mdio = mdio_dir ? mdio_out : 1'bz; //控制双向io方向
assign mdio_in = eth_mdio;                    //MDIO数据输入
//将PHY_CLK的分频系数除以2,得到dri_clk的分频系数,方便对MDC和MDIO信号操作
assign clk_divide = CLK_DIV >> 1;

//分频得到dri_clk时钟
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dri_clk <=  1'b0;
        clk_cnt <= 1'b0;
    end
    else if(clk_cnt == clk_divide[5:1] - 1'd1) begin
        clk_cnt <= 1'b0;
        dri_clk <= ~dri_clk;
    end
    else
        clk_cnt <= clk_cnt + 1'b1;
end

//产生PHY_MDC时钟
always @(posedge dri_clk or negedge rst_n) begin
    if(!rst_n)
        eth_mdc <= 1'b1;
    else if(cnt[0] == 1'b0)
        eth_mdc <= 1'b1;
    else    
        eth_mdc <= 1'b0;  
end

//(三段式状态机)同步时序描述状态转移
always @(posedge dri_clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end  

//组合逻辑判断状态转移条件
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle : begin
            if(op_exec)
                next_state = st_pre;
            else 
                next_state = st_idle;   
        end  
        st_pre : begin
            if(st_done)
                next_state = st_start;
            else
                next_state = st_pre;
        end
        st_start : begin
            if(st_done)
                next_state = st_addr;
            else
                next_state = st_start;
        end
        st_addr : begin
            if(st_done) begin
                if(op_code == 2'b01)                //MDIO接口写操作  
                    next_state = st_wr_data;
                else
                    next_state = st_rd_data;        //MDIO接口读操作  
            end
            else
                next_state = st_addr;
        end
        st_wr_data : begin
            if(st_done)
                next_state = st_idle;
            else
                next_state = st_wr_data;
        end        
        st_rd_data : begin
            if(st_done)
                next_state = st_idle;
            else
                next_state = st_rd_data;
        end                                                                          
        default : next_state = st_idle;
    endcase
  end

//时序电路描述状态输出
always @(posedge dri_clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 5'd0;
        op_code <= 2'd0;
        addr_t <= 5'd0;
        wr_data_t <= 16'd0;
        rd_data_t <= 16'd0;
        op_done <= 1'b0;
        st_done <= 1'b0; 
        op_rd_data <= 16'd0;
        op_rd_ack <= 1'b1;
        mdio_dir <= 1'b0;
        mdio_out <= 1'b1;
    end
    else begin
        st_done <= 1'b0 ;                            
        cnt     <= cnt +1'b1 ;          
        case(cur_state)
            st_idle : begin
                mdio_out <= 1'b1;                     
                mdio_dir <= 1'b0;                     
                op_done <= 1'b0;                     
                cnt <= 7'b0;  
                if(op_exec) begin
                    op_code <= {op_rh_wl,~op_rh_wl}; //OP_CODE: 2'b01(写)  2'b10(读) 
                    addr_t <= op_addr;
                    wr_data_t <= op_wr_data;
                    op_rd_ack <= 1'b1;
                end     
            end 
            st_pre : begin                          //发送前导码:32个1bit 
                mdio_dir <= 1'b1;                   //切换MDIO引脚方向:输出
                mdio_out <= 1'b1;                   //MDIO引脚输出高电平
                if(cnt == 7'd62) 
                    st_done <= 1'b1;
                else if(cnt == 7'd63)
                    cnt <= 7'b0;
            end            
            st_start  : begin
                case(cnt)
                    7'd1 : mdio_out <= 1'b0;        //发送开始信号 2'b01
                    7'd3 : mdio_out <= 1'b1; 
                    7'd5 : mdio_out <= op_code[1];  //发送操作码
                    7'd6 : st_done <= 1'b1;
                    7'd7 : begin
                               mdio_out <= op_code[0];
                               cnt <= 7'b0;  
                           end    
                    default : ;
                endcase
            end    
            st_addr : begin
                case(cnt)
                    7'd1 : mdio_out <= PHY_ADDR[4]; //发送PHY地址
                    7'd3 : mdio_out <= PHY_ADDR[3];
                    7'd5 : mdio_out <= PHY_ADDR[2];
                    7'd7 : mdio_out <= PHY_ADDR[1];  
                    7'd9 : mdio_out <= PHY_ADDR[0];
                    7'd11: mdio_out <= addr_t[4];  //发送寄存器地址
                    7'd13: mdio_out <= addr_t[3];
                    7'd15: mdio_out <= addr_t[2];
                    7'd17: mdio_out <= addr_t[1];  
                    7'd18: st_done <= 1'b1;
                    7'd19: begin
                               mdio_out <= addr_t[0]; 
                               cnt <= 7'd0;
                           end    
                    default : ;
                endcase                
            end    
            st_wr_data : begin
                case(cnt)
                    7'd1 : mdio_out <= 1'b1;         //发送TA,写操作(2'b10)
                    7'd3 : mdio_out <= 1'b0;
                    7'd5 : mdio_out <= wr_data_t[15];//发送写寄存器数据
                    7'd7 : mdio_out <= wr_data_t[14];
                    7'd9 : mdio_out <= wr_data_t[13];
                    7'd11: mdio_out <= wr_data_t[12];
                    7'd13: mdio_out <= wr_data_t[11];
                    7'd15: mdio_out <= wr_data_t[10];
                    7'd17: mdio_out <= wr_data_t[9];
                    7'd19: mdio_out <= wr_data_t[8];
                    7'd21: mdio_out <= wr_data_t[7];
                    7'd23: mdio_out <= wr_data_t[6];
                    7'd25: mdio_out <= wr_data_t[5];
                    7'd27: mdio_out <= wr_data_t[4];
                    7'd29: mdio_out <= wr_data_t[3];
                    7'd31: mdio_out <= wr_data_t[2];
                    7'd33: mdio_out <= wr_data_t[1];
                    7'd35: mdio_out <= wr_data_t[0];
                    7'd37: begin
                        mdio_dir <= 1'b0;
                        mdio_out <= 1'b1;
                    end
                    7'd39: st_done <= 1'b1;           
                    7'd40: begin
                               cnt <= 7'b0;
                               op_done <= 1'b1;      //写操作完成,拉高op_done信号 
                           end    
                    default : ;
                endcase    
            end
            st_rd_data : begin
                case(cnt)
                    7'd1 : begin
                        mdio_dir <= 1'b0;            //MDIO引脚切换至输入状态
                        mdio_out <= 1'b1;
                    end
                    7'd2 : ;                         //TA[1]位,该位为高阻状态,不操作             
                    7'd4 : op_rd_ack <= mdio_in;     //TA[0]位,0(应答) 1(未应答)
                    7'd6 : rd_data_t[15] <= mdio_in; //接收寄存器数据
                    7'd8 : rd_data_t[14] <= mdio_in;
                    7'd10: rd_data_t[13] <= mdio_in;
                    7'd12: rd_data_t[12] <= mdio_in;
                    7'd14: rd_data_t[11] <= mdio_in;
                    7'd16: rd_data_t[10] <= mdio_in;
                    7'd18: rd_data_t[9] <= mdio_in;
                    7'd20: rd_data_t[8] <= mdio_in;
                    7'd22: rd_data_t[7] <= mdio_in;
                    7'd24: rd_data_t[6] <= mdio_in;
                    7'd26: rd_data_t[5] <= mdio_in;
                    7'd28: rd_data_t[4] <= mdio_in;
                    7'd30: rd_data_t[3] <= mdio_in;
                    7'd32: rd_data_t[2] <= mdio_in;
                    7'd34: rd_data_t[1] <= mdio_in;
                    7'd36: rd_data_t[0] <= mdio_in;
                    7'd39: st_done <= 1'b1;
                    7'd40: begin
                        op_done <= 1'b1;             //读操作完成,拉高op_done信号          
                        op_rd_data <= rd_data_t;
                        rd_data_t <= 16'd0;
                        cnt <= 7'd0;
                    end
                    default : ;
                endcase   
            end                
            default : ;
        endcase               
    end
end                    

endmodule