#ifndef _KERNEL_TIMER_H
#define _KERNEL_TIMER_H
#include "io.h"
#include "thread.h"
#include "interrupt.h"
/* 控制字段属性 */
//端口号
#define CONTROL_PORT        0x43
//选择计数器
#define COUNTER0_NUM        0
#define COUNTER1_NUM        1
#define COUNTER2_NUM        2
//选择读写方式
#define LATCH_FOR_CPU       0
#define WRITE_LOW_BITS      1
#define WRITE_HIGH_BITS     2
#define WRITE_BOTH_BITS     3
//选择工作方式
#define MODE_0              0
#define MODE_1              1
#define MODE_2              2
#define MODE_3              3
#define MODE_4              4
#define MODE_5              5
//控制字段组合
#define CONTROL_SET_0     (COUNTER0_NUM<<6 | WRITE_BOTH_BITS<<4 | MODE_2<<1 | 0)      //计数器0，16位初值，模式2

/* 初值字段属性 */
//端口号
#define COUNTER0_PORT       0x40
#define COUNTER1_PORT       0x41
#define COUNTER2_PORT       0x42
//初值字段组合
#define INPUT_FREQUENCY     1193180
#define IRQ0_FREQUENCY      100
#define COUNTER0_VALUE      (INPUT_FREQUENCY/IRQ0_FREQUENCY)           //100HZ


void timer_init(void);
void mtime_sleep(uint32_t m_seconds);
#endif