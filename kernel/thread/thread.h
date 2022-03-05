#ifndef _KERNEL_THREAD_H
#define _KERNEL_THREAD_H
#include "stdint.h"
#include "memory.h"
#include "list.h"
/* 自定义通用函数类型 */
typedef void thread_func(void *);

/* 任务等待队列和总队列 */
struct list thread_ready_list;
struct list thread_all_list;

/* 进程或线程的状态 */
enum task_status {
    TASK_RUNNING,
    TASK_READY,
    TASK_BLOCKED,
    TASK_WAITING,
    TASK_HANGING,
    TASK_DIED
};

/* 中断栈 */
struct intr_stack {
    uint32_t vec_no;
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp_dummy;
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
    uint32_t gs;
    uint32_t fs;
    uint32_t es;
    uint32_t ds;
    
    uint32_t err_code;
    void (*eip) (void);
    uint32_t cs;
    uint32_t eflags;
    //以下由CPU从低特权级进入高特权级时压入
    void *esp;
    uint32_t ss;
};

/* 线程栈 */
struct thread_stack {
    uint32_t ebp;
    uint32_t ebx;
    uint32_t edi;
    uint32_t esi;
    //线程第一次执行时，eip指向待调用的函数kernel_thread;其他时候，eip是指向switch_to的返回地址
    void (*eip) (thread_func *func, void *func_arg);
    void (*unused_retaddr);
    thread_func *function;
    void *func_arg;
};

/* 进程或线程的PCB块 */
struct task_struct {
    uint32_t *self_kstack;
    enum task_status status;
    char name[16];
    uint8_t priority;
    uint8_t ticks;
    uint32_t elapsed_ticks;                 // 此任务自上CPU运行后至今占用了多少CPU滴答数
    uint32_t *pgdir;                        //进程自己页目录表的虚拟地址
    struct vaddr_pool userprog_vaddr_pool;  //每个用户进程单独管理一个虚拟内存池
    
    struct list_elem general_tag;
    struct list_elem all_list_tag;

    uint32_t stack_magic;
};

struct task_struct *running_thread(void);
struct task_struct *thread_start(char *name, int prio, thread_func function, void *func_arg);
void init_thread(struct task_struct *pthread, char *name, int prio);        /* 初始化PCB */
void thread_create(struct task_struct *pthread, thread_func *function, void *func_arg); ///* 初始化线程栈 */
void main_thread_init(void);     /* 初始化main的线程环境 */
void schedule(void);
void thread_block(enum task_status stat);
void thread_unblock(struct task_struct *pthread);

#endif