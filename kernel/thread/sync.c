#include "sync.h"
#include "thread.h"
#include "interrupt.h"

void sema_init(struct semaphore *psema, uint8_t value)
{
    psema->value = value;
    list_init(&psema->waiters);
}

void sema_down(struct semaphore *psema)
{
    //关中断，保证原子操作
    enum intr_status old_status = intr_disable();

    while(psema->value == 0) {
        //当前线程不应该在信号量的waiters队列中
        ASSERT(!elem_find(&psema->waiters, &running_thread()->general_tag));
        //把当前线程加入到waiters中
        list_append(&psema->waiters, &running_thread()->general_tag);
        thread_block(TASK_BLOCKED);
    }
    //此刻，阻塞进程已经被唤醒
    psema->value--;
    intr_set_status(old_status);
}

void sema_up(struct semaphore *psema)
{
    //关中断，保证原子操作
    enum intr_status old_status = intr_disable();
    if(!list_empty(&psema->waiters)) {
        struct task_struct *thread_blocked = elem2entry(struct task_struct, general_tag, list_pop(&psema->waiters));
        thread_unblock(thread_blocked);
    }
    psema->value++;
    intr_set_status(old_status);
}

void lock_init(struct lock *plock)
{
    sema_init(&plock->semaphore, 1);         //用二元信号量定义锁
    plock->holder = NULL;
    plock->holder_repeat_num = 0;
}

/* 获取锁lock */
void lock_acquire(struct lock *plock)
{
    if(running_thread() == plock->holder) {
        plock->holder_repeat_num++;
    } else {
        sema_down(&plock->semaphore);
        plock->holder = running_thread();
        ASSERT(plock->holder_repeat_num == 0);          //因为这是线程刚获得锁
        plock->holder_repeat_num = 1;
    }
}

/* 释放锁lock */
void lock_release(struct lock *plock)
{
    //要释放的锁的持有者必须是当前线程
    ASSERT(plock->holder == running_thread());
    if(plock->holder_repeat_num > 1) {
        plock->holder_repeat_num--;
        return;
    }
    ASSERT(plock->holder_repeat_num == 1);

    plock->holder = NULL;
    plock->holder_repeat_num = 0;
    
    sema_up(&plock->semaphore);
}
