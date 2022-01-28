#ifndef  _KERNEL_MEMORY_H
#define  _KERNEL_MEMORY_H
#include "stdint.h"
#include "bitmap.h"

/* 虚拟地址池，用于虚拟地址管理 */
struct vaddr_pool {
    struct bitmap pool_bitmap;     //虚拟地址用到的位图结构
    uint32_t vaddr_start;           //虚拟地址起始地址
};
/* 内存池标记，用于判断使用哪个内存池 */
enum pool_flag {
    PF_KERNEL = 1,
    PF_USER   = 2
};
/* 页表项和页目录项的一些属性定义 */
#define PG_P_0  0
#define PG_P_1  1
#define PG_RW_R 0       //读/执行
#define PG_RW_W 2       //读/写/执行
#define PG_US_S 0       //系统级，不允许3特权级
#define PG_US_U 4       //用户级别，任意特权级

void mem_init(void); 
uint32_t *pde_ptr(uint32_t vaddr);
uint32_t *pte_ptr(uint32_t vaddr);
void *malloc_page(enum pool_flag pf, uint32_t pg_cnt);
void *get_kernel_pages(uint32_t pg_cnt);
#endif