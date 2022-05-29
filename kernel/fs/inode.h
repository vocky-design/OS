#ifndef _KERNEL_FS_INODE_H
#define _KERNEL_FS_INODE_H

#include "stdint.h"
#include "config.h"
#include "ide.h"
#include "super_block.h"
#include "fs.h"

struct inode {
    uint32_t i_no;
    uint32_t i_size;
    uint32_t i_open_cnts;
    bool write_deny;                //写文件不能并行，进程写文件前检查此标志。
    //i_sectors[0-11]是直接块指针，i_sectors[12]用来存储一级间接块指针
    uint32_t i_sectors[13];         //块lba地址   
    struct list_elem inode_tag;  
};

#define INODE_SIZE  (sizeof(struct inode))
#define INODE_NUM_PER_BLOCK     (BLOCK_SIZE / INODE_SIZE)


void inode_init(uint32_t inode_no, struct inode *new_inode);
void inode_sync(struct partition *part, struct inode *inode, void *io_buf);
struct inode *inode_open(struct partition *part, uint32_t i_no);
void inode_close(struct inode *inode);
int32_t inode_release(struct partition *part, uint32_t inode_no);
#endif