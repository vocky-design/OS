#ifndef _KERNEL_USERPROG_PROCESS_H
#define _KERNEL_USERPROG_PROCESS_H

#include "global.h"
#include "stdint.h"
#include "console.h"
#include "debug.h"
#include "string.h"
#include "memory.h"
#include "thread.h"
#include "tss.h"
#include "interrupt.h"

#define USER_VADDR_START     0x8048000
#define USER_STACK3_VADDR    (0xc0000000-PG_SIZE)

void process_activate(struct task_struct *pthread);
void process_create(void *filename, char *name);

#endif