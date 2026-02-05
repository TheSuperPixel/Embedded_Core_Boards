/***
	************************************************************************************************
	*	@file  	usart.c
	*	@version V1.0
	*  @date    2022-7-7
	*	@author  反客科技
	*	@brief   usart相关函数
   ************************************************************************************************
   *  @description
	*
	*	实验平台：反客STM32H750XBH6核心板 （型号：FK750M5-XBH6）
	*	淘宝地址：https://shop212360197.taobao.com
	*	QQ交流群：536665479
	*
>>>>> 文件说明：
	*
	*  初始化usart引脚，配置波特率等参数
	*
	************************************************************************************************
***/


#include "usart.h"
#include "stm32h7xx_hal.h"


extern UART_HandleTypeDef huart1;  // UART_HandleTypeDef 结构体变量

/*************************************************************************************************
*	在有些场合，例如LVGL因为需要用__aeabi_assert或者TouchGFX，不能勾选 microLib 以使用printf
*	添加以下代码，让标准C库支持重定向fput
*  根据编译器，选择对应的代码即可
*************************************************************************************************/


//// AC5编译器使用这段代码
//#pragma import(__use_no_semihosting)  
//int _ttywrch(int ch)    
//{
//    ch=ch;
//	return ch;
//}         
//struct __FILE 
//{ 
//	int handle; 

//}; 
//FILE __stdout;       

//void _sys_exit(int x) 
//{ 
//	x = x; 
//} 



//// AC6编译器使用这段代码
//__asm (".global __use_no_semihosting\n\t");
//void _sys_exit(int x) 
//{
//  x = x;
//}
////__use_no_semihosting was requested, but _ttywrch was 
//void _ttywrch(int ch)
//{
//    ch = ch;
//}

//FILE __stdout;



/*************************************************************************************************
*	函 数 名:	fputc
*	入口参数:	ch - 要输出的字符 ，  f - 文件指针（这里用不到）
*	返 回 值:	正常时返回字符，出错时返回 EOF（-1）
*	函数功能:	重定向 fputc 函数，目的是使用 printf 函数
*	说    明:	无		
*************************************************************************************************/

int fputc(int ch, FILE *f)
{
	HAL_UART_Transmit(&huart1, (uint8_t *)&ch, 1, 100);	// 发送单字节数据
	return (ch);
}

