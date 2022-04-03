#include "process.h"
#define default_prio    10

extern void intr_exit(void);

static void start_process(void *filename_)
{
    void *function = filename_;
    struct task_struct *cur = running_thread();
    cur->self_kstack += sizeof(struct thread_stack);
    struct intr_stack *proc_stack = (struct intr_stack *)cur->self_kstack;
    proc_stack->edi = proc_stack->esi = proc_stack->ebp = proc_stack->esp_dummy = 0;
    proc_stack->ebx = proc_stack->edx = proc_stack->ecx = proc_stack->eax = 0;
    proc_stack->gs = 0;
    proc_stack->ds = proc_stack->es = proc_stack->fs = SELECTOR_U_DATA;
    proc_stack->eip = function;
    proc_stack->cs = SELECTOR_U_CODE;
    proc_stack->eflags = EFLAGS_IOPL_0 | EFLAGS_MBS | EFLAGS_IF_1;
    proc_stack->esp = (void *)((uint32_t)get_a_page(PF_USER, USER_STACK3_VADDR) + PG_SIZE); //其实就是放在虚拟地址0xc0000000 
    proc_stack->ss = SELECTOR_U_STACK;
    asm volatile("movl %0,%%esp; jmp intr_exit"::"m"(proc_stack):"memory");
}


void process_activate(struct task_struct *pthread)
{
    ASSERT(pthread != NULL);
    
    uint32_t pdt_phy_addr = 0x100000;
    if(pthread->pgdir) {        //是用户进程
        pdt_phy_addr = addr_v2p((uint32_t)pthread->pgdir);
    }
    //切换页表
    asm volatile("movl %0,%%cr3"::"r"(pdt_phy_addr):"memory");
    
    if(pthread->pgdir) {
        update_tss_esp0(pthread);
    }
}

/* 创建页目录表：成功则返回页目录表的虚拟地址  */
static uint32_t *create_pdt(void)
{
    uint32_t *page_dir_vaddr = get_kernel_pages(1);
    ASSERT(page_dir_vaddr != NULL);
    if(page_dir_vaddr == NULL) {
        return NULL;
    }
    //共享内核的设计
    memcpy((uint32_t *)((uint32_t)page_dir_vaddr + 0x300 * 4), (uint32_t *)(0xfffff000 + 0x300 * 4), 1024);
    uint32_t to_phyaddr = addr_v2p((uint32_t)page_dir_vaddr);
    page_dir_vaddr[1023] = to_phyaddr | PG_US_U | PG_RW_W | PG_P_1;
    return page_dir_vaddr;
}

/* 创建用户进程虚拟地址位图 */
static void create_vaddr_bitmap(struct task_struct *user_prog)
{
    user_prog->userprog_vaddr_pool.vaddr_start = USER_VADDR_START;
    uint32_t bitmap_bytes_len = (0xc0000000-PG_SIZE-USER_VADDR_START) / PG_SIZE / 8 ;
    uint32_t bitmap_page_len = DIV_ROUND_UP(bitmap_bytes_len, PG_SIZE);
    user_prog->userprog_vaddr_pool.pool_bitmap.bytes = (uint8_t *)get_kernel_pages(bitmap_page_len);
    user_prog->userprog_vaddr_pool.pool_bitmap.btmp_bytes_len = bitmap_bytes_len;
    bitmap_init(&user_prog->userprog_vaddr_pool.pool_bitmap);
}

void process_create(void *filename, char *name)
{
    //1.PCB的基本信息
    struct task_struct *thread = get_kernel_pages(1);           //为PCB表申请一页内核空间
    init_thread(thread, name, default_prio);
    //
    block_desc_init(thread->u_block_descs);
    //2.用户进程的虚拟内存池
    create_vaddr_bitmap(thread);
    //3.初始化线程栈
    thread_create(thread, start_process, filename);
    //4.创建页目录表
    thread->pgdir = create_pdt();
    //5.挂载到队列中
    enum intr_status old_status = intr_disable();
    ASSERT(!elem_find(&thread_ready_list, &thread->general_tag));
    list_append(&thread_ready_list, &thread->general_tag);
    ASSERT(!elem_find(&thread_all_list, &thread->all_list_tag));
    list_append(&thread_all_list, &thread->all_list_tag);
    intr_set_status(old_status);
}