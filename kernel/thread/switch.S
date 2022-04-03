section .text
global switch_to
switch_to:
    push esi
    push edi
    push ebx
    push ebp
    mov eax,[esp + 20]  ;得到栈中的参数cur_thread
    mov [eax],esp       ;将当前进程的栈顶指针esp保存在PCB的self_kstack处（偏移为0）

    ;-----以上是备份当前线程的环境，下面是恢复下一个线程的环境--------
    mov eax,[esp + 24]  ;得到栈中的参数next_thread
    mov esp,[eax]
    pop ebp
    pop ebx
    pop edi
    pop esi
    ret