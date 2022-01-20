#ifndef _KERNEL_INTERRUPT_H
#define _KERNEL_INTERRUPT_H

typedef void* intr_handler;

//定义eflags中断标志位IF的两种状态
enum intr_status {
    INTR_OFF,           //0
    INTR_ON             //1 
};

void idt_init(void);
enum intr_status intr_set_status(enum intr_status status);
#endif