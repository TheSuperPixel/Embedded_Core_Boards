//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           touch_dri
// Created by:          正点原子
// Created date:        2023年5月24日14:17:02
// Version:             V1.0
// Descriptions:        LCD触摸驱动
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module touch_dri #(parameter   WIDTH = 4'd8) //一次读写寄存器的个数的位宽
(
    input                   clk          , //时钟信号
    input                   rst_n        , //复位信号（低有效）
    //I2C用户端口                        
    output  reg [6:0]       slave_addr   , //i2c器件地址
    output  reg             i2c_exec     , //i2c触发控制
    output  reg             i2c_rh_wl    , //i2c读写控制
    output  reg [15:0]      i2c_addr     , //i2c操作地址
    output  reg [7:0]       i2c_data_w   , //i2c写入的数据
    output  reg             bit_ctrl     , //字地址位控制(0:8b,1:16b)
    output  reg [WIDTH-1:0] reg_num      , //一次读写寄存器的个数
                                         
    input       [7:0]       i2c_data_r    , //i2c读出的数据
    input                   i2c_ack       , //i2c应答信号
    input                   i2c_done      , //i2c操作结束标志
    input                   once_byte_done, //一字节数据读/写操作完成
                                          
    //LCD相关端口                         
    input       [15:0]      lcd_id       , //LCD ID
    output  reg [31:0]      data         , //触摸点的坐标数据
    output  reg             touch_rst_n  , //触摸屏复位
    inout                   touch_int      //INT信号
 );

//parameter define
//FT系列
localparam FT_SLAVE_ADDR    = 7'h38;     //FT系列器件地址
localparam FT_BIT_CTRL      = 1'b0;      //FT系列位控制
                                         
localparam FT_ID_LIB_VERSION= 8'hA1;     //版本
localparam FT_DEVIDE_MODE   = 8'h00;     //模式控制寄存器
localparam FT_ID_MODE       = 8'hA4;     //FT中断模式控制寄存器
localparam FT_ID_THGROUP    = 8'h80;     //触摸有效值设置寄存器
localparam FT_ID_PERIOD_ACT = 8'h88;     //激活状态周期设置寄存器
localparam FT_STATE_REG     = 8'h02;     //触摸状态寄存器
localparam FT_TP1_REG       = 8'h03;     //第一个触摸点数据地址

//GT系列
localparam GT_SLAVE_ADDR    = 7'h14;     //GT系列器件地址
localparam GT_BIT_CTRL      = 1'b1;      //GT系列位控制

localparam GT_STATE_REG     = 16'h814E;  //触摸状态寄存器
localparam GT_TP1_REG       = 16'h8150;  //第一个触摸点数据地址

localparam st_idle          = 7'b000_0001;//空闲状态
localparam st_init          = 7'b000_0010;//上电初始化
localparam st_get_id        = 7'b000_0100;//获取触摸芯片ID
localparam st_cfg_reg       = 7'b000_1000;//配置寄存器
localparam st_check_touch   = 7'b001_0000;//检测触摸状态
localparam st_get_coord     = 7'b010_0000;//获取触摸点坐标
localparam st_coord_handle  = 7'b100_0000;//针对不同尺寸的触摸的坐标数据进行处理

//reg define
reg                 touch_int_dir; //INT数据方向控制信号
reg                 touch_int_out; //INT数据输出

reg    [6:0]        cur_state   ;  //当前状态
reg    [6:0]        next_state  ;  //次态

reg                 cnt_time_en ;  //使能计时
reg    [19:0]       cnt_time    ;  //计时计数器
reg    [15:0]       chip_version;  //芯片版本号
reg                 ft_flag     ;  //FT系列芯片的标志
reg    [15:0]       touch_s_reg ;  //触摸状态寄存器
reg    [15:0]       coord_reg   ;  //触摸点坐标寄存器
reg    [15:0]       tp_x_coord_t;  //X方向触摸点临时坐标
reg    [15:0]       tp_y_coord_t;  //Y方向触摸点临时坐标
reg    [3:0]        flow_cnt    ;  //流程计数器
reg                 st_done     ;  //操作完成信号
reg    [15:0]       tp_x_coord  ;  //X方向触摸点的坐标
reg    [15:0]       tp_y_coord  ;  //Y方向触摸点的坐标
reg                 touch_valid ;  //触摸标志（0：未检测到触摸，1：检测到触摸）

//wire define
wire          touch_int_in ;      //INT数据输入
//*****************************************************
//**                    main code
//*****************************************************
//控制INT信号输入/输出
assign touch_int = touch_int_dir ? touch_int_out : 1'bz;
assign touch_int_in = touch_int;

//计时控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_time <= 20'd0;
    end
    else if(cnt_time_en)
        cnt_time <= cnt_time + 1'b1;
    else
        cnt_time <= 20'd0;
end

//触摸坐标数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data <= 32'd0;
    end
    else if(touch_valid)
        data <= {tp_x_coord,tp_y_coord};
    else
        data <= data;
end

//状态跳转
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end

//组合逻辑状态判断转换条件
always @(*) begin
    case(cur_state)
        st_idle : begin
            if(st_done)
                next_state = st_init;
            else 
                next_state = st_idle;
        end
        st_init : begin
            if(st_done)
                next_state = st_get_id; 
            else
                next_state = st_init;
        end
        st_get_id : begin
            if(st_done) begin
                if(ft_flag)  //仅FT系列需要配置寄存器
                    next_state = st_cfg_reg;
                else
                    next_state = st_check_touch;
            end
            else
                next_state = st_get_id;
        end       
        st_cfg_reg : begin
            if(st_done)
                next_state = st_check_touch;
            else
                next_state = st_cfg_reg;
        end
        st_check_touch: begin
            if(st_done)
                next_state = st_get_coord;
            else
                next_state = st_check_touch;
        end
        st_get_coord : begin
            if(st_done)
                next_state = st_coord_handle;
            else
                next_state = st_get_coord;
        end
        st_coord_handle : begin
            if(st_done)
                next_state = st_check_touch;
            else
                next_state = st_coord_handle;
        end
        default: next_state = st_idle;
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_time_en  <= 1'b0;
        chip_version <= 1'b0;
        ft_flag      <= 1'b0;
        touch_s_reg  <= 1'b0;
        coord_reg    <= 1'b0;
        tp_x_coord_t <= 1'b0;
        tp_y_coord_t <= 1'b0;
        flow_cnt     <= 1'b0;
        st_done      <= 1'b0;
        touch_int_dir<= 1'b0;
        touch_int_out<= 1'b0;
        
        slave_addr   <= 1'b0;
        i2c_exec     <= 1'b0;
        i2c_rh_wl    <= 1'b0;
        i2c_addr     <= 16'b0;
        i2c_data_w   <= 1'b0;
        bit_ctrl     <= 1'b0;
        reg_num      <= 1'b0;
        
        touch_valid  <= 1'b0;
        tp_x_coord   <= 1'b0;
        tp_y_coord   <= 1'b0;
        touch_rst_n  <= 1'b0;
    end
    else begin
        i2c_exec <= 1'b0;
        st_done <= 1'b0;
        case(next_state)
            st_idle : begin
                cnt_time_en   <= 1'b1;
                touch_int_dir <= 1'b1;   //TOUCH INT端口方向设置为输出
                touch_int_out <= 1'b1;   //TOUCH INT端口输出高电平
                if(cnt_time >= 10) begin
                    st_done     <= 1'b1;
                    cnt_time_en <= 1'b0;
                end
            end
            st_init : begin
                cnt_time_en <= 1'b1;
                if(cnt_time < 10_000)             //延时10ms
                    touch_rst_n <= 1'b0;             //开始复位
                else if(cnt_time == 10_000)
                    touch_rst_n <= 1'b1;             //结束复位
                else if(cnt_time == 60_000) begin //再次延时50ms(60_000-10_000)
                    touch_int_dir <= 1'b0;           //将INT引脚设置为浮空输入
                    cnt_time_en   <= 1'b0;
                    st_done       <= 1'b1;
                    flow_cnt      <= 'd0;
                end    
            end
            st_get_id : begin  //获取触摸芯片ID，读触摸芯片版本号
                case(flow_cnt)
                    'd0 : begin
                        //根据屏幕ID，判断这几款屏幕是GT系列
                        if(lcd_id == 16'h4384 || lcd_id == 16'h4342 || 
                        lcd_id == 16'h1018) begin 
                            flow_cnt <= 'd5;
                            ft_flag  <= 1'b0; //ft_flag=0,说明触摸芯片为GT系列 
                        end    
                        else
                            flow_cnt <= flow_cnt + 1'b1;
                    end
                    'd1 : begin  //读FT系列版本号
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b1;
                        i2c_addr   <= FT_ID_LIB_VERSION;
                        reg_num    <= 'd2;
                        slave_addr <= FT_SLAVE_ADDR;
                        bit_ctrl   <= FT_BIT_CTRL;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd2 : begin 
                        if(once_byte_done) begin
                            chip_version[15:8] <= i2c_data_r;
                            flow_cnt <= flow_cnt + 1'b1;
                        end    
                        else if(i2c_done && i2c_ack) begin  //未应答,说明是GT系列
                            chip_version = "GT";
                            flow_cnt <= 'd4;
                        end
                    end
                    'd3 : begin
                        if(i2c_done) begin
                            chip_version[7:0] <= i2c_data_r;
                            flow_cnt <= flow_cnt + 1'b1;
                        end
                    end
                    'd4 : begin
                        flow_cnt <= flow_cnt + 1'b1;
                        //FT系列版本:0X3003/0X0001/0X0002/CST340
                        if(chip_version == 16'h3003 || chip_version == 16'h0001
                        || chip_version == 16'h0002 || chip_version == 16'h0000)
                            ft_flag <= 1'b1;         //ft_flag=1,说明触摸芯片为FT系列
                        else 
                            ft_flag <= 1'b0;         //ft_flag=0,说明触摸芯片为GT系列
                    end
                    'd5 : begin //根据对应系列配置参数
                        st_done <= 1'b1;
                        flow_cnt <= 'd0;
                        if(ft_flag) begin                 //将参数配置为FT系列
                            touch_s_reg <= FT_STATE_REG;  //触摸状态寄存器（0X02）
                            coord_reg   <= FT_TP1_REG;    //第一个触摸点数据地址
                            bit_ctrl    <= FT_BIT_CTRL;   //FT系列位控制
                            slave_addr  <= FT_SLAVE_ADDR; //FT系列器件地址
                        end
                        else begin                        //将参数配置为GT系列
                            touch_s_reg <= GT_STATE_REG;  //状态寄存器（0X814E）
                            coord_reg   <= GT_TP1_REG;    //第一个触摸点数据地址
                            bit_ctrl    <= GT_BIT_CTRL;   //GT系列位控制
                            slave_addr  <= GT_SLAVE_ADDR; //GT系列器件地址
                        end
                    end
                    default :;
                endcase    
            end
            st_cfg_reg : begin
                case(flow_cnt)
                    //配置FT系列
                    'd0 : begin
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b0;
                        i2c_addr   <= FT_DEVIDE_MODE;//工作模式寄存器（0X00）
                        i2c_data_w <= 8'd0;          //进入正常模式
                        reg_num    <= 'd1;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd1 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0)      //I2C应答
                                flow_cnt <= flow_cnt + 1'b1;
                            else                     //I2C未应答
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    'd2 : begin
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b0;
                        i2c_addr   <= FT_ID_MODE;      //中断状态控制寄存器（0XA4）
                        i2c_data_w <= 8'd0;            //查询模式
                        reg_num    <= 'd1;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd3 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0)      //I2C应答
                                flow_cnt <= flow_cnt + 1'b1;
                            else                     //I2C未应答
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    'd4 : begin
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b0;
                        i2c_addr   <= FT_ID_THGROUP; //有效触摸门限控制寄存器（0X80）
                        i2c_data_w <= 8'd22;         //设置触摸有效值,值越小,越灵敏
                        reg_num    <= 'd1;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd5 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0)      //I2C应答
                                flow_cnt <= flow_cnt + 1'b1;
                            else                     //I2C未应答
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    'd6 : begin
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b0;
                        i2c_addr   <= FT_ID_PERIOD_ACT;//激活周期控制寄存器（0X88）
                        i2c_data_w <= 8'd12;           //激活周期
                        reg_num    <= 'd1;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd7 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0) begin//I2C应答
                                flow_cnt <= 'd0;
                                st_done  <= 1'b1;
                            end    
                            else                     //I2C未应答
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    default : ;
                endcase
            end
            st_check_touch : begin
                case(flow_cnt)
                    'd0: begin  //延时
                        cnt_time_en <= 1'b1;
                        if(cnt_time == 20_000) begin
                            flow_cnt    <= flow_cnt + 1'b1;
                            cnt_time_en <= 1'b0;
                        end    
                    end        
                    'd1 : begin
                        i2c_exec  <= 1'b1;
                        i2c_rh_wl <= 1'b1;
                        i2c_addr  <= touch_s_reg;     //读取触摸点状态
                        reg_num   <= 'd1;
                        flow_cnt  <= flow_cnt + 1'b1;
                    end
                    'd2 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0)
                                flow_cnt <= flow_cnt + 1'b1;
                            else
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    'd3 : begin    //读状态寄存器（0X814E），最低4位用于表示有效触点的个数，范围是：0~5，0表示没有触摸，5表示有5点触摸
                        flow_cnt <= flow_cnt + 1'b1;
                        if(ft_flag) begin
                            if(i2c_data_r[3:0] > 4'd0 && i2c_data_r[3:0] <= 4'd5)
                                touch_valid <= 1'b1; //检测到触摸 
                            else
                                touch_valid <= 1'b0; //未检测到触摸
                        end
                        else begin
                            if(i2c_data_r[7]== 1'b1 && i2c_data_r[3:0] > 4'd0 
                            && i2c_data_r[3:0] <= 4'd5) begin      
                                touch_valid <= 1'b1; //检测到触摸 
                            end
                            else 
                                touch_valid <= 1'b0; //未检测到触摸
                        end
                    end
                    'd4 : begin
                        i2c_exec   <= 1'b1;
                        i2c_rh_wl  <= 1'b0;
                        i2c_addr   <= touch_s_reg;
                        i2c_data_w <= 8'd0;          //清除触摸标志
                        reg_num    <= 'd1;
                        flow_cnt   <= flow_cnt + 1'b1;
                    end
                    'd5 : begin
                        if(i2c_done) begin
                            if(i2c_ack == 1'b0) begin
                                st_done  <= touch_valid;
                                flow_cnt <= 1'b0;
                            end
                            else
                                flow_cnt <= flow_cnt - 1'b1;
                        end
                    end
                    default : ;
                endcase
            end
            st_get_coord : begin
                case(flow_cnt)
                    'd0 : begin
                        i2c_exec  <= 1'b1;
                        i2c_rh_wl <= 1'b1;
                        i2c_addr  <= coord_reg;       //获取X和Y方向坐标点
                        reg_num   <= 'd4;             //连续读四个寄存器
                        flow_cnt  <= flow_cnt + 1'b1;
                    end
                    'd1 : begin
                        if(once_byte_done) begin
                            if(i2c_ack == 1'b0) begin
                                tp_x_coord_t[7:0] <= i2c_data_r;
                                flow_cnt <= flow_cnt + 1'b1;
                            end
                            else
                                flow_cnt <= 1'b0;
                        end
                    end
                    'd2 : begin
                        if(once_byte_done) begin
                            flow_cnt <= flow_cnt + 1'b1;
                            tp_x_coord_t[15:8] <= i2c_data_r;
                        end
                    end
                    'd3 : begin
                        if(once_byte_done) begin
                            flow_cnt <= flow_cnt + 1'b1;
                            tp_y_coord_t[7:0] <= i2c_data_r;
                        end
                    end    
                    'd4 : begin
                        if(once_byte_done) begin
                            st_done  <= 1'b1;
                            flow_cnt <= 'd0;
                            tp_y_coord_t[15:8] <= i2c_data_r;
                        end
                    end
                    default:;
                endcase
            end
            st_coord_handle : begin
                st_done <= 1'b1;
                if(ft_flag) begin                    //FT系列需对数据做处理
                    tp_x_coord <= {4'd0,tp_y_coord_t[3:0],tp_y_coord_t[15:8]};
                    tp_y_coord <= {4'd0,tp_x_coord_t[3:0],tp_x_coord_t[15:8]};
                end
                else begin
                    tp_x_coord <= tp_x_coord_t;
                    tp_y_coord <= tp_y_coord_t;
                end
            end
            default : ;
        endcase
    end
end

endmodule 
