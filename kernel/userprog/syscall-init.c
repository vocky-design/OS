#include "syscall-init.h"
#include "global.h"
#include "thread.h"
#include "usr/syscall.h"
#include "fs/file.h"

/* 返回当前任务的pid */
static uint16_t sys_getpid(void)
{
    return running_thread()->pid;
}

/* 初始化syscall_table */
void syscall_init(void)
{
    console_put_str("syscall_init start\n");
    syscall_table[SYS_GETPID] = sys_getpid;
    syscall_table[SYS_WRITE] = sys_write;
    console_put_str("syscall_init done\n");
}