%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
;-------------构建gdt及其内部的描述符---------------
	GDT_BASE: 			dd 0x00000000
			  			dd 0x00000000
	CODE_DESC:			dd 0x0000ffff
						dd DESC_CODE_HIGH4
	DATA_STACK_DESC:	dd 0x0000ffff
						dd DESC_DATA_HIGH4
	VIDEO_DESC:			dd 0x80000007			;(0xbffff-0xb8000)/4k=0x7
						dd DESC_VIDEO_HIGH4

	GDT_SIZE 	equ $-GDT_BASE
	GDT_LIMIT	equ GDT_SIZE-1

	times 60 dq 0 ;此处预留60个描述符的空位

	total_mem_bytes dd 0		;这块地址是0xb00,0x900+(60+4)*8=0xb00

	SELECTOR_CODE 	equ (0x0001<<3) + TI_GDT + RPL0
	SELECTOR_DATA 	equ (0x0002<<3) + TI_GDT + RPL0
	SELECTOR_VIDEO	equ (0x0003<<3) + TI_GDT + RPL0

	gdt_ptr dw GDT_LIMIT
			dd GDT_BASE

	ards_buf times 244 db 0
	ards_nr dw 0

loader_start:
	mov sp,LOADER_BASE_ADDR
;打印"in loader"
	mov byte [gs:160],'i'
	mov byte [gs:161],0xa4

	mov byte [gs:162],'n'
	mov byte [gs:163],0xa4

	mov byte [gs:164],' '
	mov byte [gs:165],0xa4

	mov byte [gs:166],'l'
	mov byte [gs:167],0xa4

	mov byte [gs:168],'o'
	mov byte [gs:169],0xa4

	mov byte [gs:170],'a'
	mov byte [gs:171],0xa4

	mov byte [gs:172],'d'
	mov byte [gs:173],0xa4

	mov byte [gs:174],'e'
	mov byte [gs:175],0xa4

	mov byte [gs:176],'r'
	mov byte [gs:177],0xa4
;--------------------利用BIOS中断0x15获取物理内存容量-----
;1.子功能号:0xe820
		;---------获取所有ards----------
	xor ebx,ebx
	mov edx,0x534d4150
	mov di,ards_buf
.e820_mem_get_loop:
	mov ecx,20
	mov eax,0xe820
	int 0x15
	jc .e820_failed_so_try_e801
	add di,cx
	inc word [ards_nr]
	cmp ebx,0
	jnz .e820_mem_get_loop
		;----------分析返回-------------
	mov cx,[ards_nr]
	mov ebx,ards_buf
	xor edx,edx
.find_max_mem_area:
	mov eax,[ebx]
	add eax,[ebx+8]
	add ebx,20
	cmp eax,edx
	jl .next_ards
	mov edx,eax
.next_ards:
	loop .find_max_mem_area
	jmp .mem_get_ok

;2.子功能号:0xe801
.e820_failed_so_try_e801:
	mov ax,0xe801
	int 0x15
	jc .e801_failed_so_try_88
	
	mov cx,0x400
	mul cx
	shl edx,16
	and eax,0x0000ffff
	or  edx,eax
	add edx,0x100000
	mov esi,edx

	xor eax,eax
	mov ax,bx
	mov ecx,0x10000
	mul ecx
	add esi,eax

	mov edx,esi
	jmp .mem_get_ok
	
;3.子功能号:0xe88
.e801_failed_so_try_88:
	mov ah,0x88
	int 0x15
	jc .error_halt
	
	mov cx,0x400
	mul cx
	shl edx,16
	or  edx,eax
	add edx,0x100000
.error_halt:
	mov byte [gs:240],'e'
	mov byte [gs:241],0xa4
.mem_get_ok:
	mov [total_mem_bytes],edx

;--------------------进入保护模式-----------------
;1.打开A20GATE
;2.加载gdt
;3.将CR0的PE位置1
		;-----------打开A20GATE------------
	in al,0x92
	or al,0000_0010b
	out 0x92,al
		;-----------加载gdt----------------
	lgdt [gdt_ptr]
		;-----------将CR0寄存器的PE位置1---
	mov eax,cr0
	or eax,0x00000001
	mov cr0,eax

	jmp dword SELECTOR_CODE:p_mode_start		;作用:1.清空流水线2.更新段描述符缓冲寄存器

[bits 32]
p_mode_start:
	mov ax,SELECTOR_DATA						;段选择子是16位的。
	mov ds,ax
	mov es,ax
	mov ss,ax                                           
	mov esp,LOADER_BASE_ADDR
	mov ax,SELECTOR_VIDEO
	mov gs,ax

	;打印"P"
	mov byte [gs:320],'P'
	mov byte [gs:321],0xa4
	;加载kernel
	mov eax,KERNEL_START_SECTOR
	mov ebx,KERNEL_BIN_BASE_ADDR
	mov cl,200
	call rd_disk_m_32
;----------------------------------------------------------
;--------------------开启分页机制------------------------------
;----------------------------------------------------------
;1.创建必要的PDE和PTE
	call setup_page
	;准备好段访问的虚拟地址
	sgdt [gdt_ptr]
	mov ebx,[gdt_ptr+2]
	or dword [ebx+8*3+4],0xc0000000		;将显存段映射到内核地址
	add dword [gdt_ptr+2],0xc0000000	;将GDTR寄存器的gdt基址映射到内核地址,其实页目录项还是对应的低
	add esp,0xc0000000					;将栈指针映射到内核地址
;2.把页目录表地址赋值给cr3
	mov eax,PAGE_DIR_TABLE_POS
	mov cr3,eax
;3.打开cr0的pg位(第31位)
	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax

;在开启分页后，用gdt新的地址重新加载
	lgdt [gdt_ptr]
	;打印"V"
	mov byte [gs:480],'V'
	mov byte [gs:481],0xa4

	jmp dword SELECTOR_CODE:enter_kernel		;作用:1.清空流水线2.更新段描述符缓冲寄存器
enter_kernel:
	call kernel_init
	mov esp,0xc009f000							;最高可用地址9fbff的4kb对齐	
;----------------------------------------------------------
;--------------------启动内核------------------------------
;----------------------------------------------------------
	jmp KERNEL_ENTRY_POINT

;------------------------------------------------
;功能：读取硬盘n个扇区
;输入：eax,ebx,cl(不能超过255)
rd_disk_m_32:
;------------------------------------------------		
	mov esi,eax
	;第一步：设置要读取的扇区数
 	mov dx,0x1f2
	mov al,cl 					;sector count寄存器是8位。  
	out dx,al
	mov eax,esi

	;第二步：将LBA地址存入0x1f3-0x1f6
	mov dx,0x1f3
	out dx,al

	shr eax,8
	mov dx,0x1f4
	out dx,al

	shr eax,8
	mov dx,0x1f5
	out dx,al

	shr eax,8
	and al,0x0f
	or  al,0xe0				;设置7-4位为1110,表示lba模式,主盘。	
	mov dx,0x1f6				
	out dx,al
	;第三步：向0x1f7端口写入读命令，0x20
	mov dx,0x1f7
	mov al,0x20
	out dx,al
	;第四步：检测硬盘状态
	.not_ready:
	nop
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .not_ready
	;第五步：从0x1f0端口读数据
	mov ax,0					;ax清零
	mov al,cl					;假设cl不是0(0代表256个扇区)			？这里是个小bug
	mov dx,256					;每次读入2个字节，所以一个扇区512字节需要读次数512/2=256
	mul dx						;如果乘数是16位，就把ax看作被乘数，结果存入dx:ax
	mov cx,ax		
		
	mov dx,0x1f0
	.on_read:
	in ax,dx
	mov [ebx],ax
	add ebx,2
	loop .on_read

	ret

;------------------------------------------------
;功能：创建页目录表及页表
;输入：无
setup_page:
;------------------------------------------------
	;先把页目录表占用的空间清零
	mov ecx,4096								;1024*4=4096
	mov esi,0
	.clear_page_dir:
	mov byte [PAGE_DIR_TABLE_POS + esi],0
	inc esi
	loop .clear_page_dir
	;开始创建页目录项(PDE)
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x1000
	mov ebx,eax								;此处为ebx赋值，是为.create_pte做准备，ebx是基址。

	or eax,PG_US_U|PG_RW_R|PG_P				;
	mov [PAGE_DIR_TABLE_POS+0x000*4],eax	;在页目录表第一项，是页表基址
	mov [PAGE_DIR_TABLE_POS+0x300*4],eax	;在页目录表的OS内存区第一项，是页表基址
	sub eax,0x10000
	mov [PAGE_DIR_TABLE_POS+0x3ff*4],eax	;在页目录表的OS内存区最后一项，是页目录表基址
	;下面创建低1MB的页表项(PTE)
	mov ecx,256								;1MB/4KB=256
	mov esi,0
	mov edx,0|PG_US_U|PG_RW_R|PG_P
	.create_pte:
	mov [ebx+esi*4],edx
	add edx,0x1000							;0x1000:4kb
	inc esi
	loop .create_pte
	;创建虚拟地址内核区其他页表的PDE
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x1000*2						;the address of second pte table
	or 	eax,PG_US_U|PG_RW_R|PG_P
	mov ebx,PAGE_DIR_TABLE_POS
	mov ecx,254					;范围为第769-1022的所有目录项数量，768和1023有特别用途。
	mov esi,769
	.create_kernel_pde:
	mov [ebx+esi*4],eax
	add eax,0x1000
	inc esi
	loop .create_kernel_pde

	ret

;------------------------------------------------
;功能：将kernel.bin中的segment拷贝到编译的地址
;输入：无
kernel_init:
;------------------------------------------------
	xor eax,eax
	xor ebx,ebx			;ebx记录程序头表地址
	xor ecx,ecx			;cx记录程序头表中的program header大小
	xor edx,edx			;dx记录program header尺寸

	mov dx,[KERNEL_BIN_BASE_ADDR + 42]
	mov ebx,[KERNEL_BIN_BASE_ADDR + 28]
	add ebx,KERNEL_BIN_BASE_ADDR
	mov ecx,0
	mov cx,[KERNEL_BIN_BASE_ADDR + 44]

.each_segment:
	cmp byte [ebx],PT_NULL
	je .PTNULL
;为函数mem_cpy(dst,src,size)压入参数
	push dword [ebx + 16]
	mov eax,[ebx + 4]
	add eax,KERNEL_BIN_BASE_ADDR
	push eax
	push dword [ebx + 8]			;p_vaddr,这就是目的地址。
	call mem_cpy
	add esp,12
.PTNULL:
	add ebx,edx
	loop .each_segment
	ret
;---------------------------------------------------------
mem_cpy:
	cld
	push ebp
	mov ebp,esp
	push ecx
	
	mov edi,[ebp+8]
	mov esi,[ebp+12]
	mov ecx,[ebp+16]
	rep movsb

	;恢复环境
	pop ecx
	pop ebp
	ret
