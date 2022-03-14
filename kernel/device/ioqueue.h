#ifndef _KERNEL_DEVICE_IOQUEUE_H
#define _KERNEL_DEVICE_IOQUEUE_H

#include "global.h"
#include "thread.h"
#include "sync.h"
#include "interrupt.h"

#define bufsize 64

/* 环形缓冲队列 */
/* 在头被写入，在尾被读出 */
struct ioqueue
{
    struct lock lock;
    struct task_struct *producer;   
    struct task_struct *consumer;
    char buf[bufsize];
    uint32_t head;                  //用数组实现此环形缓冲队列
    uint32_t tail;
};

void ioqueue_init(struct ioqueue *ioq);
bool ioq_full(struct ioqueue *ioq);
bool ioq_empty(struct ioqueue *ioq);
char ioq_getchar(struct ioqueue *ioq);
void ioq_putchar(struct ioqueue *ioq, char byte);




#endif