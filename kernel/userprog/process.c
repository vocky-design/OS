#include "process.h"

/* 创建页目录表：成功则返回页目录表的虚拟地址  */
uint32_t *create_pdt(void)
{
    uint32_t *page_dir_vaddr = get_kernel_pages(1);
    if(page_dir_vaddr == NULL) {
        return NULL;
    }
    memcpy((void *)((uint32_t)page_dir_vaddr + 0x300 * 4), (void *)(0xfffff000 + 0x300 * 4), 1024);
    uint32_t to_phyaddr = addr_v2p((uint32_t)page_dir_vaddr);
    page_dir_vaddr[1023] = to_phyaddr | PG_US_U | PG_RW_W | PG_P_1;
    return page_dir_vaddr;
}

/* 创建用户进程虚拟地址位图 */
void create_vaddr_bitmap(struct task_struct *user_prog)
{
    user_prog->userprog_vaddr_pool.vaddr_start = USER_ADDR_START;
    uint32_t bitmap_bytes_len = (0xc0000000-USER_ADDR_START) / PG_SIZE / 8 ;
    uint32_t bitmap_page_len = DIV_ROUND_UP(bitmap_bytes_len, PG_SIZE);
    bitmap_init(&user_prog->userprog_vaddr_pool.pool_bitmap, get_kernel_pages(bitmap_page_len), bitmap_bytes_len);
}