#ifndef _KERNEL_THREAD_SYNC_H
#define _KERNEL_THREAD_SYNC_H

#include "global.h"

/* 信号量结构 */
struct semaphore
{
    uint8_t value;
    struct list waiters;    //记录在此信号量上等待(阻塞)的所有线程
};

/* 锁结构 */
struct lock
{
    struct task_struct *holder;     //锁的持有者
    struct semaphore semaphore;     //用二元信号量实现锁
    uint32_t holder_repeat_num;     //锁的持有者重复申请锁的次数 
};

void sema_init(struct semaphore *psema, uint8_t value);
void sema_down(struct semaphore *psema);
void sema_up(struct semaphore *psema);

void lock_init(struct lock *plock);
void lock_acquire(struct lock *plock);
void lock_release(struct lock *plock);


#endif