/***
	************************************************************************************************
	*	@version V1.0
	*  @date    2024-4-19
	*	@author  反客科技
   ************************************************************************************************
   *  @description
	*
	*	实验平台：反客STM32H750XBH6核心板 （型号：FK750M6-XBH6）
	*	淘宝地址：https://shop212360197.taobao.com
	*	QQ交流群：536665479
	*
>>>>> 文件说明：
	*
	*  SDRAM相关初始化函数
	*
	************************************************************************************************
***/

#include "sdram.h"   

FMC_SDRAM_CommandTypeDef *Command;	// 控制指令

/******************************************************************************************************
*	函 数 名: SDRAM_Initialization_Sequence
*	入口参数: hsdram - SDRAM_HandleTypeDef定义的变量，即表示定义的sdram
*				 Command	- 控制指令
*	返 回 值: 无
*	函数功能: SDRAM 参数配置
*	说    明: 配置SDRAM相关时序和控制方式
*******************************************************************************************************/

void SDRAM_Initialization_Sequence(SDRAM_HandleTypeDef *hsdram)
{
	__IO uint32_t tmpmrd = 0;


	/* Configure a clock configuration enable command */
	Command->CommandMode 				= FMC_SDRAM_CMD_CLK_ENABLE;	// 开启SDRAM时钟 
	Command->CommandTarget 				= FMC_COMMAND_TARGET_BANK; 	// 选择要控制的区域
	Command->AutoRefreshNumber 		= 1;
	Command->ModeRegisterDefinition 	= 0;

	HAL_SDRAM_SendCommand(hsdram, Command, SDRAM_TIMEOUT);	// 发送控制指令
	HAL_Delay(1);		// 延时等待

	/* Configure a PALL (precharge all) command */ 
	Command->CommandMode 				= FMC_SDRAM_CMD_PALL;		// 预充电命令
	Command->CommandTarget 				= FMC_COMMAND_TARGET_BANK;	// 选择要控制的区域
	Command->AutoRefreshNumber 		= 1;
	Command->ModeRegisterDefinition 	= 0;

	HAL_SDRAM_SendCommand(hsdram, Command, SDRAM_TIMEOUT);  // 发送控制指令

	/* Configure a Auto-Refresh command */ 
	Command->CommandMode 				= FMC_SDRAM_CMD_AUTOREFRESH_MODE;	// 使用自动刷新
	Command->CommandTarget 				= FMC_COMMAND_TARGET_BANK;          // 选择要控制的区域
	Command->AutoRefreshNumber			= 8;                                // 自动刷新次数
	Command->ModeRegisterDefinition 	= 0;

	HAL_SDRAM_SendCommand(hsdram, Command, SDRAM_TIMEOUT);	// 发送控制指令

	/* Program the external memory mode register */
	tmpmrd = (uint32_t)SDRAM_MODEREG_BURST_LENGTH_1         |
							SDRAM_MODEREG_BURST_TYPE_SEQUENTIAL   |
							SDRAM_MODEREG_CAS_LATENCY_3           |
							SDRAM_MODEREG_OPERATING_MODE_STANDARD |
							SDRAM_MODEREG_WRITEBURST_MODE_SINGLE;

	Command->CommandMode					= FMC_SDRAM_CMD_LOAD_MODE;	// 加载模式寄存器命令
	Command->CommandTarget 				= FMC_COMMAND_TARGET_BANK;	// 选择要控制的区域
	Command->AutoRefreshNumber 		= 1;
	Command->ModeRegisterDefinition 	= tmpmrd;

	HAL_SDRAM_SendCommand(hsdram, Command, SDRAM_TIMEOUT);	// 发送控制指令
	
	HAL_SDRAM_ProgramRefreshRate(hsdram, 1543);  // 配置刷新率

}



//#define SDRAM_Size 32*1024*1024  //32M字节

/******************************************************************************************************
*	函 数 名: SDRAM_Test
*	入口参数: 无
*	返 回 值: SUCCESS - 成功，ERROR - 失败
*	函数功能: SDRAM测试
*	说    明: 先以16位的数据宽度写入数据，再读取出来一一进行比较，随后以8位的数据宽度写入，
*				 用以验证NBL0和NBL1两个引脚的连接是否正常。          
*******************************************************************************************************/

uint8_t SDRAM_Test(void)
{
	uint32_t i = 0;			// 计数变量
	uint32_t *pSDRAM;
	uint32_t ReadData = 0; 	// 读取到的数据
	uint8_t  ReadData_8b;

	uint32_t ExecutionTime_Begin;		// 开始时间
	uint32_t ExecutionTime_End;		// 结束时间
	uint32_t ExecutionTime;				// 执行时间	
	float    ExecutionSpeed;			// 执行速度
	
	printf("\r\n*****************************************************************************************************\r\n");		
	printf("\r\n进行速度测试>>>\r\n");

// 写入 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	
	pSDRAM =  (uint32_t *)SDRAM_BANK_ADDR;
	
	ExecutionTime_Begin 	= HAL_GetTick();	// 获取 systick 当前时间，单位ms
	
	for (i = 0; i < SDRAM_Size/4; i++)
	{
 		*(__IO uint32_t*)pSDRAM++ = i;		// 写入数据
	}

	
	ExecutionTime_End		= HAL_GetTick();											// 获取 systick 当前时间，单位ms
	ExecutionTime  = ExecutionTime_End - ExecutionTime_Begin; 				// 计算擦除时间，单位ms
	ExecutionSpeed = (float)SDRAM_Size /1024/1024 /ExecutionTime*1000 ; 	// 计算速度，单位 MB/S	
	
	printf("\r\n以32位数据宽度写入数据，大小：%d MB，耗时: %d ms, 写入速度：%.2f MB/s\r\n",SDRAM_Size/1024/1024,ExecutionTime,ExecutionSpeed);

// 读取	>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 

	pSDRAM =  (uint32_t *)SDRAM_BANK_ADDR;
		
	ExecutionTime_Begin 	= HAL_GetTick();	// 获取 systick 当前时间，单位ms
	
	for(i = 0; i < SDRAM_Size/4;i++ )
	{
		ReadData = *(__IO uint32_t*)pSDRAM++;  // 从SDRAM读出数据	
	}
	ExecutionTime_End		= HAL_GetTick();											// 获取 systick 当前时间，单位ms
	ExecutionTime  = ExecutionTime_End - ExecutionTime_Begin; 				// 计算擦除时间，单位ms
	ExecutionSpeed = (float)SDRAM_Size /1024/1024 /ExecutionTime*1000 ; 	// 计算速度，单位 MB/S	
	
	printf("\r\n读取数据完毕，大小：%d MB，耗时: %d ms, 读取速度：%.2f MB/s\r\n",SDRAM_Size/1024/1024,ExecutionTime,ExecutionSpeed);
	
//// 数据校验 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
		
	printf("\r\n*****************************************************************************************************\r\n");		
	printf("\r\n进行数据校验>>>\r\n");
	
	pSDRAM =  (uint32_t *)SDRAM_BANK_ADDR;
		
	for(i = 0; i < SDRAM_Size/4;i++ )
	{
		ReadData = *(__IO uint32_t*)pSDRAM++;  // 从SDRAM读出数据	
		if( ReadData != (uint32_t)i )      //检测数据，若不相等，跳出函数,返回检测失败结果。
		{
			printf("\r\nSDRAM测试失败！！出错位置：%d,读出数据：%d\r\n ",i,ReadData);
			return ERROR;	 // 返回失败标志
		}
	}

	
	printf("\r\n32位数据宽度读写通过，以8位数据宽度写入数据\r\n");
	for (i = 0; i < SDRAM_Size; i++)
	{
 		*(__IO uint8_t*) (SDRAM_BANK_ADDR + i) =  (uint8_t)i;
	}	
	printf("写入完毕，读取数据并比较...\r\n");
	for (i = 0; i < SDRAM_Size; i++)
	{
		ReadData_8b = *(__IO uint8_t*) (SDRAM_BANK_ADDR + i);
		if( ReadData_8b != (uint8_t)i )      //检测数据，若不相等，跳出函数,返回检测失败结果。
		{
			printf("8位数据宽度读写测试失败！！\r\n");
			printf("请检查NBL0和NBL1的连接\r\n");	
			return ERROR;	 // 返回失败标志
		}
	}	
	printf("8位数据宽度读写通过\r\n");
	printf("SDRAM读写测试通过，系统正常\r\n");
	
	
	return SUCCESS;	 // 返回成功标志
}

