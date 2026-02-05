#ifndef  __SDRAM_H
#define	__SDRAM_H

#include "stm32h7xx_hal.h"
#include "usart.h"

#define SDRAM_Size 16*1024*1024  //16M字节

#define SDRAM_BANK_ADDR     ((uint32_t)0xC0000000) 				// FMC SDRAM 数据基地址
#define FMC_COMMAND_TARGET_BANK   FMC_SDRAM_CMD_TARGET_BANK1	//	SDRAM 的bank选择
#define SDRAM_TIMEOUT     ((uint32_t)0x1000) 						// 超时判断时间

#define SDRAM_MODEREG_BURST_LENGTH_1             ((uint16_t)0x0000)
#define SDRAM_MODEREG_BURST_LENGTH_2             ((uint16_t)0x0001)
#define SDRAM_MODEREG_BURST_LENGTH_4             ((uint16_t)0x0002)
#define SDRAM_MODEREG_BURST_LENGTH_8             ((uint16_t)0x0004)
#define SDRAM_MODEREG_BURST_TYPE_SEQUENTIAL      ((uint16_t)0x0000)
#define SDRAM_MODEREG_BURST_TYPE_INTERLEAVED     ((uint16_t)0x0008)
#define SDRAM_MODEREG_CAS_LATENCY_2              ((uint16_t)0x0020)
#define SDRAM_MODEREG_CAS_LATENCY_3              ((uint16_t)0x0030)
#define SDRAM_MODEREG_OPERATING_MODE_STANDARD    ((uint16_t)0x0000)
#define SDRAM_MODEREG_WRITEBURST_MODE_PROGRAMMED ((uint16_t)0x0000) 
#define SDRAM_MODEREG_WRITEBURST_MODE_SINGLE     ((uint16_t)0x0200) 

/*--------------------------------------- 函数声明 -------------------------------------*/

void SDRAM_Initialization_Sequence(SDRAM_HandleTypeDef *hsdram);	// 配置SDRAM相关时序和控制方式

uint8_t SDRAM_Test(void);	// SDRAM读写测试


#endif 

