#ifndef _KERNEL_USERPROG_TSS_H
#define _KERNEL_USERPROG_TSS_H

#include "stdint.h"
#include "debug.h"
#include "print.h"
#include "string.h"
#include "global.h"
#include "thread.h"



void update_tss_esp0(struct task_struct *pthread);
void tss_init(void);


#endif