#include "init.h"
#include "print.h"
#include "interrupt.h"
#include "timer.h"
#include "memory.h"
#include "thread.h"
#include "console.h"
#include "keyboard.h"
/* 负责初始化所有模块 */
void init_all(void)
{
    put_str("init_all\n");
    idt_init();
    timer_init();
    mem_init();             //建立并初始化内存池
    thread_init();
    console_init();
    keyboard_init();
}