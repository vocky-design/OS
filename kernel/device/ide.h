#ifndef _KERNEL_DEVICE_IDE_H
#define _KERNEL_DEVICE_IDE_H

#include "global.h"
#include "sync.h"
#include "io.h"
#include "timer.h"
#include "interrupt.h"

struct partition {
    //ide_init初始化部分
    char name[8];
    uint32_t start_lba;             //起始扇区
    uint32_t sec_cnt;               //扇区数
    struct disk *my_disk;           //此分区属于哪个硬盘
    struct list_elem part_tag;
    //mount_partition初始化部分(执行mount_partition前已经在硬盘中设置好了以下内容)
    struct super_block *sb;         //超级块指针
    struct bitmap block_bitmap;
    struct bitmap inode_bitmap;
    struct list open_inodes;        //打开的inode
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

uint8_t channel_cnt;            //通道数
struct ide_channel channels[2]; //通道数组
struct list partition_list;     //分区队列

void ide_init(void);
void ide_read(struct disk *hd, uint32_t lba, void *buf, uint8_t sec_cnt);
void ide_write(struct disk *hd, uint32_t lba, void *buf, uint8_t sec_cnt);

#endif