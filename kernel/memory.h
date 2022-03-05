#ifndef  _KERNEL_MEMORY_H
#define  _KERNEL_MEMORY_H
#include "global.h"
#include "stdint.h"
#include "debug.h"
#include "print.h"
#include "string.h"
#include "bitmap.h"
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


void mem_init(void); 
uint32_t *pde_ptr(uint32_t vaddr);
uint32_t *pte_ptr(uint32_t vaddr);
void *get_kernel_pages(uint32_t pg_cnt);
void *get_user_pages(uint32_t pg_cnt);
void *get_a_page(enum pool_flag pf, uint32_t vaddr);
uint32_t addr_v2p(uint32_t vaddr);
#endif