/**
  ******************************************************************************
  * @file    stm32h743i_eval_sd.h
  * @author  MCD Application Team
    * @brief   This file contains the common defines and functions prototypes for
  *          the stm32h743i_eval_sd.c driver.
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

/* Define to prevent recursive inclusion -------------------------------------  */
#ifndef STM32H743I_EVAL_SD_H
#define STM32H743I_EVAL_SD_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------  */
#include "stm32h7xx_hal.h"
#include "usart.h"
	
#define BSP_SD_RX_IT_PRIORITY               14U
#define BSP_SD_TX_IT_PRIORITY               15U
	
#define BSP_ERROR_NONE                    0
#define BSP_ERROR_NO_INIT                -1
#define BSP_ERROR_WRONG_PARAM            -2
#define BSP_ERROR_BUSY                   -3
#define BSP_ERROR_PERIPH_FAILURE         -4
#define BSP_ERROR_COMPONENT_FAILURE      -5
#define BSP_ERROR_UNKNOWN_FAILURE        -6
#define BSP_ERROR_UNKNOWN_COMPONENT      -7
#define BSP_ERROR_BUS_FAILURE            -8
#define BSP_ERROR_CLOCK_FAILURE          -9
#define BSP_ERROR_MSP_FAILURE            -10
#define BSP_ERROR_FEATURE_NOT_SUPPORTED  -11


/* BSP BUS error codes */
#define BSP_ERROR_BUS_TRANSACTION_FAILURE    -100
#define BSP_ERROR_BUS_ARBITRATION_LOSS       -101
#define BSP_ERROR_BUS_ACKNOWLEDGE_FAILURE    -102
#define BSP_ERROR_BUS_PROTOCOL_FAILURE       -103

#define BSP_ERROR_BUS_MODE_FAULT             -104
#define BSP_ERROR_BUS_FRAME_ERROR            -105
#define BSP_ERROR_BUS_CRC_ERROR              -106
#define BSP_ERROR_BUS_DMA_FAILURE            -107
/** @addtogroup BSP
  * @{
  */

/** @addtogroup STM32H743I_EVAL
  * @{
  */

/** @defgroup STM32H743I_EVAL_SD SD
  * @{
  */

/** @defgroup STM32H743I_EVAL_SD_Exported_Types SD Exported Types
  * @{
  */

/**
  * @brief SD Card information structure
  */
#define BSP_SD_CardInfo HAL_SD_CardInfoTypeDef

#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
typedef struct
{
  void (* pMspInitCb)(SD_HandleTypeDef *);
  void (* pMspDeInitCb)(SD_HandleTypeDef *);
}BSP_SD_Cb_t;
#endif /* (USE_HAL_SD_REGISTER_CALLBACKS == 1)   */

/**
  * @}
  */

/** @defgroup STM32H747I_EVAL_SD_Exported_Constants Exported Constants
  * @{
  */
#define SD_Instance	0

#define SD_INSTANCES_NBR         1UL

#ifndef SD_WRITE_TIMEOUT
  #define SD_WRITE_TIMEOUT       100U
#endif

#ifndef SD_READ_TIMEOUT
  #define SD_READ_TIMEOUT        100U
#endif

/**
  * @brief  SD transfer state definition
  */
#define   SD_TRANSFER_OK         0U
#define   SD_TRANSFER_BUSY       1U

/**
  * @brief SD-detect signal
  */
#define SD_PRESENT               1UL
#define SD_NOT_PRESENT           0UL

#if (USE_BSP_IO_CLASS > 0U)
#define SD_DETECT_PIN                    IO_PIN_15
#define SD_LDO_SEL_PIN                   IO_PIN_13
#endif

#define SD_DETECT_EXTI_LINE              EXTI_LINE_8
#define SD_DetectIRQHandler()            HAL_GPIO_EXTI_IRQHandler(GPIO_PIN_8)

/**
  * @}
  */

/** @addtogroup STM32H747I_EVAL_SD_Exported_Variables
  * @{
  */
extern SD_HandleTypeDef    hsd_sdmmc[];
extern EXTI_HandleTypeDef  hsd_exti[];

/**
  * @}
  */

/** @defgroup STM32H7B3I_EVAL_SD_Exported_Functions SD Exported Functions
  * @{
  */
  
void SDCard_Init(void);  		// SDø®≥ı ºªØ
uint8_t SDCard_Test(void);	 	// SDø®∂¡–¥≤‚ ‘	
	
int32_t BSP_SD_Init(uint32_t Instance);
int32_t BSP_SD_DeInit(uint32_t Instance);
#if (USE_HAL_SD_REGISTER_CALLBACKS == 1)
int32_t BSP_SD_RegisterMspCallbacks(uint32_t Instance, BSP_SD_Cb_t *CallBacks);
int32_t BSP_SD_RegisterDefaultMspCallbacks(uint32_t Instance);
#endif /* (USE_HAL_SD_REGISTER_CALLBACKS == 1) */
int32_t BSP_SD_DetectITConfig(uint32_t Instance);
int32_t BSP_SD_ReadBlocks(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t BlocksNbr);
int32_t BSP_SD_WriteBlocks(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t NbrOfBlocks);
int32_t BSP_SD_ReadBlocks_DMA(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t NbrOfBlocks);
int32_t BSP_SD_WriteBlocks_DMA(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t NbrOfBlocks);
int32_t BSP_SD_ReadBlocks_IT(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t NbrOfBlocks);
int32_t BSP_SD_WriteBlocks_IT(uint32_t Instance, uint32_t *pData, uint32_t BlockIdx, uint32_t NbrOfBlocks);
int32_t BSP_SD_Erase(uint32_t Instance, uint32_t BlockIdx, uint32_t BlocksNbr);
int32_t BSP_SD_GetCardState(uint32_t Instance);
int32_t BSP_SD_GetCardInfo(uint32_t Instance, BSP_SD_CardInfo *CardInfo);
int32_t BSP_SD_IsDetected(uint32_t Instance);

void    BSP_SD_DETECT_IRQHandler(uint32_t Instance);
void    BSP_SD_IRQHandler(uint32_t Instance);

/* These functions can be modified in case the current settings (e.g. DMA stream ot IT)
   need to be changed for specific application needs */
void BSP_SD_AbortCallback(uint32_t Instance);
void BSP_SD_WriteCpltCallback(uint32_t Instance);
void BSP_SD_ReadCpltCallback(uint32_t Instance);
void BSP_SD_DetectCallback(uint32_t Instance, uint32_t Status);


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

#ifdef __cplusplus
}
#endif

#endif /* STM32H743I_EVAL_SD_H   */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
