#ifndef _KERNEL_GLOBAL_H
#define _KERNEL_GLOBAL_H

#include "stdint.h"

#define PG_SIZE 4096

/* GDT描述符的结构 */
struct gdt_desc {
        uint16_t        limit_low_word;
        uint16_t        base_low_word;
        uint8_t         base_mid_byte;
        uint8_t         attr_low_byte;
        uint8_t         limit_high_attr_high_byte;
        uint8_t         base_high_byte;                   
};

/* 段描述符属性 */
#define DESC_G_4K       1
#define DESC_D_32       1
#define DESC_L          0       //64位代码标记
#define DESC_AVL        0       //cpu不用此位，暂置为0
#define DESC_P          1
#define DESC_DPL_0      0
#define DESC_DPL_1      1
#define DESC_DPL_2      2
#define DESC_DPL_3      3
#define DESC_S_CODE     1
#define DESC_S_DATA     DESC_S_CODE
#define DESC_S_SYS      0
#define DESC_TYPE_CODE  8
#define DESC_TYPE_DATA  2
/* TSS描述符属性(补充) */
#define DESC_D_TSS      0
#define DESC_TYPE_TSS   9

//段描述符字段
#define GDT_CODE_ATTR_LOW_DPL3 \
        (DESC_P << 7) + (DESC_DPL_3 << 5) + (DESC_S_CODE <<4) + DESC_TYPE_CODE
#define GDT_DATA_ATTR_LOW_DPL3 \
        (DESC_P << 7) + (DESC_DPL_3 << 5) + (DESC_S_DATA <<4) + DESC_TYPE_DATA
#define GDT_ATTR_HIGH \
        (DESC_G_4K << 7) + (DESC_D_32 << 6) + (DESC_L << 5) + (DESC_AVL << 4)
//TSS描述符字段
#define TSS_ATTR_LOW \
        (DESC_P << 7) + (DESC_DPL_0 << 5) + (DESC_S_SYS << 4) + DESC_TYPE_TSS
#define TSS_ATTR_HIGH \
        (DESC_G_4K << 7) + (DESC_D_TSS << 6) + (DESC_L << 5) + (DESC_AVL << 4)


/* IDT描述符属性 */
#define IDT_DESC_P          1
#define IDT_DESC_DPL0       0
#define IDT_DESC_DPL3       3
#define IDT_DESC_32_TYPE    0xE     //32位的门
#define IDT_DESC_16_TYPE    0x6     //16位的门，不会用到。

//中断门描述符属性部分(8位二进制)
#define IDT_DESC_ATTR_DPL0 \
        ((IDT_DESC_P<<7) + (IDT_DESC_DPL0<<5) + IDT_DESC_32_TYPE)
#define IDT_DESC_ATTR_DPL3 \
        ((IDT_DESC_P<<7) + (IDT_DESC_DPL3<<5) + IDT_DESC_32_TYPE)

//段选择子属性
#define RPL0 0
#define RPL1 1
#define RPL2 2
#define RPL3 3
#define TI_GDT  0
#define TI_LDT  1
//段选择子
#define SELECTOR_K_CODE         ((1<<3) + (TI_GDT<<2) + RPL0)
#define SELECTOR_K_DATA         ((2<<3) + (TI_GDT<<2) + RPL0)
#define SELECTOR_K_STACK        SELECTOR_K_DATA
#define SELECTOR_K_GS           ((3<<3) + (TI_GDT<<2) + RPL0)
#define SELECTOR_TSS            ((4<<3) + (TI_GDT<<2) + RPL0)
#define SELECTOR_U_CODE         ((5<<3) + (TI_GDT<<2) + RPL3)
#define SELECTOR_U_DATA         ((6<<3) + (TI_GDT<<2) + RPL3)
#define SELECTOR_U_STACK        SELECTOR_U_DATA

/* 页表项和页目录项的一些属性定义 */
#define PG_P_0  0
#define PG_P_1  0x1
#define PG_RW_R 0       //读/执行
#define PG_RW_W 0x2       //读/写/执行
#define PG_US_S 0       //系统级，不允许3特权级
#define PG_US_U 0x4       //用户级别，任意特权级



/* eflags寄存器字段 */
#define EFLAGS_MBS      (1 << 1)                //此项必须要设置？？？
#define EFLAGS_IF_1     (1 << 9)
#define EFLAGS_IF_0     0
#define EFLAGS_IOPL_3   (3 << 12)               //IOPL3，用于测试用户程序在非系统调用下进行IO
#define EFLAGS_IOPL_0   0 

/* 杂项 */
#define DIV_ROUND_UP(X,STEP)    (((X)+(STEP)-1)/(STEP))













#endif