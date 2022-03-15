#include "interrupt.h"

#define IDT_DESC_CNT    0x81
#define EFLAGS_IF       0x00000200
#define GET_EFLAGS(eflags)      asm volatile ("pushfl; popl %0":"=m"(eflags))

/* 中断门描述符结构体 */
struct gate_desc {
    uint16_t func_offset_low_word;
    uint16_t selector;
    uint8_t  dcount;                //固定0
    uint8_t  attribute;
    uint16_t func_offset_high_word;
};
static struct gate_desc IDT[IDT_DESC_CNT];
char* intr_name[IDT_DESC_CNT];              //和下面的函数地址是联系的。
intr_handler idt_function[IDT_DESC_CNT];
extern intr_handler intr_entry_table[IDT_DESC_CNT];

/* 获取IF标志位状态 */
enum intr_status intr_get_status(void)
{
    uint32_t eflags = 0;
    GET_EFLAGS(eflags);
    return (EFLAGS_IF & eflags) ? INTR_ON:INTR_OFF ;
}

/* 开中断和关中断函数 */
enum intr_status intr_enable(void)
{
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()) {
        old_status = INTR_ON;
        return old_status;
    } else {
        old_status = INTR_OFF;
        asm volatile ("sti");
        return old_status;
    }
}
enum intr_status intr_disable(void)
{
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()) {
        old_status = INTR_ON;
        asm volatile ("cli");                       //注意：此处与书籍给出不符
        return old_status;
    } else {
        old_status = INTR_OFF;
        return old_status;
    }
}

/* 将中断状态设置为status */
enum intr_status intr_set_status(enum intr_status status)
{
    return status & INTR_ON ? intr_enable():intr_disable();
}

/* 通用的中断处理函数，一般用在异常出现时的处理 */
static void general_intr_handler(uint8_t vec_nr)
{
    //0x2f是从片8259A上的最后一个irq引脚，保留。
    if(vec_nr == 0x27 || vec_nr == 0x2f) {
        return;     //IRQ7和IRQ15会产生伪中断，无需处理。
    }
    //从屏幕左上角清理出一片打印异常信息的区域，方便阅读
    set_cursor(0);
    uint16_t cursor_pos = 0;
    while(cursor_pos++ < 4*80) {
        put_char(' ');
    }
    //打印信息
    set_cursor(0);
    put_str("!!!!!!     exception message begin     !!!!!!\n");
    set_cursor(88);
    put_str(intr_name[vec_nr]);put_char('\n');
    if(vec_nr == 14) {      //如果Pagefault，将缺失的地址打印出来并悬停
        uint32_t page_fault_vaddr = 0;
        asm volatile ("movl %%cr2,%0" : "=r"(page_fault_vaddr));        //cr2存放造成page fault的地址。
        put_str("page fault addr is ");put_int(page_fault_vaddr);put_char('\n');
    }
    put_str("!!!!!!     exception message end       !!!!!!\n");
    //悬停
    while(1);
}

/* 填俩表：intr_name[],idt_function[] */
static void exception_init(void)
{
    for(int i=0; i<IDT_DESC_CNT; ++i)
    {
        idt_function[i] = general_intr_handler;
        intr_name[i] = "unknown";
    }
    //前20个中断是异常。
    intr_name[0] = "#DE Divide Error";
    intr_name[1] = "#DB Debug Exception";
    intr_name[2] = "NMI Interrupt";
    intr_name[3] = "#BP Breakpoint Exception";
    intr_name[4] = "#OF Overflow Exception";
    intr_name[5] = "#BR BOUND Range Exceeded Exception";
    intr_name[6] = "#UD Invalid Opcode Exception";
    intr_name[7] = "#NM Device Not Valiable Exception";
    intr_name[8] = "#DF Double Fault Exception";
    intr_name[9] = "Coprocessor Segment Overrun";
    intr_name[10] = "#TS Invalid TSS Exception";
    intr_name[11] = "#NP Segment Not Present";
    intr_name[12] = "#SS Stack Fault Exception";
    intr_name[13] = "#GP General Protection Exception";
    intr_name[14] = "#PF Page-Fault Exception";
    //  intr_name[15] 第15项是Intel保留项，未使用。
    intr_name[16] = "#MF x87 FPU Floating-Point Error";
    intr_name[17] = "#AC Alignment Check Exception";
    intr_name[18] = "#MC Machine-Check Exception";
    intr_name[19] = "#XF SIMD Floating-Point Exception";

}

/* 中断注册函数 */
void register_handler(uint8_t vector_no, intr_handler function)
{
    idt_function[vector_no] = function;
}

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
    //单独处理系统调用，系统调用对应的中断门DPL为3，中断处理程序为单独的syscall_handler
    make_idt_desc(&IDT[0x80], (uint8_t)IDT_DESC_DPL3, syscall_handler);
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
    outb(0x21, 0x00);
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
    idt_desc_init();    //初始化IDT
    exception_init();   //初始化intr_name[]和idt_function[]。
    pic_init();         //初始化8259A
    //加载IDT
    //uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)((uint32_t)IDT << 16)));
    uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)(uint32_t)IDT) << 16 );
    asm volatile ("lidt %0"::"m"(idt_ptr));
    put_str("idt_init done\n");
}