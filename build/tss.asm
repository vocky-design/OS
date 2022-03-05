
./build/tss.o:     file format elf32-i386


Disassembly of section .text:

00000000 <update_tss_esp0>:
};
static struct tss tss;

/* 更新TSS中的esp0字段的值为pthread的0级栈 */
void update_tss_esp0(struct task_struct *pthread)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
    tss.esp0 = (uint32_t *)((uint32_t)pthread + PG_SIZE);
   3:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
   6:	05 00 10 00 00       	add    eax,0x1000
   b:	a3 04 00 00 00       	mov    ds:0x4,eax
}
  10:	90                   	nop
  11:	5d                   	pop    ebp
  12:	c3                   	ret    

00000013 <make_gdt_desc>:
static struct gdt_desc make_gdt_desc( \
    uint32_t    desc_base, \
    uint32_t    limit, \
    uint8_t     attr_low, \
    uint8_t     attr_high \
) {
  13:	55                   	push   ebp
  14:	89 e5                	mov    ebp,esp
  16:	83 ec 18             	sub    esp,0x18
  19:	8b 55 14             	mov    edx,DWORD PTR [ebp+0x14]
  1c:	8b 45 18             	mov    eax,DWORD PTR [ebp+0x18]
  1f:	88 55 ec             	mov    BYTE PTR [ebp-0x14],dl
  22:	88 45 e8             	mov    BYTE PTR [ebp-0x18],al
    struct gdt_desc desc;
    desc.limit_low_word = limit & 0x0000ffff;
  25:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  28:	66 89 45 f8          	mov    WORD PTR [ebp-0x8],ax
    desc.base_low_word = desc_base & 0x0000ffff;
  2c:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  2f:	66 89 45 fa          	mov    WORD PTR [ebp-0x6],ax
    desc.base_mid_byte = (desc_base & 0x00ff0000) >> 16;
  33:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  36:	25 00 00 ff 00       	and    eax,0xff0000
  3b:	c1 e8 10             	shr    eax,0x10
  3e:	88 45 fc             	mov    BYTE PTR [ebp-0x4],al
    desc.attr_low_byte = attr_low;
  41:	0f b6 45 ec          	movzx  eax,BYTE PTR [ebp-0x14]
  45:	88 45 fd             	mov    BYTE PTR [ebp-0x3],al
    desc.limit_high_attr_high_byte = ((limit & 0x000f0000) >> 16) | attr_high;
  48:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  4b:	25 00 00 0f 00       	and    eax,0xf0000
  50:	c1 e8 10             	shr    eax,0x10
  53:	0a 45 e8             	or     al,BYTE PTR [ebp-0x18]
  56:	88 45 fe             	mov    BYTE PTR [ebp-0x2],al
    desc.base_high_byte = desc_base >> 24;
  59:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  5c:	c1 e8 18             	shr    eax,0x18
  5f:	88 45 ff             	mov    BYTE PTR [ebp-0x1],al
    return desc;
  62:	8b 4d 08             	mov    ecx,DWORD PTR [ebp+0x8]
  65:	8b 45 f8             	mov    eax,DWORD PTR [ebp-0x8]
  68:	8b 55 fc             	mov    edx,DWORD PTR [ebp-0x4]
  6b:	89 01                	mov    DWORD PTR [ecx],eax
  6d:	89 51 04             	mov    DWORD PTR [ecx+0x4],edx
}
  70:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  73:	c9                   	leave  
  74:	c2 04 00             	ret    0x4

00000077 <tss_init>:

/* 创建tss，在GDT中添加TSS描述符，3特权级数据段，3特权级代码段 */
void tss_init(void)
{
  77:	55                   	push   ebp
  78:	89 e5                	mov    ebp,esp
  7a:	53                   	push   ebx
  7b:	83 ec 24             	sub    esp,0x24
    put_str("tss_init start\n");
  7e:	83 ec 0c             	sub    esp,0xc
  81:	68 00 00 00 00       	push   0x0
  86:	e8 fc ff ff ff       	call   87 <tss_init+0x10>
  8b:	83 c4 10             	add    esp,0x10
    //创建TSS
    uint32_t tss_size = sizeof(tss);
  8e:	c7 45 f4 6c 00 00 00 	mov    DWORD PTR [ebp-0xc],0x6c
    memset(&tss, 0, tss_size);
  95:	83 ec 04             	sub    esp,0x4
  98:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
  9b:	6a 00                	push   0x0
  9d:	68 00 00 00 00       	push   0x0
  a2:	e8 fc ff ff ff       	call   a3 <tss_init+0x2c>
  a7:	83 c4 10             	add    esp,0x10
    tss.ss0 = SELECTOR_K_STACK;
  aa:	c7 05 08 00 00 00 10 	mov    DWORD PTR ds:0x8,0x10
  b1:	00 00 00 
    tss.io_base = tss_size;                  //表示TSS中没有IO位图
  b4:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  b7:	a3 68 00 00 00       	mov    ds:0x68,eax

    //GDT基址为0x900，把TSS放在第四个，代码段放在第5个，数据段放在第6个 //TSS的DPL=0
    *((struct gdt_desc *)0xc0000920) = make_gdt_desc(\
  bc:	bb 20 09 00 c0       	mov    ebx,0xc0000920
  c1:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  c4:	8d 50 ff             	lea    edx,[eax-0x1]
  c7:	b9 00 00 00 00       	mov    ecx,0x0
  cc:	8d 45 e0             	lea    eax,[ebp-0x20]
  cf:	83 ec 0c             	sub    esp,0xc
  d2:	68 80 00 00 00       	push   0x80
  d7:	68 89 00 00 00       	push   0x89
  dc:	52                   	push   edx
  dd:	51                   	push   ecx
  de:	50                   	push   eax
  df:	e8 2f ff ff ff       	call   13 <make_gdt_desc>
  e4:	83 c4 1c             	add    esp,0x1c
  e7:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
  ea:	8b 55 e4             	mov    edx,DWORD PTR [ebp-0x1c]
  ed:	89 03                	mov    DWORD PTR [ebx],eax
  ef:	89 53 04             	mov    DWORD PTR [ebx+0x4],edx
        (uint32_t)&tss, \
        tss_size-1, \
        TSS_ATTR_LOW, \
        TSS_ATTR_HIGH );
    *((struct gdt_desc *)0xc0000928) = make_gdt_desc(\
  f2:	bb 28 09 00 c0       	mov    ebx,0xc0000928
  f7:	8d 45 e0             	lea    eax,[ebp-0x20]
  fa:	83 ec 0c             	sub    esp,0xc
  fd:	68 c0 00 00 00       	push   0xc0
 102:	68 f8 00 00 00       	push   0xf8
 107:	68 ff ff 0f 00       	push   0xfffff
 10c:	6a 00                	push   0x0
 10e:	50                   	push   eax
 10f:	e8 ff fe ff ff       	call   13 <make_gdt_desc>
 114:	83 c4 1c             	add    esp,0x1c
 117:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
 11a:	8b 55 e4             	mov    edx,DWORD PTR [ebp-0x1c]
 11d:	89 03                	mov    DWORD PTR [ebx],eax
 11f:	89 53 04             	mov    DWORD PTR [ebx+0x4],edx
        (uint32_t)0, \
        0xfffff, \
        GDT_CODE_ATTR_LOW_DPL3, \
        GDT_ATTR_HIGH );
    *((struct gdt_desc *)0xc0000930) = make_gdt_desc(\
 122:	bb 30 09 00 c0       	mov    ebx,0xc0000930
 127:	8d 45 e0             	lea    eax,[ebp-0x20]
 12a:	83 ec 0c             	sub    esp,0xc
 12d:	68 c0 00 00 00       	push   0xc0
 132:	68 f2 00 00 00       	push   0xf2
 137:	68 ff ff 0f 00       	push   0xfffff
 13c:	6a 00                	push   0x0
 13e:	50                   	push   eax
 13f:	e8 cf fe ff ff       	call   13 <make_gdt_desc>
 144:	83 c4 1c             	add    esp,0x1c
 147:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
 14a:	8b 55 e4             	mov    edx,DWORD PTR [ebp-0x1c]
 14d:	89 03                	mov    DWORD PTR [ebx],eax
 14f:	89 53 04             	mov    DWORD PTR [ebx+0x4],edx
        0xfffff, \
        GDT_DATA_ATTR_LOW_DPL3, \
        GDT_ATTR_HIGH );

    //更新GDTR和TR
    uint64_t gdt_operand = ((uint64_t)(uint32_t)0x900 << 16) + ((7 * 8) - 1);
 152:	c7 45 e8 37 00 00 09 	mov    DWORD PTR [ebp-0x18],0x9000037
 159:	c7 45 ec 00 00 00 00 	mov    DWORD PTR [ebp-0x14],0x0
    asm volatile("lgdt %0"::"m"(gdt_operand));
 160:	0f 01 55 e8          	lgdtd  [ebp-0x18]
    asm volatile("ltr %w0"::"r"(SELECTOR_TSS));     //存的是TSS选择子
 164:	b8 20 00 00 00       	mov    eax,0x20
 169:	0f 00 d8             	ltr    ax
    put_str("tss_init done\n");
 16c:	83 ec 0c             	sub    esp,0xc
 16f:	68 10 00 00 00       	push   0x10
 174:	e8 fc ff ff ff       	call   175 <tss_init+0xfe>
 179:	83 c4 10             	add    esp,0x10
}
 17c:	90                   	nop
 17d:	8b 5d fc             	mov    ebx,DWORD PTR [ebp-0x4]
 180:	c9                   	leave  
 181:	c3                   	ret    
