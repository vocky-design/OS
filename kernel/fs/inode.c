#include "inode.h"

/* 暂存inode位置信息 */
struct inode_position {
    uint32_t sec_lba;   //inode所在扇区地址
    uint32_t off_size;  //inode在扇区内的字节偏移
};

/* 初始化new_inode */
void inode_init(uint32_t inode_no, struct inode *new_inode)
{
    new_inode->i_no = inode_no;
    new_inode->i_open_cnts = 0;
    new_inode->i_size = 0;
    new_inode->write_deny = FALSE;
    for(int i=0; i<13; ++i) {
        new_inode->i_sectors[i] = 0;
    }
}

static void inode_locate(struct partition *part, uint32_t i_no, struct inode_position *position)
{
    ASSERT(i_no < MAX_INODES_PER_PART);
    
    position->sec_lba = part->sb->inode_table_lba + i_no / INODE_NUM_PER_BLOCK;
    position->off_size = (i_no % INODE_NUM_PER_BLOCK) * sizeof(struct inode);
}

/* io_buf是1个扇区大小 */
void inode_sync(struct partition *part, struct inode *inode, void *io_buf)
{
    ASSERT(part != NULL && inode != NULL && io_buf != NULL);
    //定位，调用inode_locate
    struct inode_position position;
    inode_locate(part, inode->i_no, &position);
    //准备数据
    struct inode pure_inode;
    memcpy(&pure_inode, inode, sizeof(struct inode));
    pure_inode.i_open_cnts = 0;
    pure_inode.write_deny = FALSE;
    pure_inode.inode_tag.prev = pure_inode.inode_tag.next = NULL;
    //
    ide_read(part->my_disk, position.sec_lba, io_buf, 1);
    memcpy((uint8_t *)io_buf + position.off_size, &pure_inode, sizeof(struct inode));
    ide_write(part->my_disk, position.sec_lba, io_buf, 1);
}

/* 先检索open_inodes链表，查看是否已经打开过；
   若没有则读磁盘，第一次打开，将inode插入到链表头上 
   注：在inode_close()中释放inode节点 */
struct inode *inode_open(struct partition *part, uint32_t i_no)
{
    ASSERT(i_no < MAX_INODES_PER_PART);

    //先检索open_inodes链表
    struct list_elem *elem = part->open_inodes.head.next;
    struct inode *inode_found;
    while (elem != &part->open_inodes.tail)
    {
        inode_found = elem2entry(struct inode, inode_tag, elem);
        if(inode_found->i_no == i_no) {
            inode_found->i_open_cnts++;
            return inode_found;
        }
        elem = elem->next;
    }

    //从磁盘读inode,并插入链表头部
    //1.准备inode节点（要求在内核池申请）
    struct task_struct *cur_thread = running_thread();
    uint32_t *pgdir_bak = cur_thread->pgdir;
    cur_thread->pgdir = NULL;  //因为这是malloc函数判断是从用户池还是内核池分配内存的依据
    struct inode *new_inode = (struct inode *)sys_malloc(sizeof(struct inode));
    cur_thread->pgdir = pgdir_bak;
    //2.准备暂存缓冲区
    char *inode_buf = (char *)sys_malloc(SECTOR_SIZE);
    //3.定位inode在磁盘位置
    struct inode_position position; 
    inode_locate(part, i_no, &position);
    //4.ide_read，提取inode信息，添加到链表头，返回inode_found
    ide_read(part->my_disk, position.sec_lba, inode_buf, 1);
    memcpy(new_inode, inode_buf + position.off_size, sizeof(struct inode));
    new_inode->i_open_cnts = 1;
    list_push(&part->open_inodes, &new_inode->inode_tag);
    return new_inode;
}

void inode_close(struct inode *inode)
{
    enum intr_status old_status = intr_disable();

    inode->i_open_cnts--;
    if(inode->i_open_cnts == 0) {
        list_remove(&inode->inode_tag);

        //确保释放的内存也是内核池的内存
        struct task_struct *cur_thread = running_thread();
        uint32_t *pgdir_bak = cur_thread->pgdir;
        cur_thread->pgdir = NULL;
        sys_free(inode);
        cur_thread->pgdir = pgdir_bak;
    }
    intr_set_status(old_status);
}

/* 功能：将inode_table上的inode清空 
    注：非必要函数，方便调试*/
static void inode_delete(struct partition *part, uint32_t inode_no, void *io_buf)
{
    ASSERT(inode_no < MAX_INODES_PER_PART);
    struct inode_position inode_pos;
    inode_locate(part, inode_no, &inode_pos);
    ASSERT(inode_pos.sec_lba <= (part->start_lba + part->sec_cnt));

    char *inode_buf = (char *)io_buf;
    ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
    memset(inode_buf + inode_pos.off_size, 0, sizeof(struct inode));
    ide_write(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
}

/* 功能：回收inode的数据块和inode本身在inode位图中的bit
    成功返回0，失败返回-1 */
int32_t inode_release(struct partition *part, uint32_t inode_no)
{
    struct inode *inode_to_del = inode_open(part, inode_no);
    ASSERT(inode_to_del->i_no == inode_no);

    uint32_t *all_blocks = sys_malloc(12 * 4 + BLOCK_SIZE);
    if(all_blocks == NULL) {
        printk("inode_release: sys_malloc for all_blocks failed\n");
        return -1;
    }
    memset(all_blocks, 0, 12 * 4 + BLOCK_SIZE);

    /* 第一步：回收inode使用的block（不必清空block内容） */   
    memcpy(all_blocks, inode_to_del->i_sectors, 12 * 4);
    if(inode_to_del->i_sectors[12] != 0) {
        ide_read(part->my_disk, inode_to_del->i_sectors[12], all_blocks + 12, 1);
        // 回收一级间接索引块表本身的扇区空间（*）
        block_bitmap_free(part, inode_to_del->i_sectors[12] - part->sb->data_start_lba);
        bitmap_sync(part, inode_to_del->i_sectors[12] - part->sb->data_start_lba, BLOCK_BITMAP);
    }
    uint32_t block_idx = 0;
    while(block_idx < 12 + BLOCK_SIZE / 4) {
        if(all_blocks[block_idx] != 0) {
            block_bitmap_free(part, all_blocks[block_idx] - part->sb->data_start_lba);
            bitmap_sync(part, all_blocks[block_idx] - part->sb->data_start_lba, BLOCK_BITMAP);
        }
        ++block_idx;
    }
    /* 第二步：清零inode_table的相应inode */
    void *io_buf = sys_malloc(BLOCK_SIZE);
    if(io_buf == NULL) {
        sys_free(all_blocks);
        return -1;
    }
    inode_delete(part, inode_no, io_buf);
    // 第三步：回收inode_bitmap的相应位
    inode_bitmap_free(part, inode_no);
    bitmap_sync(part, inode_no, INODE_BITMAP);

    sys_free(io_buf);
    sys_free(all_blocks);
    inode_close(inode_to_del);
    return 0;
}


