
./build/interrupt.o:     file format elf32-i386


Disassembly of section .text:

00000000 <outb>:
#ifndef   _LIB_IO_H
#define   _LIB_IO_H
#include "stdint.h"
/* 向端口port写入一个字节 */
static inline void outb(uint16_t port, uint8_t data)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 08             	sub    esp,0x8
   6:	8b 55 08             	mov    edx,DWORD PTR [ebp+0x8]
   9:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
   c:	66 89 55 fc          	mov    WORD PTR [ebp-0x4],dx
  10:	88 45 f8             	mov    BYTE PTR [ebp-0x8],al
    asm volatile ("outb %b0,%w1"::"a"(data),"d"(port));
  13:	0f b6 45 f8          	movzx  eax,BYTE PTR [ebp-0x8]
  17:	0f b7 55 fc          	movzx  edx,WORD PTR [ebp-0x4]
  1b:	ee                   	out    dx,al
}
  1c:	90                   	nop
  1d:	c9                   	leave  
  1e:	c3                   	ret    

0000001f <intr_get_status>:
intr_handler idt_function[IDT_DESC_CNT];
extern intr_handler intr_entry_table[IDT_DESC_CNT];

/* 获取IF标志位状态 */
enum intr_status intr_get_status(void)
{
  1f:	55                   	push   ebp
  20:	89 e5                	mov    ebp,esp
  22:	83 ec 10             	sub    esp,0x10
    uint32_t eflags = 0;
  25:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [ebp-0x4],0x0
    GET_EFLAGS(eflags);
  2c:	9c                   	pushf  
  2d:	8f 45 fc             	pop    DWORD PTR [ebp-0x4]
    return (EFLAGS_IF & eflags) ? INTR_ON:INTR_OFF ;
  30:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  33:	25 00 02 00 00       	and    eax,0x200
  38:	85 c0                	test   eax,eax
  3a:	0f 95 c0             	setne  al
  3d:	0f b6 c0             	movzx  eax,al
}
  40:	c9                   	leave  
  41:	c3                   	ret    

00000042 <intr_enable>:

/* 开中断和关中断函数 */
enum intr_status intr_enable(void)
{
  42:	55                   	push   ebp
  43:	89 e5                	mov    ebp,esp
  45:	83 ec 10             	sub    esp,0x10
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()) {
  48:	e8 fc ff ff ff       	call   49 <intr_enable+0x7>
  4d:	83 f8 01             	cmp    eax,0x1
  50:	75 0c                	jne    5e <intr_enable+0x1c>
        old_status = INTR_ON;
  52:	c7 45 fc 01 00 00 00 	mov    DWORD PTR [ebp-0x4],0x1
        return old_status;
  59:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  5c:	eb 0b                	jmp    69 <intr_enable+0x27>
    } else {
        old_status = INTR_OFF;
  5e:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [ebp-0x4],0x0
        asm volatile ("sti");
  65:	fb                   	sti    
        return old_status;
  66:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
    }
}
  69:	c9                   	leave  
  6a:	c3                   	ret    

0000006b <intr_disable>:
enum intr_status intr_disable(void)
{
  6b:	55                   	push   ebp
  6c:	89 e5                	mov    ebp,esp
  6e:	83 ec 10             	sub    esp,0x10
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()) {
  71:	e8 fc ff ff ff       	call   72 <intr_disable+0x7>
  76:	83 f8 01             	cmp    eax,0x1
  79:	75 0d                	jne    88 <intr_disable+0x1d>
        old_status = INTR_ON;
  7b:	c7 45 fc 01 00 00 00 	mov    DWORD PTR [ebp-0x4],0x1
        asm volatile ("cli");                       //注意：此处与书籍给出不符
  82:	fa                   	cli    
        return old_status;
  83:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  86:	eb 0a                	jmp    92 <intr_disable+0x27>
    } else {
        old_status = INTR_OFF;
  88:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [ebp-0x4],0x0
        return old_status;
  8f:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
    }
}
  92:	c9                   	leave  
  93:	c3                   	ret    

00000094 <intr_set_status>:

/* 将中断状态设置为status */
enum intr_status intr_set_status(enum intr_status status)
{
  94:	55                   	push   ebp
  95:	89 e5                	mov    ebp,esp
    return status & INTR_ON ? intr_enable():intr_disable();
  97:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  9a:	83 e0 01             	and    eax,0x1
  9d:	85 c0                	test   eax,eax
  9f:	74 07                	je     a8 <intr_set_status+0x14>
  a1:	e8 fc ff ff ff       	call   a2 <intr_set_status+0xe>
  a6:	eb 05                	jmp    ad <intr_set_status+0x19>
  a8:	e8 fc ff ff ff       	call   a9 <intr_set_status+0x15>
}
  ad:	5d                   	pop    ebp
  ae:	c3                   	ret    

000000af <general_intr_handler>:

/* 通用的中断处理函数，一般用在异常出现时的处理 */
static void general_intr_handler(uint8_t vec_nr)
{
  af:	55                   	push   ebp
  b0:	89 e5                	mov    ebp,esp
  b2:	83 ec 28             	sub    esp,0x28
  b5:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  b8:	88 45 e4             	mov    BYTE PTR [ebp-0x1c],al
    //0x2f是从片8259A上的最后一个irq引脚，保留。
    if(vec_nr == 0x27 || vec_nr == 0x2f) {
  bb:	80 7d e4 27          	cmp    BYTE PTR [ebp-0x1c],0x27
  bf:	0f 84 db 00 00 00    	je     1a0 <general_intr_handler+0xf1>
  c5:	80 7d e4 2f          	cmp    BYTE PTR [ebp-0x1c],0x2f
  c9:	0f 84 d1 00 00 00    	je     1a0 <general_intr_handler+0xf1>
        return;     //IRQ7和IRQ15会产生伪中断，无需处理。
    }
    //从屏幕左上角清理出一片打印异常信息的区域，方便阅读
    set_cursor(0);
  cf:	83 ec 0c             	sub    esp,0xc
  d2:	6a 00                	push   0x0
  d4:	e8 fc ff ff ff       	call   d5 <general_intr_handler+0x26>
  d9:	83 c4 10             	add    esp,0x10
    uint16_t cursor_pos = 0;
  dc:	66 c7 45 f6 00 00    	mov    WORD PTR [ebp-0xa],0x0
    while(cursor_pos++ < 4*80) {
  e2:	eb 0d                	jmp    f1 <general_intr_handler+0x42>
        put_char(' ');
  e4:	83 ec 0c             	sub    esp,0xc
  e7:	6a 20                	push   0x20
  e9:	e8 fc ff ff ff       	call   ea <general_intr_handler+0x3b>
  ee:	83 c4 10             	add    esp,0x10
        return;     //IRQ7和IRQ15会产生伪中断，无需处理。
    }
    //从屏幕左上角清理出一片打印异常信息的区域，方便阅读
    set_cursor(0);
    uint16_t cursor_pos = 0;
    while(cursor_pos++ < 4*80) {
  f1:	0f b7 45 f6          	movzx  eax,WORD PTR [ebp-0xa]
  f5:	8d 50 01             	lea    edx,[eax+0x1]
  f8:	66 89 55 f6          	mov    WORD PTR [ebp-0xa],dx
  fc:	66 3d 3f 01          	cmp    ax,0x13f
 100:	76 e2                	jbe    e4 <general_intr_handler+0x35>
        put_char(' ');
    }
    //打印信息
    set_cursor(0);
 102:	83 ec 0c             	sub    esp,0xc
 105:	6a 00                	push   0x0
 107:	e8 fc ff ff ff       	call   108 <general_intr_handler+0x59>
 10c:	83 c4 10             	add    esp,0x10
    put_str("!!!!!!     exception message begin     !!!!!!\n");
 10f:	83 ec 0c             	sub    esp,0xc
 112:	68 00 00 00 00       	push   0x0
 117:	e8 fc ff ff ff       	call   118 <general_intr_handler+0x69>
 11c:	83 c4 10             	add    esp,0x10
    set_cursor(88);
 11f:	83 ec 0c             	sub    esp,0xc
 122:	6a 58                	push   0x58
 124:	e8 fc ff ff ff       	call   125 <general_intr_handler+0x76>
 129:	83 c4 10             	add    esp,0x10
    put_str(intr_name[vec_nr]);put_char('\n');
 12c:	0f b6 45 e4          	movzx  eax,BYTE PTR [ebp-0x1c]
 130:	8b 04 85 00 00 00 00 	mov    eax,DWORD PTR [eax*4+0x0]
 137:	83 ec 0c             	sub    esp,0xc
 13a:	50                   	push   eax
 13b:	e8 fc ff ff ff       	call   13c <general_intr_handler+0x8d>
 140:	83 c4 10             	add    esp,0x10
 143:	83 ec 0c             	sub    esp,0xc
 146:	6a 0a                	push   0xa
 148:	e8 fc ff ff ff       	call   149 <general_intr_handler+0x9a>
 14d:	83 c4 10             	add    esp,0x10
    if(vec_nr == 14) {      //如果Pagefault，将缺失的地址打印出来并悬停
 150:	80 7d e4 0e          	cmp    BYTE PTR [ebp-0x1c],0xe
 154:	75 38                	jne    18e <general_intr_handler+0xdf>
        uint32_t page_fault_vaddr = 0;
 156:	c7 45 f0 00 00 00 00 	mov    DWORD PTR [ebp-0x10],0x0
        asm volatile ("movl %%cr2,%0" : "=r"(page_fault_vaddr));        //cr2存放造成page fault的地址。
 15d:	0f 20 d0             	mov    eax,cr2
 160:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
        put_str("page fault addr is ");put_int(page_fault_vaddr);put_char('\n');
 163:	83 ec 0c             	sub    esp,0xc
 166:	68 2f 00 00 00       	push   0x2f
 16b:	e8 fc ff ff ff       	call   16c <general_intr_handler+0xbd>
 170:	83 c4 10             	add    esp,0x10
 173:	83 ec 0c             	sub    esp,0xc
 176:	ff 75 f0             	push   DWORD PTR [ebp-0x10]
 179:	e8 fc ff ff ff       	call   17a <general_intr_handler+0xcb>
 17e:	83 c4 10             	add    esp,0x10
 181:	83 ec 0c             	sub    esp,0xc
 184:	6a 0a                	push   0xa
 186:	e8 fc ff ff ff       	call   187 <general_intr_handler+0xd8>
 18b:	83 c4 10             	add    esp,0x10
    }
    put_str("!!!!!!     exception message end       !!!!!!\n");
 18e:	83 ec 0c             	sub    esp,0xc
 191:	68 44 00 00 00       	push   0x44
 196:	e8 fc ff ff ff       	call   197 <general_intr_handler+0xe8>
 19b:	83 c4 10             	add    esp,0x10
    //悬停
    while(1);
 19e:	eb fe                	jmp    19e <general_intr_handler+0xef>
/* 通用的中断处理函数，一般用在异常出现时的处理 */
static void general_intr_handler(uint8_t vec_nr)
{
    //0x2f是从片8259A上的最后一个irq引脚，保留。
    if(vec_nr == 0x27 || vec_nr == 0x2f) {
        return;     //IRQ7和IRQ15会产生伪中断，无需处理。
 1a0:	90                   	nop
        put_str("page fault addr is ");put_int(page_fault_vaddr);put_char('\n');
    }
    put_str("!!!!!!     exception message end       !!!!!!\n");
    //悬停
    while(1);
}
 1a1:	c9                   	leave  
 1a2:	c3                   	ret    

000001a3 <exception_init>:

/* 填俩表：intr_name[],idt_function[] */
static void exception_init(void)
{
 1a3:	55                   	push   ebp
 1a4:	89 e5                	mov    ebp,esp
 1a6:	83 ec 10             	sub    esp,0x10
    for(int i=0; i<IDT_DESC_CNT; ++i)
 1a9:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [ebp-0x4],0x0
 1b0:	eb 20                	jmp    1d2 <exception_init+0x2f>
    {
        idt_function[i] = general_intr_handler;
 1b2:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 1b5:	c7 04 85 00 00 00 00 	mov    DWORD PTR [eax*4+0x0],0xaf
 1bc:	af 00 00 00 
        intr_name[i] = "unknown";
 1c0:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 1c3:	c7 04 85 00 00 00 00 	mov    DWORD PTR [eax*4+0x0],0x73
 1ca:	73 00 00 00 
}

/* 填俩表：intr_name[],idt_function[] */
static void exception_init(void)
{
    for(int i=0; i<IDT_DESC_CNT; ++i)
 1ce:	83 45 fc 01          	add    DWORD PTR [ebp-0x4],0x1
 1d2:	83 7d fc 2f          	cmp    DWORD PTR [ebp-0x4],0x2f
 1d6:	7e da                	jle    1b2 <exception_init+0xf>
    {
        idt_function[i] = general_intr_handler;
        intr_name[i] = "unknown";
    }
    //前20个中断是异常。
    intr_name[0] = "#DE Divide Error";
 1d8:	c7 05 00 00 00 00 7b 	mov    DWORD PTR ds:0x0,0x7b
 1df:	00 00 00 
    intr_name[1] = "#DB Debug Exception";
 1e2:	c7 05 04 00 00 00 8c 	mov    DWORD PTR ds:0x4,0x8c
 1e9:	00 00 00 
    intr_name[2] = "NMI Interrupt";
 1ec:	c7 05 08 00 00 00 a0 	mov    DWORD PTR ds:0x8,0xa0
 1f3:	00 00 00 
    intr_name[3] = "#BP Breakpoint Exception";
 1f6:	c7 05 0c 00 00 00 ae 	mov    DWORD PTR ds:0xc,0xae
 1fd:	00 00 00 
    intr_name[4] = "#OF Overflow Exception";
 200:	c7 05 10 00 00 00 c7 	mov    DWORD PTR ds:0x10,0xc7
 207:	00 00 00 
    intr_name[5] = "#BR BOUND Range Exceeded Exception";
 20a:	c7 05 14 00 00 00 e0 	mov    DWORD PTR ds:0x14,0xe0
 211:	00 00 00 
    intr_name[6] = "#UD Invalid Opcode Exception";
 214:	c7 05 18 00 00 00 03 	mov    DWORD PTR ds:0x18,0x103
 21b:	01 00 00 
    intr_name[7] = "#NM Device Not Valiable Exception";
 21e:	c7 05 1c 00 00 00 20 	mov    DWORD PTR ds:0x1c,0x120
 225:	01 00 00 
    intr_name[8] = "#DF Double Fault Exception";
 228:	c7 05 20 00 00 00 42 	mov    DWORD PTR ds:0x20,0x142
 22f:	01 00 00 
    intr_name[9] = "Coprocessor Segment Overrun";
 232:	c7 05 24 00 00 00 5d 	mov    DWORD PTR ds:0x24,0x15d
 239:	01 00 00 
    intr_name[10] = "#TS Invalid TSS Exception";
 23c:	c7 05 28 00 00 00 79 	mov    DWORD PTR ds:0x28,0x179
 243:	01 00 00 
    intr_name[11] = "#NP Segment Not Present";
 246:	c7 05 2c 00 00 00 93 	mov    DWORD PTR ds:0x2c,0x193
 24d:	01 00 00 
    intr_name[12] = "#SS Stack Fault Exception";
 250:	c7 05 30 00 00 00 ab 	mov    DWORD PTR ds:0x30,0x1ab
 257:	01 00 00 
    intr_name[13] = "#GP General Protection Exception";
 25a:	c7 05 34 00 00 00 c8 	mov    DWORD PTR ds:0x34,0x1c8
 261:	01 00 00 
    intr_name[14] = "#PF Page-Fault Exception";
 264:	c7 05 38 00 00 00 e9 	mov    DWORD PTR ds:0x38,0x1e9
 26b:	01 00 00 
    //  intr_name[15] 第15项是Intel保留项，未使用。
    intr_name[16] = "#MF x87 FPU Floating-Point Error";
 26e:	c7 05 40 00 00 00 04 	mov    DWORD PTR ds:0x40,0x204
 275:	02 00 00 
    intr_name[17] = "#AC Alignment Check Exception";
 278:	c7 05 44 00 00 00 25 	mov    DWORD PTR ds:0x44,0x225
 27f:	02 00 00 
    intr_name[18] = "#MC Machine-Check Exception";
 282:	c7 05 48 00 00 00 43 	mov    DWORD PTR ds:0x48,0x243
 289:	02 00 00 
    intr_name[19] = "#XF SIMD Floating-Point Exception";
 28c:	c7 05 4c 00 00 00 60 	mov    DWORD PTR ds:0x4c,0x260
 293:	02 00 00 

}
 296:	90                   	nop
 297:	c9                   	leave  
 298:	c3                   	ret    

00000299 <register_handler>:

/* 中断注册函数 */
void register_handler(uint8_t vector_no, intr_handler function)
{
 299:	55                   	push   ebp
 29a:	89 e5                	mov    ebp,esp
 29c:	83 ec 04             	sub    esp,0x4
 29f:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2a2:	88 45 fc             	mov    BYTE PTR [ebp-0x4],al
    idt_function[vector_no] = function;
 2a5:	0f b6 45 fc          	movzx  eax,BYTE PTR [ebp-0x4]
 2a9:	8b 55 0c             	mov    edx,DWORD PTR [ebp+0xc]
 2ac:	89 14 85 00 00 00 00 	mov    DWORD PTR [eax*4+0x0],edx
}
 2b3:	90                   	nop
 2b4:	c9                   	leave  
 2b5:	c3                   	ret    

000002b6 <make_idt_desc>:

/* 初始化中断门描述符 */
static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr, intr_handler function)
{
 2b6:	55                   	push   ebp
 2b7:	89 e5                	mov    ebp,esp
 2b9:	83 ec 04             	sub    esp,0x4
 2bc:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 2bf:	88 45 fc             	mov    BYTE PTR [ebp-0x4],al
    p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000FFFF;
 2c2:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
 2c5:	89 c2                	mov    edx,eax
 2c7:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2ca:	66 89 10             	mov    WORD PTR [eax],dx
    p_gdesc->selector = (uint16_t)SELECTOR_K_CODE;
 2cd:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2d0:	66 c7 40 02 08 00    	mov    WORD PTR [eax+0x2],0x8
    p_gdesc->dcount = 0;
 2d6:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2d9:	c6 40 04 00          	mov    BYTE PTR [eax+0x4],0x0
    p_gdesc->attribute = attr;
 2dd:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2e0:	0f b6 55 fc          	movzx  edx,BYTE PTR [ebp-0x4]
 2e4:	88 50 05             	mov    BYTE PTR [eax+0x5],dl
    p_gdesc->func_offset_high_word =  ((uint32_t)function && 0xFFFF0000) >> 16;
 2e7:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 2ea:	66 c7 40 06 00 00    	mov    WORD PTR [eax+0x6],0x0
}
 2f0:	90                   	nop
 2f1:	c9                   	leave  
 2f2:	c3                   	ret    

000002f3 <idt_desc_init>:

/* 初始化IDT */
static void idt_desc_init(void)
{
 2f3:	55                   	push   ebp
 2f4:	89 e5                	mov    ebp,esp
 2f6:	83 ec 18             	sub    esp,0x18
    for(int i=0; i<IDT_DESC_CNT; ++i) {
 2f9:	c7 45 f4 00 00 00 00 	mov    DWORD PTR [ebp-0xc],0x0
 300:	eb 29                	jmp    32b <idt_desc_init+0x38>
        make_idt_desc(&IDT[i],(uint8_t)IDT_DESC_ATTR_DPL0,intr_entry_table[i]);
 302:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 305:	8b 04 85 00 00 00 00 	mov    eax,DWORD PTR [eax*4+0x0]
 30c:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
 30f:	c1 e2 03             	shl    edx,0x3
 312:	81 c2 00 00 00 00    	add    edx,0x0
 318:	50                   	push   eax
 319:	68 8e 00 00 00       	push   0x8e
 31e:	52                   	push   edx
 31f:	e8 92 ff ff ff       	call   2b6 <make_idt_desc>
 324:	83 c4 0c             	add    esp,0xc
}

/* 初始化IDT */
static void idt_desc_init(void)
{
    for(int i=0; i<IDT_DESC_CNT; ++i) {
 327:	83 45 f4 01          	add    DWORD PTR [ebp-0xc],0x1
 32b:	83 7d f4 2f          	cmp    DWORD PTR [ebp-0xc],0x2f
 32f:	7e d1                	jle    302 <idt_desc_init+0xf>
        make_idt_desc(&IDT[i],(uint8_t)IDT_DESC_ATTR_DPL0,intr_entry_table[i]);
    }
    put_str("   idt_desc_init done\n");
 331:	83 ec 0c             	sub    esp,0xc
 334:	68 82 02 00 00       	push   0x282
 339:	e8 fc ff ff ff       	call   33a <idt_desc_init+0x47>
 33e:	83 c4 10             	add    esp,0x10
}
 341:	90                   	nop
 342:	c9                   	leave  
 343:	c3                   	ret    

00000344 <pic_init>:

/* 初始化8259A */
static void pic_init(void)
{
 344:	55                   	push   ebp
 345:	89 e5                	mov    ebp,esp
 347:	83 ec 08             	sub    esp,0x8
    //初始化主片
    outb(0x20, 0x11);
 34a:	6a 11                	push   0x11
 34c:	6a 20                	push   0x20
 34e:	e8 ad fc ff ff       	call   0 <outb>
 353:	83 c4 08             	add    esp,0x8
    outb(0x21, 0x20);
 356:	6a 20                	push   0x20
 358:	6a 21                	push   0x21
 35a:	e8 a1 fc ff ff       	call   0 <outb>
 35f:	83 c4 08             	add    esp,0x8
    outb(0x21, 0x04);
 362:	6a 04                	push   0x4
 364:	6a 21                	push   0x21
 366:	e8 95 fc ff ff       	call   0 <outb>
 36b:	83 c4 08             	add    esp,0x8
    outb(0x21, 0x01);
 36e:	6a 01                	push   0x1
 370:	6a 21                	push   0x21
 372:	e8 89 fc ff ff       	call   0 <outb>
 377:	83 c4 08             	add    esp,0x8
    //初始化从片
    outb(0xa0, 0x11);
 37a:	6a 11                	push   0x11
 37c:	68 a0 00 00 00       	push   0xa0
 381:	e8 7a fc ff ff       	call   0 <outb>
 386:	83 c4 08             	add    esp,0x8
    outb(0xa1, 0x28);
 389:	6a 28                	push   0x28
 38b:	68 a1 00 00 00       	push   0xa1
 390:	e8 6b fc ff ff       	call   0 <outb>
 395:	83 c4 08             	add    esp,0x8
    outb(0xa1, 0x02);
 398:	6a 02                	push   0x2
 39a:	68 a1 00 00 00       	push   0xa1
 39f:	e8 5c fc ff ff       	call   0 <outb>
 3a4:	83 c4 08             	add    esp,0x8
    outb(0xa1, 0x01);
 3a7:	6a 01                	push   0x1
 3a9:	68 a1 00 00 00       	push   0xa1
 3ae:	e8 4d fc ff ff       	call   0 <outb>
 3b3:	83 c4 08             	add    esp,0x8
    //只打开主片上IR0，也就是目前只接受时钟产生的中断
    outb(0x21, 0x00);
 3b6:	6a 00                	push   0x0
 3b8:	6a 21                	push   0x21
 3ba:	e8 41 fc ff ff       	call   0 <outb>
 3bf:	83 c4 08             	add    esp,0x8
    outb(0xa1, 0xff);
 3c2:	68 ff 00 00 00       	push   0xff
 3c7:	68 a1 00 00 00       	push   0xa1
 3cc:	e8 2f fc ff ff       	call   0 <outb>
 3d1:	83 c4 08             	add    esp,0x8

    put_str("   pic_init done\n");
 3d4:	83 ec 0c             	sub    esp,0xc
 3d7:	68 99 02 00 00       	push   0x299
 3dc:	e8 fc ff ff ff       	call   3dd <pic_init+0x99>
 3e1:	83 c4 10             	add    esp,0x10
}
 3e4:	90                   	nop
 3e5:	c9                   	leave  
 3e6:	c3                   	ret    

000003e7 <idt_init>:
1.初始化IDT
2.初始化PIC
3.加载IDT
*/
void idt_init(void)
{
 3e7:	55                   	push   ebp
 3e8:	89 e5                	mov    ebp,esp
 3ea:	56                   	push   esi
 3eb:	53                   	push   ebx
 3ec:	83 ec 10             	sub    esp,0x10
    put_str("idt_init start\n");
 3ef:	83 ec 0c             	sub    esp,0xc
 3f2:	68 ab 02 00 00       	push   0x2ab
 3f7:	e8 fc ff ff ff       	call   3f8 <idt_init+0x11>
 3fc:	83 c4 10             	add    esp,0x10
    idt_desc_init();    //初始化IDT
 3ff:	e8 ef fe ff ff       	call   2f3 <idt_desc_init>
    exception_init();   //初始化intr_name[]和idt_function[]。
 404:	e8 9a fd ff ff       	call   1a3 <exception_init>
    pic_init();         //初始化8259A
 409:	e8 36 ff ff ff       	call   344 <pic_init>
    //加载IDT
    //uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)((uint32_t)IDT << 16)));
    uint64_t idt_ptr = ((sizeof(IDT)-1) | ((uint64_t)(uint32_t)IDT) << 16 );
 40e:	b8 00 00 00 00       	mov    eax,0x0
 413:	ba 00 00 00 00       	mov    edx,0x0
 418:	0f a4 c2 10          	shld   edx,eax,0x10
 41c:	c1 e0 10             	shl    eax,0x10
 41f:	89 c1                	mov    ecx,eax
 421:	81 c9 7f 01 00 00    	or     ecx,0x17f
 427:	89 cb                	mov    ebx,ecx
 429:	89 d0                	mov    eax,edx
 42b:	80 cc 00             	or     ah,0x0
 42e:	89 c6                	mov    esi,eax
 430:	89 5d f0             	mov    DWORD PTR [ebp-0x10],ebx
 433:	89 75 f4             	mov    DWORD PTR [ebp-0xc],esi
    asm volatile ("lidt %0"::"m"(idt_ptr));
 436:	0f 01 5d f0          	lidtd  [ebp-0x10]
    put_str("idt_init done\n");
 43a:	83 ec 0c             	sub    esp,0xc
 43d:	68 bb 02 00 00       	push   0x2bb
 442:	e8 fc ff ff ff       	call   443 <idt_init+0x5c>
 447:	83 c4 10             	add    esp,0x10
 44a:	90                   	nop
 44b:	8d 65 f8             	lea    esp,[ebp-0x8]
 44e:	5b                   	pop    ebx
 44f:	5e                   	pop    esi
 450:	5d                   	pop    ebp
 451:	c3                   	ret    
