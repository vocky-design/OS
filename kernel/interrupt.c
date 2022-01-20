#include "stdint.h"
#include "interrupt.h"
#include "global.h"
#include "print.h"
#include "io.h"
#define IDT_DESC_CNT 0x21

/* 中断门描述符结构体 */
struct gate_desc {
    uint16_t func_offset_low_word;
    uint16_t selector;
    uint8_t  dcount;                //固定0
    uint8_t  attribute;
    uint16_t func_offset_high_word;
};
static struct gate_desc IDT[IDT_DESC_CNT];
extern intr_handler intr_entry_table[IDT_DESC_CNT];
/* 初始化中断门描述符 */
static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr, intr_handler function)
{
    p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000FFFF;
    p_gdesc->selector = (uint16_t)SELECTOR_K_CODE;
    p_gdesc->dcount = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word =  ((uint32_t)function && 0xFFFF0000) >> 16;
}
/* 初始化IDT */
static void idt_desc_init(void)
{
    for(int i=0; i<IDT_DESC_CNT; ++i) {
        make_idt_desc(&IDT[i],(uint8_t)IDT_DESC_ATTR_DPL0,intr_entry_table[i]);
    }
    put_str("   idt_desc_init done\n");
}
/* 初始化8259A */
static void pic_init(void)
{
    //初始化主片
    outb(0x20, 0x11);
    outb(0x21, 0x20);
    outb(0x21, 0x04);
    outb(0x21, 0x01);
    //初始化从片
    outb(0xa0, 0x11);
    outb(0xa1, 0x28);
    outb(0xa1, 0x02);
    outb(0xa1, 0x01);
    //只打开主片上IR0，也就是目前只接受时钟产生的中断
    outb(0x21, 0xfe);
    outb(0xa1, 0xff);

    put_str("   pic_init done\n");
}
/* 完成有关中断的所有初始化工作 
1.初始化IDT
2.初始化PIC
3.加载IDT
*/

void idt_init(void)
{
    put_str("idt_init start\n");
    idt_desc_init();
    pic_init();
    //加载IDT
    //uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)((uint32_t)IDT << 16)));
    uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)(uint32_t)IDT) << 16 );
    asm volatile ("lidt %0"::"m"(idt_ptr));
    put_str("idt_init done\n");
}