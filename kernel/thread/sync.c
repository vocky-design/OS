#include "sync.h"
#include "thread.h"
#include "debug.h"
#include "interrupt.h"

static void sema_init(struct semaphore *psema, uint8_t value)
{
    psema->value = value;
    list_init(&psema->waiters);
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
    //如果当前线程不是锁的持有者，或者锁的持有者是NULL。
    if(running_thread() != plock->holder) {
        //关中断，保证原子操作
        enum intr_status old_status = intr_disable();
        while(plock->semaphore.value == 0) {            //需要阻塞自己
            ASSERT(elem_find(&plock->semaphore.waiters, &running_thread()->general_tag) == FALSE);
            list_append(&plock->semaphore.waiters, &running_thread()->general_tag);
            thread_block(TASK_BLOCKED);
        }       
        plock->semaphore.value--;
        ASSERT(plock->semaphore.value == 0);            //因为这是二元信号量
        intr_set_status(old_status);

        plock->holder = running_thread();
        ASSERT(plock->holder_repeat_num == 0);          //因为这是线程刚获得锁
        plock->holder_repeat_num = 1;
    } else {
        plock->holder_repeat_num++;
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
    enum intr_status old_status = intr_disable();
    ASSERT(plock->semaphore.value == 0);                //因为这是二元信号量
    if(list_empty(&plock->semaphore.waiters) == FALSE) {
        struct task_struct *thread_blocked = (struct task_struct *)elem2entry(struct task_struct, general_tag, list_pop(&plock->semaphore.waiters) );
        thread_unblock(thread_blocked);
    }
    plock->semaphore.value++;
    ASSERT(plock->semaphore.value == 1);
    intr_set_status(old_status);
}
