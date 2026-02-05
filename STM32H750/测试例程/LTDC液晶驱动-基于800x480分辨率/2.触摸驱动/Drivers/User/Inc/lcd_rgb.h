#ifndef  __LCD_RGB_H
#define	__LCD_RGB_H

#include "stm32h7xx_hal.h"
#include "usart.h"
#include "sdram.h"  
#include "lcd_fonts.h"
#include <stdio.h>

// LTDC时钟例程配置为33MHz，
// 过高的时钟会加大对SDRAM的占用，容易造成花屏，过低的时钟会导致刷新率太低，屏幕会有明显的闪烁。
// 开启2层显示，同样也会加大对SDRAM的占用，用户实际调试如果发现花屏，可以修改为单层

#define 	LCD_NUM_LAYERS  1	//	定义显示的层数，H7可驱动两层显示

#define	ColorMode_0   LTDC_PIXEL_FORMAT_RGB565   		//定义 layer0 的颜色格式
//#define	ColorMode_0   LTDC_PIXEL_FORMAT_ARGB1555  
//#define	ColorMode_0    LTDC_PIXEL_FORMAT_ARGB4444  
//#define	ColorMode_0   LTDC_PIXEL_FORMAT_RGB888
//#define	ColorMode_0   LTDC_PIXEL_FORMAT_ARGB8888   


#if  LCD_NUM_LAYERS == 2	// 如果开启了双层，则在此处定义 layer1 的颜色格式			

//	#define	ColorMode_1   LTDC_PIXEL_FORMAT_RGB565   	
	#define	ColorMode_1   LTDC_PIXEL_FORMAT_ARGB1555  // ARGB1555仅支持一位透明色，即仅有透明和不透明两种状态
//	#define	ColorMode_1   LTDC_PIXEL_FORMAT_ARGB4444  // ARGB4444支持4位透明色，有16种透明状态
// #define	ColorMode_1   LTDC_PIXEL_FORMAT_RGB888   
//	#define	ColorMode_1   LTDC_PIXEL_FORMAT_ARGB8888   // ARGB8888支持8位透明色，有256种透明状态	

#endif


// 显示方向参数
// 使用示例：LCD_DisplayDirection(Direction_H) ，设置屏幕横屏显示
// 使用示例：LCD_DisplayDirection(Direction_V) ，设置屏幕竖直显示

#define	Direction_H	0		//LCD横屏显示
#define	Direction_V	1		//LCD竖屏显示

// 设置变量显示时多余位补0还是补空格
// 只有 LCD_DisplayNumber() 显示整数 和 LCD_DisplayDecimals()显示小数 这两个函数用到
// 使用示例： LCD_ShowNumMode(Fill_Zero) 设置多余位填充0，例如 123 可以显示为 000123
//
#define  Fill_Zero  0		//填充0
#define  Fill_Space 1		//填充空格


/*---------------------------------------- 常用颜色 ------------------------------------------------------

 1. 这里为了方便用户使用，定义的是32位颜色，然后再通过代码自动转换成对应颜色格式所需要的的颜色
 2. 32位的颜色中，从高位到低位分别对应 A、R、G、B  4个颜色通道，其中A表示透明通道
 3. 最多可设置255级透明色，ff表示不透明，0表示完全透明
 4. 除非使用ARGB1555和ARGB8888等支持透明色的颜色格式，不然透明色不起作用，其中ARGB1555仅支持一位
	 透明色，即仅有透明和不透明两种状态，ARGB4444有16级透明度，ARGB8888支持255级透明度
 5. 用户可以在电脑用调色板获取24位RGB颜色，然后再补充透明通道得到32位的颜色，再将此32位颜色输入
	 LCD_SetColor()或LCD_SetBackColor()就可以显示出相应的颜色。 
 6. 使用示例：纯蓝色的RGB值为0x0000FF，如果不需要透明色，则对应的32位颜色值为 0xff0000FF
 7. 以下定义的颜色都设置为不透明，用户可根据需求自行定义对应的颜色								*/

#define 	LCD_WHITE       0xffFFFFFF		// 纯白色
#define 	LCD_BLACK       0xff000000		// 纯黑色
                           
#define 	LCD_BLUE        0xff0000FF		//	纯蓝色
#define 	LCD_GREEN       0xff00FF00    //	纯绿色
#define 	LCD_RED         0xffFF0000    //	纯红色
#define 	LCD_CYAN        0xff00FFFF    //	蓝绿色
#define 	LCD_MAGENTA     0xffFF00FF    //	紫红色
#define 	LCD_YELLOW      0xffFFFF00    //	黄色
#define 	LCD_GREY        0xff2C2C2C    //	灰色
													
#define 	LIGHT_BLUE      0xff8080FF    //	亮蓝色
#define 	LIGHT_GREEN     0xff80FF80    //	亮绿色
#define 	LIGHT_RED       0xffFF8080    //	亮红色
#define 	LIGHT_CYAN      0xff80FFFF    //	亮蓝绿色
#define 	LIGHT_MAGENTA   0xffFF80FF    //	亮紫红色
#define 	LIGHT_YELLOW    0xffFFFF80    //	亮黄色
#define 	LIGHT_GREY      0xffA3A3A3    //	亮灰色
													
#define 	DARK_BLUE       0xff000080    //	暗蓝色
#define 	DARK_GREEN      0xff008000    //	暗绿色
#define 	DARK_RED        0xff800000    //	暗红色
#define 	DARK_CYAN       0xff008080    //	暗蓝绿色
#define 	DARK_MAGENTA    0xff800080    //	暗紫红色
#define 	DARK_YELLOW     0xff808000    //	暗黄色
#define 	DARK_GREY       0xff404040    //	暗灰色

/*---------------------------------------------------------- 函数声明 -------------------------------------------------------*/
	
void 	LCD_RGB_Init(void);		// 初始化屏幕
void 	LCD_Clear(void);			// 清屏函数
void 	LCD_ClearRect(uint16_t x, uint16_t y, uint16_t width, uint16_t height);	// 局部清屏函数

void  LCD_SetLayer(uint8_t Layerx); 					//	设置层
void  LCD_SetColor(uint32_t Color); 				   //	设置画笔颜色
void  LCD_SetBackColor(uint32_t Color);  				//	设置背景颜色
void  LCD_DisplayDirection(uint8_t direction);  	//	设置显示方向

//>>>>>	显示ASCII字符
void  LCD_SetFont(pFONT *fonts);												//	设置ASCII字体
void 	LCD_DisplayChar(uint16_t x, uint16_t y,uint8_t c);				//	显示单个ASCII字符
void 	LCD_DisplayString( uint16_t x, uint16_t y, char *p);	 		//	显示ASCII字符串

//>>>>>	显示中文字符，包括ASCII码
void 	LCD_SetTextFont(pFONT *fonts);										// 设置文本字体，包括中文和ASCII字体
void 	LCD_DisplayChinese(uint16_t x, uint16_t y, char *pText);		// 显示单个汉字
void 	LCD_DisplayText(uint16_t x, uint16_t y, char *pText) ;		// 显示字符串，包括中文和ASCII字符

//>>>>>	显示整数或小数
void  LCD_ShowNumMode(uint8_t mode);		// 设置显示模式，多余位填充空格还是填充0
void  LCD_DisplayNumber( uint16_t x, uint16_t y, int32_t number,uint8_t len) ;					// 显示整数
void  LCD_DisplayDecimals( uint16_t x, uint16_t y, double number,uint8_t len,uint8_t decs);	// 显示小数

//>>>>>	绘制图片

void 	LCD_DrawImage(uint16_t x,uint16_t y,uint16_t width,uint16_t height,const uint8_t *pImage)  ;

//>>>>>	2D图形绘制函数

void  LCD_DrawPoint(uint16_t x,uint16_t y,uint32_t color);   								//画点
uint32_t 	LCD_ReadPoint(uint16_t x,uint16_t y);												//读点
void  LCD_DrawLine(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);					//画线
void  LCD_DrawRect(uint16_t x, uint16_t y, uint16_t width, uint16_t height);			//画矩形
void  LCD_DrawCircle(uint16_t x, uint16_t y, uint16_t r);									//画圆
void  LCD_DrawEllipse(int x, int y, int r1, int r2);											//画椭圆

//>>>>>	区域填充函数

void  LCD_FillRect(uint16_t x, uint16_t y, uint16_t width, uint16_t height);			//填充矩形
void  LCD_FillCircle(uint16_t x, uint16_t y, uint16_t r);									//填充圆



// FK750M5-XBH6 核心板 使用的是外部SDRAM作为显存，起始地址0xC0000000
// 显存所需空间 = 分辨率 * 每个像素所占字节数，例如 800*480的屏，使用16位色（RGB565或者AEGB1555），需要显存 800*480*2 = 768000 字节

#define LCD_Width     		800						//	LCD的像素长度
#define LCD_Height    		480						//	LCD的像素宽度
#define LCD_MemoryAdd   	SDRAM_BANK_ADDR 		//	显存的起始地址  

	
#if ( ColorMode_0 == LTDC_PIXEL_FORMAT_RGB565 || ColorMode_0 == LTDC_PIXEL_FORMAT_ARGB1555 || ColorMode_0 ==LTDC_PIXEL_FORMAT_ARGB4444 )
	#define BytesPerPixel_0		2		//16位色模式每个像素占2字节
#elif ColorMode_0 == LTDC_PIXEL_FORMAT_RGB888
	#define BytesPerPixel_0		3		//24位色模式每个像素占3字节
#else
	#define BytesPerPixel_0		4		//32位色模式每个像素占4字节
#endif	

#if LCD_NUM_LAYERS == 2

	#if ( ColorMode_1 == LTDC_PIXEL_FORMAT_RGB565 || ColorMode_1 == LTDC_PIXEL_FORMAT_ARGB1555 || ColorMode_1 == LTDC_PIXEL_FORMAT_ARGB4444 )
		#define BytesPerPixel_1		2	//16位色模式每个像素占2字节
	#elif ColorMode_1 == LTDC_PIXEL_FORMAT_RGB888	
		#define BytesPerPixel_1		3	//24位色模式每个像素占3字节
	#else	
		#define BytesPerPixel_1		4	//32位色模式每个像素占4字节
	#endif	

	#define LCD_MemoryAdd_OFFSET   LCD_Width * LCD_Height * BytesPerPixel_0 	 //第二层的显存的偏移地址 

#endif
/*-------------------------------------------------------- LCD背光引脚 -------------------------------------------------------*/

#define  LCD_Backlight_PIN								GPIO_PIN_6								
#define	LCD_Backlight_PORT							GPIOH									
#define 	GPIO_LDC_Backlight_CLK_ENABLE        	__HAL_RCC_GPIOH_CLK_ENABLE()	 	

#define	LCD_Backlight_OFF		HAL_GPIO_WritePin(LCD_Backlight_PORT, LCD_Backlight_PIN, GPIO_PIN_RESET);	// 关闭背光
#define 	LCD_Backlight_ON		HAL_GPIO_WritePin(LCD_Backlight_PORT, LCD_Backlight_PIN, GPIO_PIN_SET);		// 开启背光


	 
#endif //__LCD_RGB_H

