#include "thread.h"
#include "interrupt.h"
#include "process.h"

extern void switch_to(struct task_struct *cur_thread, struct task_struct *next_thread);

struct task_struct *main_thread;        //主线程PCB
struct task_struct *idle_thread;
struct lock pid_lock;                   //pid唯一，分配pid时需互斥

/* 分配pid */
static int16_t allocte_pid(void)
{
    static int16_t next_pid = 0;
    lock_acquire(&pid_lock);
    next_pid++;
    int16_t temp_pid = next_pid;
    lock_release(&pid_lock);
    return temp_pid;
}

/* 获取当前进程PCB指针 */
struct task_struct *running_thread(void)
{
    uint32_t esp;
    asm volatile ("mov %%esp,%0":"=g"(esp));        //g:表示可以存放到任意地点（寄存器和内存），包括q（eax/ebx/ecx/edx）和内存
    return (struct task_struct *)(esp & 0xfffff000);
}

/* 由kernel_thread去执行function(func_arg) */
static void kernel_thread(thread_func function, void *func_arg)             //????????????????
{
    //此函数在中断函数内执行
    //默认中断服务函数内会关闭中断
    intr_enable();          //调度器基于时钟中断，保证后面调度器正常工作
    function(func_arg);
}

/* 初始化PCB */
void init_thread(struct task_struct *pthread, char *name, int prio)
{
    if(pthread == main_thread) {
        pthread->status = TASK_RUNNING;
    } else {
        pthread->status = TASK_READY;
    }
    //
    pthread->self_kstack = (uint32_t *)((uint32_t)pthread + PG_SIZE);
    strcpy(pthread->name, name);
    pthread->pid = allocte_pid();
    pthread->priority = prio;
    pthread->ticks = prio;
    pthread->elapsed_ticks = 0;
    pthread->pgdir = NULL;
    //初始化文件描述符数组
    pthread->fd_table[0] = 0;
    pthread->fd_table[1] = 1;
    pthread->fd_table[2] = 2;
    for(int i=3; i<MAX_FILES_OPEN_PER_PROC; ++i) {
        pthread->fd_table[i] = -1;
    }
    pthread->stack_magic = 0x19870916;  
    //后面要分别初始化     uint32_t *pgdir;
    //                    struct vaddr_pool userprog_vaddr_pool;
    //                    struct list_elem general_tag;
    //                    struct list_elem all_list_tag;   
}

/* 初始化内核线程栈 */
void thread_create(struct task_struct *pthread, thread_func *function, void *func_arg)
{
    pthread->self_kstack -= sizeof(struct intr_stack);
    pthread->self_kstack -= sizeof(struct thread_stack);
    //在初始化阶段，self_kstack指针就指向了这里。
    struct thread_stack *kthread_stack = (struct thread_stack *)pthread->self_kstack;
    kthread_stack->ebp = kthread_stack->ebx = kthread_stack->esi = kthread_stack->edi = 0;
    kthread_stack->eip = kernel_thread;
    kthread_stack->function = function;
    kthread_stack->func_arg = func_arg;
}

/* 创建线程 */
struct task_struct *thread_start(char *name, int prio, thread_func function, void *func_arg)
{
    //PCB都位于内核空间，包括用户进程的PCB也在内核空间
    struct task_struct *thread = (struct task_struct *)get_kernel_pages(1);
    init_thread(thread, name, prio);
    thread_create(thread, function, func_arg);

    ASSERT(elem_find(&thread_ready_list, &thread->general_tag) == FALSE);
    list_append(&thread_ready_list, &thread->general_tag);
    ASSERT(elem_find(&thread_all_list, &thread->all_list_tag) == FALSE);
    list_append(&thread_all_list, &thread->all_list_tag);

    return thread;
}

/*************************************************************************************************************************/
/* 将kernel中的main函数创建为主线程 */
static void make_main_thread(void)
{
    //因为main函数早已运行，esp=0xc009f000,已经预留一个PCB位置
    //不需要get_kernel_page另分配一页。
    main_thread = running_thread();
    init_thread(main_thread, "main", 31);
    //main函数是当前进程，当前进程不再thread_ready_list中，所以只加入thread_all_list中。
    ASSERT(elem_find(&thread_all_list, &main_thread->all_list_tag) == FALSE);
    list_append(&thread_all_list, &main_thread->all_list_tag);   
}

/* 系统空闲时运行的进程 */
static void idle(void *UNUSED)
{
    while(1) {
        //阻塞自己
        thread_block(TASK_BLOCKED);
        //醒来后
        asm volatile("sti; hlt":::"memory");
    }
}

/* 初始化线程环境 */
void thread_init(void)
{
    put_str("thread_init start\n");
    list_init(&thread_ready_list);
    list_init(&thread_all_list);
    lock_init(&pid_lock);
    //初始化main的PCB，并挂载到总队列中
    make_main_thread();
    //创建idle线程
    idle_thread = thread_start("idle", 10, idle, NULL);
    put_str("thread_init done\n");
}

/* 实现任务调度 */
/*现有的引用：
    时钟中断
    线程阻塞
*/
void schedule(void)
{
    //schedule()过程中，中断必须是关闭状态
    ASSERT(intr_get_status() == INTR_OFF);

    struct task_struct *cur_thread = running_thread();
    if(cur_thread->status == TASK_RUNNING) {    //说明是时间片到的情况
        //重新加入READY队列末尾
        ASSERT(elem_find(&thread_ready_list, &cur_thread->general_tag) == FALSE);
        list_append(&thread_ready_list, &cur_thread->general_tag);
        //更新滴答值，设置状态为TASK_READY
        cur_thread->ticks = cur_thread->priority;
        cur_thread->status = TASK_READY;
    } else {
        //其他情况调用schedule，进入时status已经不是TASK_RUNNING了。
    }

    //如果就绪队列中没有可运行的任务，就唤醒idle
    if(list_empty(&thread_ready_list)) {
        thread_unblock(idle_thread);
    }
    //取出下一个任务
    struct list_elem *thread_tag = list_pop(&thread_ready_list);
    struct task_struct *next_thread = elem2entry(struct task_struct, general_tag, thread_tag);
    //更新下一个任务的status
    next_thread->status = TASK_RUNNING;
    process_activate(next_thread);
    switch_to(cur_thread, next_thread);

}

/* 主动让出cpu，换其他线程运行 */
void thread_yield(void)
{
    struct task_struct *cur = running_thread();
    enum intr_status old_status = intr_disable();
    ASSERT(!elem_find(&thread_ready_list, &cur->general_tag));
    list_append(&thread_ready_list, &cur->general_tag);
    cur->status = TASK_READY;
    //等于说前面做了一次特殊的schedule流程。
    schedule();
    intr_set_status(old_status);
}

//线程阻塞函数
void thread_block(enum task_status stat)
{
    //对参数的限制
    ASSERT(stat == TASK_BLOCKED || stat == TASK_WAITING || stat == TASK_HANGING);
    //关闭中断,要求原子操作
    enum task_status old_status =  intr_disable();                                                                                                       intr_disable();
    //
    struct task_struct *cur_thread = running_thread();
    cur_thread->status = stat;
    schedule();

    //还原调用环境的中断设置
    intr_set_status(old_status);
}

//线程唤醒函数：唤醒进程push到队列头，等待schedule
void thread_unblock(struct task_struct *pthread)
{
    ASSERT(pthread->status == TASK_BLOCKED || pthread->status == TASK_WAITING || pthread->status == TASK_HANGING);
    //关闭中断
    enum task_status old_status = intr_disable();  
    ASSERT(elem_find(&thread_ready_list, &pthread->general_tag) == FALSE);
    list_push(&thread_ready_list, &pthread->general_tag);
    pthread->status = TASK_READY;
    //还原调用环境的中断设置
    intr_set_status(old_status);  
}