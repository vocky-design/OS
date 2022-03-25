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

uint8_t channel_cnt;
struct ide_channel channels[2];
/* 硬盘数据结构初始化 */
void ide_init(void)
{
    printk("ide_init start\n");
    uint8_t hd_cnt = *(uint8_t *)0x475;
    channel_cnt = DIV_ROUND_UP(hd_cnt, 2);
    ASSERT(hd_cnt >= 0 && hd_cnt <= 2);
    struct ide_channel *channel;
    uint8_t channel_no = 0;
    while(channel_no < channel_cnt) {
        channel = &channels[channel_no];
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
        lock_init(&channel->lock);
        channel->expecting_intr = FALSE;
        //初始化为0，目的是向硬盘控制器请求数据后，硬盘驱动sema_down此信号量会阻塞线程，
        //直到硬盘完成后发中断。
        sema_init(&channel->disk_done, 0);
        ++channel_no;
    }
    printk("ide_init end\n");
}
