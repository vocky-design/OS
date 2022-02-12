TI_GDT  equ 0
RPL0    equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0      ;make selector

[bits 32]
section .data 
    put_int_buffer dq 0             ;定义了8个字节，存放8位16进制数的字符值。 db,dw,dd,dq
section .text 
global put_char
global put_str
global put_int
global set_cursor
;-----------------------------------------------------------------
;功能描述：把栈中的一个字符写入光标所在处。
;入口参数：2字节压栈。
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

;-----------------------------------------------------------------
;功能描述：把字符串写入光标所在处。
;入口参数：
put_str:
;-----------------------------------------------------------------
    push ecx
    push ebx
    ;获取地址
    mov ebx,[esp + 4*2 + 4]
    ;调用put_char
    xor ecx,ecx
    .goon:
    mov cl,[ebx]
    cmp cl,0
    jz  .str_over
    push cx
    call put_char
    add esp,2
    inc ebx
    loop .goon
    .str_over:
    pop ebx
    pop ecx
    ret

;-----------------------------------------------------------------
;功能描述：把整数写入光标所在处。允许数字范围为32位二进制数可以表示的范围，输出格式为16进制数。
;入口参数：压入4字节。
put_int:
;-----------------------------------------------------------------
    pushad
    mov eax,[esp + 8*4 + 4]         ;读取压入的32位二进制数。   
    mov edx,eax
    mov ebx,put_int_buffer                                             
    mov ecx,8
    mov edi,7                       ;数组下标是0-7.
    .16based_4bits:
    and edx,0x0f
    cmp edx,9
    jg  .is_A2Z
    add edx,'0'
    jmp .store
    .is_A2Z:
    sub edx,10
    add edx,'A'                     ;其实有效数只在dl中。
    ;存储
    .store:
    mov [ebx + edi],dl
    ;更新循环量
    shr eax,4                       ;4位二进制数组合为一位16进制数。
    mov edx,eax
    dec edi
    loop .16based_4bits

    ;打印
    xor ax,ax
    mov ecx,8
    mov edi,0
    .goon:
    mov al,[ebx + edi]
    push ax
    call put_char
    add esp,2
    inc edi
    loop .goon

    popad
    ret


;-----------------------------------------------------------------
;功能描述：设置光标位置
;入口参数：2字节压栈。
set_cursor:
;-----------------------------------------------------------------
    pushad

    mov bx,[esp + 4*8 + 4]

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
