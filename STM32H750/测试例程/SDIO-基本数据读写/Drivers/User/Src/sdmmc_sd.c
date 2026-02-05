/**
该驱动移植于 stm32h743i_eval 板卡的例程
反客科技  2020-11-16
  ******************************************************************************
  * @file    stm32h743i_eval_sd.c
  * @author  MCD Application Team
  * @brief   This file includes the uSD card driver mounted on STM32H743I-EVAL
  *          evaluation boards.
  @verbatim
  How To use this driver:
  -----------------------
  - This driver is used to drive the micro SD external cards mounted on STM32H743I-EVAL
  evaluation board.
  - This driver does not need a specific component driver for the micro SD device
  to be included with.

  Driver description:
  ------------------
  + Initialization steps:
  o Initialize the micro SD card using the BSP_SD_Init() function. This
  function includes the MSP layer hardware resources initialization and the
  SDIO interface configuration to interface with the external micro SD. It
  also includes the micro SD initialization sequence for SDCard1.
  o To check the SD card presence you can use the function BSP_SD_IsDetected() which
  returns the detection status for SDCard1. The function BSP_SD_IsDetected() returns
  the detection status for SDCard1.
  o If SD presence detection interrupt mode is desired, you must configure the
  SD detection interrupt mode by calling the functions BSP_SD_ITConfig() for
  SDCard1. The interrupt is generated as an external interrupt whenever the
  micro SD card is plugged/unplugged in/from the evaluation board. The SD detection
  is managed by MFX, so the SD detection interrupt has to be treated by MFX_IRQOUT
  gpio pin IRQ handler.
  o The function BSP_SD_GetCardInfo() are used to get the micro SD card information
  which is stored in the structure "HAL_SD_CardInfoTypedef".

  + Micro SD card operations
  o The micro SD card can be accessed with read/write block(s) operations once
  it is ready for access. The access, by default to SDCard1, can be performed whether
  using the polling mode by calling the functions BSP_SD_ReadBlocks()/BSP_SD_WriteBlocks(),
  or by DMA transfer using the functions BSP_SD_ReadBlocks_DMA()/BSP_SD_WriteBlocks_DMA().
  o The DMA transfer complete is used with interrupt mode. Once the SD transfer
  is complete, the SD interrupt is handled using the function BSP_SDMMC1_IRQHandler()
  when SDCard1 is used.
  o The SD erase block(s) is performed using the functions BSP_SD_Erase() with specifying
  the number of blocks to erase.
  o The SD runtime status is returned when calling the function BSP_SD_GetStatus().

  @endverbatim
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2019 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "sdmmc_sd.h"

/********************************************** 变量定义 *******************************************/

#define	NumOf_Blocks	64
#define 	Test_BlockSize  ((BLOCKSIZE * NumOf_Blocks) >> 2)	 //定义数据大小,SD块大小为512字节，因为是32位的数组，所以这里除以4
#define	Test_Addr 	 0x00


int32_t  SD_Status ; 		 //SD卡检测标志位
uint32_t SD_WriteBuffer[Test_BlockSize];	//	写数据数组
uint32_t SD_ReadBuffer[Test_BlockSize];	//	读数据数组

/*************************************************************************************************
*	函 数 名:	SDCard_Init
*
*	说    明:初始化配置SD卡		
*************************************************************************************************/

void SDCard_Init(void)
{
	SD_Status = BSP_SD_Init(SD_Instance);	//SD卡初始化
	
	if( SD_Status == BSP_ERROR_NONE )	//检测是否初始化成功
	{		
		printf("SD卡初始化成功 \r\n");	
	}
	else
		printf("检测不到SD卡，ERROR: %d\r\n",SD_Status);		
}

	
/*************************************************************************************************
*	函 数 名:	SDCard_Test
*
*	返回值：BSP_ERROR_NONE - 读写测试成功
*
*	说    明:SD卡读写测试		
*************************************************************************************************/

uint8_t SDCard_Test(void)
{
	uint32_t i = 0;	
	uint32_t ExecutionTime_Begin;		// 开始时间
	uint32_t ExecutionTime_End;		// 结束时间
	uint32_t ExecutionTime;				// 执行时间	
	float    ExecutionSpeed;			// 执行速度

// 擦除 >>>>>>>    
		
	ExecutionTime_Begin 	= HAL_GetTick();	// 获取 systick 当前时间，单位ms
	SD_Status = BSP_SD_Erase(SD_Instance,Test_Addr, NumOf_Blocks);
	while(BSP_SD_GetCardState(SD_Instance) != SD_TRANSFER_OK);	//等待通信结束	
	ExecutionTime_End		= HAL_GetTick();	// 获取 systick 当前时间，单位ms
	
	ExecutionTime = ExecutionTime_End - ExecutionTime_Begin; // 计算擦除时间，单位ms
	
	if( SD_Status == BSP_ERROR_NONE )
	{
		printf ("\r\n 擦除成功, 擦除所需时间: %d ms\r\n",ExecutionTime);		
	}
	else
	{
		printf ("\r\n 擦除失败!!!!!  错误代码:%d\r\n",SD_Status);
		while (1);
	}		
	
// 写入 >>>>>>>    
	for(i=0;i<Test_BlockSize;i++)	//将要写入SD卡的数据写入数组
	{
		SD_WriteBuffer[i] = i;
	}
	
	ExecutionTime_Begin 	= HAL_GetTick();	// 获取 systick 当前时间，单位ms	
	SD_Status = BSP_SD_WriteBlocks(SD_Instance,SD_WriteBuffer, Test_Addr, NumOf_Blocks);	//块写入	
	while(BSP_SD_GetCardState(SD_Instance) != SD_TRANSFER_OK);	//等待通信结束	
	ExecutionTime_End		= HAL_GetTick();	// 获取 systick 当前时间，单位ms
	
	ExecutionTime  = ExecutionTime_End - ExecutionTime_Begin; 		// 计算擦除时间，单位ms
	ExecutionSpeed = (float)BLOCKSIZE * NumOf_Blocks / ExecutionTime /1024 ; // 计算写入速度，单位 MB/S	
	if( SD_Status == BSP_ERROR_NONE )
	{
		printf ("\r\n写入成功,数据大小：%d KB, 耗时: %d ms, 写入速度：%.2f MB/s\r\n",BLOCKSIZE * NumOf_Blocks/1024,ExecutionTime,ExecutionSpeed);		
	}
	else
	{
		printf ("\r\n写入错误!!!!!  错误代码:%d\r\n",SD_Status);
		while (1);
	}		
	
	
// 读取 >>>>>>>    
	ExecutionTime_Begin 	= HAL_GetTick();	// 获取 systick 当前时间，单位ms		
	SD_Status = BSP_SD_ReadBlocks(SD_Instance,SD_ReadBuffer, Test_Addr, NumOf_Blocks);	//块读取
	while(BSP_SD_GetCardState(SD_Instance) != SD_TRANSFER_OK);	//等待通信结束	
	ExecutionTime_End		= HAL_GetTick();	// 获取 systick 当前时间，单位ms

	ExecutionTime  = ExecutionTime_End - ExecutionTime_Begin; 						// 计算擦除时间，单位ms
	ExecutionSpeed = (float)BLOCKSIZE * NumOf_Blocks / ExecutionTime / 1024 ; 	// 计算读取速度，单位 MB/S 
	
	if( SD_Status == BSP_ERROR_NONE )
	{
		printf ("\r\n读取成功,数据大小：%d KB, 耗时: %d ms, 读取速度：%.2f MB/s \r\n",BLOCKSIZE * NumOf_Blocks/1024,ExecutionTime,ExecutionSpeed);		
	}
	else
	{
		printf ("\r\n读取错误!!!!!  错误代码:%d\r\n",SD_Status);
		while (1);
	}		

// 校验 >>>>>>>   
	for(i=0;i<Test_BlockSize;i++)	//验证读出的数据是否等于写入的数据
	{
		if( SD_WriteBuffer[i] != SD_ReadBuffer[i] )	//如果数据不相等，则返回0	
		{
			printf ("\r\n数据校验失败!!!!!\r\n");	
			while(1);
		}
	}		
	printf ("\r\n校验通过!!!!!SD卡测试正常\r\n");		
	return BSP_ERROR_NONE; 	//数据正确，读写测试通过
}

	
	
/** @addtogroup BSP
  * @{
  */

/** @addtogroup STM32H743I_EVAL
  * @{
  */

/** @addtogroup STM32H743I_EVAL_SD
  * @{
  */

/** @defgroup STM32H743I_EVAL_SD_Private_TypesDefinitions Private TypesDefinitions
  * @{
  */
/**
  * @}
  */

/** @defgroup STM32H743I_EVAL_SD_Private_Defines Private Defines
  * @{
  */
/**
  * @}
  */

/** @defgroup STM32H743I_EVAL_SD_Private_Macros Private Macros
  * @{
  */
/**
  * @}
  */
/** @defgroup STM32H743I_EVAL_SD_Private_TypesDefinitions Private TypesDefinitions
  * @{
  */
typedef void (* BSP_EXTI_LineCallback) (void);
/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Exported_Variables Exported Variables
  * @{
  */
extern SD_HandleTypeDef hsd1;
EXTI_HandleTypeDef hsd_exti[SD_INSTANCES_NBR];
/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Private_Variables Private Variables
  * @{
  */
#if (USE_BSP_IO_CLASS > 0U)
static uint32_t PinDetect[SD_INSTANCES_NBR]  = {SD_DETECT_PIN};
#endif
#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
/* Is Msp Callbacks registered   */
static uint32_t   IsMspCallbacksValid[SD_INSTANCES_NBR] = {0};
#endif
/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Private_Functions_Prototypes Private Functions Prototypes
  * @{
  */


#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
static void SD_AbortCallback(SD_HandleTypeDef *hsd);
static void SD_TxCpltCallback(SD_HandleTypeDef *hsd);
static void SD_RxCpltCallback(SD_HandleTypeDef *hsd);
#if (USE_SD_TRANSCEIVER != 0U)
static void SD_DriveTransceiver_1_8V_Callback(FlagStatus status);
#endif
#endif /* (USE_HAL_SD_REGISTER_CALLBACKS == 1)   */
static void SD_EXTI_Callback(void);
/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Exported_Functions Exported Functions
  * @{
  */

/**
  * @brief  Initializes the SD card device.
  * @param  Instance      SD Instance
  * @retval BSP status
  */
int32_t BSP_SD_Init(uint32_t Instance)
{
  int32_t ret = BSP_ERROR_NONE;

#if (USE_BSP_IO_CLASS > 0U)
  BSP_IO_Init_t io_init_structure;
#endif

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
#if (USE_BSP_IO_CLASS > 0U)

    /* Configure SD pin detect   */
    io_init_structure.Pin  =PinDetect[Instance];
    io_init_structure.Pull = IO_PULLUP;
    io_init_structure.Mode = IO_MODE_INPUT;

    if(BSP_IO_Init(0, &io_init_structure) != BSP_ERROR_NONE)
    {
      ret = BSP_ERROR_BUS_FAILURE;
    }
    else
    {
      /* Initialise Transciver MFXPIN to enable 1.8V Switch mode */
      io_init_structure.Pin  = SD_LDO_SEL_PIN;
      io_init_structure.Pull = IO_PULLDOWN;
      io_init_structure.Mode = IO_MODE_OUTPUT_PP;

      if(BSP_IO_Init(0, &io_init_structure) != BSP_ERROR_NONE)
      {
        ret = BSP_ERROR_BUS_FAILURE;
      }
    }
#endif
    /* Check if SD card is present   */

    if((uint32_t)BSP_SD_IsDetected(Instance) != SD_PRESENT)
    {
      ret = BSP_ERROR_UNKNOWN_COMPONENT;
    }
    else
    {

#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
      /* Register the SD MSP Callbacks   */
      if(IsMspCallbacksValid[Instance] == 0UL)
      {
        if(BSP_SD_RegisterDefaultMspCallbacks(Instance) != BSP_ERROR_NONE)
        {
          ret = BSP_ERROR_PERIPH_FAILURE;
        }
      }
#else

#endif /* USE_HAL_SD_REGISTER_CALLBACKS   */

      if(ret == BSP_ERROR_NONE)
      {
        /* HAL SD initialization and Enable wide operation   */

        if(HAL_SD_ConfigWideBusOperation(&hsd1, SDMMC_BUS_WIDE_4B) != HAL_OK)
        {
          ret = BSP_ERROR_PERIPH_FAILURE;
        }
        else
        {
          /* Switch to High Speed mode if the card support this mode */
          (void)HAL_SD_ConfigSpeedBusOperation(&hsd1, SDMMC_SPEED_MODE_HIGH);

#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
          /* Register SD TC, HT and Abort callbacks */
          if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_TX_CPLT_CB_ID, SD_TxCpltCallback) != HAL_OK)
          {
            ret = BSP_ERROR_PERIPH_FAILURE;
          }
          else if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_RX_CPLT_CB_ID, SD_RxCpltCallback) != HAL_OK)
          {
            ret = BSP_ERROR_PERIPH_FAILURE;
          }
          else if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_ABORT_CB_ID, SD_AbortCallback) != HAL_OK)
          {
            ret = BSP_ERROR_PERIPH_FAILURE;
          }
          else
          {
#if (USE_SD_TRANSCEIVER != 0U)
            if(HAL_SD_RegisterTransceiverCallback(&hsd1, SD_DriveTransceiver_1_8V_Callback) != HAL_OK)
            {
              ret = BSP_ERROR_PERIPH_FAILURE;
            }
#endif
          }
#endif /* USE_HAL_SD_REGISTER_CALLBACKS   */
        }
      }
    }
  }


  return ret;
}

/**
  * @brief  DeInitializes the SD card device.
  * @param Instance      SD Instance
  * @retval SD status
  */
int32_t BSP_SD_DeInit(uint32_t Instance)
{
  int32_t ret = BSP_ERROR_NONE;

#if (USE_BSP_IO_CLASS > 0U)
  BSP_IO_Init_t io_init_structure;
#endif
  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else if(HAL_SD_DeInit(&hsd1) != HAL_OK)/* HAL SD de-initialization   */
  {
    ret = BSP_ERROR_PERIPH_FAILURE;
  }
  else
  {
    /* Msp SD de-initialization   */
#if (USE_HAL_SD_REGISTER_CALLBACKS == 0)
//    SD_MspDeInit(&hsd1);
#endif /* (USE_HAL_SD_REGISTER_CALLBACKS == 0)   */
#if (USE_BSP_IO_CLASS > 0U)
    io_init_structure.Pin  = PinDetect[Instance];
    io_init_structure.Pull = IO_PULLUP;
    io_init_structure.Mode = IO_MODE_INPUT;

    if(BSP_IO_Init(0, &io_init_structure) != BSP_ERROR_NONE)
    {
      ret = BSP_ERROR_BUS_FAILURE;
    }
#endif
  }

  return ret;
}

/**
  * @brief  Initializes the SDMMC1 peripheral.
  * @param  hsd SD handle
  * @retval HAL status
  */
__weak HAL_StatusTypeDef MX_SDMMC1_SD_Init(SD_HandleTypeDef *hsd)
{
  HAL_StatusTypeDef ret = HAL_OK;
  /* uSD device interface configuration */
  hsd->Instance                 = SDMMC1;
  hsd->Init.ClockEdge           = SDMMC_CLOCK_EDGE_RISING;
  hsd->Init.ClockPowerSave      = SDMMC_CLOCK_POWER_SAVE_DISABLE;
  hsd->Init.BusWide             = SDMMC_BUS_WIDE_4B;
  hsd->Init.HardwareFlowControl = SDMMC_HARDWARE_FLOW_CONTROL_DISABLE;

//  SDMMC_CK （输出时钟）=  sdmmc_ker_ck （SDMMC 内核时钟） / [2 * CLKDIV]
// 在本例程中，sdmmc_ker_ck = 240M
// 为了兼容性和稳定性，这里设置为 SDMMC_CK =  sdmmc_ker_ck / (2*6) = 20M
  hsd->Init.ClockDiv            = 6;   

	
  /* HAL SD initialization   */
  if(HAL_SD_Init(hsd) != HAL_OK)
  {
    ret = HAL_ERROR;
  }

  return ret;
}

#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
/**
  * @brief Default BSP SD Msp Callbacks
  * @param Instance      SD Instance
  * @retval BSP status
  */
int32_t BSP_SD_RegisterDefaultMspCallbacks(uint32_t Instance)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    /* Register MspInit/MspDeInit Callbacks */
    if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_MSP_INIT_CB_ID, SD_MspInit) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
    else if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_MSP_DEINIT_CB_ID, SD_MspDeInit) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
    else
    {
      IsMspCallbacksValid[Instance] = 1U;
    }
  }
  /* Return BSP status */
  return ret;
}

/**
  * @brief BSP SD Msp Callback registering
  * @param Instance     SD Instance
  * @param CallBacks    pointer to MspInit/MspDeInit callbacks functions
  * @retval BSP status
  */
int32_t BSP_SD_RegisterMspCallbacks(uint32_t Instance, BSP_SD_Cb_t *CallBacks)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    /* Register MspInit/MspDeInit Callbacks */
    if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_MSP_INIT_CB_ID, CallBacks->pMspInitCb) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
    else if(HAL_SD_RegisterCallback(&hsd1, HAL_SD_MSP_DEINIT_CB_ID, CallBacks->pMspDeInitCb) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
    else
    {
      IsMspCallbacksValid[Instance] = 1U;
    }
  }

  /* Return BSP status */
  return ret;
}
#endif /* (USE_HAL_SD_REGISTER_CALLBACKS == 1) */

/**
  * @brief  Configures Interrupt mode for SD detection pin.
  * @param  Instance      SD Instance
  * @retval BSP status
  */
int32_t BSP_SD_DetectITConfig(uint32_t Instance)
{
  int32_t ret = BSP_ERROR_NONE;
  const uint32_t SD_EXTI_LINE[SD_INSTANCES_NBR]   = {SD_DETECT_EXTI_LINE};
  static BSP_EXTI_LineCallback SdCallback[SD_INSTANCES_NBR] = {SD_EXTI_Callback};

  if(Instance> SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
#if (USE_BSP_IO_CLASS > 0U)
    BSP_IO_Init_t io_init_structure;

    io_init_structure.Pin  = PinDetect[Instance];
    io_init_structure.Pull = IO_PULLUP;
    /* Configure IO interrupt acquisition mode   */
    if(((uint32_t)BSP_IO_ReadPin(0, PinDetect[Instance]) && PinDetect[Instance]) != PinDetect[Instance])
    {
      io_init_structure.Mode = IO_MODE_IT_RISING_EDGE;
    }
    else
    {
      io_init_structure.Mode = IO_MODE_IT_FALLING_EDGE;
    }

    if(BSP_IO_Init(0, &io_init_structure) != BSP_ERROR_NONE)
    {
      ret = BSP_ERROR_BUS_FAILURE;
    }
#endif
    if(ret == BSP_ERROR_NONE)
    {
      if(HAL_EXTI_GetHandle(&hsd_exti[Instance], SD_EXTI_LINE[Instance]) != HAL_OK)
      {
        ret = BSP_ERROR_PERIPH_FAILURE;
      }
      else
      {
        if(HAL_EXTI_RegisterCallback(&hsd_exti[Instance],  HAL_EXTI_COMMON_CB_ID, SdCallback[Instance]) != HAL_OK)
        {
          ret = BSP_ERROR_PERIPH_FAILURE;
        }
      }
    }
  }
   return ret;
}

/**
  * @brief  BSP SD Callback.
  * @param  Instance SD Instance
  * @param  Status   Pin status
  * @retval None.
  */
__weak void BSP_SD_DetectCallback(uint32_t Instance, uint32_t Status)
{
  /* Prevent unused argument(s) compilation warning   */
  UNUSED(Instance);
  UNUSED(Status);

  /* This function should be implemented by the user application.
  It is called into this driver when an event on JoyPin is triggered.   */
}

/**
  * @brief  Detects if SD card is correctly plugged in the memory slot or not.
  * @param Instance  SD Instance
  * @retval Returns if SD is detected or not
  */
int32_t BSP_SD_IsDetected(uint32_t Instance)
{
  int32_t ret = BSP_ERROR_UNKNOWN_FAILURE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    return BSP_ERROR_WRONG_PARAM;
  }
  else
  {
		ret = (int32_t)SD_PRESENT;	  
    /* Check SD card detect pin */
//#if (USE_BSP_IO_CLASS > 0)
//   if((BSP_IO_ReadPin(0, PinDetect[Instance]) && PinDetect[Instance]) != 0UL)
//    {
//      ret = (int32_t)SD_NOT_PRESENT;
//    }
//    else
//    {
//      ret = (int32_t)SD_PRESENT;
//    }
//#endif
  }

  return ret;
}

/**
  * @brief  Reads block(s) from a specified address in an SD card, in polling mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be read
  * @param  BlocksNbr  Number of SD blocks to read
  * @retval BSP status
  */
int32_t BSP_SD_ReadBlocks(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;
  uint32_t timeout = SD_READ_TIMEOUT*BlocksNbr;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_ReadBlocks(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr, timeout) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Writes block(s) to a specified address in an SD card, in polling mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be written
  * @param  BlocksNbr  Number of SD blocks to write
  * @retval BSP status
  */
int32_t BSP_SD_WriteBlocks(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;
  uint32_t timeout = SD_READ_TIMEOUT*BlocksNbr;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_WriteBlocks(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr, timeout) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Reads block(s) from a specified address in an SD card, in DMA mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be read
  * @param  BlocksNbr  Number of SD blocks to read
  * @retval BSP status
  */
int32_t BSP_SD_ReadBlocks_DMA(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_ReadBlocks_DMA(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Writes block(s) to a specified address in an SD card, in DMA mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be written
  * @param  BlocksNbr  Number of SD blocks to write
  * @retval BSP status
  */
int32_t BSP_SD_WriteBlocks_DMA(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_WriteBlocks_DMA(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Reads block(s) from a specified address in an SD card, in DMA mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be read
  * @param  BlocksNbr  Number of SD blocks to read
  * @retval SD status
  */
int32_t BSP_SD_ReadBlocks_IT(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_ReadBlocks_IT(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Writes block(s) to a specified address in an SD card, in DMA mode.
  * @param  Instance   SD Instance
  * @param  pData      Pointer to the buffer that will contain the data to transmit
  * @param  BlockIdx   Block index from where data is to be written
  * @param  BlocksNbr  Number of SD blocks to write
  * @retval SD status
  */
int32_t BSP_SD_WriteBlocks_IT(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_WriteBlocks_IT(&hsd1, (uint8_t *)pData, BlockIdx, BlocksNbr) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}


/**
  * @brief  Erases the specified memory area of the given SD card.
  * @param  Instance   SD Instance
  * @param  BlockIdx   Block index from where data is to be
  * @param  BlocksNbr  Number of SD blocks to erase
  * @retval SD status
  */
int32_t BSP_SD_Erase(uint32_t Instance, uint32_t BlockIdx, uint32_t BlocksNbr)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_Erase(&hsd1, BlockIdx, BlockIdx + BlocksNbr) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }

  /* Return BSP status   */
  return ret;
}

/**
  * @brief  Gets the current SD card data status.
  * @param  Instance  SD Instance
  * @retval Data transfer state.
  *          This value can be one of the following values:
  *            @arg  SD_TRANSFER_OK: No data transfer is acting
  *            @arg  SD_TRANSFER_BUSY: Data transfer is acting
  */
int32_t BSP_SD_GetCardState(uint32_t Instance)
{
  return (int32_t)((HAL_SD_GetCardState(&hsd1) == HAL_SD_CARD_TRANSFER ) ? SD_TRANSFER_OK : SD_TRANSFER_BUSY);
}

/**
  * @brief  Get SD information about specific SD card.
  * @param  Instance  SD Instance
  * @param  CardInfo  Pointer to HAL_SD_CardInfoTypedef structure
  * @retval BSP status
  */
int32_t BSP_SD_GetCardInfo(uint32_t Instance, BSP_SD_CardInfo *CardInfo)
{
  int32_t ret = BSP_ERROR_NONE;

  if(Instance >= SD_INSTANCES_NBR)
  {
    ret = BSP_ERROR_WRONG_PARAM;
  }
  else
  {
    if(HAL_SD_GetCardInfo(&hsd1, CardInfo) != HAL_OK)
    {
      ret = BSP_ERROR_PERIPH_FAILURE;
    }
  }
  /* Return BSP status */
  return ret;
}

#if !defined (USE_HAL_SD_REGISTER_CALLBACKS) || (USE_HAL_SD_REGISTER_CALLBACKS == 0)
/**
  * @brief SD Abort callbacks
  * @param hsd  SD handle
  * @retval None
  */
void HAL_SD_AbortCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_AbortCallback((hsd == &hsd1) ? 0UL : 1UL);
}

/**
  * @brief Tx Transfer completed callbacks
  * @param hsd  SD handle
  * @retval None
  */
void HAL_SD_TxCpltCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_WriteCpltCallback((hsd == &hsd1) ? 0UL : 1UL);
}

/**
  * @brief Rx Transfer completed callbacks
  * @param hsd  SD handle
  * @retval None
  */
void HAL_SD_RxCpltCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_ReadCpltCallback((hsd == &hsd1) ? 0UL : 1UL);
}

#if (USE_SD_TRANSCEIVER != 0U)
/**
  * @brief  Enable the SD Transceiver 1.8V Mode Callback.
  */
void HAL_SD_DriveTransciver_1_8V_Callback(FlagStatus status)
{
#if (USE_BSP_IO_CLASS > 0U)
  if(status == SET)
  {
    BSP_IO_WritePin(0, SD_LDO_SEL_PIN, IO_PIN_SET);
  }
  else
  {
    BSP_IO_WritePin(0, SD_LDO_SEL_PIN, IO_PIN_RESET);
  }
#endif
}
#endif
#endif /* !defined (USE_HAL_SD_REGISTER_CALLBACKS) || (USE_HAL_SD_REGISTER_CALLBACKS == 0)   */

/**
  * @brief  This function handles pin detection interrupt request.
  * @param  Instance  SD Instance
  * @retval None
  */
void BSP_SD_DETECT_IRQHandler(uint32_t Instance)
{
  HAL_EXTI_IRQHandler(&hsd_exti[Instance]);
}

/**
  * @brief  This function handles SDMMC interrupt requests.
  * @param  Instance  SD Instance
  * @retval None
  */
void BSP_SD_IRQHandler(uint32_t Instance)
{
  HAL_SD_IRQHandler(&hsd1);
}

/**
  * @brief BSP SD Abort callbacks
  * @param  Instance     SD Instance
  * @retval None
  */
__weak void BSP_SD_AbortCallback(uint32_t Instance)
{
  /* Prevent unused argument(s) compilation warning   */
  UNUSED(Instance);
}

/**
  * @brief BSP Tx Transfer completed callbacks
  * @param  Instance     SD Instance
  * @retval None
  */
__weak void BSP_SD_WriteCpltCallback(uint32_t Instance)
{
  /* Prevent unused argument(s) compilation warning   */
  UNUSED(Instance);
}

/**
  * @brief BSP Rx Transfer completed callbacks
  * @param  Instance     SD Instance
  * @retval None
  */
__weak void BSP_SD_ReadCpltCallback(uint32_t Instance)
{
  /* Prevent unused argument(s) compilation warning   */
  UNUSED(Instance);
}

/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Private_Functions Private Functions
  * @{
  */
#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
/**
  * @brief SD Abort callbacks
  * @param hsd  SD handle
  * @retval None
  */
static void SD_AbortCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_AbortCallback((hsd == &hsd1) ? 0UL : 1UL);
}

/**
  * @brief Tx Transfer completed callbacks
  * @param hsd  SD handle
  * @retval None
  */
static void SD_TxCpltCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_WriteCpltCallback((hsd == &hsd1) ? 0UL : 1UL);
}

/**
  * @brief Rx Transfer completed callbacks
  * @param hsd  SD handle
  * @retval None
  */
static void SD_RxCpltCallback(SD_HandleTypeDef *hsd)
{
  BSP_SD_ReadCpltCallback((hsd == &hsd1) ? 0UL : 1UL);
}

#if (USE_SD_TRANSCEIVER != 0U)
/**
  * @brief  Enable the SD Transciver 1.8V Mode Callback.
  * @param  status Tranceiver 1.8V status
  * @retval None
  */
static void SD_DriveTransceiver_1_8V_Callback(FlagStatus status)
{
#if (USE_BSP_IO_CLASS > 0U)
  if(status == SET)
  {
    BSP_IO_WritePin(0, SD_LDO_SEL_PIN, IO_PIN_SET);
  }
  else
  {
    BSP_IO_WritePin(0, SD_LDO_SEL_PIN, IO_PIN_RESET);
  }
#endif
}
#endif
#endif/* (USE_HAL_SD_REGISTER_CALLBACKS == 1) */

/**
  * @brief  SD EXTI line detection callbacks.
  * @retval None
  */
static void SD_EXTI_Callback(void)
{
#if (USE_BSP_IO_CLASS > 0)
  uint32_t sd_pin, sd_status = SD_PRESENT;
  BSP_IO_Init_t io_init_structure;

  sd_pin = (uint32_t)BSP_IO_GetIT(0, SD_DETECT_PIN);
  io_init_structure.Pin  = sd_pin;
  io_init_structure.Pull = IO_PULLUP;
  /* Check SD card detect pin   */
  if(((uint32_t)BSP_IO_ReadPin(0, sd_pin) & sd_pin) != sd_pin)
  {
    io_init_structure.Mode = IO_MODE_IT_RISING_EDGE;
    (void)BSP_IO_Init(0, &io_init_structure);
  }
  else
  {
    sd_status = SD_NOT_PRESENT;
    io_init_structure.Mode = IO_MODE_IT_FALLING_EDGE;
    (void)BSP_IO_Init(0, &io_init_structure);
  }
  if(sd_pin == SD_DETECT_PIN)
  {
    BSP_SD_DetectCallback(0, sd_status);
  }

  (void)BSP_IO_ClearIT(0, sd_pin);
#endif
}



/**
  * @}
  */

/**
  * @}
  */

/**
  * @}
  */

/**
  * @}
  */
/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE***  */
