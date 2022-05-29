#ifndef _KERNEL_FS_CONFIG_H
#define _KERNEL_FS_CONFIG_H

//文件系统类型
#define FS_TYPE 0x19590318
//系统配置
#define SECTOR_SIZE                 512
#define BLOCK_SIZE                  SECTOR_SIZE             //一个BLOCK是一扇区
#define BLOCK_ADDR_SIZE             4                       //4字节
#define MAX_INODES_PER_PART         4096
#define MAX_FILES_PER_PART          MAX_INODES_PER_PART     //INODE是FILE的底层机制
#define ROOT_DIR_INODE          0
#define MAX_FILES_OPEN 32                                   //系统可打开的最大文件数

#define BITS_PER_BLOCK              (BLOCK_SIZE * 8)
#define BLOCK_ADDR_NUM_PER_BLOCK    (BLOCK_SIZE / BLOCK_ADDR_SIZE)



//路径解析
#define MAX_PATH_LEN            512

#endif