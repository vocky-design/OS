#include "memory.h"
#include "thread.h"

#define PG_SIZE                 4096
#define MEM_BITMAP_BASE       0xc009a000  //1个物理块的PCB+4个物理块的位图
#define K_HEAP_START          0xc0100000  //跨过低端1MB内存，其实后面还要跨过loader.S中定义的页目录表和页表占用的物理地址0x100000-0x101ff。

#define PDE_IDX(addr)          ((addr & 0xffc00000) >> 22)
#define PTE_IDX(addr)          ((addr & 0x003ff000) >> 12)

#define ALL_MEM_ADDRESS        0xc0000b00 

struct paddr_pool {
    struct lock lock;
    struct bitmap pool_bitmap;
    uint32_t paddr_start;
    uint32_t pool_size;         //以页为基本单位  4KB
};
struct paddr_pool kernel_pool, user_pool;
struct vaddr_pool kernel_vaddr_pool;

static void mem_pool_init(uint32_t all_mem)
{
    put_str("   mem_pool_init start\n");         
    //页目录表和页表占用的物理地址，其实地址0x100000,包括1个目录表，0和768页目录项指向同一页表，769-1022目录项指向254个页表。
    uint32_t used_mem = 256 * PG_SIZE + 0x100000;     //加上低端1MB内存。
    uint32_t free_mem = all_mem - used_mem;
    uint32_t free_pages = free_mem / PG_SIZE;           //理论上，完全可以整除
    uint32_t kernel_free_pages = free_pages / 2;
    uint32_t user_free_pages = free_pages - kernel_free_pages;
    //为简化位图操作，余数不处理，坏处是这样做会丢内存；好处是不用做内存的越界检查，因为位图表示的内存少于实际物理内存。
    uint32_t kbm_length = kernel_free_pages / 8;
    uint32_t ubm_length = user_free_pages / 8;
    //从0开始，物理起始地址
    uint32_t kp_start = used_mem;
    uint32_t up_start = used_mem + kernel_free_pages * PG_SIZE;
    //以页为基本单位  4KB
    kernel_pool.pool_size = kernel_free_pages * PG_SIZE;
    user_pool.pool_size = user_free_pages * PG_SIZE;

    kernel_pool.paddr_start = kp_start;
    user_pool.paddr_start = up_start;

    kernel_pool.pool_bitmap.bytes = (uint8_t*)MEM_BITMAP_BASE;
    kernel_pool.pool_bitmap.btmp_bytes_len = kbm_length;

    user_pool.pool_bitmap.bytes = (uint8_t*)(MEM_BITMAP_BASE + kbm_length);
    user_pool.pool_bitmap.btmp_bytes_len = ubm_length;
    
    bitmap_init(&kernel_pool.pool_bitmap);
    bitmap_init(&user_pool.pool_bitmap);
    lock_init(&kernel_pool.lock);
    lock_init(&user_pool.lock);
    //输出内存池信息
    put_str("   kernel_pool_bitmap_start:");
    put_int((uint32_t)kernel_pool.pool_bitmap.bytes);
    put_str("   kernel_pool_paddr_start:");
    put_int((uint32_t)kernel_pool.paddr_start);
    put_char('\n');
    put_str("   user_pool_bitmap_start:");
    put_int((uint32_t)user_pool.pool_bitmap.bytes);
    put_str("   user_pool_paddr_start:");
    put_int((uint32_t)user_pool.paddr_start);
    put_char('\n');   

    kernel_vaddr_pool.vaddr_start = K_HEAP_START;
    kernel_vaddr_pool.pool_bitmap.bytes = (uint8_t *)(MEM_BITMAP_BASE + kbm_length + ubm_length);
    kernel_vaddr_pool.pool_bitmap.btmp_bytes_len = kbm_length;
    bitmap_init(&kernel_vaddr_pool.pool_bitmap);

    put_str("   mem_pool_init done\n");
}

void mem_init(void) 
{
    put_str("mem_init start\n");
    uint32_t mem_bytes_total = (*(uint32_t *)0xb00);
    mem_pool_init(mem_bytes_total);
    put_str("mem_init done\n");
}

/* 申请cnt个虚拟内存块，成功返回虚拟起始地址，失败返回NULL 
   因为虚拟地址分配是连续的，所以一次申请多个*/
/*static void *vaddr_get(enum pool_flag pf, uint32_t cnt)
{
    uint32_t vaddr_start;
    if(pf == PF_KERNEL) {
        int32_t bit_idx = bitmap_scan(&kernel_vaddr_pool.pool_bitmap, cnt);
        if(bit_idx != -1) {
            while(cnt--) {
                bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx+cnt-1, 1);
            }
            vaddr_start = kernel_vaddr_pool.vaddr_start + bit_idx * PG_SIZE;
        } else {    
            return NULL;
        }
    } else {
        //用户虚拟空间，后面写。
    }
    return (void *)vaddr_start;
}*/
static void *vaddr_get(enum pool_flag pf, uint32_t pg_cnt)
{
    int vaddr_start = 0, bit_idx_start = -1;
    uint32_t cnt = 0;
    if(pf == PF_KERNEL) {
        bit_idx_start = bitmap_scan(&kernel_vaddr_pool.pool_bitmap, pg_cnt);
        if(bit_idx_start == -1) {
            return NULL;
        }
        while(cnt < pg_cnt) {
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
        }
        vaddr_start = kernel_vaddr_pool.vaddr_start + bit_idx_start * PG_SIZE;
    } else {
        struct task_struct *cur_thread = running_thread();
        bit_idx_start = bitmap_scan(&cur_thread->userprog_vaddr_pool.pool_bitmap, pg_cnt);
        if(bit_idx_start == -1) {
            return NULL;
        }
        while(cnt < pg_cnt) {
            bitmap_set(&cur_thread->userprog_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
        }
        vaddr_start = cur_thread->userprog_vaddr_pool.vaddr_start + bit_idx_start * PG_SIZE;        
        //(0xc0000000-PG_SZIE)作为用户3级栈已经在start_process被分配
        ASSERT((uint32_t)vaddr_start < (0xc0000000-PG_SIZE));
    }
    return (void *)vaddr_start;
}

/* 在m_pool指向的物理内存池中分配1个物理页,成功返回物理起始地址 */
static void *paddr_get(struct paddr_pool *m_pool)
{
    int32_t bit_idx = bitmap_scan(&m_pool->pool_bitmap, 1);
    if(bit_idx == -1) {
        return NULL;
    }
    bitmap_set(&m_pool->pool_bitmap, bit_idx, 1);
    uint32_t paddr_start = m_pool->paddr_start + bit_idx * PG_SIZE;
    return (void *)paddr_start;
}

/* 得到虚拟地址vaddr对应的pde指针 */
/*uint32_t *pde_ptr(uint32_t vaddr)
{
    uint32_t *pde = (uint32_t *)(0xfffff000 + ((0xffc00000 & vaddr) >> 20));
    return pde;
}*/
/* 得到虚拟地址vaddr对应的pte指针 */
/*uint32_t *pte_ptr(uint32_t vaddr)
{
    uint32_t *pte = (uint32_t *)(0xffc00000 + ((0xffc00000 & vaddr) >> 10) + ((0x003ff000 & vaddr) >> 10));
    return pte;
}*/
uint32_t *pde_ptr(uint32_t vaddr)
{
    uint32_t *pde = (uint32_t *)(0xfffff000 + PDE_IDX(vaddr)*4);
    return pde;
}
uint32_t *pte_ptr(uint32_t vaddr)
{
    uint32_t *pte = (uint32_t *)(0xffc00000 + ((vaddr & 0xffc00000) >> 10) + PTE_IDX(vaddr) * 4);
    return pte;
}

/* 页表中添加虚拟地址_vaddr与物理地址_paddr的映射 */
static void page_table_add(void *_vaddr, void *_paddr)
{
    uint32_t vaddr = (uint32_t)(uint32_t *)_vaddr;
    uint32_t paddr = (uint32_t)(uint32_t *)_paddr;

    uint32_t *pde = pde_ptr(vaddr);
    uint32_t *pte = pte_ptr(vaddr); 

    if(*pde & 0x1) {
        ASSERT(!(*pte & 0x1));  //pte不存在
        if(!(*pte & 0x1)) {     
            *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
        } else {
            PANIC("pte repeat");  
        }
    } else {
        uint32_t pte_paddr = (uint32_t)(uint32_t *)paddr_get(&kernel_pool);       //为页表申请空间
        *pde = pte_paddr | PG_US_U | PG_RW_W | PG_P_1;
        memset((void *)((uint32_t)pte & 0xfffff000), 0, PG_SIZE);               //清空页表，要用虚拟地址访问刚申请的页表        
        ASSERT(!(*pte & 0x1));  
        *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
    }
}

/* 分配cnt个页空间，成功则返回起始虚拟地址，失败返回NULL */
static void *malloc_page(enum pool_flag pf, uint32_t pg_cnt)
{
    ASSERT(pg_cnt >0 && pg_cnt < 3840);      //15MB*1024*1024/4096=3840页
    //三步：
    //1.通过vaddr_get在虚拟内存池申请虚拟地址。
    //2.通过paddr_get在物理内存池申请物理页。
    //3.通过page_table_add进行地址映射。
    void *vaddr_start = vaddr_get(pf, pg_cnt);
    if(vaddr_start == NULL) {
        return NULL;
    }

    uint32_t vaddr = (uint32_t)vaddr_start, cnt = pg_cnt;
    struct paddr_pool *mem_pool = pf & PF_KERNEL ? &kernel_pool : &user_pool;

    while(cnt--) {
        void *paddr_start = paddr_get(mem_pool);
        if(paddr_start == NULL) {
            return NULL;
        }
        page_table_add((void *)vaddr, paddr_start);
        vaddr += PG_SIZE;
    }  

    return vaddr_start;
}

/* 从内核物理内存池申请一页内存，并清空 */
/* 成功则返回虚拟地址，失败返回NULL */
void *get_kernel_pages(uint32_t pg_cnt)
{
    lock_acquire(&kernel_pool.lock);
    void *vaddr = malloc_page(PF_KERNEL, pg_cnt);
    //清空内容
    if(vaddr != NULL) {
        memset(vaddr, 0 , pg_cnt*PG_SIZE);
    }
    
    lock_release(&kernel_pool.lock);
    return vaddr;
}
/* 从用户物理内存池申请一页内存，并清空 */
/* 成功则返回虚拟地址，失败返回NULL */
void *get_user_pages(uint32_t pg_cnt)
{
    lock_acquire(&user_pool.lock);
    void *vaddr = malloc_page(PF_USER, pg_cnt);
    /*
    if(vaddr != NULL) {
        memset(vaddr, 0 , pg_cnt*PG_SIZE);
    }
    */
    lock_release(&user_pool.lock);
    return vaddr;
}
/* 将vaddr与pf池中的物理地址关联，只支持一页空间分配 */
void *get_a_page(enum pool_flag pf, uint32_t vaddr)
{
    ASSERT((vaddr & 0x00000fff) == 0);
    struct paddr_pool *mem_pool = pf & PF_KERNEL ? &kernel_pool: &user_pool;
    lock_acquire(&mem_pool->lock);
    //先将虚拟地址的位图置1
    struct task_struct *cur = running_thread();
    int32_t bit_idx = -1;
    if(cur->pgdir != NULL && pf == PF_USER) {               //当前是用户进程
        bit_idx = (vaddr - cur->userprog_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        bitmap_set(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx, 1);
    } else if(cur->pgdir == NULL && pf == PF_KERNEL) {      //当前是内核线程
        bit_idx = (vaddr - kernel_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx, 1);
    } else {
        PANIC("get_a_page: not allow 'kernel alloc userspace' or 'user alloc kernelspace'");
    }
    //做好虚拟地址与物理地址的映射
    void *alloced_phyaddr = paddr_get(mem_pool);
    ASSERT(alloced_phyaddr != NULL);
    if(alloced_phyaddr == NULL) {
        return NULL;
    }
    page_table_add((void *)vaddr, alloced_phyaddr);
    //
    lock_release(&mem_pool->lock);
    return (void *)vaddr;
}

/* 计算虚拟地址映射到的物理地址 */
uint32_t addr_v2p(uint32_t vaddr)
{
    uint32_t *pte = pte_ptr(vaddr);
    return (*pte & 0xfffff000) + (vaddr & 0x00000fff);
}
