
./build/process.o:     file format elf32-i386


Disassembly of section .text:

00000000 <start_process>:
#define default_prio    10

extern void intr_exit(void);

static void start_process(void *filename_)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 18             	sub    esp,0x18
    void *function = filename_;
   6:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
   9:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    struct task_struct *cur = running_thread();
   c:	e8 fc ff ff ff       	call   d <start_process+0xd>
  11:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    cur->self_kstack += sizeof(struct thread_stack);
  14:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  17:	8b 00                	mov    eax,DWORD PTR [eax]
  19:	8d 90 80 00 00 00    	lea    edx,[eax+0x80]
  1f:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  22:	89 10                	mov    DWORD PTR [eax],edx
    struct intr_stack *proc_stack = (struct intr_stack *)cur->self_kstack;
  24:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  27:	8b 00                	mov    eax,DWORD PTR [eax]
  29:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    proc_stack->edi = proc_stack->esi = proc_stack->ebp = proc_stack->esp_dummy = 0;
  2c:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  2f:	c7 40 10 00 00 00 00 	mov    DWORD PTR [eax+0x10],0x0
  36:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  39:	8b 50 10             	mov    edx,DWORD PTR [eax+0x10]
  3c:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  3f:	89 50 0c             	mov    DWORD PTR [eax+0xc],edx
  42:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  45:	8b 50 0c             	mov    edx,DWORD PTR [eax+0xc]
  48:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  4b:	89 50 08             	mov    DWORD PTR [eax+0x8],edx
  4e:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  51:	8b 50 08             	mov    edx,DWORD PTR [eax+0x8]
  54:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  57:	89 50 04             	mov    DWORD PTR [eax+0x4],edx
    proc_stack->ebx = proc_stack->edx = proc_stack->ecx = proc_stack->eax = 0;
  5a:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  5d:	c7 40 20 00 00 00 00 	mov    DWORD PTR [eax+0x20],0x0
  64:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  67:	8b 50 20             	mov    edx,DWORD PTR [eax+0x20]
  6a:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  6d:	89 50 1c             	mov    DWORD PTR [eax+0x1c],edx
  70:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  73:	8b 50 1c             	mov    edx,DWORD PTR [eax+0x1c]
  76:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  79:	89 50 18             	mov    DWORD PTR [eax+0x18],edx
  7c:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  7f:	8b 50 18             	mov    edx,DWORD PTR [eax+0x18]
  82:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  85:	89 50 14             	mov    DWORD PTR [eax+0x14],edx
    proc_stack->gs = 0;
  88:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  8b:	c7 40 24 00 00 00 00 	mov    DWORD PTR [eax+0x24],0x0
    proc_stack->ds = proc_stack->es = proc_stack->fs = SELECTOR_U_DATA;
  92:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  95:	c7 40 28 33 00 00 00 	mov    DWORD PTR [eax+0x28],0x33
  9c:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  9f:	8b 50 28             	mov    edx,DWORD PTR [eax+0x28]
  a2:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  a5:	89 50 2c             	mov    DWORD PTR [eax+0x2c],edx
  a8:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  ab:	8b 50 2c             	mov    edx,DWORD PTR [eax+0x2c]
  ae:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  b1:	89 50 30             	mov    DWORD PTR [eax+0x30],edx
    proc_stack->eip = function;
  b4:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
  b7:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  ba:	89 50 38             	mov    DWORD PTR [eax+0x38],edx
    proc_stack->cs = SELECTOR_U_CODE;
  bd:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  c0:	c7 40 3c 2b 00 00 00 	mov    DWORD PTR [eax+0x3c],0x2b
    proc_stack->eflags = EFLAGS_IOPL_0 | EFLAGS_MBS | EFLAGS_IF_1;
  c7:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  ca:	c7 40 40 02 02 00 00 	mov    DWORD PTR [eax+0x40],0x202
    proc_stack->esp = (void *)((uint32_t)get_a_page(PF_USER, USER_STACK3_VADDR) + PG_SIZE);
  d1:	83 ec 08             	sub    esp,0x8
  d4:	68 00 f0 ff bf       	push   0xbffff000
  d9:	6a 02                	push   0x2
  db:	e8 fc ff ff ff       	call   dc <start_process+0xdc>
  e0:	83 c4 10             	add    esp,0x10
  e3:	05 00 10 00 00       	add    eax,0x1000
  e8:	89 c2                	mov    edx,eax
  ea:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  ed:	89 50 44             	mov    DWORD PTR [eax+0x44],edx
    proc_stack->ss = SELECTOR_U_STACK;
  f0:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  f3:	c7 40 48 33 00 00 00 	mov    DWORD PTR [eax+0x48],0x33
    asm volatile("movl %0,%%esp; jmp intr_exit"::"g"(proc_stack):"memory");
  fa:	8b 65 ec             	mov    esp,DWORD PTR [ebp-0x14]
  fd:	e9 fc ff ff ff       	jmp    fe <start_process+0xfe>
}
 102:	90                   	nop
 103:	c9                   	leave  
 104:	c3                   	ret    

00000105 <process_activate>:
    proc_stack.ss = SELECTOR_U_DATA;
    asm volatile("movl %0,%%esp; jmp intr_exit"::"m"(proc_stack):"memory");
}
*/
void process_activate(struct task_struct *pthread)
{
 105:	55                   	push   ebp
 106:	89 e5                	mov    ebp,esp
 108:	83 ec 18             	sub    esp,0x18
    ASSERT(pthread != NULL);
 10b:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
 10f:	75 19                	jne    12a <process_activate+0x25>
 111:	68 00 00 00 00       	push   0x0
 116:	68 b0 00 00 00       	push   0xb0
 11b:	6a 2d                	push   0x2d
 11d:	68 10 00 00 00       	push   0x10
 122:	e8 fc ff ff ff       	call   123 <process_activate+0x1e>
 127:	83 c4 10             	add    esp,0x10
    
    uint32_t pdt_phy_addr = 0x100000;
 12a:	c7 45 f4 00 00 10 00 	mov    DWORD PTR [ebp-0xc],0x100000
    if(pthread->pgdir) {                        //用户进程有自己的页目录表
 131:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 134:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 137:	85 c0                	test   eax,eax
 139:	74 15                	je     150 <process_activate+0x4b>
        pdt_phy_addr = addr_v2p((uint32_t)pthread->pgdir);
 13b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 13e:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 141:	83 ec 0c             	sub    esp,0xc
 144:	50                   	push   eax
 145:	e8 fc ff ff ff       	call   146 <process_activate+0x41>
 14a:	83 c4 10             	add    esp,0x10
 14d:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    }
    //切换页表
    asm volatile("movl %0,%%cr3"::"r"(pdt_phy_addr):"memory");
 150:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 153:	0f 22 d8             	mov    cr3,eax
    
    if(pthread->pgdir) {
 156:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 159:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 15c:	85 c0                	test   eax,eax
 15e:	74 0e                	je     16e <process_activate+0x69>
        //切换TSS
        update_tss_esp0(pthread);
 160:	83 ec 0c             	sub    esp,0xc
 163:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 166:	e8 fc ff ff ff       	call   167 <process_activate+0x62>
 16b:	83 c4 10             	add    esp,0x10
    }
}
 16e:	90                   	nop
 16f:	c9                   	leave  
 170:	c3                   	ret    

00000171 <create_pdt>:

/* 创建页目录表：成功则返回页目录表的虚拟地址  */
static uint32_t *create_pdt(void)
{
 171:	55                   	push   ebp
 172:	89 e5                	mov    ebp,esp
 174:	83 ec 18             	sub    esp,0x18
    uint32_t *page_dir_vaddr = get_kernel_pages(1);
 177:	83 ec 0c             	sub    esp,0xc
 17a:	6a 01                	push   0x1
 17c:	e8 fc ff ff ff       	call   17d <create_pdt+0xc>
 181:	83 c4 10             	add    esp,0x10
 184:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    ASSERT(page_dir_vaddr != NULL);
 187:	83 7d f4 00          	cmp    DWORD PTR [ebp-0xc],0x0
 18b:	75 19                	jne    1a6 <create_pdt+0x35>
 18d:	68 2a 00 00 00       	push   0x2a
 192:	68 c4 00 00 00       	push   0xc4
 197:	6a 40                	push   0x40
 199:	68 10 00 00 00       	push   0x10
 19e:	e8 fc ff ff ff       	call   19f <create_pdt+0x2e>
 1a3:	83 c4 10             	add    esp,0x10
    if(page_dir_vaddr == NULL) {
 1a6:	83 7d f4 00          	cmp    DWORD PTR [ebp-0xc],0x0
 1aa:	75 07                	jne    1b3 <create_pdt+0x42>
        return NULL;
 1ac:	b8 00 00 00 00       	mov    eax,0x0
 1b1:	eb 43                	jmp    1f6 <create_pdt+0x85>
    }
    //共享内核的设计
    memcpy((uint32_t *)((uint32_t)page_dir_vaddr + 0x300 * 4), (uint32_t *)(0xfffff000 + 0x300 * 4), 1024);
 1b3:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1b6:	05 00 0c 00 00       	add    eax,0xc00
 1bb:	83 ec 04             	sub    esp,0x4
 1be:	68 00 04 00 00       	push   0x400
 1c3:	68 00 fc ff ff       	push   0xfffffc00
 1c8:	50                   	push   eax
 1c9:	e8 fc ff ff ff       	call   1ca <create_pdt+0x59>
 1ce:	83 c4 10             	add    esp,0x10
    uint32_t to_phyaddr = addr_v2p((uint32_t)page_dir_vaddr);
 1d1:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1d4:	83 ec 0c             	sub    esp,0xc
 1d7:	50                   	push   eax
 1d8:	e8 fc ff ff ff       	call   1d9 <create_pdt+0x68>
 1dd:	83 c4 10             	add    esp,0x10
 1e0:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    page_dir_vaddr[1023] = to_phyaddr | PG_US_U | PG_RW_W | PG_P_1;
 1e3:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1e6:	05 fc 0f 00 00       	add    eax,0xffc
 1eb:	8b 55 f0             	mov    edx,DWORD PTR [ebp-0x10]
 1ee:	83 ca 07             	or     edx,0x7
 1f1:	89 10                	mov    DWORD PTR [eax],edx
    return page_dir_vaddr;
 1f3:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 1f6:	c9                   	leave  
 1f7:	c3                   	ret    

000001f8 <create_vaddr_bitmap>:

/* 创建用户进程虚拟地址位图 */
static void create_vaddr_bitmap(struct task_struct *user_prog)
{
 1f8:	55                   	push   ebp
 1f9:	89 e5                	mov    ebp,esp
 1fb:	83 ec 18             	sub    esp,0x18
    user_prog->userprog_vaddr_pool.vaddr_start = USER_VADDR_START;
 1fe:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 201:	c7 40 2c 00 80 04 08 	mov    DWORD PTR [eax+0x2c],0x8048000
    uint32_t bitmap_bytes_len = (0xc0000000-USER_VADDR_START) / PG_SIZE / 8 ;
 208:	c7 45 f4 f7 6f 01 00 	mov    DWORD PTR [ebp-0xc],0x16ff7
    uint32_t bitmap_page_len = DIV_ROUND_UP(bitmap_bytes_len, PG_SIZE);
 20f:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 212:	05 ff 0f 00 00       	add    eax,0xfff
 217:	c1 e8 0c             	shr    eax,0xc
 21a:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    user_prog->userprog_vaddr_pool.pool_bitmap.bytes = (uint8_t *)get_kernel_pages(bitmap_page_len);
 21d:	83 ec 0c             	sub    esp,0xc
 220:	ff 75 f0             	push   DWORD PTR [ebp-0x10]
 223:	e8 fc ff ff ff       	call   224 <create_vaddr_bitmap+0x2c>
 228:	83 c4 10             	add    esp,0x10
 22b:	89 c2                	mov    edx,eax
 22d:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 230:	89 50 28             	mov    DWORD PTR [eax+0x28],edx
    user_prog->userprog_vaddr_pool.pool_bitmap.btmp_bytes_len = bitmap_bytes_len;
 233:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 236:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
 239:	89 50 24             	mov    DWORD PTR [eax+0x24],edx
    bitmap_init(&user_prog->userprog_vaddr_pool.pool_bitmap);
 23c:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 23f:	83 c0 24             	add    eax,0x24
 242:	83 ec 0c             	sub    esp,0xc
 245:	50                   	push   eax
 246:	e8 fc ff ff ff       	call   247 <create_vaddr_bitmap+0x4f>
 24b:	83 c4 10             	add    esp,0x10
}
 24e:	90                   	nop
 24f:	c9                   	leave  
 250:	c3                   	ret    

00000251 <process_create>:

void process_create(void *filename, char *name)
{
 251:	55                   	push   ebp
 252:	89 e5                	mov    ebp,esp
 254:	83 ec 18             	sub    esp,0x18
    //1.PCB的基本信息
    struct task_struct *thread = get_kernel_pages(1);           //为PCB表申请一页内核空间
 257:	83 ec 0c             	sub    esp,0xc
 25a:	6a 01                	push   0x1
 25c:	e8 fc ff ff ff       	call   25d <process_create+0xc>
 261:	83 c4 10             	add    esp,0x10
 264:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    init_thread(thread, name, default_prio);
 267:	83 ec 04             	sub    esp,0x4
 26a:	6a 0a                	push   0xa
 26c:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 26f:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 272:	e8 fc ff ff ff       	call   273 <process_create+0x22>
 277:	83 c4 10             	add    esp,0x10
    //2.用户进程的虚拟内存池
    create_vaddr_bitmap(thread);
 27a:	83 ec 0c             	sub    esp,0xc
 27d:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 280:	e8 73 ff ff ff       	call   1f8 <create_vaddr_bitmap>
 285:	83 c4 10             	add    esp,0x10
    //3.初始化线程栈
    thread_create(thread, start_process, filename);
 288:	83 ec 04             	sub    esp,0x4
 28b:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 28e:	68 00 00 00 00       	push   0x0
 293:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 296:	e8 fc ff ff ff       	call   297 <process_create+0x46>
 29b:	83 c4 10             	add    esp,0x10
    //4.创建页目录表
    thread->pgdir = create_pdt();
 29e:	e8 ce fe ff ff       	call   171 <create_pdt>
 2a3:	89 c2                	mov    edx,eax
 2a5:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2a8:	89 50 20             	mov    DWORD PTR [eax+0x20],edx
    //5.挂载到队列中
    enum intr_status old_status = intr_disable();
 2ab:	e8 fc ff ff ff       	call   2ac <process_create+0x5b>
 2b0:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    ASSERT(!elem_find(&thread_ready_list, &thread->general_tag));
 2b3:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2b6:	83 c0 30             	add    eax,0x30
 2b9:	83 ec 08             	sub    esp,0x8
 2bc:	50                   	push   eax
 2bd:	68 00 00 00 00       	push   0x0
 2c2:	e8 fc ff ff ff       	call   2c3 <process_create+0x72>
 2c7:	83 c4 10             	add    esp,0x10
 2ca:	85 c0                	test   eax,eax
 2cc:	74 19                	je     2e7 <process_create+0x96>
 2ce:	68 44 00 00 00       	push   0x44
 2d3:	68 d0 00 00 00       	push   0xd0
 2d8:	6a 63                	push   0x63
 2da:	68 10 00 00 00       	push   0x10
 2df:	e8 fc ff ff ff       	call   2e0 <process_create+0x8f>
 2e4:	83 c4 10             	add    esp,0x10
    list_append(&thread_ready_list, &thread->general_tag);
 2e7:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2ea:	83 c0 30             	add    eax,0x30
 2ed:	83 ec 08             	sub    esp,0x8
 2f0:	50                   	push   eax
 2f1:	68 00 00 00 00       	push   0x0
 2f6:	e8 fc ff ff ff       	call   2f7 <process_create+0xa6>
 2fb:	83 c4 10             	add    esp,0x10
    ASSERT(!elem_find(&thread_all_list, &thread->all_list_tag));
 2fe:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 301:	83 c0 38             	add    eax,0x38
 304:	83 ec 08             	sub    esp,0x8
 307:	50                   	push   eax
 308:	68 00 00 00 00       	push   0x0
 30d:	e8 fc ff ff ff       	call   30e <process_create+0xbd>
 312:	83 c4 10             	add    esp,0x10
 315:	85 c0                	test   eax,eax
 317:	74 19                	je     332 <process_create+0xe1>
 319:	68 7c 00 00 00       	push   0x7c
 31e:	68 d0 00 00 00       	push   0xd0
 323:	6a 65                	push   0x65
 325:	68 10 00 00 00       	push   0x10
 32a:	e8 fc ff ff ff       	call   32b <process_create+0xda>
 32f:	83 c4 10             	add    esp,0x10
    list_append(&thread_all_list, &thread->all_list_tag);
 332:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 335:	83 c0 38             	add    eax,0x38
 338:	83 ec 08             	sub    esp,0x8
 33b:	50                   	push   eax
 33c:	68 00 00 00 00       	push   0x0
 341:	e8 fc ff ff ff       	call   342 <process_create+0xf1>
 346:	83 c4 10             	add    esp,0x10
    intr_set_status(old_status);
 349:	83 ec 0c             	sub    esp,0xc
 34c:	ff 75 f0             	push   DWORD PTR [ebp-0x10]
 34f:	e8 fc ff ff ff       	call   350 <process_create+0xff>
 354:	83 c4 10             	add    esp,0x10
 357:	90                   	nop
 358:	c9                   	leave  
 359:	c3                   	ret    
