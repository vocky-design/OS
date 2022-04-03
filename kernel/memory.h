#ifndef  _KERNEL_MEMORY_H
#define  _KERNEL_MEMORY_H
#include "global.h"
#include "sync.h"

/* 虚拟地址池，用于虚拟地址管理 */
struct vaddr_pool {
    struct bitmap pool_bitmap;
    uint32_t vaddr_start;
};

/* 内存池标记，用于判断使用哪个内存池 */
enum pool_flag {
    PF_KERNEL = 1,
    PF_USER   = 2
};

/* 内存块 */
struct mem_block {
    struct list_elem free_elem;
};

/* 内存块描述符 */
struct mem_block_desc {
    uint32_t block_size;        //块大小
    uint32_t blocks_per_arena;  //每arena块数
    struct list free_list;      //块链
};

/* 内存仓库arena */
struct arena {
    struct mem_block_desc *desc;
    uint32_t cnt;
    bool large;
};

#define DESC_CNT 7

void mem_init(void); 
uint32_t *pde_ptr(uint32_t vaddr);
uint32_t *pte_ptr(uint32_t vaddr);
void *get_kernel_pages(uint32_t pg_cnt);
void *get_user_pages(uint32_t pg_cnt);
void *get_a_page(enum pool_flag pf, uint32_t vaddr);
uint32_t addr_v2p(uint32_t vaddr);\

void block_desc_init(struct mem_block_desc *desc_array);
void *sys_malloc(uint32_t size);
void sys_free(void *ptr);
#endif