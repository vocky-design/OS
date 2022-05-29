#ifndef _KERNEL_FS_FILE_H
#define _KERNEL_FS_FILE_H

#include "global.h"
#include "thread.h"
#include "config.h"
#include "device/ide.h"
#include "dir.h"

struct partition *cur_part;  
enum oflags {
    O_RDONLY = 1,
    O_WRONLY = 2,
    O_RDWR = 4,
    O_CREAT = 8,
};
/* 文件结构 */
struct file {
    struct inode    *fd_inode;
    uint32_t        fd_pos;             //文件偏移，最小0，最大-1(文件大小)
    uint8_t        fd_flags;           //uint8_t说明能支持8种flag
};

/* 标准输入输出描述符 */
enum std_fd {
    stdin_no,
    stdout_no,
    stderr_no,
};

/* 文件读写位置偏移量 */
enum whence {
    SEEK_SET = 1,
    SEEK_CUR,
    SEEK_END
};

/* 文件属性结构体 */
struct stat {
    uint32_t st_ino;
    uint32_t st_size;
    enum file_types st_ftype;
};


/*  */
struct file file_table[MAX_FILES_OPEN];

int32_t file_table_alloc(void);
void file_table_free(uint32_t fd_idx);
int32_t pcb_fd_install(int32_t global_fd_idx);


int32_t sys_open(const char *pathname, uint8_t flags);
int32_t sys_close(uint32_t fd);
int32_t sys_write(int32_t fd, const void *buf, uint32_t count);
int32_t sys_read(int32_t fd, void *buf, uint32_t count);
int32_t sys_lseek(int32_t fd, int32_t offset, uint8_t whence);
int32_t sys_unlink(const char *pathname);
int32_t sys_stat(const char *pathname, struct stat *buf);
#endif
