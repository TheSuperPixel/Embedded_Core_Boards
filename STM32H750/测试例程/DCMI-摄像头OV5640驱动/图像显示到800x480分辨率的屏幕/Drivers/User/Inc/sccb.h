#ifndef __CAMERA_SCCB_H
#define __CAMERA_SCCB_H

#include "stm32h7xx_hal.h"

#define OV2640_DEVICE_ADDRESS     0x60    // OV2640地址
#define OV5640_DEVICE_ADDRESS     0X78		// OV5640地址

/*----------------------------------------- IIIC 引脚配置宏 -----------------------------------------------*/

#define SCCB_SCL_CLK_ENABLE       __HAL_RCC_GPIOG_CLK_ENABLE()		// SCL 引脚时钟
#define SCCB_SCL_PORT   		   GPIOG                 				// SCL 引脚端口
#define SCCB_SCL_PIN     		   GPIO_PIN_2  							// SCL 引脚
        
#define SCCB_SDA_CLK_ENABLE       __HAL_RCC_GPIOG_CLK_ENABLE() 	// SDA 引脚时钟
#define SCCB_SDA_PORT   			 GPIOG                  			// SDA 引脚端口
#define SCCB_SDA_PIN    			 GPIO_PIN_3              			// SDA 引脚

/*------------------------------------------ IIC相关定义 -------------------------------------------------*/

#define ACK_OK  	1  			// 响应正常
#define ACK_ERR 	0				// 响应错误

// SCCB通信延时，SCCB_Delay()函数使用，
//	通信速度在300KHz左右
#define SCCB_DelayVaule  8  	

/*-------------------------------------------- IO口操作 ---------------------------------------------------*/   

#define SCCB_SCL(a)	if (a)	\
										HAL_GPIO_WritePin(SCCB_SCL_PORT, SCCB_SCL_PIN, GPIO_PIN_SET); \
									else		\
										HAL_GPIO_WritePin(SCCB_SCL_PORT, SCCB_SCL_PIN, GPIO_PIN_RESET)	

#define SCCB_SDA(a)	if (a)	\
										HAL_GPIO_WritePin(SCCB_SDA_PORT, SCCB_SDA_PIN, GPIO_PIN_SET); \
									else		\
										HAL_GPIO_WritePin(SCCB_SDA_PORT, SCCB_SDA_PIN, GPIO_PIN_RESET)		

/*--------------------------------------------- 函数声明 --------------------------------------------------*/  		
					
void 		SCCB_GPIO_Config (void);				// IIC引脚初始化
void 		SCCB_Delay(uint32_t a);					// IIC延时函数						
void 		SCCB_Start(void);							// 启动IIC通信
void 		SCCB_Stop(void);							// IIC停止信号
void 		SCCB_ACK(void);							//	发送响应信号
void 		SCCB_NoACK(void);							// 发送非应答信号
uint8_t 	SCCB_WaitACK(void);						//	等待应答信号
uint8_t	SCCB_WriteByte(uint8_t IIC_Data); 	// 写字节函数
uint8_t 	SCCB_ReadByte(uint8_t ACK_Mode);		// 读字节函数
		
uint8_t  SCCB_WriteReg (uint8_t addr,uint8_t value);     // 对指定的寄存器写一字节数据
uint8_t  SCCB_ReadReg (uint8_t addr);                    // 对指定的寄存器读取一字节数据

																	
uint8_t 	SCCB_WriteReg_16Bit(uint16_t addr,uint8_t value);	// 对指定的寄存器(16位地址)写一字节数据，OV5640用到									
uint8_t 	SCCB_ReadReg_16Bit (uint16_t addr);						// 对指定的寄存器(16位地址)读一字节数据，OV5640用到
uint8_t 	SCCB_WriteBuffer_16Bit(uint16_t addr,uint8_t *pData, uint32_t size);	// 对指定的寄存器(16位地址)批量写数据，OV5640 写入自动对焦固件时用到		
						
#endif //__CAMERA_SCCB_H
