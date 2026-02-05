#ifndef __DCMI_OV5640_H
#define __DCMI_OV5640_H

#include "stm32h7xx_hal.h"
#include "sccb.h"  
#include "usart.h"
#include "lcd_rgb.h"
#include <string.h>

 // DCMI状态标志，当数据帧传输完成时，会被 HAL_DCMI_FrameEventCallback() 中断回调函数置 1 

extern volatile uint8_t 	OV5640_FrameState;  	// DCMI状态标志，当数据帧传输完成时，会被 HAL_DCMI_FrameEventCallback() 中断回调函数置 1 
extern volatile uint8_t 	OV5640_FPS ;      	// 帧率
extern volatile uint16_t 	OV5640_BufferCount;  // 缓冲计数


#define Frame_Buffer		(SDRAM_BANK_ADDR + LCD_Width * LCD_Height * BytesPerPixel_0  )    // 完整的画面存储区

// 摄像头图像缓冲区，用于缓存摄像头DMA接收的数据
#define Camera_Buffer	0x24000000   

// 用于设置输出的格式，被 OV5640_Set_Pixformat() 引用
#define 	Pixformat_RGB565   0
#define 	Pixformat_JPEG     1
#define 	Pixformat_GRAY		 2

#define  OV5640_AF_Focusing     	2           // 正在处于自动对焦中
#define  OV5640_AF_End				1				// 自动对焦结束
#define  OV5640_Success   			0           // 通讯成功标志
#define  OV5640_Error     			-1          // 通讯错误

#define  OV5640_Enable    1
#define  OV5640_Disable   0


// OV5640的特效模式，被 OV5640_Set_Effect() 引用
#define  OV5640_Effect_Normal       0  // 正常模式
#define  OV5640_Effect_Negative     1  // 负片模式，也就是颜色全部取反
#define  OV5640_Effect_BW           2  // 黑白模式
#define  OV5640_Effect_Solarize  	3  // 正负片叠加模式

// 1. 定义OV5640实际输出的图像大小，可以根据实际的应用或者显示屏进行调整
// 2. 这两个参数不会影响帧率
// 3. 因为配置的OV5640的ISP窗口比例为16:9(1920*1080，30帧)，用户设置的输出尺寸也应满足这个比例
// 4. 如果需要其它比例，需要修改初始化配置里的参数
#define 	OV5640_Width          880   // 图像长度 
#define 	OV5640_Height         495   // 图像宽度

// 1. 定义要显示的画面大小，数值一定要能被4整除！！
// 2. RGB565格式下，最终会由DCMI将OV5640输出的16:9图像裁剪为适应屏幕的比例
// 3. JPG模式下，数值一定要能被8整除！！
#define 	Display_Width          LCD_Width   		// 要显示的 图像长度 
#define 	Display_Height         LCD_Height   	// 要显示的 图像宽度

// 单次DMA传输的 图像宽度，也就是每次DMA只传输 96行
// 注意，因为本例程使用的是DMA双缓冲传输，因此实际需要占用的 96*2=192行的大小
#define 	DMA_Height         96 		

/*------------------------------------------------------------ 常用寄存器 ------------------------------------------------*/

#define 	OV5640_ChipID_H          	0x300A  	// 芯片ID寄存器 高字节
#define 	OV5640_ChipID_L          	0x300B  	// 芯片ID寄存器 低字节

#define	OV5640_FORMAT_CONTROL		0x4300	// 设置数据接口输出的格式	
#define 	OV5640_FORMAT_CONTROL_MUX  0x501F	// 设置ISP的格式

#define	OV5640_JPEG_MODE_SELECT		0x4713	// JPEG模式选择，有1~6模式，用户可数据手册里的说明
#define	OV5640_JPEG_VFIFO_CTRL00 	0x4600	// 用于设置JPEG模式2是否固定输出宽度
#define	OV5640_JPEG_VFIFO_HSIZE_H	0x4602	// JPEG输出水平尺寸,高字节
#define	OV5640_JPEG_VFIFO_HSIZE_L	0x4603	// JPEG输出水平尺寸,低字节
#define	OV5640_JPEG_VFIFO_VSIZE_H	0x4604	// JPEG输出垂直尺寸,低字节
#define	OV5640_JPEG_VFIFO_VSIZE_L	0x4605	// JPEG输出垂直尺寸,低字节

#define 	OV5640_GroupAccess			0X3212	// 寄存器组访问
#define 	OV5640_TIMING_DVPHO_H		0x3808	// 输出水平尺寸,高字节
#define 	OV5640_TIMING_DVPHO_L		0x3809	// 输出水平尺寸,低字节
#define 	OV5640_TIMING_DVPVO_H		0x380A	// 输出垂直尺寸,高字节
#define 	OV5640_TIMING_DVPVO_L		0x380B   // 输出垂直尺寸,低字节
#define 	OV5640_TIMING_Flip			0x3820	// Bit[2:1]用于设置是否垂直翻转
#define 	OV5640_TIMING_Mirror			0x3821	// Bit[2:1]用于设置是否水平镜像

#define 	OV5640_AF_CMD_MAIN			0x3022	// AF 主命令
#define 	OV5640_AF_CMD_ACK				0x3023	// AF 命令确认
#define 	OV5640_AF_FW_STATUS			0x3029	// 对焦状态寄存器

/*------------------------------------------------------------ 函数声明 ------------------------------------------------*/

int8_t   DCMI_OV5640_Init(void);	// 初始SCCB、DCMI、DMA以及配置OV5640

void     OV5640_DMA_Transmit_Continuous(uint32_t DMA_Buffer,uint32_t DMA_BufferSize);	// 启动DMA传输，连续模式
void     OV5640_DMA_Transmit_Snapshot(uint32_t DMA_Buffer,uint32_t DMA_BufferSize);		//  启动DMA传输，快照模式，传输一帧图像后停止
void     OV5640_DCMI_Suspend(void);		// 挂起DCMI，停止捕获数据
void     OV5640_DCMI_Resume(void);		// 恢复DCMI，开始捕获数据
void     OV5640_DCMI_Stop(void);			// 禁止DCMI的DMA请求，停止DCMI捕获，禁止DCMI外设
int8_t 	OV5640_DCMI_Crop(uint16_t Displey_XSize,uint16_t Displey_YSize,uint16_t Sensor_XSize,uint16_t Sensor_YSize ); // 裁剪画面

void     OV5640_Reset(void);				//	执行软件复位
uint16_t OV5640_ReadID(void);				// 读取器件ID
void		OV5640_Config(void);				// 配置OV5640各项参数
	
void		OV5640_Set_Pixformat(uint8_t pixformat);					// 设置图像输出格式	
void 		OV5640_Set_JPEG_QuantizationScale(uint8_t scale);		// 设置JPEG格式的压缩等级,取值 0x01~0x3F
int8_t 	OV5640_Set_Framesize(uint16_t width,uint16_t height);	// 设置实际输出的图像大小
int8_t 	OV5640_Set_Horizontal_Mirror( int8_t ConfigState );	// 用于设置输出的图像是否进行水平镜像
int8_t 	OV5640_Set_Vertical_Flip( int8_t ConfigState );			//	用于设置输出的图像是否进行垂直翻转 
void 		OV5640_Set_Brightness(int8_t Brightness);					// 设置亮度
void		OV5640_Set_Contrast(int8_t Contrast);						// 设置对比度
void 		OV5640_Set_Effect(uint8_t effect_Mode);					// 用于设置特效，正常、负片等模式

int8_t 	OV5640_AF_Download_Firmware(void);		//	将自动对焦固件写入OV5640
int8_t 	OV5640_AF_QueryStatus(void);				//	对焦状态查询
void 		OV5640_AF_Trigger_Constant(void);		// 自动对焦 ，持续 触发
void 		OV5640_AF_Trigger_Single(void);			// 自动对焦 ，触发 单次 
void 		OV5640_AF_Release(void);					// 释放马达，镜头回到初始（对焦为无穷远处）位置

/*-------------------------------------------------------------- 引脚配置宏 ---------------------------------------------*/

#define OV5640_PWDN_PIN            			 GPIO_PIN_7       				 	// PWDN 引脚      
#define OV5640_PWDN_PORT           			 GPIOG                 			 	// PWDN GPIO端口     
#define GPIO_OV5640_PWDN_CLK_ENABLE    	__HAL_RCC_GPIOG_CLK_ENABLE() 		// PWDN GPIO端口时钟

// 低电平，不开启掉电模式，摄像头正常工作
#define	OV5640_PWDN_OFF	HAL_GPIO_WritePin(OV5640_PWDN_PORT, OV5640_PWDN_PIN, GPIO_PIN_RESET)	

// 高电平，进入掉电模式，摄像头停止工作，此时功耗降到最低
#define 	OV5640_PWDN_ON		HAL_GPIO_WritePin(OV5640_PWDN_PORT, OV5640_PWDN_PIN, GPIO_PIN_SET)	
  
 
 
#endif //__DCMI_OV5640_H




