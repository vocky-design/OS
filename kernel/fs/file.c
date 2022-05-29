#include "file.h"

/* 从文件表fd_table获取一个空闲位。成功返回下标，失败返回-1 */
int32_t file_table_alloc(void) 
{
    //跳过前3个
    for(int i=3; i<MAX_FILES_OPEN; ++i) {
        if(file_table[i].fd_inode == NULL) {
            return i;
        }
    }
    return -1;  
}

inline void file_table_free(uint32_t fd_idx)
{
    memset(file_table + fd_idx, 0, sizeof(struct file));
}

/* 将文件全局描述符下标安装到进程的文件描述符数组file_table中。成功返回下标，失败返回-1 */
int32_t pcb_fd_install(int32_t global_fd_idx)
{
    struct task_struct *cur_thread = running_thread();
    for(int i=3; i<MAX_FILES_OPEN_PER_PROC; ++i) {
        if(cur_thread->fd_table[i] == -1) {
            cur_thread->fd_table[i] = global_fd_idx;
            return global_fd_idx;
        }
    }
    return -1;
}



/****************************************************************************************************************
 * **************************************************sys_open****************************************************
 * **************************************************************************************************************/
/* 若成功则返回文件描述符，失败返回-1 */
static int32_t file_create(struct dir *parent_dir, const char *filename, uint8_t flags)
{
    /*******************************准备部分**********************************/
    /* 准备公用缓冲区 */
    void *io_buf = sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        printk("io_buf alloc failed\n");
        return -1;
    }

    /* 申请inode号 */
    int32_t inode_no = inode_bitmap_alloc(cur_part);
    if(inode_no == -1) {
        printk("inode_bitmap_alloc failed\n");
        goto f1;
    }

    /* 准备inode对象 */
    //因为还要挂载open_inodes链表上，所以要在堆中申请
    struct inode *new_inode = (struct inode *)sys_malloc(sizeof(struct inode));
    if(new_inode == NULL) {
        printk("struct inode alloc failed\n");
        goto f2;
    }
    inode_init(inode_no, new_inode);

    /* 申请file_table空位，初始化file_table申请下来的项目*/
    int32_t fd_idx = file_table_alloc();
    if(fd_idx == -1) {
        goto f3;
    }
    file_table[fd_idx].fd_inode = new_inode;
    file_table[fd_idx].fd_pos = 0;
    file_table[fd_idx].fd_flags = flags;

    /* 准备dir_entry */
    struct dir_entry dir_e;
    dir_entry_init(filename, inode_no, FT_REGULAR, &dir_e);

    /**************************************上传部分*******************************/
    /* 上传dir_entry */
    memset(io_buf, 0, BLOCK_SIZE);
    dir_entry_sync(cur_part, parent_dir, &dir_e, io_buf);

    /* 上传更新父目录inode */
    parent_dir->inode->i_size += sizeof(struct dir_entry);
    memset(io_buf, 0, BLOCK_SIZE);
    inode_sync(cur_part, parent_dir->inode, io_buf);

    /*上传新创建inode*/
    memset(io_buf, 0, BLOCK_SIZE);
    inode_sync(cur_part, new_inode, io_buf);

    /* 上传更新inode_bitmap */
    bitmap_sync(cur_part, inode_no, INODE_BITMAP);

    /* 将new_inode添加到open_inodes链表 */
    //create就算是打开文件一次了。
    list_push(&cur_part->open_inodes, &new_inode->inode_tag);
    new_inode->i_open_cnts = 1;

    /* 安装本进程pcb的fd */
    const int32_t pcb_fd_idx = pcb_fd_install(fd_idx);

    sys_free(io_buf);
    return pcb_fd_idx;

    /************************************资源释放部分**********************************/
    f3:
        sys_free(new_inode);
    f2:
        inode_bitmap_free(cur_part, inode_no);
    f1:
        sys_free(io_buf);

    return -1;
}
/* 1.从全局文件描述符表申请空位
   2.打开inode，填充全局描述符
   3.pcb_fd_install */
/* 若成功返回文件描述符，否则返回-1 */
static int32_t file_open(uint32_t inode_no, uint8_t flags)
{
    //1.从全局文件描述符表申请空位
    int32_t file_idx = file_table_alloc();
    if(file_idx == -1) {
        printk("exceed max open files\n");
        return -1;
    }
    PRINTK_DEBUG("file_idx = %d\n", file_idx);

    //2.打开inode，填充全局描述符
    file_table[file_idx].fd_inode = inode_open(cur_part, inode_no);
    file_table[file_idx].fd_pos = 0;
    file_table[file_idx].fd_flags = flags;

    //TODO 有必要在这里验证吗？
    //3.只支持一个写入，不支持并发写入
    bool *write_deny = &file_table[file_idx].fd_inode->write_deny;
    if(flags & O_WRONLY || flags & O_RDWR) {
        enum intr_status old_status = intr_disable();

        if(!(*write_deny)) {
            *write_deny = TRUE;
            intr_set_status(old_status);
        } else {
            intr_set_status(old_status);
            printk("file can't be wrote now, try again later\n");
            return -1;
        }
    }
    //若是读文件，不用理会write_deny
    return pcb_fd_install(file_idx);
}
//TODO
int32_t sys_open(const char *pathname, uint8_t flags)
{
    /* 对目录要用dir_open,目前还未实现 */
    if(pathname[strlen(pathname)-1] == '/') {
        printk("Can't open a directory %s\n", pathname);
        return -1;
    }
    
    int32_t fd = -1;

    struct path_search_record searched_record;
    //memset(&searched_record, 0, sizeof(struct path_search_record));

    int32_t inode_no = search_file(pathname, &searched_record);
    bool found = inode_no != -1 ? TRUE : FALSE;

    const uint32_t pathname_depth = path_depth_calculate(pathname);
    const uint32_t path_searched_depth = path_depth_calculate(searched_record.searched_path);
    if(pathname_depth != path_searched_depth) {
        printk("Can't access %s: Not a directory, subpath %s isn't exist\n", \
            pathname, searched_record.searched_path);
        dir_close(searched_record.parent_dir);
        return -1;
    }

    if(!found && !(flags & O_CREAT)) {
        printk("in path %s, file %s isn't exist\n", \
           searched_record.searched_path, (strrchr(searched_record.searched_path, '/')) + 1 );
        dir_close(searched_record.parent_dir);
        return -1;   
    } else if(found && (flags & O_CREAT)) {
        printk("%s has already exist\n", pathname);
        dir_close(searched_record.parent_dir);
        return -1; 
    }

    switch(flags & O_CREAT) {
        case O_CREAT:
            printk("creating file\n");
            fd = file_create(searched_record.parent_dir, strrchr(pathname, '/') + 1, flags);
            PRINTK_DEBUG("searched_record.parent_dir = %d\n", searched_record.parent_dir->inode->i_no);
            dir_close(searched_record.parent_dir);    
            break;
        default:
            //除了创建文件，其他就都是直接打开文件了，调用file_open
            fd = file_open(inode_no, flags);        
    }

    return fd;
}


static int32_t file_close(struct file *file)
{
    if(file == NULL) {
        return -1;
    }

    file->fd_inode->write_deny = FALSE;
    inode_close(file->fd_inode);
    file->fd_inode = NULL;  //使文件结构可用
    return 0;
}

/* 将PCB文件描述符转换为全局file_table的下标 */
static uint32_t local_fd_to_global_index(uint32_t local_fd)
{
    struct task_struct *cur_thread = running_thread();
    int32_t global_index = cur_thread->fd_table[local_fd];
    ASSERT(global_index >= 0 && global_index < MAX_FILES_OPEN);
    return (uint32_t)global_index;
}

/* 关闭文件描述符fd指向的文件，成功返回0，失败返回-1 */
int32_t sys_close(uint32_t fd)
{
    int32_t ret = -1;
    if(fd > 2) {
        uint32_t file_idx = local_fd_to_global_index(fd);
        ret = file_close(&file_table[file_idx]);
        running_thread()->fd_table[fd] = -1;    //使该文件描述符位可用
    } else {
        printk("Can't close fd %d\n", fd);
    }
    return ret;
}
/*1.申请足够的blocks
  2.再申请1个block，安装在inode->sectors[12]
  3.更新block_bitmap
  3.先更新inode以更新inode->sectors
  4.再用ide_write更新inode->sectos[12]指向的那一块
*/
/* 成功返回0，失败返回-1
　　all_blocks需要是清零的 */
static int32_t all_blocks_download_for_write(struct inode *inode, uint32_t *all_blocks, uint32_t blocks_new_idx)
{
    /* 申请空间 */
    uint32_t *io_buf = (uint32_t *)sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        printk("io_buf alloc failed\n");
        return -1;
    }
    //1. 准备好空间，更新好数据结构  
    uint32_t blocks_old_idx = inode->i_size / BLOCK_SIZE;  
    uint32_t blocks_add = blocks_new_idx - blocks_old_idx;       //需要申请新增的block数
    uint32_t all_blocks_idx = blocks_old_idx;
    int32_t block_idx = -1;     //bitmap申请返回位
    /* 保存一个inode->i_sectors副本，用于错误恢复 */
    uint32_t i_sectors_bak[13];
    memcpy(i_sectors_bak, inode->i_sectors, 13 * 4);    
    /* 如果待操作的第一块不存在，那么提前准备好，因为后面是默认第一个操作块存在的 */
    if(inode->i_size % BLOCK_SIZE == 0) {    
        block_idx = block_bitmap_alloc(cur_part);
        if(block_idx == -1) {
            printk("block_bitmap_alloc failed\n");
            goto err0;
        }
        bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);

        if(blocks_old_idx < 12) {
            inode->i_sectors[blocks_old_idx] = block_idx + cur_part->sb->data_start_lba; 
        //鉴于对blocks_old_idx >= 12的整block读取的覆盖性，不可以将申请block注册于all_blocks，而是要sync到硬盘
        } else if(blocks_old_idx == 12) {
            //第一个block注册
            inode->i_sectors[12] = block_idx + cur_part->sb->data_start_lba; 
            //第二个block申请并注册  
            block_idx = block_bitmap_alloc(cur_part);
            if(block_idx == -1) {
                printk("second block_bitmap_alloc failed\n");
                goto err1;
            }  
            bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
            memset(io_buf, 0, BLOCK_SIZE);
            io_buf[0] = block_idx + cur_part->sb->data_start_lba;  
            ide_write(cur_part->my_disk, inode->i_sectors[12], io_buf, 1);        
        } else {
            ide_read(cur_part->my_disk, inode->i_sectors[12], io_buf, 1);
            ASSERT(blocks_old_idx - 12 >= 0 && io_buf[blocks_old_idx - 12] == 0);
            io_buf[blocks_old_idx - 12] =  block_idx + cur_part->sb->data_start_lba; 
            ide_write(cur_part->my_disk, inode->i_sectors[12], io_buf, 1);     
        }
    }

    if(blocks_add == 0) {   
        //blocks_new_idx == blocks_old_idx
        if(blocks_new_idx < 12) {
            all_blocks[blocks_new_idx] = inode->i_sectors[blocks_new_idx];
        } else {
            uint32_t indirect_pointer = inode->i_sectors[12];
            ASSERT(indirect_pointer != 0);
            ide_read(cur_part->my_disk, indirect_pointer, io_buf, 1);
            ASSERT(io_buf[blocks_new_idx - 12] != 0);
            all_blocks[blocks_new_idx] = io_buf[blocks_new_idx - 12];
        }
    } else {  //blocks_add != 0
        if(blocks_new_idx < 12) {
            /* 更新inode->i_sectors */        
            all_blocks[blocks_old_idx] = inode->i_sectors[blocks_old_idx];
            for(all_blocks_idx = blocks_old_idx + 1; all_blocks_idx <= blocks_new_idx; ++all_blocks_idx) {
                block_idx = block_bitmap_alloc(cur_part);
                if(block_idx == -1) {
                    printk("block_bitmap_alloc failed\n");
                    goto err1;
                }
                bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
                all_blocks[all_blocks_idx] = inode->i_sectors[all_blocks_idx] = (uint32_t)block_idx + cur_part->sb->data_start_lba;
            } 
            /* sync inode */
            memset(io_buf, 0, BLOCK_SIZE);
            inode_sync(cur_part, inode, io_buf);
        } else if(blocks_old_idx < 12 && blocks_new_idx >= 12) {
            /* 更新inode->i_sectors */
            all_blocks[blocks_old_idx] = inode->i_sectors[blocks_old_idx];
            for(all_blocks_idx = blocks_old_idx + 1; all_blocks_idx < 12; ++all_blocks_idx) {
                block_idx = block_bitmap_alloc(cur_part);
                if(block_idx == -1) {
                    printk("block_bitmap_alloc failed\n");
                    goto err1;
                }
                bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
                all_blocks[all_blocks_idx] = inode->i_sectors[all_blocks_idx] = (uint32_t)block_idx + cur_part->sb->data_start_lba;        
            }
            //再申请一个block作为地址块指针
            block_idx = block_bitmap_alloc(cur_part);
            if(block_idx == -1) {
                printk("block_bitmap_alloc failed\n");
                goto err1;
            }
            bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
            inode->i_sectors[12] = (uint32_t)block_idx + cur_part->sb->data_start_lba;
            
            // 申请间接block
            ASSERT(all_blocks_idx == 12);
            for(; all_blocks_idx <= blocks_new_idx; ++all_blocks_idx) {
                block_idx = block_bitmap_alloc(cur_part);
                if(block_idx == -1) {
                    printk("block_bitmap_alloc failed\n");
                    goto err1;
                }
                bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
                all_blocks[all_blocks_idx] = (uint32_t)block_idx + cur_part->sb->data_start_lba; 
            }
            /* sync inode */
            memset(io_buf, 0, BLOCK_SIZE);
            inode_sync(cur_part, inode, io_buf);
            /* sync inode->i_sectors[12]指向块 */
            ide_write(cur_part->my_disk, inode->i_sectors[12], all_blocks + 12, 1);
        } else if(blocks_old_idx >= 12) {
            uint32_t indirect_pointer = inode->i_sectors[12];
            ASSERT(indirect_pointer != 0);
            ide_read(cur_part->my_disk, indirect_pointer, io_buf, 1);
            all_blocks[blocks_old_idx] = io_buf[blocks_old_idx - 12];
            for(all_blocks_idx = blocks_old_idx + 1; all_blocks_idx < blocks_new_idx; ++all_blocks_idx) {
                int32_t block_idx = block_bitmap_alloc(cur_part);
                if(block_idx == -1) {
                    // 因为前一部分已经使用过ide_weite,所以这一分支也要释放
                    goto err2;
                }
                bitmap_sync(cur_part, block_idx, BLOCK_BITMAP);
                all_blocks[all_blocks_idx] = io_buf[all_blocks_idx - 12] = (uint32_t)block_idx + cur_part->sb->data_start_lba;                 
            }
            //更新间接指针
            ide_write(cur_part->my_disk, indirect_pointer, io_buf, 1);
        }
    }
    sys_free(io_buf);
    return 0;

    err2:
        /* 恢复inode->i_sectors[12]指向的块地址 */
        ide_read(cur_part->my_disk, inode->i_sectors[12], io_buf, 1);
        ASSERT(io_buf[inode->i_size / BLOCK_SIZE - 12] != 0);
        io_buf[inode->i_size / BLOCK_SIZE - 12] = 0;
        ide_write(cur_part->my_disk, inode->i_sectors[12], io_buf, 1);
    err1:
        /* 恢复inode->i_sectors */
        memcpy(inode->i_sectors, i_sectors_bak, 13 * 4);
        /* 恢复block_bitmap */
        while(blocks_old_idx <= all_blocks_idx) {
            block_bitmap_free(cur_part, all_blocks[blocks_old_idx] - cur_part->sb->data_start_lba);
            bitmap_sync(cur_part, all_blocks[blocks_old_idx] - cur_part->sb->data_start_lba, BLOCK_BITMAP);
            ++blocks_old_idx;
        }
    err0:
        sys_free(io_buf);
        return -1;
}
/* 成功返回写入的字节数，失败返回-1 */
static int32_t file_write(struct file *file, const void *buf, uint32_t count)
{
    /* 如果写count超出文件最大容量 */
    if((file->fd_inode->i_size + count) > (BLOCK_SIZE * 140)) {
        printk("exceed max file_size 71680 bytes, write file failed\n");
        goto free0;
    }
    /* 申请空间 */
    uint8_t *io_buf = sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        printk("file_write: sys_malloc for io_buf failed\n");
        goto free0;
    }
    uint32_t *all_blocks = sys_malloc(4 * 12 + BLOCK_SIZE);
    if(all_blocks == NULL) {
        printk("file_write: sys_malloc for all_blocks failed\n");
        goto free1;
    }

    memset(all_blocks, 0, 4 * 12 + BLOCK_SIZE);
    uint32_t blocks_new_idx = (file->fd_inode->i_size + count) / BLOCK_SIZE; 
    all_blocks_download_for_write(file->fd_inode, all_blocks, blocks_new_idx);



    uint8_t *src = (uint8_t *)buf;
    uint32_t bytes_written = 0;
    uint32_t size_left = count;
    bool first_write_block = TRUE;
    file->fd_pos = file->fd_inode->i_size - 1;
    while(bytes_written < count) {
        memset(io_buf, 0, BLOCK_SIZE);
        uint32_t sec_idx = file->fd_inode->i_size / BLOCK_SIZE;
        uint32_t sec_lba = all_blocks[sec_idx];
        uint32_t sec_off_bytes = file->fd_inode->i_size % BLOCK_SIZE;
        uint32_t sec_left_bytes = BLOCK_SIZE - sec_off_bytes;
        //判断此次写入硬盘数据的大小
        uint32_t chunk_size = size_left < sec_left_bytes ? size_left : sec_left_bytes;
        if(first_write_block) {
            ide_read(cur_part->my_disk, sec_lba, io_buf, 1);
            first_write_block = FALSE;
        }
        memcpy(io_buf + sec_off_bytes, src, chunk_size);
        ide_write(cur_part->my_disk, sec_lba, io_buf, 1);
        PRINTK_DEBUG("file write at lba %d\n", sec_lba);
        src += chunk_size;
        file->fd_inode->i_size += chunk_size;
        file->fd_pos += chunk_size;
        bytes_written += chunk_size;
        size_left -= chunk_size;
    }
    inode_sync(cur_part, file->fd_inode, io_buf);
    sys_free(all_blocks);
    sys_free(io_buf);
    return bytes_written;

    free1:
        sys_free(io_buf);
    free0:
        return -1;
}

int32_t sys_write(int32_t fd, const void *buf, uint32_t count)
{
    if(fd < 0) {
        printk("sys_write: fd error\n");
        return -1;
    }

    if(fd == stdout_no) {
        char tmp_buf[1024] = {0};
        memcpy(tmp_buf, buf, count);
        console_put_str(tmp_buf);
        return count;
    }

    uint32_t _fd = local_fd_to_global_index(fd);
    struct file *wr_file = &file_table[_fd];
    if(wr_file->fd_flags & O_RDONLY || wr_file->fd_flags & O_RDWR) {
        uint32_t bytes_written = file_write(wr_file, buf, count);
        return bytes_written;
    } else {
        console_put_str("sys_write: not allowed to write file without O_RDONLY or O_RDWR");
        return -1;
    }
}

/* 从文件file中读取count个字节写入buf，返回读出的字节数，若到文件尾返回-1 */
static int32_t file_read(struct file *file, void *buf, uint32_t count)
{
    uint8_t *buf_dst = (uint8_t *)buf;
    uint32_t size = count, size_left = size;
    /* 若要读取的字节数超过了文件可读的剩余量，就用剩余量作为待读取的字节数 */
    if((file->fd_pos + count) > file->fd_inode->i_size) {
        size = file->fd_inode->i_size;
        size_left = size;
        /* 如果i_size==0， 那就不需要读了 */
        if(size == 0) {
            return -1;
        }
    }

    uint8_t *io_buf = sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        printk("file_read: sys_malloc for io_buf failed\n");
        return -1;
    }
    uint32_t *all_blocks = sys_malloc(4 * 12 + BLOCK_SIZE);
    if(all_blocks == NULL) {
        printk("file_read: sys_malloc for all_blocks failed\n");
        sys_free(io_buf);
        return -1;
    }

    uint32_t start_idx_block = file->fd_pos / BLOCK_SIZE;
    uint32_t end_idx_block = (file->fd_pos + size) / BLOCK_SIZE;
    uint32_t nums_block_read = end_idx_block - start_idx_block + 1;

    int32_t indirect_pointer;
    uint32_t block_idx;

    /* 以下开始构建all_blocks块地址数组，专门存储用到的块地址 */
    ASSERT(nums_block_read >= 1);
    if(nums_block_read == 1) {  //在同一扇区内读数据，不涉及跨扇区读取
        if(end_idx_block < 12) {
            block_idx = start_idx_block;
            all_blocks[block_idx] = file->fd_inode->i_sectors[block_idx];
        } else {
            indirect_pointer = file->fd_inode->i_sectors[12];
            ASSERT(indirect_pointer != 0);
            ide_read(cur_part->my_disk, indirect_pointer, all_blocks + 12, 1);
        }
    } else {
        if(end_idx_block < 12) {
            block_idx = start_idx_block;
            while(block_idx <= end_idx_block) {
                all_blocks[block_idx] = file->fd_inode->i_sectors[block_idx];
                ++block_idx;
            }
        } else if(start_idx_block < 12 && end_idx_block >= 12) {
            block_idx = start_idx_block;
            while(block_idx < 12) {
                all_blocks[block_idx] = file->fd_inode->i_sectors[block_idx];
                ++block_idx;
            }
            indirect_pointer = file->fd_inode->i_sectors[12];
            ASSERT(indirect_pointer != 0);
            ide_read(cur_part->my_disk, indirect_pointer, all_blocks + 12, 1);          

        }else if(start_idx_block >= 12) {
            indirect_pointer = file->fd_inode->i_sectors[12];
            ASSERT(indirect_pointer != 0);
            ide_read(cur_part->my_disk, indirect_pointer, all_blocks + 12, 1);                 
        }
    }

    /* 用到的块地址已经收集到all_blocks中，下面可以开始读数据 */
    uint32_t sec_idx, sec_lba, sec_off_bytes, sec_left_bytes, chunk_size;
    uint32_t bytes_read = 0;
    while(bytes_read < size) {
        sec_idx = file->fd_pos / BLOCK_SIZE;
        sec_lba = all_blocks[sec_idx];
        sec_off_bytes = file->fd_pos % BLOCK_SIZE;
        sec_left_bytes = BLOCK_SIZE - sec_off_bytes;
        chunk_size = size_left < sec_left_bytes ? size_left : sec_left_bytes;   //待读入的数据大小

        ide_read(cur_part->my_disk, sec_lba, io_buf, 1);
        memcpy(buf_dst, io_buf + sec_off_bytes, chunk_size);

        buf_dst += chunk_size;
        file->fd_pos += chunk_size;
        size_left -= chunk_size;
        bytes_read += chunk_size;
    }

    sys_free(all_blocks);
    sys_free(io_buf);
    return bytes_read;
}

int32_t sys_read(int32_t fd, void *buf, uint32_t count)
{
    if(fd < 0) {
        printk("sys_read: fd error\n");
        return -1;
    }

    ASSERT(buf != NULL);
    uint32_t _fd = local_fd_to_global_index(fd);
    return file_read(&file_table[_fd], buf, count);
}

/* 重置用于文件读写操作的偏移指针，成功时返回新的偏移量，失败返回-1 */
int32_t sys_lseek(int32_t fd, int32_t offset, uint8_t whence)
{
    if(fd < 0) {
        printk("sys_lseek: fd error\n");
        return -1;
    }
    ASSERT(whence > 0 && whence < 4);
    uint32_t _fd = local_fd_to_global_index(fd);
    struct file *file = &file_table[_fd];
    int32_t new_pos = 0;
    int32_t file_size = (int32_t)file->fd_inode->i_size;
    switch(whence) {
        case SEEK_SET:
            new_pos = offset;
            break;
        case SEEK_CUR:
            new_pos = (int32_t)file->fd_pos + offset;
            break;
        case SEEK_END:
            new_pos = file_size + offset;
            break;
    }
    if(new_pos < 0 || new_pos > file_size - 1) {
        return -1;
    }
    file->fd_pos = new_pos;
    return file->fd_pos;
}

/* 删除文件(非目录)，成功0，失败-1 */
int32_t sys_unlink(const char *pathname)
{
    ASSERT(strlen(pathname) < MAX_FILE_NAME_LEN);

    /* 先检查待删除的文件是否存在 */
    struct path_search_record searched_record;
    //memset(&searched_record, 0, sizeof(struct path_search_record));
    int inode_no = search_file(pathname, &searched_record);
    PRINTK_DEBUG("inode_no = %d\n", inode_no);
    ASSERT(inode_no != 0);
    if(inode_no == -1) {
        printk("file %s not found!\n", pathname);
        dir_close(searched_record.parent_dir);
        return -1;
    }
    if(searched_record.file_type == FT_DIRECTORY) {
        printk("can't delete a directory with unlink(), use rmdir() to instead\n");
        dir_close(searched_record.parent_dir);
        return -1;        
    }
    /* 执行到此，确认文件存在 */
    /* 检查是否在已打开文件列表中 */
    uint32_t file_idx = 0;
    while(file_idx < MAX_FILES_OPEN) {
        if(file_table[file_idx].fd_inode != NULL && file_table[file_idx].fd_inode->i_no == (uint32_t)inode_no) {
            break;
        }
        ++file_idx;
    }
    if(file_idx < MAX_FILES_OPEN) {
        printk("file %s is in use, not allow to delete\n", pathname);
        dir_close(searched_record.parent_dir);
        return -1;
    }

    /* 删除目录项 */
    dir_entry_delete(cur_part, searched_record.parent_dir, inode_no);
    /* 回收inode资源 */
    inode_release(cur_part, inode_no);
    dir_close(searched_record.parent_dir);
    return 0; 
}


/* 收集文件信息 */
int32_t sys_stat(const char *pathname, struct stat *buf)
{
    /* 若是直接查看根目录 */
    while(*(pathname + 1) == '/') {
        ++pathname;
    }    
    if(!strcmp(pathname, "/") || !strcmp(pathname, "/.") || !strcmp(pathname, "/..")) {
        buf->st_ino = 0;
        buf->st_size = root_dir.inode->i_size;
        buf->st_ftype = FT_DIRECTORY;
        return 0;
    }

    /* 否则就查找文件 */
    int32_t ret = -1;
    struct path_search_record searched_record;
    memset(&searched_record, 0, sizeof(struct path_search_record));
    int32_t inode_no =  search_file(pathname, &searched_record);
    if(inode_no != -1 && inode_no != 0) {
        struct inode *obj_inode = inode_open(cur_part, inode_no);
        buf->st_ino = inode_no;
        buf->st_size = obj_inode->i_size;
        buf->st_ftype = searched_record.file_type;
        ret = 0;
    } else {
        //TODO
        PRINTK_DEBUG("%s not found\n", pathname);
    }
    dir_close(searched_record.parent_dir);
    return ret;
}



