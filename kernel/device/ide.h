#ifndef _KERNEL_DEVICE_IDE_H
#define _KERNEL_DEVICE_IDE_H

#include "global.h"
#include "sync.h"
struct partition {
    char name[8];
    uint32_t start_lba;             //起始扇区
    uint32_t sec_cnt;               //扇区数
    struct disk *my_disk;           //此分区属于哪个硬盘
    struct list_elem part_tag;
    struct super_block *sb;
    struct bitmap block_bitmap;
    struct bitmap inode_bitmap;
    struct list open_inodes; 
};

struct disk {
    char name[8];
    struct ide_channel *my_channel;     //此硬盘归属于哪个ide通道
    uint8_t dev_no;                     //主盘0，从盘1
    struct partition prim_parts[4];
    struct partition logic_parts[8];
};

struct ide_channel {
    char name[8];                       
    uint16_t port_base;                 //控制起始端口
    uint8_t irq_no;                     //所用的中断号
    struct lock lock;                   //通道锁
    bool expecting_intr;                //表示正在等待通道的中断
    struct semaphore disk_done;         //用于阻塞，唤醒驱动程序
    struct disk device[2];
};


#endif