%include "boot.inc"
;主引导程序
;--------------------------------------------------------------------------------
SECTION MBR vstart=0x7c00
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov fs,ax
	mov sp,0x7c00
	mov ax,0xb800
	mov gs,ax

;利用0x06号功能，上卷全部行，则可清屏
;输入：
;AH 功能号= 0x06
;AL = 上卷的行数（如果是0,则为全部）
;BH = 上卷行属性
;(CL,CH) = 窗口左上角的(X,Y)值
;(DL,DH) = 窗口右下角的(X,Y)值
;无返回值
	mov ax,0x0600
	mov bh,0x07
	mov cx,0x0000
	mov dx,0x184f
	int 0x10

;打印"1 MBR"
	mov byte [gs:0x00],'1'
	mov byte [gs:0x01],0xa4

	mov byte [gs:0x02],' '
	mov byte [gs:0x03],0xa4

	mov byte [gs:0x04],'M'
	mov byte [gs:0x05],0xa4

	mov byte [gs:0x06],'B'
	mov byte [gs:0x07],0xa4

	mov byte [gs:0x08],'R'
	mov byte [gs:0x09],0xa4

;-----------------读入LOADER---------------------------

	mov eax,LOADER_START_SECTOR
	mov bx,LOADER_BASE_ADDR
	mov cl,4					;待读入的扇区数
	call rd_disk_m_16

	jmp LOADER_BASE_ADDR+0x300	;跳转到loader.S的loader_start

;------------------------------------------------
;功能：读取硬盘n个扇区
;输入：eax,bx,cl
rd_disk_m_16:
;------------------------------------------------
	mov esi,eax
;第一步：设置要读取的扇区数
 	mov dx,0x1f2
	mov al,cl
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
	or  al,0xe0					;设置7-4位为1110,表示lba模式,主盘。
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
	mov ax,0
	mov al,cl
	mov dx,256					;每次读入2个字节，所以一个扇区512字节需要读次数512/2=256
	mul dx,
	mov cx,ax		
		
	mov dx,0x1f0
.on_read:
	in ax,dx
	mov [bx],ax
	add bx,2
	loop .on_read

	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;
	times 510-($-$$) db 0
	db 0x55,0xaa



