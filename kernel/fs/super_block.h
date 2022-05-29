#ifndef _KERNEL_FS_SUPERBLOCK_H
#define _KERNEL_FS_SUPERBLOCK_H

#include "global.h"

struct super_block {
    uint32_t fs_type;

    uint32_t lba_base;
    uint32_t sec_cnt;
    
    uint32_t block_bitmap_lba;
    uint32_t block_bitmap_sects;

    uint32_t inode_bitmap_lba;
    uint32_t inode_bitmap_sects; 

    uint32_t inode_table_lba;
    uint32_t inode_table_sects;

    uint32_t data_start_lba;        //数据区

    uint8_t pad[472];               //仅作填充
}__attribute__((packed));

#endif