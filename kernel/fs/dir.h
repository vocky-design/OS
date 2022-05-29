#ifndef _KERNEL_FS_DIR_H
#define _KERNEL_FS_DIR_H

#define MAX_FILE_NAME_LEN 16
#include "stdint.h"
#include "config.h"
#include "device/ide.h"
#include "fs/inode.h"
#include "fs/fs.h"
/* 目录 */
struct dir {
    struct inode *inode;
    uint32_t dir_pos;       //记录在目录中的偏移
    uint8_t dir_buf[512];   //目录的数据缓存
};

enum file_types {
    FT_UNKNOWN = 0,     //不支持的文件类型
    FT_REGULAR = 1,     //普通文件
    FT_DIRECTORY = 2   //目录文件
};

/* 目录项结构 */
struct dir_entry {
    char filename[MAX_FILE_NAME_LEN];      //文件名最大长度16
    uint32_t i_no;                         //目录项的父目录     
    enum file_types f_type;    
};

/* 用来记录查找文件过程中已经找到的上级路径，也就是查找文件过程中“走过的地方”。 */
struct path_search_record {
    char searched_path[MAX_PATH_LEN];
    struct dir *parent_dir;
    enum file_types file_type;
};

#define DIR_ENTRY_SIZE (sizeof(struct dir_entry))
#define DIR_ENTRY_NUM_PER_BLOCK (BLOCK_SIZE / DIR_ENTRY_SIZE)

//根目录
struct dir root_dir;

void open_root_dir(struct partition *part);
struct dir *dir_open(struct partition *part, uint32_t inode_no);
bool dir_entry_search(struct partition *part, struct dir *dir, \
    const char *name, struct dir_entry *entry_return);
void dir_close(struct dir *dir);
void dir_entry_init(char *filename, uint32_t inode_no, \
    enum file_types f_type, struct dir_entry *entry);
bool dir_entry_sync(struct partition *part, struct dir *parent_dir, \
    struct dir_entry *dir_entry, void *io_buf);
bool dir_entry_delete(struct partition *part, struct dir *dir, uint32_t inode_no);

const char *path_parse(const char *pathname, char *name_store);
uint32_t path_depth_calculate(const char *pathname);
int32_t search_file(char *pathname, struct path_search_record *searched_record);
#endif