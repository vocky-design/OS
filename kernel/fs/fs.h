#ifndef _KERNEL_FS_FS_H
#define _KERNEL_FS_FS_H


#include "global.h"
#include "fs/config.h"
#include "device/ide.h"
#include "inode.h"
#include "file.h"
#include "dir.h"
/* 位图类型 */
enum bitmap_type {
    INODE_BITMAP,
    BLOCK_BITMAP
};

//当前挂载的分区
struct partition *cur_part;     

void filesys_init(void);

int32_t inode_bitmap_alloc(struct partition *part);
void inode_bitmap_free(struct partition *part, uint32_t inode_no);
int32_t block_bitmap_alloc(struct partition *part);
void block_bitmap_free(struct partition *part, uint32_t block_idx);
void bitmap_sync(struct partition *part, uint32_t idx, enum bitmap_type bitmap_type);

#endif