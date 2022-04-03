#include "init.h"
#include "print.h"
#include "interrupt.h"
#include "timer.h"
#include "memory.h"
#include "thread.h"
#include "console.h"
#include "keyboard.h"
#include "tss.h"
#include "syscall-init.h"
#include "ide.h"
/* 负责初始化所有模块 */
void init_all(void)
{
    put_str("init_all\n");
    idt_init();
    timer_init();
    mem_init();             //建立并初始化内存池
    thread_init();          //初始化线程环境
    console_init();
    keyboard_init();
    tss_init();
    syscall_init();
    ide_init();
}