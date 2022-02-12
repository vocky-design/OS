[bits 32]
%define ERROR_CODE  nop
%define ZERO        push 0              ;push 立即数,8位按模式默认操作数大小扩展压栈,16位和32位按操作数大小压栈。

extern put_str                          ;声明外部函数
extern idt_function                     ;声明存储中断函数地址的数组idt_function[]
global intr_entry_table

section .data
intr_str db "interrupt occur!",0xa,0
intr_entry_table:

%macro VECTOR 2
section .text
intr%1entry:
    %2
    ;保存(用户)上下文环境。
    push ds 
    push es
    push fs
    push gs
    pushad              ;PUSHAD指令压入32位寄存器，入栈顺序为：EAX->ECX->EDX->EBX->ESP->EBP->ESI->EDI
    ;发送EOI
    mov al,0x20
    out 0xa0,al
    out 0x20,al
    ;调用中断函数
    push %1             ;不论idt_function中的目标函数是否需要参数，都一律压入中断向量号，调试时很方便。
    call [idt_function + %1*4]
    add esp,4
    ;恢复上下文环境，退出
    popad
    pop gs
    pop fs
    pop es
    pop ds
    add esp,4           ;跳过error_code
    iret
section .data
    dd intr%1entry
%endmacro

VECTOR 0x00,ZERO
VECTOR 0x01,ZERO
VECTOR 0x02,ZERO
VECTOR 0x03,ZERO
VECTOR 0x04,ZERO
VECTOR 0x05,ZERO
VECTOR 0x06,ZERO
VECTOR 0x07,ZERO
VECTOR 0x08,ZERO
VECTOR 0x09,ZERO
VECTOR 0x0a,ZERO
VECTOR 0x0b,ZERO
VECTOR 0x0c,ZERO
VECTOR 0x0d,ZERO
VECTOR 0x0e,ZERO
VECTOR 0x0f,ZERO
VECTOR 0x10,ZERO
VECTOR 0x11,ZERO
VECTOR 0x12,ZERO
VECTOR 0x13,ZERO
VECTOR 0x14,ZERO
VECTOR 0x15,ZERO
VECTOR 0x16,ZERO
VECTOR 0x17,ZERO
VECTOR 0x18,ZERO
VECTOR 0x19,ZERO
VECTOR 0x1a,ZERO
VECTOR 0x1b,ZERO
VECTOR 0x1c,ZERO
VECTOR 0x1d,ZERO
VECTOR 0x1e,ERROR_CODE
VECTOR 0x1f,ZERO
VECTOR 0x20,ZERO        ;时钟中断
VECTOR 0x21,ZERO        ;键盘中断
VECTOR 0x22,ZERO        ;级联yong
VECTOR 0x23,ZERO        ;串口2
VECTOR 0x24,ZERO        ;串口1
VECTOR 0x25,ZERO        ;并口2
VECTOR 0x26,ZERO        ;软盘
VECTOR 0x27,ZERO        ;并口1
VECTOR 0x28,ZERO        ;实时时钟
VECTOR 0x29,ZERO        ;重定向
VECTOR 0x2a,ZERO        ;保留
VECTOR 0x2b,ZERO        ;保留
VECTOR 0x2c,ZERO        ;ps/2鼠标
VECTOR 0x2d,ZERO        ;fpu浮点单元异常
VECTOR 0x2e,ZERO        ;硬盘
VECTOR 0x2f,ZERO        ;保留

