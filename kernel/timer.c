#include "timer.h"
#include "io.h"
#include "print.h"
#include "debug.h"
#include "thread.h"
#include "interrupt.h"

uint32_t ticks = 0;             //记录内核自中断开启以来总共的滴答数

static void timer_set(uint8_t port, uint8_t control_value, uint16_t counter_value)
{
    outb(CONTROL_PORT, control_value);
    outb(port, (uint8_t)counter_value);
    outb(port, (uint8_t)(counter_value>>8));
}

/* 时钟中断处理函数 */
static void intr_timer_handler(void)
{
    struct task_struct *cur_thread = running_thread();
    //检查当前进程PCB的栈是否溢出
    ASSERT(cur_thread->stack_magic == 0x19870916);
    //更新滴答数
    ticks++;
    cur_thread->elapsed_ticks++;
    if(cur_thread->ticks == 0) {
        schedule();
    } else {
        cur_thread->ticks--;
    }
}

void timer_init(void)
{
    put_str("timer_init start\n");
    timer_set(COUNTER0_PORT, CONTROL_SET_0, COUNTER0_VALUE);
    //注册时钟中断服务函数
    register_handler(0x20, intr_timer_handler);
    put_str("timer_init done\n");
}

