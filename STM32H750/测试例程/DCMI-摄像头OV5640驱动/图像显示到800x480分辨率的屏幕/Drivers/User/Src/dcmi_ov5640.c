/***
	***********************************************************************************************************************************************
	*	@version V1.0
	*  @date    2024-5-8
	*	@author  反客科技	
   ***********************************************************************************************************************************************
   *  @description
	*
	*	实验平台：反客STM32H750XBH6核心板 （型号：FK750M6-XBH6）+ OV5640模块（型号：OV5640M1-500W） 
	*	淘宝地址：https://shop212360197.taobao.com
	*	QQ交流群：536665479
	*
	*	驱动参考	Arduino/ArduCAM 和 OpenMV 的源码
	*
>>>>> 驱动说明：
	*
	*  1.例程默认配置 16:9(1920*1080) 30帧 的配置
	*	2.开启了DMA并使能了中断，移植的时候需要移植对应的中断
	*
	*************************************************************************************************************************************************************************************************************************************************************************************FANke*****
***/

#include "dcmi_ov5640.h"  
#include "dcmi_ov5640_cfg.h"  

extern	DCMI_HandleTypeDef   hdcmi;            // DCMI句柄
extern	DMA_HandleTypeDef    hdma_dcmi;  // DMA句柄

volatile uint8_t 	OV5640_FrameState = 0;  // DCMI状态标志，当数据帧传输完成时，会被 HAL_DCMI_FrameEventCallback() 中断回调函数置 1     
volatile uint8_t 	OV5640_FPS ;          	// 帧率

volatile uint16_t OV5640_BufferCount = 0; // 缓冲计数     

/*****************************************************************************************************************************************
*	函 数 名:	DCMI_GPIO_Init
*
*	函数功能:	初始化 摄像头的控制 引脚
*
*****************************************************************************************************************************************/
void DCMI_GPIO_Init(void)
{
   GPIO_InitTypeDef GPIO_InitStruct = {0};

	GPIO_OV5640_PWDN_CLK_ENABLE;    // 使能PWDN 引脚的 GPIO 时钟


// 初始化 PWDN 引脚  
	OV5640_PWDN_ON;	// 高电平，进入掉电模式，摄像头停止工作，此时功耗降到最低

	GPIO_InitStruct.Pin 		= OV5640_PWDN_PIN;				// PWDN 引脚
	GPIO_InitStruct.Mode 	= GPIO_MODE_OUTPUT_PP;			// 推挽输出模式
	GPIO_InitStruct.Pull 	= GPIO_PULLUP;						// 上拉
	GPIO_InitStruct.Speed 	= GPIO_SPEED_FREQ_LOW;			// 速度等级低
	HAL_GPIO_Init(OV5640_PWDN_PORT, &GPIO_InitStruct);	   // 初始化  

}


/***************************************************************************************************************************************
*	函 数 名: OV5640_Delay
*	入口参数: Delay - 延时时间，单位 ms 
*	函数功能: 简单延时函数，不是很精确
*	说    明: 为了移植的简便性,此处采用软件延时，实际项目中可以替换成RTOS的延时或者HAL库的延时
*****************************************************************************************************************************************/
void OV5640_Delay(uint32_t Delay)
{
	volatile uint16_t i;

	while (Delay --)				
	{
		for (i = 0; i < 40000; i++);
	}	
//	HAL_Delay(Delay);	  // 可使用HAL库的延时
}

/***************************************************************************************************************************************
*	函 数 名: DCMI_OV5640_Init
*
*	函数功能: 初始SCCB、DCMI、DMA以及配置OV5640
*
*****************************************************************************************************************************************/
int8_t DCMI_OV5640_Init(void)
{
	uint16_t	Device_ID;		// 定义变量存储器件ID
	
   SCCB_GPIO_Config();		               // SCCB引脚初始化
	DCMI_GPIO_Init();								// 初始化摄像头的控制引脚
	OV5640_Reset();	                     // 执行软件复位
	Device_ID =  OV5640_ReadID();		      // 读取器件ID

	if( Device_ID == 0x5640 )		// 进行匹配
	{
		printf ("OV5640 OK,ID:0x%X\r\n",Device_ID);		      // 匹配通过

		OV5640_Config();													// 配置各项参数
		OV5640_Set_Framesize(OV5640_Width,OV5640_Height);		//	设置OV5640输出的图像大小
		OV5640_DCMI_Crop( Display_Width, Display_Height, OV5640_Width, OV5640_Height );	// 将输出图像裁剪成适应屏幕的大小，JPG模式不需要裁剪
				
		return OV5640_Success;	 // 返回成功标志		
	}
	else
	{
		printf ("OV5640 ERROR!!!!!  ID:%X\r\n",Device_ID);	   // 读取ID错误
		return  OV5640_Error;	 // 返回错误标志
	}	
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_DMA_Transmit_Continuous
*
*	入口参数:  DMA_Buffer - DMA将要传输的地址，即用于存储摄像头数据的存储区地址
*            DMA_BufferSize - 传输的数据大小，32位宽
*
*	函数功能: 启动DMA传输，连续模式
*
*	说    明: 1. 开启连续模式之后，会一直进行传输，除非挂起或者停止DCMI
*            2. OV5640使用RGB565模式时，1个像素点需要2个字节来存储
*				 3. 因为DMA配置传输数据为32位宽，计算 DMA_BufferSize 时，需要除以4，例如：
*               要获取 240*240分辨率 的图像，需要传输 240*240*2 = 115200 字节的数据，
*               则 DMA_BufferSize = 115200 / 4 = 28800 。
*fanke
*****************************************************************************************************************************************/
void OV5640_DMA_Transmit_Continuous(uint32_t DMA_Buffer,uint32_t DMA_BufferSize)
{
   hdma_dcmi.Init.Mode  = DMA_CIRCULAR;  // 循环模式					

   HAL_DMA_Init(&hdma_dcmi);    // 配置DMA

  // 使能DCMI采集数据,连续采集模式
   HAL_DCMI_Start_DMA(&hdcmi, DCMI_MODE_CONTINUOUS, (uint32_t)DMA_Buffer,DMA_BufferSize);
	
//	HAL_DMAEx_MultiBufferStart(hdcmi, (uint32_t)&DCMI->DR, (uint32_t)DMA_Buffer, (uint32_t)(DMA_Buffer+480*2),DMA_BufferSize):
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_DMA_Transmit_Snapshot
*
*	入口参数:  DMA_Buffer - DMA将要传输的地址，即用于存储摄像头数据的存储区地址
*            DMA_BufferSize - 传输的数据大小，32位宽
*
*	函数功能: 启动DMA传输，快照模式，传输一帧图像后停止
*
*	说    明: 1. 快照模式，只传输一帧的数据
*            2. OV5640使用RGB565模式时，1个像素点需要2个字节来存储
*				 3. 因为DMA配置传输数据为32位宽，计算 DMA_BufferSize 时，需要除以4，例如：
*               要获取 240*240分辨率 的图像，需要传输 240*240*2 = 115200 字节的数据，
*               则 DMA_BufferSize = 115200 / 4 = 28800 。
*            4. 使用该模式传输完成之后，DCMI会被挂起，再次启用传输之前，需要调用 OV5640_DCMI_Resume() 恢复DCMI
*
*****************************************************************************************************************************************/
void OV5640_DMA_Transmit_Snapshot(uint32_t DMA_Buffer,uint32_t DMA_BufferSize)
{
   hdma_dcmi.Init.Mode  = DMA_NORMAL;  // 正常模式					

   HAL_DMA_Init(&hdma_dcmi);    // 配置DMA

   HAL_DCMI_Start_DMA(&hdcmi, DCMI_MODE_SNAPSHOT, (uint32_t)DMA_Buffer,DMA_BufferSize);
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_DCMI_Suspend
*
*	函数功能: 挂起DCMI，停止捕获数据
*
*	说    明: 1. 开启连续模式之后，再调用该函数，会停止捕获DCMI的数据
*            2. 可以调用 OV5640_DCMI_Resume() 恢复DCMI
*				 3. 需要注意的，挂起DCMI期间，DMA是没有停止工作的
*FANKE
*****************************************************************************************************************************************/
void OV5640_DCMI_Suspend(void) 
{
   HAL_DCMI_Suspend(&hdcmi);    // 挂起DCMI
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_DCMI_Resume
*
*	函数功能: 恢复DCMI，开始捕获数据
*
*	说    明: 1. 当DCMI被挂起时，可以调用该函数恢复
*            2. 使用 OV5640_DMA_Transmit_Snapshot() 快照模式，传输完成之后，DCMI也会被挂起，再次启用传输之前，
*				    需要调用本函数恢复DCMI捕获
*
*****************************************************************************************************************************************/
void  OV5640_DCMI_Resume(void) 
{
   (&hdcmi)->State = HAL_DCMI_STATE_BUSY;       // 变更DCMI标志
   (&hdcmi)->Instance->CR |= DCMI_CR_CAPTURE;   // 开启DCMI捕获
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_DCMI_Stop
*
*	函数功能: 禁止DCMI的DMA请求，停止DCMI捕获，禁止DCMI外设
*
*****************************************************************************************************************************************/
void  OV5640_DCMI_Stop(void) 
{
   HAL_DCMI_Stop(&hdcmi);
}


/***************************************************************************************************************************************
*	函 数 名: OV5640_DCMI_Crop
*
*	入口参数:  Displey_XSize 、Displey_YSize - 显示器的长宽
*				  Sensor_XSize、Sensor_YSize - 摄像头传感器输出图像的长宽
*
*	函数功能: 使用DCMI的裁剪功能，将传感器输出的图像裁剪成适应屏幕的大小
*
*	说    明: 1. 因为摄像头输出的画面比例不一定匹配显示器，所以需要裁剪
*				 2. 摄像头的输出画面比例由 OV5640_Config()配置参数决定，最终画面大小由 OV5640_Set_Framesize()决定
*            3. DCMI的水平有效像素也必须要能被4整除！
*				 4. 函数会计算水平和垂直偏移，尽量让画面居中裁剪
*****************************************************************************************************************************************/
int8_t OV5640_DCMI_Crop(uint16_t Displey_XSize,uint16_t Displey_YSize,uint16_t Sensor_XSize,uint16_t Sensor_YSize )
{
	uint16_t DCMI_X_Offset,DCMI_Y_Offset;	// 水平和垂直偏移，垂直代表的是行数，水平代表的是像素时钟数（PCLK周期数）
	uint16_t DCMI_CAPCNT;		// 水平有效像素，代表的是像素时钟数（PCLK周期数）
	uint16_t DCMI_VLINE;			// 垂直有效行数

	if( (Displey_XSize>=Sensor_XSize)|| (Displey_YSize>=Sensor_YSize) )
	{
//		printf("实际显示的尺寸大于或等于摄像头输出的尺寸，退出DCMI裁剪\r\n");
		return OV5640_Error;  //如果实际显示的尺寸大于或等于摄像头输出的尺寸，则退出当前函数，不进行裁剪
	}
// 在设置为RGB565格式时，水平偏移，必须是奇数，否则画面色彩不正确，
// 因为一个有效像素是2个字节，需要2个PCLK周期，所以必须从奇数位开始，不然数据会错乱，
// 需要注意的是，寄存器值是从0开始算起的	！
	DCMI_X_Offset = Sensor_XSize - Displey_XSize; // 实际计算过程为（Sensor_XSize - LCD_XSize）/2*2

// 计算垂直偏移，尽量让画面居中裁剪，该值代表的是行数，	
	DCMI_Y_Offset = (Sensor_YSize - Displey_YSize)/2-1; // 寄存器值是从0开始算起的，所以要-1

// 因为一个有效像素是2个字节，需要2个PCLK周期，所以要乘2
// 最终得到的寄存器值，必须要能被4整除！
	DCMI_CAPCNT = Displey_XSize*2-1;	// 寄存器值是从0开始算起的，所以要-1
	
	DCMI_VLINE = Displey_YSize-1;		// 垂直有效行数
	
//	printf("%d  %d  %d  %d\r\n",DCMI_X_Offset,DCMI_Y_Offset,DCMI_CAPCNT,DCMI_VLINE);
	
	HAL_DCMI_ConfigCrop (&hdcmi,DCMI_X_Offset,DCMI_Y_Offset,DCMI_CAPCNT,DCMI_VLINE);// 设置裁剪窗口
	HAL_DCMI_EnableCrop(&hdcmi);		// 使能裁剪
	
	return OV5640_Success;
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Reset
*
*	函数功能: 执行软件复位
*
*	说    明: 期间有多个延时操作          
*
*****************************************************************************************************************************************/
void OV5640_Reset(void)
{
	OV5640_Delay(30);  // 等待模块上电稳定，最少5ms，然后拉低PWDN  	
	
	OV5640_PWDN_OFF;  // PWDN 引脚输出低电平，不开启掉电模式，摄像头正常工作，此时摄像头模块的白色LED会点亮
  
// 根据OV5640的上电时序，PWDN拉低之后，要等待1ms再去拉高RESET，反客的OV5640模块采用硬件RC复位，持续时间大概在6~10ms，
// 因此加入延时，等待硬件复位完成并稳定下来
	OV5640_Delay(5);    
	
// 复位完成之后，要>=20ms方可执行SCCB配置
	OV5640_Delay(20);    
	
	SCCB_WriteReg_16Bit(0x3103, 0x11);	// 根据手册的建议，复位之前，直接将时钟输入引脚的时钟作为主时钟
	SCCB_WriteReg_16Bit(0x3008, 0x82);	// 执行一次软复位
	OV5640_Delay(5);  //延时5ms
	
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_ReadID
*
*	函数功能: 读取 OV5640 的器件ID
*
*****************************************************************************************************************************************/
uint16_t OV5640_ReadID(void)
{
   uint8_t PID_H,PID_L;     // ID变量
	
   PID_H = SCCB_ReadReg_16Bit(OV5640_ChipID_H); // 读取ID高字节
   PID_L = SCCB_ReadReg_16Bit(OV5640_ChipID_L); // 读取ID低字节
	
	return(PID_H<<8)|PID_L; // 返回完整的器件ID
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Config
*
*	函数功能: 配置 OV5640 各个寄存器参数
*
*	说    明: 参数定义在 dcmi_ov5640_cfg.h
*            
*****************************************************************************************************************************************/

void OV5640_Config(void)
{
	uint32_t i;	// 计数变量
	
//	uint8_t	Verify_Reg; // 读取配置，用于调试

	for(i=0; i<(sizeof(OV5640_INIT_Config)/4); i++)
	{
		SCCB_WriteReg_16Bit(OV5640_INIT_Config[i][0], OV5640_INIT_Config[i][1]); // 写入配置
		
		OV5640_Delay(1);
		
//		Verify_Reg = SCCB_ReadReg_16Bit(OV5640_INIT_Config[i][0]);	// 读取配置，用于调试

//		if( OV5640_INIT_Config[i][1] != Verify_Reg )	// 配置不成功
//		{
//			printf("出错位置：%d\r\n",i);	// 打印出错位置
//			printf("0x%x-0x%x-0x%x\r\n",OV5640_INIT_Config[i][0],OV5640_INIT_Config[i][1],Verify_Reg);
//		}
	}
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Pixformat
*
*	入口参数:  pixformat - 像素格式，可选择 Pixformat_RGB565、Pixformat_GRAY、Pixformat_JPEG
*
*	函数功能: 设置输出的像素格式
*
*****************************************************************************************************************************************/

void OV5640_Set_Pixformat(uint8_t pixformat)
{
   uint8_t OV5640_Reg;  // 寄存器的值

	if( pixformat == Pixformat_JPEG )
	{
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL, 		0x30);	//	设置数据接口输出的格式	
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL_MUX, 	0x00);	// 设置ISP的格式	
 
		SCCB_WriteReg_16Bit(OV5640_JPEG_MODE_SELECT, 0x02);	 	// JPEG 模式2

		SCCB_WriteReg_16Bit(OV5640_JPEG_VFIFO_CTRL00, 0xA0); 		// JPEG 固定行数
		
		SCCB_WriteReg_16Bit(OV5640_JPEG_VFIFO_HSIZE_H, OV5640_Width>>8);			// JPEG输出水平尺寸,高字节
		SCCB_WriteReg_16Bit(OV5640_JPEG_VFIFO_HSIZE_L, (uint8_t)OV5640_Width);	// JPEG输出水平尺寸,低字节
		SCCB_WriteReg_16Bit(OV5640_JPEG_VFIFO_VSIZE_H, OV5640_Height>>8);			// JPEG输出垂直尺寸,低字节
		SCCB_WriteReg_16Bit(OV5640_JPEG_VFIFO_VSIZE_L, (uint8_t)OV5640_Height);	// JPEG输出垂直尺寸,低字节	
		
	}
	else if( pixformat == Pixformat_GRAY )
	{
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL, 		0x10);	//	设置数据接口输出的格式
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL_MUX, 	0x00);	// 设置ISP的格式		
	}
	else	// RGB565
	{
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL, 		0x6F);	// 此处设置为RGB565格式，序列为 G[2:0]B[4:0], R[4:0]G[5:3]	
		SCCB_WriteReg_16Bit(OV5640_FORMAT_CONTROL_MUX, 	0x01);	// 设置ISP的格式	
	}
	
   OV5640_Reg = SCCB_ReadReg_16Bit(0x3821);   // 读取寄存器值，Bit[5]用于是否使能JPEG模式
	SCCB_WriteReg_16Bit(0x3821,(OV5640_Reg & 0xDF) | ((pixformat == Pixformat_JPEG) ? 0x20 : 0x00));
	 
   OV5640_Reg = SCCB_ReadReg_16Bit(0x3002);   // 读取寄存器值，Bit[7]、Bit[4]和Bit[2]使能 VFIFO、JFIFO、JPG
	SCCB_WriteReg_16Bit(0x3002,(OV5640_Reg & 0xE3) | ((pixformat == Pixformat_JPEG) ? 0x00 : 0x1C));
	 
   OV5640_Reg = SCCB_ReadReg_16Bit(0x3006);   // 读取寄存器值，Bit[5]和Bit[3] 用于是否使能JPG时钟
	SCCB_WriteReg_16Bit(0x3006,(OV5640_Reg & 0xD7) | ((pixformat == Pixformat_JPEG) ? 0x28 : 0x00));

}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_JPEG_QuantizationScale
*
*	入口参数: scale - 压缩等级，取值 0x01~0x3F
*
*	函数功能: 数值越大，压缩就越厉害，得到的图片占用空间就越小，但相应的画质会变差，客户可自行调节
*
*****************************************************************************************************************************************/

void OV5640_Set_JPEG_QuantizationScale(uint8_t scale)
{
	SCCB_WriteReg_16Bit(0x4407, scale); 	// JPEG 压缩等级
}


/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Framesize
*
*	入口参数:  width - 实际输出图像的长度，height - 实际输出图像的宽度
*
*	函数功能: 设置实际输出的图像大小（缩放后）
*
*	说    明: 1. 需要注意的是，要设置的图像长、宽需要满足初始化配置时ISP窗口的比例，不然图像会变形
*            2. 并不是设置输出的图像分辨率越小帧率就越高，帧率只和初始化的配置（PLL、HTS和VTS）有关
*
*****************************************************************************************************************************************/

int8_t OV5640_Set_Framesize(uint16_t width,uint16_t height)
{
// OV5640的很多操作，都要加上这种对应 group 的配置	
    SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X03);  	// 开始 group 3 的配置
	
    SCCB_WriteReg_16Bit(OV5640_TIMING_DVPHO_H,width>>8);			// DVPHO，设置输出水平尺寸
    SCCB_WriteReg_16Bit(OV5640_TIMING_DVPHO_L,width&0xff);
    SCCB_WriteReg_16Bit(OV5640_TIMING_DVPVO_H,height>>8);		// DVPVO，设置输出垂直尺寸
    SCCB_WriteReg_16Bit(OV5640_TIMING_DVPVO_L,height&0xff);

    SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X13);		// 结束配置
    SCCB_WriteReg_16Bit(OV5640_GroupAccess,0Xa3);		// 启用设置
	
	return OV5640_Success; 
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Horizontal_Mirror
*
*	入口参数:  ConfigState - 置1时，图像会水平镜像，置0时恢复正常
*
*	函数功能: 用于设置输出的图像是否进行水平镜像
*
*****************************************************************************************************************************************/
int8_t OV5640_Set_Horizontal_Mirror( int8_t ConfigState )
{
   uint8_t OV5640_Reg;  // 寄存器的值

   OV5640_Reg = SCCB_ReadReg_16Bit(OV5640_TIMING_Mirror);   // 读取寄存器值

// Bit[2:1]用于设置是否水平镜像
   if ( ConfigState == OV5640_Enable )    // 如果使能镜像
   { 
      OV5640_Reg |= 0X06;  
   } 
   else                    // 取消镜像
   {
      OV5640_Reg &= 0xF9; 	
   }
   return  SCCB_WriteReg_16Bit(OV5640_TIMING_Mirror,OV5640_Reg);   // 写入寄存器
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Vertical_Flip
*
*	入口参数:  ConfigState - 置1时，图像会垂直翻转，置0时恢复正常
*
*	函数功能: 用于设置输出的图像是否进行垂直翻转
*
*****************************************************************************************************************************************/
int8_t OV5640_Set_Vertical_Flip( int8_t ConfigState )
{
   uint8_t OV5640_Reg;  // 寄存器的值

   OV5640_Reg = SCCB_ReadReg_16Bit(OV5640_TIMING_Flip);          // 读取寄存器值

// Bit[2:1]用于设置是否垂直翻转
   if ( ConfigState == OV5640_Enable )   
   { 
		OV5640_Reg |= 0X06;       
   } 
   else   // 取消翻转
   {
      OV5640_Reg &= 0xF9; 	
   }
   return  SCCB_WriteReg_16Bit(OV5640_TIMING_Flip,OV5640_Reg);   // 写入寄存器
}


/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Brightness
*
*	入口参数:  Brightness - 亮度，可设置为9个等级：4，3，2，1，0，-1，-2，-3，-4   ，数字越大亮度越高                
*
*	说    明: 1. 直接使用OV5640手册给出的代码
*            2. 亮度越高，画面就越明亮，但是会变模糊一些
*				 2. 亮度太低，噪点会增多
*
*****************************************************************************************************************************************/
void OV5640_Set_Brightness(int8_t Brightness)
{
	Brightness = Brightness+4;
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X03);  	// 开始 group 3 的配置

	SCCB_WriteReg_16Bit( 0x5587, OV5640_Brightness_Config[Brightness][0]);	
	SCCB_WriteReg_16Bit( 0x5588, OV5640_Brightness_Config[Brightness][1]);
	
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X13);		// 结束配置
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0Xa3);		// 启用设置	
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Contrast
*
*	入口参数: Contrast - 对比度，可设置为7个等级：3，2，1，0，-1，-2 ，-3                  
*
*	说    明: 1. 直接使用OV5640手册给出的代码
*            2. 对比度越高，画面越清晰，黑白越加分明
*
*****************************************************************************************************************************************/
void OV5640_Set_Contrast(int8_t Contrast)
{
	Contrast = Contrast+3;
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X03);  	// 开始 group 3 的配置

	SCCB_WriteReg_16Bit( 0x5586, OV5640_Contrast_Config[Contrast][0]);	
	SCCB_WriteReg_16Bit( 0x5585, OV5640_Contrast_Config[Contrast][1]);
	
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X13);		// 结束配置
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0Xa3);		// 启用设置	
}
/***************************************************************************************************************************************
*	函 数 名: OV5640_Set_Effect
*
*	入口参数:  effect_Mode - 特效模式，可选择参数 OV5640_Effect_Normal、OV5640_Effect_Negative、
*                          OV5640_Effect_BW、OV5640_Effect_Solarize
*
*	函数功能: 用于设置OV5640的特效，正常、负片、黑白、正负片叠加模式
*
*	说    明: 这里仅列举了4个模式，更多特效模式可以参考手册进行配置
*
*****************************************************************************************************************************************/
void OV5640_Set_Effect(uint8_t effect_Mode)
{
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X03);  	// 开始 group 3 的配置

	SCCB_WriteReg_16Bit( 0x5580, OV5640_Effect_Config[effect_Mode][0]);	
	SCCB_WriteReg_16Bit( 0x5583, OV5640_Effect_Config[effect_Mode][1]);
	SCCB_WriteReg_16Bit( 0x5584, OV5640_Effect_Config[effect_Mode][2]);	
	SCCB_WriteReg_16Bit( 0x5003, OV5640_Effect_Config[effect_Mode][3]);	
	
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0X13);		// 结束配置
	SCCB_WriteReg_16Bit(OV5640_GroupAccess,0Xa3);		// 启用设置		
	
}
/***************************************************************************************************************************************
*	函 数 名: OV5640_Download_AF_Firmware
*
*	函数功能: 将自动对焦固件写入OV5640
*
*	说    明: 因为OV5640片内没有flash，不能保存固件，因此每次上电都要写入一次
*
*****************************************************************************************************************************************/

int8_t OV5640_AF_Download_Firmware(void)
{ 
	uint8_t  AF_Status = 0;		// 对焦状态
	uint16_t i = 0; 				// 计数变量
	uint16_t OV5640_MCU_Addr = 0x8000;	// OV5640 MCU 存储器的起始地址为 0x8000，大小为4KB
	
	SCCB_WriteReg_16Bit(0x3000, 0x20);	// Bit[5]，复位MCU，写入固件之前，需要执行此操作
// 开始写入固件，批量写入，提高写入速度
	SCCB_WriteBuffer_16Bit( OV5640_MCU_Addr,(uint8_t *)OV5640_AF_Firmware,sizeof(OV5640_AF_Firmware) );
	SCCB_WriteReg_16Bit(0x3000,0x00);  // Bit[5]，写入完毕，写0使能MCU
	
// 写入固件之后，会有个初始化的过程，因此尝试读取100次状态，根据状态进行判断
	for(i=0;i<100;i++)	
	{
		AF_Status = SCCB_ReadReg_16Bit(OV5640_AF_FW_STATUS);	// 读取状态寄存器
		if( AF_Status == 0x7E)
		{
			printf("AF固件初始化中>>>\r\n");	
		}			
		if( AF_Status == 0x70)	// 释放马达，镜头回到初始（对焦为无穷远处）位置，意味着固件写入成功
		{
			printf("AF固件写入成功！\r\n");
			return OV5640_Success;  
		}			
	}
// 尝试100次读取之后，还是没有读到0x70状态，说明固件没写入成功	
	printf("自动对焦固件写入失败！！！error！！\r\n");	
	return OV5640_Error;	
}  

/***************************************************************************************************************************************
*	函 数 名: OV5640_AF_QueryStatus
*
*	返 回 值：OV5640_AF_End - 对焦结束， OV5640_AF_Focusing - 正在对焦
*
*	函数功能: 对焦状态查询
*
*	说    明: 1. 对焦过程大概会持续500多ms
*				 2. 对焦没完成时，采集到的的图像不在焦点，会非常模糊
*
*****************************************************************************************************************************************/

int8_t OV5640_AF_QueryStatus(void)
{
	uint8_t  AF_Status = 0;		// 对焦状态	
	
	AF_Status = SCCB_ReadReg_16Bit(OV5640_AF_FW_STATUS);	// 读取状态寄存器
	printf("AF_Status:0x%x\r\n",AF_Status);

// 单次对焦模式	下，返回 0x10，持续对焦模式下，返回0x20
	if( (AF_Status == 0x10)||(AF_Status == 0x20) )		
	{
		return OV5640_AF_End;	// 返回 对焦结束 标志
	}
	else
	{
		return OV5640_AF_Focusing;	// 返回 正在对焦 标志
	}
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_AF_Trigger_Constant
*
*	函数功能: 持续触发对焦，当OV5640检测到当前画面不在焦点时，会一直触发对焦，无需用户干预
*
*	说    明: 1.可以调用 OV5640_AF_QueryStatus() 函数查询对焦状态
*				 2.可以调用 OV5640_AF_Release() 退出持续对焦模式
*				 3.对焦过程大概会持续500多ms
*				 4.有时环境光线太暗，OV5640会反复的进行对焦，用户可根据实际情况切换到单次对焦模式
*				
*****************************************************************************************************************************************/

void OV5640_AF_Trigger_Constant(void)
{
	SCCB_WriteReg_16Bit(0x3022,0x04);	//	持续对焦
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_AF_Trigger_Single
*
*	函数功能: 触发一次自动对焦
*
*	说    明: 对焦过程大概会持续500多ms，用户可以调用 OV5640_AF_QueryStatus() 函数查询对焦状态
*
*****************************************************************************************************************************************/

void OV5640_AF_Trigger_Single(void)
{
	SCCB_WriteReg_16Bit(OV5640_AF_CMD_MAIN,0x03);	// 触发一次自动对焦 
}

/***************************************************************************************************************************************
*	函 数 名: OV5640_AF_Release
*
*	函数功能: 释放马达，镜头回到初始（对焦为无穷远处）位置
*
*****************************************************************************************************************************************/

void OV5640_AF_Release(void)
{
	SCCB_WriteReg_16Bit(OV5640_AF_CMD_MAIN,0x08);	// 对焦释放指令		
}

/**
  * @brief  Line Event callback.
  * @param  hdcmi: pointer to a DCMI_HandleTypeDef structure that contains
  *                the configuration information for DCMI.
  * @retval None
  */
void HAL_DCMI_LineEventCallback(DCMI_HandleTypeDef *hdcmi)
{

//	OV5640_LineState = 1;
	

	
//	memcpy((uint16_t *)(Frame_Buffer + Display_Width*2*OV5640_LineCount) ,(uint16_t *)Camera_Buffer,Display_Width*2); 	
//	
//	OV5640_LineCount++;		
//	
//	if( OV5640_LineCount>= Display_Height)
//	{
//		OV5640_LineCount = 0;
//	}
}

/***************************************************************************************************************************************
*	函 数 名: HAL_DCMI_FrameEventCallback
*
*	函数功能: 帧回调函数，每传输一帧数据，会进入该中断服务函数
*
*	说    明: 每次传输完一帧，对相应的标志位进行操作，并计算帧率
*****************************************************************************************************************************************/

void HAL_DCMI_FrameEventCallback(DCMI_HandleTypeDef *hdcmi)
{
	static uint32_t DCMI_Tick = 0;         	// 用于保存当前的时间计数值
   static uint8_t  DCMI_Frame_Count = 0;   	// 帧数计数   

 	if(HAL_GetTick() - DCMI_Tick >= 1000)    // 每隔 1s 计算一次帧率
	{
		DCMI_Tick = HAL_GetTick();        // 重新获取当前时间计数值
		
		OV5640_FPS = DCMI_Frame_Count;   // 获得fps 

		DCMI_Frame_Count = 0;            // 计数清0

	}
	DCMI_Frame_Count ++;    // 每进入一次中断（每次传输完一帧数据），计数值+1

   OV5640_FrameState = 1;  // 传输完成标志位置1

}

/***************************************************************************************************************************************
*	函 数 名: HAL_DCMI_ErrorCallback
*
*	函数功能: 错误回调函数
*
*	说    明: 当发生DMA传输错误或者FIFO溢出错误就会进入
*****************************************************************************************************************************************/

void  HAL_DCMI_ErrorCallback(DCMI_HandleTypeDef *hdcmi)
{
   // if( HAL_DCMI_GetError(hdcmi) == HAL_DCMI_ERROR_OVR)
   // {
   //    printf("FIFO溢出错误！！！\r\n");
   // }
//   printf("error:0x%x!!!!\r\n",HAL_DCMI_GetError(hdcmi));
}

/*********************************************************************************************************************************************************************************************************************************************fanke*************/
// 反客
