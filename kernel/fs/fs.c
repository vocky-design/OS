#include "fs.h"


/* 对磁盘分区操作，初始化分区的原信息，也叫格式化创建文件系统 */
static void partititon_format(struct partition *part)
{
    struct disk *hd = part->my_disk;
    /* VSFS的原信息排列：启动扇区，超级块，block_bitmap，inode_bitmap，inode_table，inode数据区 */
    //一些系统配置的默认值
    const uint32_t boot_sector_sects = 1;         //启动扇区占一扇区，lba为0
    //uint32_t boot_sector_lba_off = 0;
    const uint32_t super_block_sects = 1;         //超级块预留一扇区，lba设置为1
    const uint32_t super_block_lba_off = 1;
    //按系统参数，计算其他部分
    const uint32_t inode_bitmap_sects = DIV_ROUND_UP(MAX_INODES_PER_PART, BITS_PER_BLOCK);
    const uint32_t inode_table_sects = DIV_ROUND_UP(sizeof(struct inode) * MAX_INODES_PER_PART, BLOCK_SIZE);
    const uint32_t used_sects = boot_sector_sects + super_block_sects + \
        inode_bitmap_sects + inode_table_sects;
    const uint32_t free_sects = part->sec_cnt - used_sects;
    uint32_t block_bitmap_sects = DIV_ROUND_UP(free_sects, BITS_PER_BLOCK);
    const uint32_t block_sects = free_sects - block_bitmap_sects;
    block_bitmap_sects = DIV_ROUND_UP(block_sects, BITS_PER_BLOCK);

    //在内存中定义super_block,将super_block写入分区的1扇区
    struct super_block sb;
    sb.fs_type = FS_TYPE;
    sb.lba_base = part->start_lba;
    sb.sec_cnt = part->sec_cnt;
    sb.block_bitmap_lba = sb.lba_base + 2;//跳过boot sector和super block
    sb.block_bitmap_sects = block_bitmap_sects;
    sb.inode_bitmap_lba = sb.block_bitmap_lba + sb.block_bitmap_sects;
    sb.inode_bitmap_sects = inode_bitmap_sects;
    sb.inode_table_lba = sb.inode_bitmap_lba + sb.inode_bitmap_sects;
    sb.inode_table_sects = inode_table_sects;
    sb.data_start_lba = sb.inode_table_lba + sb.inode_table_sects;
    ide_write(hd, part->start_lba + super_block_lba_off, &sb, super_block_sects);

    //申请缓冲区，size等于原信息最大大小
    uint32_t buf_size = sb.block_bitmap_sects >= sb.inode_bitmap_sects \
        ? sb.block_bitmap_sects : sb.inode_bitmap_sects;
    buf_size = (buf_size >= sb.inode_table_sects \
        ? buf_size : sb.inode_table_sects) * SECTOR_SIZE;
    uint8_t *buf = (uint8_t *)sys_malloc(buf_size);
    memset(buf, 0, buf_size);

    //初始化block_bitmap
    buf[0] |= 0x01;                 //第0个块预留给了根目录
    uint32_t last_byte = block_sects / 8;
    uint32_t last_bit = block_sects % 8;
    uint32_t latter_bytes = SECTOR_SIZE - last_byte % SECTOR_SIZE;//最后一个不满block的无用部分
    memset(&buf[last_byte], 0xff, latter_bytes);
    for(int i=0; i<last_bit; ++i) {
        buf[last_byte] &= ~(1 << i);
    }
    ide_write(hd, sb.block_bitmap_lba, buf, sb.block_bitmap_sects);

    //初始化inode_bitmap
    memset(buf, 0, buf_size);
    buf[0] |= 0x01;                 //第0个inode预留给了根目录
    ide_write(hd, sb.inode_bitmap_lba, buf, sb.inode_bitmap_sects);

    //初始化inode_table
    memset(buf, 0, buf_size);
    struct inode *inode = (struct inode *)buf;
    inode[0].i_no = 0;                                    //配置目录inode
    inode[0].i_size = sizeof(struct dir_entry) * 2;       //.和..（还未写入数据区）
    inode[0].i_sectors[0] = sb.data_start_lba;            //第0个block
    ide_write(hd, sb.inode_table_lba, buf, sb.inode_table_sects);

    //将.和..写入目录数据区中
    memset(buf, 0, buf_size);
    struct dir_entry *entry = (struct dir_entry *)buf;
    memcpy(entry[0].filename, ".", 1);
    entry[0].i_no = 0;
    entry[0].f_type = FT_DIRECTORY;
    memcpy(entry[1].filename, "..", 2);
    entry[1].i_no = 0;  //根目录的父目录还是根目录
    entry[1].f_type = FT_DIRECTORY;    
    ide_write(hd, sb.data_start_lba, buf, 1);

    sys_free(buf);
    //printk("%s info:\n", part->name);
    //printk("data_start_lba: 0x%x\n", sb.data_start_lba);
    printk("%s format done\n", part->name);
}

/* 供list_traversal调用
    挂载分区：在分区链表中遍历，找到part_name的分区，
    根据partititon_format()设置的信息，继续设置struct part的其余部分并将指针赋值给cur_part */
static bool mount_partition(struct list_elem *elem, int arg)
{
    ASSERT(elem != NULL && arg != 0);
    char *name = (char *)arg;
    //获取分区链表节点
    cur_part = elem2entry(struct partition, part_tag, elem);
    if(!strcmp(name, cur_part->name)) {//name相同
        printk("mounting...\n");
        
        struct disk *hd = cur_part->my_disk;
        uint32_t start_lba;
        uint32_t sectors;
        //1.从磁盘读取super_block
        cur_part->sb = (struct super_block *)sys_malloc(sizeof(struct super_block));
        if(cur_part->sb == NULL) {
            PANIC("malloc failed\n");
        }
        memset(cur_part->sb, 0 ,sizeof(struct super_block));
        ide_read(hd, cur_part->start_lba + 1, cur_part->sb, 1);
        //输出要挂载分区的信息
        struct super_block *sb_buf = (struct super_block *)sys_malloc(sizeof(struct super_block));
        memset(sb_buf, 0, sizeof(struct super_block));
        ide_read(hd, cur_part->start_lba + 1, sb_buf, 1);
        printk("fs_type = %d\n", sb_buf->fs_type);
        printk("lba_base = %d\n",sb_buf->lba_base);
        printk("sec_cnt = %d\n",sb_buf->sec_cnt);
        printk("block_bitmap_lba = %d\n",sb_buf->block_bitmap_lba);
        printk("block_bitmap_sects = %d\n",sb_buf->block_bitmap_sects);
        printk("inode_bitmap_lba = %d\n",sb_buf->inode_bitmap_lba);
        printk("inode_bitmap_sects = %d\n",sb_buf->inode_bitmap_sects);
        printk("inode_table_lba = %d\n",sb_buf->inode_table_lba);
        printk("inode_table_sects = %d\n",sb_buf->inode_table_sects);
        printk("data_start_lba = %d\n",sb_buf->data_start_lba);
        //2.将硬盘上的block_bitmap读取内存
        start_lba = cur_part->sb->block_bitmap_lba;
        sectors = cur_part->sb->block_bitmap_sects;
        cur_part->block_bitmap.bytes = (uint8_t *)sys_malloc(sectors * SECTOR_SIZE);
        if(cur_part->block_bitmap.bytes == NULL) {
            PANIC("malloc failed\n");
        }
        cur_part->block_bitmap.btmp_bytes_len = sectors * SECTOR_SIZE;
        bitmap_init(&cur_part->block_bitmap);
        ide_read(hd, start_lba, cur_part->block_bitmap.bytes, sectors);
        //3.将硬盘上的inode_bitmap读取内存
        start_lba = cur_part->sb->inode_bitmap_lba;
        sectors = cur_part->sb->inode_bitmap_sects;
        cur_part->inode_bitmap.bytes = (uint8_t *)sys_malloc(sectors * SECTOR_SIZE);
        if(cur_part->inode_bitmap.bytes == NULL) {
            PANIC("malloc failed\n");
        }
        cur_part->inode_bitmap.btmp_bytes_len = sectors * SECTOR_SIZE;
        bitmap_init(&cur_part->inode_bitmap);
        ide_read(hd, start_lba, cur_part->inode_bitmap.bytes, sectors);
        //4.初始化open_inodes链表
        list_init(&cur_part->open_inodes);

        printk("mount %s done\n", cur_part->name);
        return TRUE;
    }
    return FALSE;
    
}

/* 在磁盘上遍历分区搜索文件系统，若没有则格式化创建文件系统(partititon_format)
    然后挂载 */
void filesys_init(void) 
{
    printk("filesys_init start\n");
    struct super_block *sb_buf = (struct super_block *)sys_malloc(sizeof(struct super_block));
    if(sb_buf == NULL) {
        PANIC("sb_buf malloc failed\n");
    }

    //三循环，遍历通道上的每一个disk的每一个part
    uint8_t channel_no = 0;
    while(channel_no < channel_cnt) {
        uint8_t disk_no = 0;
        while(disk_no < 2) { //每个通道支持2个disk
                //跳过0通道主盘，因为是裸盘
            if(channel_no == 0 && disk_no == 0) {
                ++disk_no;
                continue;
            }
            struct disk *hd = &channels[channel_no].device[disk_no];
            uint8_t part_idx = 0;
            while(part_idx < 12) {//软件限制：最多支持12个分区
                struct partition *part;
                //1~4留给主分区
                if(part_idx < 4) {
                    part = &hd->prim_parts[part_idx];
                } else {
                    part = &hd->logic_parts[part_idx-4];
                }
                
                if(part->sec_cnt == 0) {
                    ++part_idx;
                    continue;
                } else {
                    //读分区super_block，检查fs_type成员
                    memset(sb_buf, 0, sizeof(struct super_block));
                    ide_read(hd, part->start_lba+1, sb_buf, 1);
                    if(sb_buf->fs_type == FS_TYPE) {
                        printk("%s has filesystem\n", part->name);
                    } else {//分区无法识别，按无分区处理
                        printk("formatting %s' part %s\n", hd->name, part->name);
                        partititon_format(part);
                    }
                }
                ++part_idx;
            }
            ++disk_no;
        }
        ++channel_no;
    }
    sys_free(sb_buf);

    //选择默认操作的分区
    char default_part[8] = "hdb1";
    //挂载分区
    list_traversal(&partition_list, mount_partition, (int)default_part);

    //
    open_root_dir(cur_part);
    uint32_t fd_idx = 0;
    while(fd_idx < MAX_FILES_OPEN) {
        file_table[fd_idx++].fd_inode = NULL;
    }

    printk("filesys_init done\n");
}


/* 从inode_bitmap申请一个inode。返回inode号，失败返回-1 */
int32_t inode_bitmap_alloc(struct partition *part)
{
    int32_t idx = -1;
    idx = bitmap_scan(&part->inode_bitmap, 1);      //MAX_FILES_PER_PART 4096
    if(idx != -1) {
        bitmap_set(&part->inode_bitmap, idx, 1);
        return idx;
    }
    return -1;
}
inline void inode_bitmap_free(struct partition *part, uint32_t inode_no)
{
    bitmap_set(&part->inode_bitmap, inode_no, 0);
}

/* 从block_bitmap申请一个block。返回idx，失败返回-1 */
int32_t block_bitmap_alloc(struct partition *part)
{
    int32_t idx = -1;
    idx = bitmap_scan(&part->block_bitmap, 1);      //数据区大小/block_size
    if(idx != -1) {
        bitmap_set(&part->block_bitmap, idx, 1);
        //返回lba地址
        return idx;            
    }
    return -1;
}
inline void block_bitmap_free(struct partition *part, uint32_t block_idx)
{
    bitmap_set(&part->block_bitmap, block_idx, 0);
}
//TODO 怎么实现多位修改同步更新？
/* 一位变化就要更新 */
void bitmap_sync(struct partition *part, uint32_t idx, enum bitmap_type bitmap_type)
{
    ASSERT(idx < MAX_FILES_PER_PART);

    //定位idx位所在扇区
    const uint32_t off_sec = idx / BITS_PER_BLOCK;
    uint32_t sec_lba;
    uint8_t *sec_addr_start;
    //开写
    switch(bitmap_type) {
        case INODE_BITMAP:
            sec_lba = part->sb->inode_bitmap_lba + off_sec;
            sec_addr_start = part->inode_bitmap.bytes + off_sec * SECTOR_SIZE;
            break;
        case BLOCK_BITMAP:
            sec_lba = part->sb->block_bitmap_lba + off_sec;
            sec_addr_start = part->block_bitmap.bytes + off_sec * SECTOR_SIZE;
            break;
        default:
            PANIC("bitmap_type no install\n");
            break;
    }
    ide_write(part->my_disk, sec_lba, sec_addr_start, 1);  
}
