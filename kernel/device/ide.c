#include "ide.h"

/* 硬盘各寄存器的端口号 */
#define reg_data(channel)           (channel->port_base + 0)
#define reg_error(channel)          (channel->port_base + 1)
#define reg_sec_cnt(channel)        (channel->port_base + 2)
#define reg_lba_l(channel)          (channel->port_base + 3)
#define reg_lba_m(channel)          (channel->port_base + 4)
#define reg_lba_h(channel)          (channel->port_base + 5)
#define reg_dev(channel)            (channel->port_base + 6)
#define reg_status(channel)         (channel->port_base + 7)
#define reg_cmd(channel)            reg_status(channel)
#define reg_alt_status(channel)     (channel->port_base + 0x206)
#define reg_ctl(channel)            reg_alt_status(channel)

/* reg_alt_status寄存器的一些关键位 */
#define BIT_ALT_STAT_BSY        0x80        //硬盘忙
#define BIT_ALT_STAT_DRDY       0x40        //驱动器准备好了
#define BIT_ALT_STAT_DRQ        0x8         //数据传输准备好了

/* device寄存器的一些关键位 */
#define BIT_DEV_MBS     0xa0                //第7位和第5位固定为1
#define BIT_DEV_LBA     0x40
#define BIT_DEV_DEV     0x10

/* 一些硬盘操作的指令 */
#define CMD_IDENTIFY        0xec            
#define CMD_READ_SECTOR     0x20
#define CMD_WRITE_SECTOR    0x30

/* 定义可读写的最大扇区数，调试用的 */
#define max_lba ((80 * 1024 * 1024 / 512) - 1)      //只支持80MB硬盘

/* 16字节的分区表项 */
struct partition_table_entry {
    uint8_t bootable;           //是否可导引
    uint8_t start_head;
    uint8_t start_sector;
    uint8_t start_cylinder;
    uint8_t fs_type;
    uint8_t end_head;
    uint8_t end_sector;
    uint8_t end_cylinder;
    uint32_t offset_lba;
    uint32_t sec_cnt;
}__attribute__((packed));

/* 引导扇区 */
struct boot_sector {
    uint8_t other[446];
    struct partition_table_entry partition_table[4];
    uint16_t signature;             //结束标志0x55,0xaa
}__attribute__((packed));

uint8_t channel_cnt;
struct ide_channel channels[2];

uint32_t ext_lba_base = 0;      //用于记录总扩展分区的起始lba
uint8_t p_no = 0 , l_no = 0;
struct list partition_list;     

/* 选择读写的硬盘 */
static void select_disk(struct disk *hd)
{
    uint8_t reg_device = BIT_DEV_MBS | BIT_DEV_LBA;
    if(hd->dev_no == 1) {       //如果是从盘1
        reg_device |= BIT_DEV_DEV;
    }
    outb(reg_dev(hd->my_channel), reg_device);
}

/* 向硬盘控制器写入起始扇区地址及要读写的扇区数 */
static void select_sector(struct disk *hd, uint32_t lba, uint8_t sec_cnt)
{
    ASSERT(lba <= max_lba && sec_cnt > 0);
    struct ide_channel *channel = hd->my_channel;
    outb(reg_sec_cnt(channel), sec_cnt);
    outb(reg_lba_l(channel), lba);
    outb(reg_lba_m(channel), lba >> 8);
    outb(reg_lba_h(channel), lba >> 16);
    outb(reg_dev(channel), BIT_DEV_MBS | BIT_DEV_LBA | (hd->dev_no==1 ? BIT_DEV_DEV:0) | lba >> 24);
}

/* 向通道channel发命令 */
static void cmd_out(struct ide_channel *channel, uint8_t cmd)
{
    channel->expecting_intr = TRUE;
    outb(reg_cmd(channel), cmd);
}

/* 硬盘读入sec_cnt个扇区到buf */
static void read_sector(struct disk *hd, void *buf, uint8_t sec_cnt)
{
    uint32_t size_in_bytes;
    if(sec_cnt == 0) {
        size_in_bytes = 256 * 512;
    } else {
        size_in_bytes = sec_cnt * 512;
    }
    insw(reg_data(hd->my_channel), buf, size_in_bytes / 2);
}

/* 将buf中sec_cnt个扇区的数据写入硬盘 */
static void write_sector(struct disk *hd, void *buf, uint8_t sec_cnt)
{
    uint32_t size_in_bytes;
    if(sec_cnt == 0) {
        size_in_bytes = 256 * 512;
    } else {
        size_in_bytes = sec_cnt * 512;
    }
    outsw(reg_data(hd->my_channel), buf, size_in_bytes / 2);
}

/* 等待30s */
//TODO 感觉睡眠部分实现有问题
static bool busy_wait(struct disk *hd)
{
    uint16_t msecs_limit = 30 * 1000;
    while(msecs_limit -= 10 >= 0) {
        if(!(inb(reg_status(hd->my_channel)) & BIT_ALT_STAT_BSY)) {
            return (inb(reg_status(hd->my_channel)) & BIT_ALT_STAT_DRQ);
        } else {
            mtime_sleep(10);
        }
    }
    return FALSE;
}

/* 将dst中len个相邻字节交换位置后存入buf */
static void swap_pairs_bytes(const char *dst, char *buf, uint32_t len)
{
    uint32_t idx = 0;
    for(;idx < len; idx += 2) {
        buf[idx+1] = *(dst++);
        buf[idx] = *(dst++);
    }
    buf[idx] = '\0';
}

void ide_read(struct disk *hd, uint32_t lba, void *buf, uint8_t sec_cnt)
{
    lock_acquire(&hd->my_channel->lock);

    //1.先选择要操作的磁盘
    select_disk(hd);

    uint32_t secs_op;           //每次操作的扇区数
    uint32_t secs_done = 0;     //已经完成的扇区数
    while(secs_done < sec_cnt) {
        if((sec_cnt - secs_done) >= 256) {
            secs_op = 256;
        } else {
            secs_op = sec_cnt - secs_done;
        }

        //2.写入待读取的扇区数和起始扇区号
        select_sector(hd, lba + secs_done, secs_op);
        //3.执行命令
        cmd_out(hd->my_channel, CMD_READ_SECTOR);
        //将自己阻塞，等待硬盘读操作完成后通过中断处理程序唤醒自己
        sema_down(&hd->my_channel->disk_done);

        //4.醒来后，检测硬盘状态是否可读
        if(!busy_wait(hd)) {
            char error[64];
            sprintf(error, "%s read sector %d failed", hd->name, lba);
            PANIC(error);
        }
        //5.把数据从硬盘的缓冲区读出
        read_sector(hd, (void *)((uint32_t)buf + secs_done * 512), secs_op);
        secs_done += secs_op;
    }
    lock_release(&hd->my_channel->lock);
}

void ide_write(struct disk *hd, uint32_t lba, void *buf, uint8_t sec_cnt)
{
    lock_acquire(&hd->my_channel->lock);

    uint32_t secs_op;           //每次操作的扇区数
    uint32_t secs_done = 0;     //已经完成的扇区数
    while(secs_done < sec_cnt) {
        if((sec_cnt - secs_done) >= 256) {
            secs_op = 256;
        } else {
            secs_op = sec_cnt - secs_done;
        }   

        //2.写入待读取的扇区数和起始扇区号
        select_sector(hd, lba + secs_done, secs_op);
        //3.执行命令
        cmd_out(hd->my_channel, CMD_WRITE_SECTOR);   
        //4.检测硬盘状态是否可读
        if(!busy_wait(hd)) {
            char error[64];
            sprintf(error, "%s read sector %d failed", hd->name, lba);
            PANIC(error);
        }
        //5.将数据写入磁盘
        write_sector(hd, (void *)((uint32_t)buf + secs_done * 512), secs_op);
        secs_done += secs_op;
        //阻塞自己，等待硬盘中断唤醒
        sema_down(&hd->my_channel->disk_done);
    }
    lock_release(&hd->my_channel->lock);
}

/* 获取磁盘参数信息 */
static void identify_disk(struct disk *hd)
{
    char info[512];             //承载硬盘参数信息
    select_disk(hd);
    cmd_out(hd->my_channel, CMD_IDENTIFY);
    PRINTK_DEBUG("sema_down\n");
    //向硬盘发送指令后便通过信号量阻塞自己
    sema_down(&hd->my_channel->disk_done);
    PRINTK_DEBUG("sema_up\n");
    //醒来后执行下面代码
    if(!busy_wait(hd)) {
            char error[64];
            sprintf(error, "%s identify failed", hd->name);
            PANIC(error);
    }
    read_sector(hd, info, 1);
    PRINTK_DEBUG("read_sector finished!");
    char buf[64];
    uint8_t sn_start = 10 * 2, sn_size = 20;
    uint8_t md_start = 27 * 2, md_size = 40;
    swap_pairs_bytes(&info[sn_start], buf, sn_size);
    PRINTK_DEBUG("swap_pairs_bytes finished!\n");
    printk("disk %s info:\n", hd->name);
    printk("    SERIAL NUMBER: %s\n", buf);
    memset(buf, 0, 64);
    swap_pairs_bytes(&info[md_start], buf, md_size);
    printk("    MODULE:%s\n", buf);
    uint32_t secs_available = *(uint32_t *)&info[60 * 2];
    printk("    SECTORS:%d\n", secs_available);
    printk("    CAPACITY:%dMB\n", secs_available * 512 / 1024 / 1024);
}

/* 扫描分区表，ext_lba在初次调用中是0 */
static void partition_scan(struct disk *hd, uint32_t ext_lba)
{
    struct boot_sector *bs = sys_malloc(sizeof(struct boot_sector));
    ide_read(hd, ext_lba, bs, 1);
    struct partition_table_entry *p = bs->partition_table;
    uint8_t part_idx = 0;
    while(part_idx ++ < 4) {                
        if(p->fs_type == 0x5) {                 //若为扩展分区
            if(ext_lba_base == 0) {     //说明是第一次调用，是MBR扇区
                ext_lba_base = p->offset_lba;
                partition_scan(hd, ext_lba_base);
            } else {
                partition_scan(hd, ext_lba_base + p->offset_lba);
            }

        } else if(p->fs_type != 0) {            //若为“主分区”
            if(ext_lba == 0) {          //说明是第一次调用，是MBR扇区
                sprintf(hd->prim_parts[p_no].name, "%s%d", hd->name, p_no+1);
                hd->prim_parts[p_no].start_lba = ext_lba + p->offset_lba;
                hd->prim_parts[p_no].sec_cnt = p->sec_cnt;
                hd->prim_parts[p_no].my_disk = hd;
                list_append(&partition_list, &hd->prim_parts[p_no].part_tag);
                ++p_no;
                ASSERT(p_no < 4);
            } else {                    //是扩展分区
                sprintf(hd->logic_parts[l_no].name, "%s%d", hd->name, 4+l_no);
                hd->logic_parts[l_no].start_lba = ext_lba + p->offset_lba;
                hd->logic_parts[l_no].sec_cnt = p->sec_cnt;
                hd->logic_parts[l_no].my_disk = hd;
                list_append(&partition_list, &hd->logic_parts[l_no].part_tag);
                ++l_no;
                ASSERT(l_no < 8);
                if(l_no >= 8) {//只支持8个分区
                    return;
                }             
            }
        }
        ++p;
    }
    sys_free(bs);
}

/* 打印某分区信息 */
static bool partition_info(struct list_elem *elem, int arg __attribute__((unused)))
{
    struct partition *p = elem2entry(struct partition, part_tag, elem);
    printk("    %s start_lba:0x%x, sec_cnt:0x%x\n", p->name, p->start_lba, p->sec_cnt);
    //在此处返回false与函数本身功能无关，只是为了让主调函数list_traversal继续向下遍历元素
    return FALSE;
}
/* 硬盘中断处理函数 */
static void intr_hd_handler(uint8_t irq_no)
{
    //两个中断号共用
    ASSERT(irq_no == 0x2e || irq_no == 0x2f);
    uint8_t channel_no = irq_no - 0x2e;
    struct ide_channel *channel = &channels[channel_no];
    ASSERT(channel->irq_no == irq_no);

    //不必担心此中断是否对应这一次的expecting_intr
    //每次读写硬盘时都会申请锁，从而一定是本次命令
    if(channel->expecting_intr) {
        channel->expecting_intr = FALSE;
        sema_up(&channel->disk_done);

        //读取状态寄存器，使硬盘控制器认为此次的中断已经被处理
        //从而硬盘可以执行新的读写命令
        inb(reg_status(channel));
    } else {
        //其他问题引起的中断，暂不处理
    }
}

/* 硬盘数据结构初始化 */
void ide_init(void)
{
    printk("ide_init start\n");
    //初始化全局变量
    list_init(&partition_list);//partition_scan会使用
    ext_lba_base = 0;
    p_no = 0 , l_no = 0;

    uint8_t hd_cnt = *(uint8_t *)0x475;
    channel_cnt = DIV_ROUND_UP(hd_cnt, 2);
    ASSERT(channel_cnt >= 0 && channel_cnt <= 2);

    uint8_t channel_no = 0;
    while(channel_no < channel_cnt) {
        struct ide_channel *channel = &channels[channel_no];
        sprintf(channel->name, "ide%d", channel_no);
        switch(channel_no) {
            case 0:
                channel->port_base = 0x1f0;
                channel->irq_no = 0x20 + 14;
                break;
            case 1:
                channel->port_base = 0x170;
                channel->irq_no = 0x20 + 15;
                break;
        }
        PRINTK_DEBUG("channel_irqno: %d\n", channel->irq_no);
        register_handler(channel->irq_no, intr_hd_handler);
        lock_init(&channel->lock);
        channel->expecting_intr = FALSE;
        //初始化为0，目的是向硬盘控制器请求数据后，硬盘驱动sema_down此信号量会阻塞线程，
        //直到硬盘完成后发中断。
        sema_init(&channel->disk_done, 0);
        uint8_t disk_no = 0;
        while(disk_no < 2) {
            struct disk *hd = &channel->device[disk_no];
            sprintf(hd->name, "hd%c", 'a' + channel_no * 2 + disk_no);
            PRINTK_DEBUG("channel_no:%d disk_no:%d", channel_no, disk_no);
            hd->my_channel = channel;
            hd->dev_no = disk_no;

            identify_disk(hd);       //获取硬盘参数 
            //不处理0通道0硬盘，因为它是一个裸盘
            if(channel_no == 1 || (channel_no == 0 && disk_no != 0)) {
                partition_scan(hd, 0);
            }  
            ++disk_no;
        }
        ++channel_no;
    }
    printk("\n  all partition info \n");
    list_traversal(&partition_list, partition_info, 0);
    printk("ide_init end\n");
}
