#include "memory.h"
#include "debug.h"
#include "print.h"

#define PG_SIZE                 4096
#define MEM_BITMAP_BASE       0xc009a000  //1个物理块的PCB+4个物理块的位图
#define K_HEAP_START            0xc0100000  //跨国低端1MB内存，其实后面还要跨过loader.S中定义的页目录表和页表占用的物理地址0x100000-0x101ff。

struct paddr_pool {
    struct bitmap paddr_bitmap;
    uint32_t paddr_start;
    uint32_t pool_size;         //以一个物理块为基本单位  4K
};
struct paddr_pool kernel_pool, user_pool;
struct vaddr_pool kernel_vaddr_pool;

static void mem_pool_init(uint32_t all_mem)
{
    put_str("   mem_pool_init start\n");
    uint32_t page_table_size = 256 * PG_SIZE;           //1个目录表，0和768页目录项指向同一页表，769-1022目录项指向254个页表。
    uint32_t used_mem = page_table_size + 0x100000;     //加上低端1MB内存。
    uint32_t free_mem = all_mem - used_mem;
    uint32_t free_pages = free_mem / PG_SIZE;
    uint32_t kernel_free_pages = free_pages / 2;
    uint32_t user_free_pages = free_pages - kernel_free_pages;
    //为简化位图操作，余数不处理，坏处是这样做会丢内存；好处是不用做内存的越界检查，因为位图表示的内存少于实际物理内存。
    uint32_t kbm_length = kernel_free_pages / 8;
    uint32_t ubm_length = user_free_pages / 8;
    uint32_t kp_start = used_mem;
    uint32_t up_start = used_mem + kernel_free_pages * PG_SIZE;

    kernel_pool.pool_size = kernel_free_pages;
    user_pool.pool_size = user_free_pages;

    kernel_pool.paddr_start = kp_start;
    user_pool.paddr_start = up_start;

    kernel_pool.paddr_bitmap.btmp_bytes_len = kbm_length;
    user_pool.paddr_bitmap.btmp_bytes_len = ubm_length;

    kernel_pool.paddr_bitmap.bits = (void *)MEM_BITMAP_BASE;
    user_pool.paddr_bitmap.bits = (void *)(MEM_BITMAP_BASE + kbm_length);
    
    bitmap_init(&kernel_pool.paddr_bitmap);
    bitmap_init(&user_pool.paddr_bitmap);
    //输出内存池信息
    put_str("   kernel_pool_bitmap_start:");
    put_int((uint32_t)kernel_pool.paddr_bitmap.bits);
    put_str("   kernel_pool_paddr_start:");
    put_int((uint32_t)kernel_pool.paddr_start);
    put_char('\n');
    put_str("   user_pool_bitmap_start:");
    put_int((uint32_t)user_pool.paddr_bitmap.bits);
    put_str("   user_pool_paddr_start:");
    put_int((uint32_t)user_pool.paddr_start);
    put_char('\n');   

    kernel_vaddr_pool.vaddr_bitmap.bits = (void *)(MEM_BITMAP_BASE + kbm_length + ubm_length);
    kernel_vaddr_pool.vaddr_bitmap.btmp_bytes_len = kbm_length;             //与内核物理地址大小一致
    kernel_vaddr_pool.vaddr_start = K_HEAP_START;
    bitmap_init(&kernel_vaddr_pool.vaddr_bitmap);

    put_str("   mem_pool_init done\n");
}

void mem_init(void) 
{
    put_str("mem_init start\n");
    uint32_t mem_bytes_total = (*(uint32_t *)0xc0000b00);
    mem_pool_init(mem_bytes_total);
    put_str("mem_init done\n");
}