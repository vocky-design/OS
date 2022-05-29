#include "dir.h"

/* 打开主目录： */
void open_root_dir(struct partition *part)
{
    root_dir.inode = inode_open(part, ROOT_DIR_INODE);
}
/* 打开指定目录并返回目录指针，其实就是inode的打开 */
struct dir *dir_open(struct partition *part, uint32_t inode_no)
{
    ASSERT(inode_no < MAX_FILES_PER_PART);

    struct dir *dir_open = (struct dir *)sys_malloc(sizeof(struct dir));
    if(dir_open == NULL) {
        PANIC("alloc failed\n");
    }
    memset(dir_open, 0, sizeof(struct dir));

    dir_open->inode = inode_open(part, inode_no);
    return dir_open;
}
void dir_close(struct dir *dir)
{
    /***********根目录不可以关闭***********************
     1.根目录自打开后就不应该关闭，否则还需要再次open_root_dir()
     2.root_dir所在的内存是低端1MB之内，并非在堆中，free()会出问题。*/
    if(dir == &root_dir) {
        //printk("root dir can not be unistall\n");
        return;
    }
    inode_close(dir->inode);
    sys_free(dir);
}

/* 初始化目录项 */
void dir_entry_init(char *filename, uint32_t inode_no, \
    enum file_types f_type, struct dir_entry *entry)
{
    ASSERT(strlen(filename) <= MAX_FILE_NAME_LEN);
    memcpy(entry->filename, filename, strlen(filename) + 1);
    entry->f_type = f_type;
    entry->i_no = inode_no;
}

// /* 将目录项dir_entry写入到父目录parent_dir中，io_buf由主调函数提供 */
// bool dir_entry_sync(struct partition *part, struct dir *parent_dir, 
//     struct dir_entry *dir_entry, void *io_buf)
// {
//     //标志位
//     bool FIRST = FALSE;
//     //申请暂存all_blocks[]
//     uint32_t blocks_cnt = 12 + BLOCK_SIZE / 4;
//     uint32_t *all_blocks = (uint32_t *)sys_malloc(blocks_cnt * 4);
//     if(all_blocks == NULL) {
//         PANIC("alloc failed\n");
//     }

//     //复制12个块指针
//     memset(all_blocks, 0, blocks_cnt * 4);
//     memcpy(all_blocks, parent_dir->inode->i_sectors, 12 * 4);

//     //对140个blocks进行遍历
//     struct inode *dir_inode = parent_dir->inode;
//     for(int block_idx = 0; block_idx < blocks_cnt; ++block_idx) {
//         if(all_blocks[block_idx] == 0) {
//             //1.申请1个block，注册。
//             const int32_t block_bitmap_idx = block_bitmap_alloc(part);
//             if(block_bitmap_idx == -1) {
//                 printk("block_bitmap_alloc failed\n");
//                 sys_free(all_blocks);
//                 return FALSE;
//             }
//             bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP);
//             all_blocks[block_idx] = dir_inode->i_sectors[block_idx]= part->sb->data_start_lba + block_idx;
//             inode_sync(part, dir_inode, io_buf);

//             if(block_idx == 12) {
//                 //需要再申请一个block，用作第一个存储块
//                 const int32_t block_bitmap_idx = block_bitmap_alloc(part);
//                 const int32_t block_lba = part->sb->data_start_lba + block_idx;
//                 if(block_bitmap_idx == -1) {
//                     //回滚
//                     block_bitmap_free(part, block_bitmap_idx);
//                     printk("block_bitmap_alloc failed\n");
//                     return FALSE;
//                 }
//                 bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP); 
//                 //
//                 memset(io_buf, 0, BLOCK_SIZE); 
//                 memcpy(io_buf, &block_lba, sizeof(int32_t));
//                 ide_write(part->my_disk, block_lba, io_buf, 1);  
//                 //注意，很关键
//                 --block_idx;
//             } else { //block_idx != 12
//                 memset(io_buf, 0, BLOCK_SIZE);
//                 memcpy(io_buf, dir_entry, sizeof(struct dir_entry));
//                 ide_write(part->my_disk, all_blocks[block_idx], io_buf, 1);
//                 return TRUE;
//             }
//         } else {
//             if(block_idx == 12 && FIRST == FALSE) {
//                 FIRST = TRUE;
//                 ide_read(part->my_disk, all_blocks[block_idx], all_blocks+block_idx, 1);

//             } else { //block_idx != 12
//                 ide_read(part->my_disk, all_blocks[block_idx], io_buf, 1);
//                 struct dir_entry *entry = (struct dir_entry *)io_buf;
//                 for(int entry_idx = 0; entry_idx < DIR_ENTRY_NUM_PER_BLOCK; ++entry_idx) {
//                     if(entry->f_type == FT_UNKNOWN) {
//                         //添加目录项
//                         memcpy((struct dir_entry *)io_buf + entry_idx, dir_entry, sizeof(struct dir_entry));
//                         ide_write(part->my_disk, all_blocks[block_idx], io_buf, 1);                       
//                         return TRUE;
//                     }
//                     ++entry;
//                 }
//             }
//         }
//     }
//     return FALSE;
// }

/* 将目录项dir_entry写入到父目录parent_dir中，io_buf由主调函数提供 */
bool dir_entry_sync(struct partition *part, struct dir *parent_dir, \
    struct dir_entry *dir_entry, void *io_buf) {
    struct inode *parent_inode = parent_dir->inode;
    PRINTK_DEBUG("parent_dir->inode = %d\n", parent_dir->inode->i_no);
    struct dir_entry *dir_entry_start = (struct dir_entry *)io_buf;
    uint32_t const ALL_BLOCKS_NUM =  12 + BLOCK_SIZE / 4;
    uint32_t const ALL_BLOCKS_SIZE = ALL_BLOCKS_NUM * 4;
    uint32_t *all_blocks = sys_malloc(ALL_BLOCKS_SIZE);
    if(all_blocks == NULL) {
        printk("dir_entry_sync: all_blocks malloc failed\n");
        return FALSE;
    }
    memset(all_blocks, 0, ALL_BLOCKS_SIZE);

    memcpy(all_blocks, parent_inode->i_sectors, 12 * 4);
    if(parent_inode->i_sectors[12] != 0) {
        ide_read(part->my_disk, parent_inode->i_sectors[12], all_blocks + 12, 1);
    }

    for(uint32_t all_block_idx = 0; all_block_idx < ALL_BLOCKS_NUM; ++all_block_idx) {
        if(all_blocks[all_block_idx] != 0) {
            ide_read(part->my_disk, all_blocks[all_block_idx], io_buf, 1);
            for(uint32_t entry_idx = 0; entry_idx < DIR_ENTRY_NUM_PER_BLOCK; ++entry_idx) {
                if((dir_entry_start + entry_idx)->f_type == FT_UNKNOWN) {
                    memcpy((dir_entry_start + entry_idx), dir_entry, sizeof(struct dir_entry));
                    ide_write(part->my_disk, all_blocks[all_block_idx], io_buf, 1);
                    return TRUE;
                } 
            }
        } else {    //all_blocks[all_block_idx] == 0
            int32_t block_bitmap_idx = block_bitmap_alloc(part);
            if(block_bitmap_idx == -1) {
                printk("dir_entry_sync: First block_bitmap_alloc failed\n");
                sys_free(all_blocks);
                return FALSE;
            }
            bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP);
            all_blocks[all_block_idx] = parent_inode->i_sectors[all_block_idx] = block_bitmap_idx + part->sb->block_bitmap_lba;
            if(all_block_idx == 12) {
                block_bitmap_idx = block_bitmap_alloc(part);
                if(block_bitmap_idx == -1) {
                    printk("dir_entry_sync: Second block_bitmap_alloc failed\n");
                    sys_free(all_blocks);
                    return FALSE;
                }
                bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP);
                memset(io_buf, 0, BLOCK_SIZE);
                ((uint32_t *)io_buf)[0] = (uint32_t)block_bitmap_idx + part->sb->block_bitmap_lba;
                ide_write(part->my_disk, all_blocks[all_block_idx], io_buf, 1);
                all_blocks[all_block_idx] = block_bitmap_idx + part->sb->block_bitmap_lba;  //覆盖all_blocks[12]
            }
            memset(dir_entry_start, 0, BLOCK_SIZE);
            memcpy(dir_entry_start, dir_entry, sizeof(struct dir_entry));
            ide_write(part->my_disk, all_blocks[all_block_idx], io_buf, 1);
            return TRUE;            
        }
    }
    return FALSE;
}

/* 在dir目录中寻找名为name的文件或目录。找到后返回TRUE并将目录项存入entry_return，否则返回FALSE */
bool dir_entry_search(struct partition *part, struct dir *dir, \
    const char *name, struct dir_entry *entry_return)
{
    ASSERT(strlen(name) <= MAX_FILE_NAME_LEN);
    //准备暂存point_array和buf
    const uint32_t point_cnt = 12 + (BLOCK_SIZE / 4);
    uint32_t* const point_array = (uint32_t *)sys_malloc(point_cnt * 4);//一个指针占4字节
    if(point_array == NULL) {
        PANIC("alloc failed\n");
    }
    memset(point_array, 0, point_cnt * 4);
    uint32_t* const buf = (uint32_t *)sys_malloc(BLOCK_SIZE);
    if(buf == NULL) {
        PANIC("alloc failed\n");
    }
    //1.复制140个块指针.
    struct disk* const hd = part->my_disk;
    uint32_t* const sectors = dir->inode->i_sectors;
    PRINTK_DEBUG("dir->inode = %d\n", dir->inode->i_no);
    memcpy(point_array, sectors, 12 * 4);
    if(sectors[12] != 0) {
        ide_read(hd, sectors[12], point_array+12, 1);
    }

    //2.双循环：根据指针读目录数据块，分析目录项（都要跳过空项）
    uint32_t point_idx = 0;
    const uint32_t entry_num_per_block = BLOCK_SIZE / sizeof(struct dir_entry);
    while(point_idx < point_cnt) {
        //跳过空地址
        if(point_array[point_idx] == 0) {
            ++point_idx;
            continue;
        }
        //读目录数据块到buf
        memset(buf, 0, BLOCK_SIZE);
        ide_read(hd, point_array[point_idx], buf, 1);
        struct dir_entry *entry = (struct dir_entry *)buf;
        
        for (uint32_t i = 0; i < entry_num_per_block; i++)
        {
            //滤除空目录项和name不匹配的目录项
            if(entry->filename != NULL && !strcmp(name, entry->filename)) {
                memcpy(entry_return, entry, sizeof(struct dir_entry));
                sys_free(point_array);
                sys_free(buf);
                return TRUE;        
            }
            ++entry;
        }
        ++point_idx;
    }
    sys_free(point_array);
    sys_free(buf);
    return FALSE;
}

/* 删除某文件的目录项 */
bool dir_entry_delete(struct partition *part, struct dir *dir, uint32_t inode_no)
{
    struct inode *dir_inode = dir->inode;

    uint32_t *all_blocks = sys_malloc(12 * 4 + BLOCK_SIZE);
    if(all_blocks == NULL) {
        printk("dir_entry_delete: all_blocks alloc failed\n");
        return FALSE;
    }
    memset(all_blocks, 0, 12 * 4 + BLOCK_SIZE);

    
    void *io_buf = sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        printk("dir_entry_delete: io_buf alloc failed\n");
        return FALSE;
    }
    memset(io_buf, 0, BLOCK_SIZE);
    /* 1、收集目录全部块地址 */
    memcpy(all_blocks, dir_inode->i_sectors, 12 * 4);
    if(dir_inode->i_sectors[12] != 0) {
        ide_read(part->my_disk, dir_inode->i_sectors[12], all_blocks + 12, 1);
    }
    /* 2、遍历所有块，寻找目录项 */
    bool is_dir_first_block = FALSE;    //目录的第一个block
    uint32_t dir_entry_cnt = 0;         //统计除了.和..外的目录项数
    struct dir_entry *dir_entry_found = NULL;
    uint32_t block_idx = 0;
    while(block_idx < 12 + BLOCK_SIZE / 4) {
        if(all_blocks[block_idx] == 0) {
            ++block_idx;
            continue;
        }
        ide_read(part->my_disk, all_blocks[block_idx], io_buf, 1);
        /* 遍历所有的目录项，统计该扇区的目录项数量及是否有待删除的目录项 */
        struct dir_entry *dir_entry_start = (struct dir_entry *)io_buf;
        uint32_t dir_entry_idx = 0;
        while(dir_entry_idx < DIR_ENTRY_NUM_PER_BLOCK) {
            if((dir_entry_start + dir_entry_idx)->f_type != FT_UNKNOWN) {
                if(!strcmp((dir_entry_start + dir_entry_idx)->filename, ".")) {
                    is_dir_first_block = TRUE;
                } else if(strcmp((dir_entry_start + dir_entry_idx)->filename, ".") && \
                            strcmp((dir_entry_start + dir_entry_idx)->filename, "..")) {
                    ++dir_entry_cnt;
                    if((dir_entry_start + dir_entry_idx)->i_no == inode_no) {
                        ASSERT(dir_entry_found == NULL);
                        dir_entry_found = (dir_entry_start + dir_entry_idx);
                    }
                }
            }
            ++dir_entry_idx;
        }
        if(dir_entry_found == NULL) {
            ++block_idx;
            continue;
        }
        /* 在此扇区找到目录项后，清除该目录项并判断是否回收扇区，随后退出循环直接返回 */
        ASSERT(dir_entry_cnt >= 1); //至少有一个目录项
        /* 除了目录第一个扇区外，若该扇区上只有该目录项自己，则将整个扇区回收 */
        if(dir_entry_cnt == 1 && !is_dir_first_block) {
            /* a、在块位图上回收该块 */
            uint32_t block_bitmap_idx = all_blocks[block_idx] - part->sb->data_start_lba;
            block_bitmap_free(part, block_bitmap_idx);
            bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP);
            /* b、将地址从数组i_sectors或索引表中去掉 */
            if(block_idx < 12) {
                dir_inode->i_sectors[block_idx] = 0;
            } else {
                /* 先判断索引表中块地址的数量，如果仅有这一个间接块，连同间接索引表所在的块一起回收 */
                uint32_t indirect_blocks = 0;
                uint32_t indirect_block_idx = 12;
                while(indirect_block_idx < 12 + BLOCK_SIZE / 4) {
                    if(all_blocks[indirect_block_idx] != 0) {
                        ++indirect_blocks;
                    }
                    ++indirect_block_idx;
                }
                ASSERT(indirect_blocks >= 1);
                if(indirect_blocks > 1) {
                    all_blocks[block_idx] = 0;
                    ide_write(part->my_disk, dir_inode->i_sectors[12], all_blocks + 12, 1);
                } else {    //indirect_blocks == 1
                    block_bitmap_idx = dir_inode->i_sectors[12] - part->sb->data_start_lba;
                    block_bitmap_free(part, block_bitmap_idx);
                    bitmap_sync(part, block_bitmap_idx, BLOCK_BITMAP);
                    /* 将间接索引表地址清0 */
                    dir_inode->i_sectors[12] = 0;
                }
            }
        } else {   
            memset(dir_entry_found, 0, DIR_ENTRY_SIZE);
            ide_write(part->my_disk, all_blocks[block_idx], io_buf, 1);
        }

        /* 更新i节点信息并同步到硬盘 */
        ASSERT(dir_inode->i_size >= DIR_ENTRY_SIZE);
        dir_inode->i_size -= DIR_ENTRY_SIZE;
        memset(io_buf, 0, BLOCK_SIZE);
        inode_sync(part, dir_inode, io_buf);

        sys_free(io_buf);
        sys_free(all_blocks);
        return TRUE;
    }    
    return FALSE;
}




/* namestore[]存储第一级名字；返回剩下级别的名字
    比如："//a/b/c" 
    第一次运行：namestore = "a"; 返回="/b/c"*/
const char *path_parse(const char *pathname, char *name_store)
{
    //  '/'不需要解析
    if(pathname[0] == '/') {
        //兼容多'/'根目录的情况
        while(*(++pathname) == '/');
    }
    //开始一般的路径解析
    while(*pathname != 0 && *pathname != '/') {
        *name_store++ = *pathname++;
    }

    if(pathname[0] == 0) {
        return NULL;
    }

    return pathname;
}

/* 返回路径深度，比如/a/b/c，路径深度是3 */
uint32_t path_depth_calculate(const char *pathname)
{
    ASSERT(pathname != NULL);

    const char *p = pathname;
    char name[MAX_FILE_NAME_LEN] = {0};
    uint32_t depth = 0;
    p = path_parse(p, name);
    PRINTK_DEBUG("name_store: %s\n", name);
    while(name[0]) {
        ++depth;
        memset(name, 0 ,MAX_FILE_NAME_LEN);
        if(p) {
            p = path_parse(p, name);
            PRINTK_DEBUG("name_store: %s", name);
        }
    }
    return depth;
}


/* 搜索文件pathname，若找到则返回inode号，否则返回-1 */
int32_t search_file(char *pathname, struct path_search_record *searched_record)
{
    //至少保证路径是/?的形式，并且长度满足要求
    ASSERT(pathname[0] == '/' && strlen(pathname) > 1 && strlen(pathname) < MAX_PATH_LEN);

    //如果待查找的是根目录，为避免下面无用的查找，直接返回已知根目录信息
    while(*(pathname + 1) == '/') {
        ++pathname;
    }
    if(!strcmp(pathname, "/") || !strcmp(pathname, "/.") || !strcmp(pathname, "/..")) {
        searched_record->file_type = FT_DIRECTORY;
        searched_record->parent_dir = &root_dir;
        searched_record->searched_path[0] = 0;
        return 0;
    }

    char *sub_path = pathname;
    struct dir_entry dir_e;

    char name[MAX_PATH_LEN] = {0};

    searched_record->parent_dir = &root_dir;
    searched_record->file_type = FT_UNKNOWN;
    searched_record->searched_path[0] = 0;

    sub_path = path_parse(sub_path, name);
    while(name[0]) {
        //每次解析过的路径都会追加到searched_record->searched_path
        strcat(searched_record->searched_path, "/");
        strcat(searched_record->searched_path, name);

        //目录中查找文件
        if(dir_entry_search(cur_part, searched_record->parent_dir, name, &dir_e)) {
            PRINTK_DEBUG("searched_record->parent_dir = %d\n", searched_record->parent_dir->inode->i_no);
            memset(name, 0 ,MAX_PATH_LEN);
            if(sub_path) {
                sub_path = path_parse(sub_path, name);
            }

            if(dir_e.f_type == FT_DIRECTORY) {
                dir_close(searched_record->parent_dir);
                searched_record->parent_dir = dir_open(cur_part, dir_e.i_no);
                continue;
            } else if(dir_e.f_type == FT_REGULAR) {
                searched_record->file_type = FT_REGULAR;
                PRINTK_DEBUG("dir_e.i_no = %d\n", dir_e.i_no);
                return dir_e.i_no;
            }
        } else { //若找不到，返回-1
            //找不到目录项时，要留着parent_dir不要关闭，因为若是新创建文件的话，需要在parent_dir中创建。
            return -1;
        }
    }

    //执行到此，必然是经历了完整路径，并且查找的文件或目录只有同名目录存在
    //TODO 此处有个小bug
    dir_close(searched_record->parent_dir);

    //保存被查找目录的父目录
    //searched_record->parent_dir = dir_open(cur_part, parent_inode_no);
    searched_record->file_type = FT_DIRECTORY;
    return dir_e.i_no;
}

