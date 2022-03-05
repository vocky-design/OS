#include "init.h"
#include "print.h"
#include "interrupt.h"
#include "timer.h"
#include "memory.h"
#include "thread.h"
#include "console.h"
#include "keyboard.h"
#include "tss.h"

/* 负责初始化所有模块 */
void init_all(void)
{
    put_str("init_all\n");
    idt_init();
    timer_init();
    mem_init();             //建立并初始化内存池
    main_thread_init();     //初始化主线程main的线程环境
    console_init();
    keyboard_init();
    //tss_init();
}