#ifndef  __LCD_TEST_H
#define	__LCD_TEST_H

#include "stm32h7xx_hal.h"
#include "lcd_rgb.h"
#include	"lcd_image.h"


void LCD_Test_Clear(void);				// 清屏测试
void LCD_Test_Text(void);				//	文本显示测试
void LCD_Test_Variable (void);		// 变量显示，包括整数和小数
void LCD_Test_Color(void);				// 颜色测试
void LCD_Test_GrahicTest(void);		// 2D图形绘制
void LCD_Test_FillRect(void);			// 矩形填充测试
void LCD_Test_Image(void);				// 图片显示测试
void LCD_Test_Vertical(void);			// 竖直显示测试
void LCD_Test_DoubleLayer(void);		// 双层显示

#endif //__LCD_TEST_H

