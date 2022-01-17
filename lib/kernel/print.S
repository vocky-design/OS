TI_GDT  equ 0
RPL0    equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0      ;make selector

[bits 32]
section .text 
global put_char
;-----------------------------------------------------------------
;功能描述：把栈中的一个字符写入光标所在处。
;入口参数：
put_char:
;-----------------------------------------------------------------
    pushad                  ;备份32位寄存器环境。
    mov ax,SELECTOR_VIDEO
    mov gs,ax               ;保险起见，重新为gs赋值。

    ;--------------获取当前光标位置------------------
    ;先获取高8位
    mov dx,0x03d4
    mov al,0x0e
    out dx,al
    mov dx,0x03d5
    in  al,dx
    mov ah,al
    ;再获取低8位
    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    in  al,dx
    ;将光标值存入bx
    mov bx,ax

    ;--------------获取栈中待打印字符------------------
    mov cl, [esp + 4*8 + 4]
    cmp cl,0x0d
    jz  .is_carriage_return
    cmp cl,0x0a
    jz  .is_line_feed
    cmp cl,0x08
    jz  .is_backspace
    jmp .put_other

    .is_carriage_return:
    .is_line_feed:                              ;如果是CR或者LF
    xor dx,dx
    mov ax,bx
    mov si,80
    div si
    sub bx,dx
    add bx,80
    cmp bx,2000
    jl  .set_cursor
    jmp .roll_screen
    .is_backspace:
    dec bx
    shl bx,1
    mov byte [gs:bx],0x20
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    jmp .set_cursor
    .put_other:
    shl bx,1
    mov [gs:bx],cl
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    inc bx
    cmp bx,2000
    jl  .set_cursor

    .roll_screen:
    cld
    mov ecx,960             ;使用四字节movsd，1920*2/4=960
    mov esi,0xc00b8000+160
    mov edi,0xc00b8000
    rep movsd
    ;将最后一行填为空白
    mov bx,3840             ;(2000-80)*2
    mov ecx,80
    .cls:
    mov word [gs:bx],0x0720
    add bx,2
    loop .cls
    ;将光标值重置为最后一行的首字符
    mov bx,1920             ;2000-80
    .set_cursor:
    mov dx,0x03d4
    mov al,0x0e
    out dx,al
    mov dx,0x03d5
    mov al,bh
    out dx,al

    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    mov al,bl
    out dx,al

    popad
    ret
