
./build/process.o:     file format elf32-i386


Disassembly of section .text:

00000000 <start_process>:
#define default_prio    10

extern void intr_exit(void);

static void start_process(void *filename_)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	53                   	push   ebx
   4:	83 ec 14             	sub    esp,0x14
    void *function = filename_;
   7:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
   a:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    struct task_struct *cur = running_thread();
   d:	e8 fc ff ff ff       	call   e <start_process+0xe>
  12:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    cur->self_kstack += sizeof(struct thread_stack);
  15:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  18:	8b 00                	mov    eax,DWORD PTR [eax]
  1a:	8d 90 80 00 00 00    	lea    edx,[eax+0x80]
  20:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  23:	89 10                	mov    DWORD PTR [eax],edx
    struct intr_stack *proc_stack = (struct intr_stack *)cur->self_kstack;
  25:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  28:	8b 00                	mov    eax,DWORD PTR [eax]
  2a:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    proc_stack->edi = proc_stack->esi = proc_stack->ebp = proc_stack->esp_dummy = 0;
  2d:	8b 5d ec             	mov    ebx,DWORD PTR [ebp-0x14]
  30:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  33:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
  36:	8b 4d ec             	mov    ecx,DWORD PTR [ebp-0x14]
  39:	c7 41 10 00 00 00 00 	mov    DWORD PTR [ecx+0x10],0x0
  40:	8b 49 10             	mov    ecx,DWORD PTR [ecx+0x10]
  43:	89 4a 0c             	mov    DWORD PTR [edx+0xc],ecx
  46:	8b 52 0c             	mov    edx,DWORD PTR [edx+0xc]
  49:	89 50 08             	mov    DWORD PTR [eax+0x8],edx
  4c:	8b 40 08             	mov    eax,DWORD PTR [eax+0x8]
  4f:	89 43 04             	mov    DWORD PTR [ebx+0x4],eax
    proc_stack->ebx = proc_stack->edx = proc_stack->ecx = proc_stack->eax = 0;
  52:	8b 5d ec             	mov    ebx,DWORD PTR [ebp-0x14]
  55:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  58:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
  5b:	8b 4d ec             	mov    ecx,DWORD PTR [ebp-0x14]
  5e:	c7 41 20 00 00 00 00 	mov    DWORD PTR [ecx+0x20],0x0
  65:	8b 49 20             	mov    ecx,DWORD PTR [ecx+0x20]
  68:	89 4a 1c             	mov    DWORD PTR [edx+0x1c],ecx
  6b:	8b 52 1c             	mov    edx,DWORD PTR [edx+0x1c]
  6e:	89 50 18             	mov    DWORD PTR [eax+0x18],edx
  71:	8b 40 18             	mov    eax,DWORD PTR [eax+0x18]
  74:	89 43 14             	mov    DWORD PTR [ebx+0x14],eax
    proc_stack->gs = 0;
  77:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  7a:	c7 40 24 00 00 00 00 	mov    DWORD PTR [eax+0x24],0x0
    proc_stack->ds = proc_stack->es = proc_stack->fs = SELECTOR_U_DATA;
  81:	8b 4d ec             	mov    ecx,DWORD PTR [ebp-0x14]
  84:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  87:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
  8a:	c7 42 28 33 00 00 00 	mov    DWORD PTR [edx+0x28],0x33
  91:	8b 52 28             	mov    edx,DWORD PTR [edx+0x28]
  94:	89 50 2c             	mov    DWORD PTR [eax+0x2c],edx
  97:	8b 40 2c             	mov    eax,DWORD PTR [eax+0x2c]
  9a:	89 41 30             	mov    DWORD PTR [ecx+0x30],eax
    proc_stack->eip = function;
  9d:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  a0:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
  a3:	89 50 38             	mov    DWORD PTR [eax+0x38],edx
    proc_stack->cs = SELECTOR_U_CODE;
  a6:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  a9:	c7 40 3c 2b 00 00 00 	mov    DWORD PTR [eax+0x3c],0x2b
    proc_stack->eflags = EFLAGS_IOPL_0 | EFLAGS_MBS | EFLAGS_IF_1;
  b0:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  b3:	c7 40 40 02 02 00 00 	mov    DWORD PTR [eax+0x40],0x202
    proc_stack->esp = (void *)((uint32_t)get_a_page(PF_USER, USER_STACK3_VADDR) + PG_SIZE); //其实就是放在虚拟地址0xc0000000 
  ba:	8b 5d ec             	mov    ebx,DWORD PTR [ebp-0x14]
  bd:	83 ec 08             	sub    esp,0x8
  c0:	68 00 f0 ff bf       	push   0xbffff000
  c5:	6a 02                	push   0x2
  c7:	e8 fc ff ff ff       	call   c8 <start_process+0xc8>
  cc:	83 c4 10             	add    esp,0x10
  cf:	05 00 10 00 00       	add    eax,0x1000
  d4:	89 43 44             	mov    DWORD PTR [ebx+0x44],eax
    proc_stack->ss = SELECTOR_U_STACK;
  d7:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  da:	c7 40 48 33 00 00 00 	mov    DWORD PTR [eax+0x48],0x33
    asm volatile("movl %0,%%esp; jmp intr_exit"::"m"(proc_stack):"memory");
  e1:	8b 65 ec             	mov    esp,DWORD PTR [ebp-0x14]
  e4:	e9 fc ff ff ff       	jmp    e5 <start_process+0xe5>
}
  e9:	90                   	nop
  ea:	8b 5d fc             	mov    ebx,DWORD PTR [ebp-0x4]
  ed:	c9                   	leave  
  ee:	c3                   	ret    

000000ef <process_activate>:
    proc_stack.ss = SELECTOR_U_DATA;
    asm volatile("movl %0,%%esp; jmp intr_exit"::"m"(proc_stack):"memory");
}
*/
void process_activate(struct task_struct *pthread)
{
  ef:	55                   	push   ebp
  f0:	89 e5                	mov    ebp,esp
  f2:	83 ec 18             	sub    esp,0x18
    ASSERT(pthread != NULL);
  f5:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
  f9:	75 19                	jne    114 <process_activate+0x25>
  fb:	68 00 00 00 00       	push   0x0
 100:	68 b0 00 00 00       	push   0xb0
 105:	6a 2d                	push   0x2d
 107:	68 10 00 00 00       	push   0x10
 10c:	e8 fc ff ff ff       	call   10d <process_activate+0x1e>
 111:	83 c4 10             	add    esp,0x10
    
    uint32_t pdt_phy_addr = 0x100000;
 114:	c7 45 f4 00 00 10 00 	mov    DWORD PTR [ebp-0xc],0x100000
    if(pthread->pgdir) {        //是用户进程
 11b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 11e:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 121:	85 c0                	test   eax,eax
 123:	74 15                	je     13a <process_activate+0x4b>
        pdt_phy_addr = addr_v2p((uint32_t)pthread->pgdir);
 125:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 128:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 12b:	83 ec 0c             	sub    esp,0xc
 12e:	50                   	push   eax
 12f:	e8 fc ff ff ff       	call   130 <process_activate+0x41>
 134:	83 c4 10             	add    esp,0x10
 137:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    }
    //切换页表
    asm volatile("movl %0,%%cr3"::"r"(pdt_phy_addr):"memory");
 13a:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 13d:	0f 22 d8             	mov    cr3,eax
    
    if(pthread->pgdir) {
 140:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 143:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 146:	85 c0                	test   eax,eax
 148:	74 0e                	je     158 <process_activate+0x69>
        //切换TSS
        update_tss_esp0(pthread);
 14a:	83 ec 0c             	sub    esp,0xc
 14d:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 150:	e8 fc ff ff ff       	call   151 <process_activate+0x62>
 155:	83 c4 10             	add    esp,0x10
    }
}
 158:	90                   	nop
 159:	c9                   	leave  
 15a:	c3                   	ret    

0000015b <create_pdt>:

/* 创建页目录表：成功则返回页目录表的虚拟地址  */
static uint32_t *create_pdt(void)
{
 15b:	55                   	push   ebp
 15c:	89 e5                	mov    ebp,esp
 15e:	83 ec 18             	sub    esp,0x18
    uint32_t *page_dir_vaddr = get_kernel_pages(1);
 161:	83 ec 0c             	sub    esp,0xc
 164:	6a 01                	push   0x1
 166:	e8 fc ff ff ff       	call   167 <create_pdt+0xc>
 16b:	83 c4 10             	add    esp,0x10
 16e:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    ASSERT(page_dir_vaddr != NULL);
 171:	83 7d f4 00          	cmp    DWORD PTR [ebp-0xc],0x0
 175:	75 19                	jne    190 <create_pdt+0x35>
 177:	68 2a 00 00 00       	push   0x2a
 17c:	68 c4 00 00 00       	push   0xc4
 181:	6a 40                	push   0x40
 183:	68 10 00 00 00       	push   0x10
 188:	e8 fc ff ff ff       	call   189 <create_pdt+0x2e>
 18d:	83 c4 10             	add    esp,0x10
    if(page_dir_vaddr == NULL) {
 190:	83 7d f4 00          	cmp    DWORD PTR [ebp-0xc],0x0
 194:	75 07                	jne    19d <create_pdt+0x42>
        return NULL;
 196:	b8 00 00 00 00       	mov    eax,0x0
 19b:	eb 43                	jmp    1e0 <create_pdt+0x85>
    }
    //共享内核的设计
    memcpy((uint32_t *)((uint32_t)page_dir_vaddr + 0x300 * 4), (uint32_t *)(0xfffff000 + 0x300 * 4), 1024);
 19d:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1a0:	05 00 0c 00 00       	add    eax,0xc00
 1a5:	83 ec 04             	sub    esp,0x4
 1a8:	68 00 04 00 00       	push   0x400
 1ad:	68 00 fc ff ff       	push   0xfffffc00
 1b2:	50                   	push   eax
 1b3:	e8 fc ff ff ff       	call   1b4 <create_pdt+0x59>
 1b8:	83 c4 10             	add    esp,0x10
    uint32_t to_phyaddr = addr_v2p((uint32_t)page_dir_vaddr);
 1bb:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1be:	83 ec 0c             	sub    esp,0xc
 1c1:	50                   	push   eax
 1c2:	e8 fc ff ff ff       	call   1c3 <create_pdt+0x68>
 1c7:	83 c4 10             	add    esp,0x10
 1ca:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    page_dir_vaddr[1023] = to_phyaddr | PG_US_U | PG_RW_W | PG_P_1;
 1cd:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1d0:	05 fc 0f 00 00       	add    eax,0xffc
 1d5:	8b 55 f0             	mov    edx,DWORD PTR [ebp-0x10]
 1d8:	83 ca 07             	or     edx,0x7
 1db:	89 10                	mov    DWORD PTR [eax],edx
    return page_dir_vaddr;
 1dd:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 1e0:	c9                   	leave  
 1e1:	c3                   	ret    

000001e2 <create_vaddr_bitmap>:

/* 创建用户进程虚拟地址位图 */
static void create_vaddr_bitmap(struct task_struct *user_prog)
{
 1e2:	55                   	push   ebp
 1e3:	89 e5                	mov    ebp,esp
 1e5:	83 ec 18             	sub    esp,0x18
    user_prog->userprog_vaddr_pool.vaddr_start = USER_VADDR_START;
 1e8:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 1eb:	c7 40 2c 00 80 04 08 	mov    DWORD PTR [eax+0x2c],0x8048000
    uint32_t bitmap_bytes_len = (0xc0000000-USER_VADDR_START) / PG_SIZE / 8 ;
 1f2:	c7 45 f4 f7 6f 01 00 	mov    DWORD PTR [ebp-0xc],0x16ff7
    uint32_t bitmap_page_len = DIV_ROUND_UP(bitmap_bytes_len, PG_SIZE);
 1f9:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1fc:	05 ff 0f 00 00       	add    eax,0xfff
 201:	c1 e8 0c             	shr    eax,0xc
 204:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    user_prog->userprog_vaddr_pool.pool_bitmap.bytes = (uint8_t *)get_kernel_pages(bitmap_page_len);
 207:	83 ec 0c             	sub    esp,0xc
 20a:	ff 75 f0             	push   DWORD PTR [ebp-0x10]
 20d:	e8 fc ff ff ff       	call   20e <create_vaddr_bitmap+0x2c>
 212:	83 c4 10             	add    esp,0x10
 215:	89 c2                	mov    edx,eax
 217:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 21a:	89 50 28             	mov    DWORD PTR [eax+0x28],edx
    user_prog->userprog_vaddr_pool.pool_bitmap.btmp_bytes_len = bitmap_bytes_len;
 21d:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 220:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
 223:	89 50 24             	mov    DWORD PTR [eax+0x24],edx
    bitmap_init(&user_prog->userprog_vaddr_pool.pool_bitmap);
 226:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 229:	83 c0 24             	add    eax,0x24
 22c:	83 ec 0c             	sub    esp,0xc
 22f:	50                   	push   eax
 230:	e8 fc ff ff ff       	call   231 <create_vaddr_bitmap+0x4f>
 235:	83 c4 10             	add    esp,0x10
}
 238:	90                   	nop
 239:	c9                   	leave  
 23a:	c3                   	ret    

0000023b <process_create>:

void process_create(void *filename, char *name)
{
 23b:	55                   	push   ebp
 23c:	89 e5                	mov    ebp,esp
 23e:	83 ec 18             	sub    esp,0x18
    //1.PCB的基本信息
    struct task_struct *thread = get_kernel_pages(1);           //为PCB表申请一页内核空间
 241:	83 ec 0c             	sub    esp,0xc
 244:	6a 01                	push   0x1
 246:	e8 fc ff ff ff       	call   247 <process_create+0xc>
 24b:	83 c4 10             	add    esp,0x10
 24e:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    init_thread(thread, name, default_prio);
 251:	83 ec 04             	sub    esp,0x4
 254:	6a 0a                	push   0xa
 256:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 259:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 25c:	e8 fc ff ff ff       	call   25d <process_create+0x22>
 261:	83 c4 10             	add    esp,0x10
    //2.用户进程的虚拟内存池
    create_vaddr_bitmap(thread);
 264:	83 ec 0c             	sub    esp,0xc
 267:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 26a:	e8 73 ff ff ff       	call   1e2 <create_vaddr_bitmap>
 26f:	83 c4 10             	add    esp,0x10
    //3.初始化线程栈
    thread_create(thread, start_process, filename);
 272:	83 ec 04             	sub    esp,0x4
 275:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 278:	68 00 00 00 00       	push   0x0
 27d:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 280:	e8 fc ff ff ff       	call   281 <process_create+0x46>
 285:	83 c4 10             	add    esp,0x10
    //4.创建页目录表
    thread->pgdir = create_pdt();
 288:	e8 ce fe ff ff       	call   15b <create_pdt>
 28d:	89 c2                	mov    edx,eax
 28f:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 292:	89 50 20             	mov    DWORD PTR [eax+0x20],edx
    //5.挂载到队列中
    enum intr_status old_status = intr_disable();
 295:	e8 fc ff ff ff       	call   296 <process_create+0x5b>
 29a:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    ASSERT(!elem_find(&thread_ready_list, &thread->general_tag));
 29d:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2a0:	83 c0 30             	add    eax,0x30
 2a3:	83 ec 08             	sub    esp,0x8
 2a6:	50                   	push   eax
 2a7:	68 00 00 00 00       	push   0x0
 2ac:	e8 fc ff ff ff       	call   2ad <process_create+0x72>
 2b1:	83 c4 10             	add    esp,0x10
 2b4:	85 c0                	test   eax,eax
 2b6:	74 19                	je     2d1 <process_create+0x96>
 2b8:	68 44 00 00 00       	push   0x44
 2bd:	68 d0 00 00 00       	push   0xd0
 2c2:	6a 63                	push   0x63
 2c4:	68 10 00 00 00       	push   0x10
 2c9:	e8 fc ff ff ff       	call   2ca <process_create+0x8f>
 2ce:	83 c4 10             	add    esp,0x10
    list_append(&thread_ready_list, &thread->general_tag);
 2d1:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2d4:	83 c0 30             	add    eax,0x30
 2d7:	83 ec 08             	sub    esp,0x8
 2da:	50                   	push   eax
 2db:	68 00 00 00 00       	push   0x0
 2e0:	e8 fc ff ff ff       	call   2e1 <process_create+0xa6>
 2e5:	83 c4 10             	add    esp,0x10
    ASSERT(!elem_find(&thread_all_list, &thread->all_list_tag));
 2e8:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2eb:	83 c0 38             	add    eax,0x38
 2ee:	83 ec 08             	sub    esp,0x8
 2f1:	50                   	push   eax
 2f2:	68 00 00 00 00       	push   0x0
 2f7:	e8 fc ff ff ff       	call   2f8 <process_create+0xbd>
 2fc:	83 c4 10             	add    esp,0x10
 2ff:	85 c0                	test   eax,eax
 301:	74 19                	je     31c <process_create+0xe1>
 303:	68 7c 00 00 00       	push   0x7c
 308:	68 d0 00 00 00       	push   0xd0
 30d:	6a 65                	push   0x65
 30f:	68 10 00 00 00       	push   0x10
 314:	e8 fc ff ff ff       	call   315 <process_create+0xda>
 319:	83 c4 10             	add    esp,0x10
    list_append(&thread_all_list, &thread->all_list_tag);
 31c:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 31f:	83 c0 38             	add    eax,0x38
 322:	83 ec 08             	sub    esp,0x8
 325:	50                   	push   eax
 326:	68 00 00 00 00       	push   0x0
 32b:	e8 fc ff ff ff       	call   32c <process_create+0xf1>
 330:	83 c4 10             	add    esp,0x10
    intr_set_status(old_status);
 333:	83 ec 0c             	sub    esp,0xc
 336:	ff 75 f0             	push   DWORD PTR [ebp-0x10]
 339:	e8 fc ff ff ff       	call   33a <process_create+0xff>
 33e:	83 c4 10             	add    esp,0x10
 341:	90                   	nop
 342:	c9                   	leave  
 343:	c3                   	ret    
