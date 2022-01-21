#ifndef  _KERNEL_MEMORY_H
#define  _KERNEL_MEMORY_H
#include "stdint.h"
#include "bitmap.h"

/* 虚拟地址池，用于虚拟地址管理 */
struct vaddr_pool {
    struct bitmap vaddr_bitmap;     //虚拟地址用到的位图结构
    uint32_t vaddr_start;           //虚拟地址起始地址
};
void mem_init(void); 
#endif