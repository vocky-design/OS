#include "memory.h"
#include "debug.h"
#include "print.h"
#include "string.h"

#define PG_SIZE                 4096
#define MEM_BITMAP_BASE       0xc009a000  //1个物理块的PCB+4个物理块的位图
#define K_HEAP_START          0xc0100000  //跨过低端1MB内存，其实后面还要跨过loader.S中定义的页目录表和页表占用的物理地址0x100000-0x101ff。

#define PDE_IDX(addr)          ((addr & 0xffc00000) >> 22)
#define PTE_IDX(addr)          ((addr & 0x003ff000) >> 12)

#define ALL_MEM_ADDRESS        0xc0000b00 

struct paddr_pool {
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

    kernel_pool.pool_bitmap.btmp_bytes_len = kbm_length;
    user_pool.pool_bitmap.btmp_bytes_len = ubm_length;
    //位图的起始地址
    kernel_pool.pool_bitmap.bytes = (void *)MEM_BITMAP_BASE;
    user_pool.pool_bitmap.bytes = (void *)(MEM_BITMAP_BASE + kbm_length);
    
    bitmap_init(&kernel_pool.pool_bitmap);
    bitmap_init(&user_pool.pool_bitmap);
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

    kernel_vaddr_pool.pool_bitmap.bytes = (void *)(MEM_BITMAP_BASE + kbm_length + ubm_length);
    kernel_vaddr_pool.pool_bitmap.btmp_bytes_len = kbm_length;             //与内核物理地址大小一致
    kernel_vaddr_pool.vaddr_start = K_HEAP_START;
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
    uint32_t vaddr = (uint32_t)_vaddr;
    uint32_t paddr = (uint32_t)_paddr;

    uint32_t *pde = pde_ptr(vaddr);
    uint32_t *pte = pte_ptr(vaddr); 

    if(*pde & 0x1) {
        ASSERT(!(*pte & 0x1));  //当p=1时报错
        if(!(*pte & 0x1)) {     //当p=0时
            *pte = paddr | PG_P_1 | PG_RW_W | PG_US_U;
        } else {
            //前面有ASSERT，理论上不会走到这里。
        }
    } else {
        uint32_t page_addr_start = (uint32_t)paddr_get(&kernel_pool);
        memset((void*)page_addr_start, 0, PG_SIZE);
        *pde = page_addr_start | PG_P_1 | PG_RW_W | PG_US_U;
        ASSERT(!(*pte & 0x1));  //当p=1时报错
        *pte = paddr | PG_P_1 | PG_RW_W | PG_US_U;
    }
}

/* 分配cnt个页空间，成功则返回起始虚拟地址，失败返回NULL */
void *malloc_page(enum pool_flag pf, uint32_t pg_cnt)
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

/* 从内核物理内存池申请一页内存，成功则返回虚拟地址，失败返回NULL */
void *get_kernel_pages(uint32_t pg_cnt)
{
    void *vaddr = malloc_page(PF_KERNEL, pg_cnt);
    if(vaddr != NULL) {
        memset(vaddr, 0 , pg_cnt*PG_SIZE);
    }
    return vaddr;
}


