
./build/thread.o:     file format elf32-i386


Disassembly of section .text:

00000000 <running_thread>:

struct task_struct *main_thread;        //主线程PCB

/* 获取当前进程PCB指针 */
struct task_struct *running_thread(void)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 10             	sub    esp,0x10
    uint32_t esp;
    asm volatile ("mov %%esp,%0":"=g"(esp));        //g:表示可以存放到任意地点（寄存器和内存），包括q（eax/ebx/ecx/edx）和内存
   6:	89 e0                	mov    eax,esp
   8:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
    return (struct task_struct *)(esp & 0xfffff000);
   b:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
   e:	25 00 f0 ff ff       	and    eax,0xfffff000
}
  13:	c9                   	leave  
  14:	c3                   	ret    

00000015 <kernel_thread>:

/* 由kernel_thread去执行function(func_arg) */
static void kernel_thread(thread_func function, void *func_arg)             //????????????????
{
  15:	55                   	push   ebp
  16:	89 e5                	mov    ebp,esp
  18:	83 ec 08             	sub    esp,0x8
    //此函数在中断函数内执行
    //默认中断服务函数内会关闭中断
    intr_enable();          //调度器基于时钟中断，保证后面调度器正常工作
  1b:	e8 fc ff ff ff       	call   1c <kernel_thread+0x7>
    function(func_arg);
  20:	83 ec 0c             	sub    esp,0xc
  23:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
  26:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  29:	ff d0                	call   eax
  2b:	83 c4 10             	add    esp,0x10
}
  2e:	90                   	nop
  2f:	c9                   	leave  
  30:	c3                   	ret    

00000031 <init_thread>:

/* 初始化PCB */
void init_thread(struct task_struct *pthread, char *name, int prio)
{
  31:	55                   	push   ebp
  32:	89 e5                	mov    ebp,esp
  34:	83 ec 08             	sub    esp,0x8
    if(pthread == main_thread) {
  37:	a1 00 00 00 00       	mov    eax,ds:0x0
  3c:	39 45 08             	cmp    DWORD PTR [ebp+0x8],eax
  3f:	75 0c                	jne    4d <init_thread+0x1c>
        pthread->status = TASK_RUNNING;
  41:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  44:	c7 40 04 00 00 00 00 	mov    DWORD PTR [eax+0x4],0x0
  4b:	eb 0a                	jmp    57 <init_thread+0x26>
    } else {
        pthread->status = TASK_READY;
  4d:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  50:	c7 40 04 01 00 00 00 	mov    DWORD PTR [eax+0x4],0x1
    }
    //
    pthread->self_kstack = (uint32_t *)((uint32_t)pthread + PG_SIZE);
  57:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  5a:	05 00 10 00 00       	add    eax,0x1000
  5f:	89 c2                	mov    edx,eax
  61:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  64:	89 10                	mov    DWORD PTR [eax],edx
    strcpy(pthread->name, name);
  66:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  69:	83 c0 08             	add    eax,0x8
  6c:	83 ec 08             	sub    esp,0x8
  6f:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
  72:	50                   	push   eax
  73:	e8 fc ff ff ff       	call   74 <init_thread+0x43>
  78:	83 c4 10             	add    esp,0x10
    pthread->priority = prio;
  7b:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  7e:	89 c2                	mov    edx,eax
  80:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  83:	88 50 18             	mov    BYTE PTR [eax+0x18],dl
    pthread->ticks = prio;
  86:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  89:	89 c2                	mov    edx,eax
  8b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  8e:	88 50 19             	mov    BYTE PTR [eax+0x19],dl
    pthread->elapsed_ticks = 0;
  91:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  94:	c7 40 1c 00 00 00 00 	mov    DWORD PTR [eax+0x1c],0x0
    pthread->pgdir = NULL;
  9b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  9e:	c7 40 20 00 00 00 00 	mov    DWORD PTR [eax+0x20],0x0
    pthread->stack_magic = 0x19870916;  
  a5:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  a8:	c7 40 40 16 09 87 19 	mov    DWORD PTR [eax+0x40],0x19870916
    //后面要分别初始化     uint32_t *pgdir;
    //                    struct vaddr_pool userprog_vaddr_pool;
    //                    struct list_elem general_tag;
    //                    struct list_elem all_list_tag;   
}
  af:	90                   	nop
  b0:	c9                   	leave  
  b1:	c3                   	ret    

000000b2 <thread_create>:

/* 初始化内核线程栈 */
void thread_create(struct task_struct *pthread, thread_func *function, void *func_arg)
{
  b2:	55                   	push   ebp
  b3:	89 e5                	mov    ebp,esp
  b5:	83 ec 10             	sub    esp,0x10
    pthread->self_kstack -= sizeof(struct intr_stack);
  b8:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  bb:	8b 00                	mov    eax,DWORD PTR [eax]
  bd:	8d 90 d0 fe ff ff    	lea    edx,[eax-0x130]
  c3:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  c6:	89 10                	mov    DWORD PTR [eax],edx
    pthread->self_kstack -= sizeof(struct thread_stack);
  c8:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  cb:	8b 00                	mov    eax,DWORD PTR [eax]
  cd:	8d 50 80             	lea    edx,[eax-0x80]
  d0:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  d3:	89 10                	mov    DWORD PTR [eax],edx
    //目前self_kstack指针就更新到了这里
    struct thread_stack *kthread_stack = (struct thread_stack *)pthread->self_kstack;
  d5:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  d8:	8b 00                	mov    eax,DWORD PTR [eax]
  da:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
    kthread_stack->ebp = kthread_stack->ebx = kthread_stack->esi = kthread_stack->edi = 0;
  dd:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  e0:	c7 40 08 00 00 00 00 	mov    DWORD PTR [eax+0x8],0x0
  e7:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  ea:	8b 50 08             	mov    edx,DWORD PTR [eax+0x8]
  ed:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  f0:	89 50 0c             	mov    DWORD PTR [eax+0xc],edx
  f3:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  f6:	8b 50 0c             	mov    edx,DWORD PTR [eax+0xc]
  f9:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  fc:	89 50 04             	mov    DWORD PTR [eax+0x4],edx
  ff:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 102:	8b 50 04             	mov    edx,DWORD PTR [eax+0x4]
 105:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 108:	89 10                	mov    DWORD PTR [eax],edx
    kthread_stack->eip = kernel_thread;
 10a:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 10d:	c7 40 10 15 00 00 00 	mov    DWORD PTR [eax+0x10],0x15
    kthread_stack->function = function;
 114:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 117:	8b 55 0c             	mov    edx,DWORD PTR [ebp+0xc]
 11a:	89 50 18             	mov    DWORD PTR [eax+0x18],edx
    kthread_stack->func_arg = func_arg;
 11d:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 120:	8b 55 10             	mov    edx,DWORD PTR [ebp+0x10]
 123:	89 50 1c             	mov    DWORD PTR [eax+0x1c],edx
}
 126:	90                   	nop
 127:	c9                   	leave  
 128:	c3                   	ret    

00000129 <thread_start>:

/* 创建线程 */
struct task_struct *thread_start(char *name, int prio, thread_func function, void *func_arg)
{
 129:	55                   	push   ebp
 12a:	89 e5                	mov    ebp,esp
 12c:	83 ec 18             	sub    esp,0x18
    //PCB都位于内核空间，包括用户进程的PCB也在内核空间
    struct task_struct *thread = (struct task_struct *)get_kernel_pages(1);
 12f:	83 ec 0c             	sub    esp,0xc
 132:	6a 01                	push   0x1
 134:	e8 fc ff ff ff       	call   135 <thread_start+0xc>
 139:	83 c4 10             	add    esp,0x10
 13c:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    init_thread(thread, name, prio);
 13f:	83 ec 04             	sub    esp,0x4
 142:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 145:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 148:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 14b:	e8 fc ff ff ff       	call   14c <thread_start+0x23>
 150:	83 c4 10             	add    esp,0x10
    thread_create(thread, function, func_arg);
 153:	83 ec 04             	sub    esp,0x4
 156:	ff 75 14             	push   DWORD PTR [ebp+0x14]
 159:	ff 75 10             	push   DWORD PTR [ebp+0x10]
 15c:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 15f:	e8 fc ff ff ff       	call   160 <thread_start+0x37>
 164:	83 c4 10             	add    esp,0x10

    ASSERT(elem_find(&thread_ready_list, &thread->general_tag) == FALSE);
 167:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 16a:	83 c0 30             	add    eax,0x30
 16d:	83 ec 08             	sub    esp,0x8
 170:	50                   	push   eax
 171:	68 00 00 00 00       	push   0x0
 176:	e8 fc ff ff ff       	call   177 <thread_start+0x4e>
 17b:	83 c4 10             	add    esp,0x10
 17e:	85 c0                	test   eax,eax
 180:	74 19                	je     19b <thread_start+0x72>
 182:	68 00 00 00 00       	push   0x0
 187:	68 78 02 00 00       	push   0x278
 18c:	6a 49                	push   0x49
 18e:	68 3d 00 00 00       	push   0x3d
 193:	e8 fc ff ff ff       	call   194 <thread_start+0x6b>
 198:	83 c4 10             	add    esp,0x10
    list_append(&thread_ready_list, &thread->general_tag);
 19b:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 19e:	83 c0 30             	add    eax,0x30
 1a1:	83 ec 08             	sub    esp,0x8
 1a4:	50                   	push   eax
 1a5:	68 00 00 00 00       	push   0x0
 1aa:	e8 fc ff ff ff       	call   1ab <thread_start+0x82>
 1af:	83 c4 10             	add    esp,0x10
    ASSERT(elem_find(&thread_all_list, &thread->all_list_tag) == FALSE);
 1b2:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1b5:	83 c0 38             	add    eax,0x38
 1b8:	83 ec 08             	sub    esp,0x8
 1bb:	50                   	push   eax
 1bc:	68 00 00 00 00       	push   0x0
 1c1:	e8 fc ff ff ff       	call   1c2 <thread_start+0x99>
 1c6:	83 c4 10             	add    esp,0x10
 1c9:	85 c0                	test   eax,eax
 1cb:	74 19                	je     1e6 <thread_start+0xbd>
 1cd:	68 54 00 00 00       	push   0x54
 1d2:	68 78 02 00 00       	push   0x278
 1d7:	6a 4b                	push   0x4b
 1d9:	68 3d 00 00 00       	push   0x3d
 1de:	e8 fc ff ff ff       	call   1df <thread_start+0xb6>
 1e3:	83 c4 10             	add    esp,0x10
    list_append(&thread_all_list, &thread->all_list_tag);
 1e6:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1e9:	83 c0 38             	add    eax,0x38
 1ec:	83 ec 08             	sub    esp,0x8
 1ef:	50                   	push   eax
 1f0:	68 00 00 00 00       	push   0x0
 1f5:	e8 fc ff ff ff       	call   1f6 <thread_start+0xcd>
 1fa:	83 c4 10             	add    esp,0x10

    return thread;
 1fd:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 200:	c9                   	leave  
 201:	c3                   	ret    

00000202 <make_main_thread>:

/*************************************************************************************************************************/
/* 将kernel中的main函数完善为主线程 */
static void make_main_thread(void)
{
 202:	55                   	push   ebp
 203:	89 e5                	mov    ebp,esp
 205:	83 ec 08             	sub    esp,0x8
    //因为main函数早已运行，esp=0xc009f000,已经预留一个PCB位置
    //不需要get_kernel_page另分配一页。
    main_thread = running_thread();
 208:	e8 fc ff ff ff       	call   209 <make_main_thread+0x7>
 20d:	a3 00 00 00 00       	mov    ds:0x0,eax
    init_thread(main_thread, "main", 31);
 212:	a1 00 00 00 00       	mov    eax,ds:0x0
 217:	83 ec 04             	sub    esp,0x4
 21a:	6a 1f                	push   0x1f
 21c:	68 90 00 00 00       	push   0x90
 221:	50                   	push   eax
 222:	e8 fc ff ff ff       	call   223 <make_main_thread+0x21>
 227:	83 c4 10             	add    esp,0x10
    //main函数是当前进程，当前进程不再thread_ready_list中，所以只加入thread_all_list中。
    ASSERT(elem_find(&thread_all_list, &main_thread->all_list_tag) == FALSE);
 22a:	a1 00 00 00 00       	mov    eax,ds:0x0
 22f:	83 c0 38             	add    eax,0x38
 232:	83 ec 08             	sub    esp,0x8
 235:	50                   	push   eax
 236:	68 00 00 00 00       	push   0x0
 23b:	e8 fc ff ff ff       	call   23c <make_main_thread+0x3a>
 240:	83 c4 10             	add    esp,0x10
 243:	85 c0                	test   eax,eax
 245:	74 19                	je     260 <make_main_thread+0x5e>
 247:	68 98 00 00 00       	push   0x98
 24c:	68 88 02 00 00       	push   0x288
 251:	6a 5a                	push   0x5a
 253:	68 3d 00 00 00       	push   0x3d
 258:	e8 fc ff ff ff       	call   259 <make_main_thread+0x57>
 25d:	83 c4 10             	add    esp,0x10
    list_append(&thread_all_list, &main_thread->all_list_tag);   
 260:	a1 00 00 00 00       	mov    eax,ds:0x0
 265:	83 c0 38             	add    eax,0x38
 268:	83 ec 08             	sub    esp,0x8
 26b:	50                   	push   eax
 26c:	68 00 00 00 00       	push   0x0
 271:	e8 fc ff ff ff       	call   272 <make_main_thread+0x70>
 276:	83 c4 10             	add    esp,0x10
}
 279:	90                   	nop
 27a:	c9                   	leave  
 27b:	c3                   	ret    

0000027c <main_thread_init>:

/* 初始化主线程main的线程环境 */
void main_thread_init(void)
{
 27c:	55                   	push   ebp
 27d:	89 e5                	mov    ebp,esp
 27f:	83 ec 08             	sub    esp,0x8
    put_str("thread_init start\n");
 282:	83 ec 0c             	sub    esp,0xc
 285:	68 d9 00 00 00       	push   0xd9
 28a:	e8 fc ff ff ff       	call   28b <main_thread_init+0xf>
 28f:	83 c4 10             	add    esp,0x10
    list_init(&thread_ready_list);
 292:	83 ec 0c             	sub    esp,0xc
 295:	68 00 00 00 00       	push   0x0
 29a:	e8 fc ff ff ff       	call   29b <main_thread_init+0x1f>
 29f:	83 c4 10             	add    esp,0x10
    list_init(&thread_all_list);
 2a2:	83 ec 0c             	sub    esp,0xc
 2a5:	68 00 00 00 00       	push   0x0
 2aa:	e8 fc ff ff ff       	call   2ab <main_thread_init+0x2f>
 2af:	83 c4 10             	add    esp,0x10
    //初始化main的PCB，并挂载到总队列中
    make_main_thread();
 2b2:	e8 4b ff ff ff       	call   202 <make_main_thread>
    put_str("thread_init done\n");
 2b7:	83 ec 0c             	sub    esp,0xc
 2ba:	68 ec 00 00 00       	push   0xec
 2bf:	e8 fc ff ff ff       	call   2c0 <main_thread_init+0x44>
 2c4:	83 c4 10             	add    esp,0x10
}
 2c7:	90                   	nop
 2c8:	c9                   	leave  
 2c9:	c3                   	ret    

000002ca <schedule>:
/*现有的引用：
    时钟中断
    线程阻塞
*/
void schedule(void)
{
 2ca:	55                   	push   ebp
 2cb:	89 e5                	mov    ebp,esp
 2cd:	83 ec 18             	sub    esp,0x18
    //schedule()过程中，中断必须是关闭状态
    ASSERT(intr_get_status() == INTR_OFF);
 2d0:	e8 fc ff ff ff       	call   2d1 <schedule+0x7>
 2d5:	85 c0                	test   eax,eax
 2d7:	74 19                	je     2f2 <schedule+0x28>
 2d9:	68 fe 00 00 00       	push   0xfe
 2de:	68 9c 02 00 00       	push   0x29c
 2e3:	6a 71                	push   0x71
 2e5:	68 3d 00 00 00       	push   0x3d
 2ea:	e8 fc ff ff ff       	call   2eb <schedule+0x21>
 2ef:	83 c4 10             	add    esp,0x10

    struct task_struct *cur_thread = running_thread();
 2f2:	e8 fc ff ff ff       	call   2f3 <schedule+0x29>
 2f7:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    if(cur_thread->status == TASK_RUNNING) {    //说明是时间片到的情况
 2fa:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 2fd:	8b 40 04             	mov    eax,DWORD PTR [eax+0x4]
 300:	85 c0                	test   eax,eax
 302:	75 62                	jne    366 <schedule+0x9c>
        //重新加入READY队列末尾
        ASSERT(elem_find(&thread_ready_list, &cur_thread->general_tag) == FALSE);
 304:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 307:	83 c0 30             	add    eax,0x30
 30a:	83 ec 08             	sub    esp,0x8
 30d:	50                   	push   eax
 30e:	68 00 00 00 00       	push   0x0
 313:	e8 fc ff ff ff       	call   314 <schedule+0x4a>
 318:	83 c4 10             	add    esp,0x10
 31b:	85 c0                	test   eax,eax
 31d:	74 19                	je     338 <schedule+0x6e>
 31f:	68 1c 01 00 00       	push   0x11c
 324:	68 9c 02 00 00       	push   0x29c
 329:	6a 76                	push   0x76
 32b:	68 3d 00 00 00       	push   0x3d
 330:	e8 fc ff ff ff       	call   331 <schedule+0x67>
 335:	83 c4 10             	add    esp,0x10
        list_append(&thread_ready_list, &cur_thread->general_tag);
 338:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 33b:	83 c0 30             	add    eax,0x30
 33e:	83 ec 08             	sub    esp,0x8
 341:	50                   	push   eax
 342:	68 00 00 00 00       	push   0x0
 347:	e8 fc ff ff ff       	call   348 <schedule+0x7e>
 34c:	83 c4 10             	add    esp,0x10
        //更新滴答值，设置状态为TASK_READY
        cur_thread->ticks = cur_thread->priority;
 34f:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 352:	0f b6 50 18          	movzx  edx,BYTE PTR [eax+0x18]
 356:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 359:	88 50 19             	mov    BYTE PTR [eax+0x19],dl
        cur_thread->status = TASK_READY;
 35c:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 35f:	c7 40 04 01 00 00 00 	mov    DWORD PTR [eax+0x4],0x1
    } else {
        //其他情况调用schedule，进入时status已经不是TASK_RUNNING了。
    }

    //取出下一个任务
    ASSERT(list_empty(&thread_ready_list) == FALSE);
 366:	83 ec 0c             	sub    esp,0xc
 369:	68 00 00 00 00       	push   0x0
 36e:	e8 fc ff ff ff       	call   36f <schedule+0xa5>
 373:	83 c4 10             	add    esp,0x10
 376:	85 c0                	test   eax,eax
 378:	74 1c                	je     396 <schedule+0xcc>
 37a:	68 60 01 00 00       	push   0x160
 37f:	68 9c 02 00 00       	push   0x29c
 384:	68 80 00 00 00       	push   0x80
 389:	68 3d 00 00 00       	push   0x3d
 38e:	e8 fc ff ff ff       	call   38f <schedule+0xc5>
 393:	83 c4 10             	add    esp,0x10
    struct list_elem *thread_tag = list_pop(&thread_ready_list);
 396:	83 ec 0c             	sub    esp,0xc
 399:	68 00 00 00 00       	push   0x0
 39e:	e8 fc ff ff ff       	call   39f <schedule+0xd5>
 3a3:	83 c4 10             	add    esp,0x10
 3a6:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    struct task_struct *next_thread = elem2entry(struct task_struct, general_tag, thread_tag);
 3a9:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 3ac:	83 e8 30             	sub    eax,0x30
 3af:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    //更新下一个任务的status
    next_thread->status = TASK_RUNNING;
 3b2:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 3b5:	c7 40 04 00 00 00 00 	mov    DWORD PTR [eax+0x4],0x0
    //process_activate(next_thread);
    switch_to(cur_thread, next_thread);
 3bc:	83 ec 08             	sub    esp,0x8
 3bf:	ff 75 ec             	push   DWORD PTR [ebp-0x14]
 3c2:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 3c5:	e8 fc ff ff ff       	call   3c6 <schedule+0xfc>
 3ca:	83 c4 10             	add    esp,0x10

}
 3cd:	90                   	nop
 3ce:	c9                   	leave  
 3cf:	c3                   	ret    

000003d0 <thread_block>:

//线程阻塞函数
void thread_block(enum task_status stat)
{
 3d0:	55                   	push   ebp
 3d1:	89 e5                	mov    ebp,esp
 3d3:	83 ec 18             	sub    esp,0x18
    //对参数的限制
    ASSERT(stat == TASK_BLOCKED || stat == TASK_WAITING || stat == TASK_HANGING);
 3d6:	83 7d 08 02          	cmp    DWORD PTR [ebp+0x8],0x2
 3da:	74 28                	je     404 <thread_block+0x34>
 3dc:	83 7d 08 03          	cmp    DWORD PTR [ebp+0x8],0x3
 3e0:	74 22                	je     404 <thread_block+0x34>
 3e2:	83 7d 08 04          	cmp    DWORD PTR [ebp+0x8],0x4
 3e6:	74 1c                	je     404 <thread_block+0x34>
 3e8:	68 88 01 00 00       	push   0x188
 3ed:	68 a8 02 00 00       	push   0x2a8
 3f2:	68 8e 00 00 00       	push   0x8e
 3f7:	68 3d 00 00 00       	push   0x3d
 3fc:	e8 fc ff ff ff       	call   3fd <thread_block+0x2d>
 401:	83 c4 10             	add    esp,0x10
    //关闭中断
    enum task_status old_status =                                                                                                       intr_disable();
 404:	e8 fc ff ff ff       	call   405 <thread_block+0x35>
 409:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    //
    struct task_struct *cur_thread = running_thread();
 40c:	e8 fc ff ff ff       	call   40d <thread_block+0x3d>
 411:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    cur_thread->status = stat;
 414:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 417:	8b 55 08             	mov    edx,DWORD PTR [ebp+0x8]
 41a:	89 50 04             	mov    DWORD PTR [eax+0x4],edx
    schedule();
 41d:	e8 fc ff ff ff       	call   41e <thread_block+0x4e>

    //还原调用环境的中断设置
    intr_set_status(old_status);
 422:	83 ec 0c             	sub    esp,0xc
 425:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 428:	e8 fc ff ff ff       	call   429 <thread_block+0x59>
 42d:	83 c4 10             	add    esp,0x10
}
 430:	90                   	nop
 431:	c9                   	leave  
 432:	c3                   	ret    

00000433 <thread_unblock>:

//线程唤醒函数
void thread_unblock(struct task_struct *pthread)
{
 433:	55                   	push   ebp
 434:	89 e5                	mov    ebp,esp
 436:	83 ec 18             	sub    esp,0x18
    ASSERT(pthread->status == TASK_BLOCKED || pthread->status == TASK_WAITING || pthread->status == TASK_HANGING);
 439:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 43c:	8b 40 04             	mov    eax,DWORD PTR [eax+0x4]
 43f:	83 f8 02             	cmp    eax,0x2
 442:	74 32                	je     476 <thread_unblock+0x43>
 444:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 447:	8b 40 04             	mov    eax,DWORD PTR [eax+0x4]
 44a:	83 f8 03             	cmp    eax,0x3
 44d:	74 27                	je     476 <thread_unblock+0x43>
 44f:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 452:	8b 40 04             	mov    eax,DWORD PTR [eax+0x4]
 455:	83 f8 04             	cmp    eax,0x4
 458:	74 1c                	je     476 <thread_unblock+0x43>
 45a:	68 d0 01 00 00       	push   0x1d0
 45f:	68 b8 02 00 00       	push   0x2b8
 464:	68 9d 00 00 00       	push   0x9d
 469:	68 3d 00 00 00       	push   0x3d
 46e:	e8 fc ff ff ff       	call   46f <thread_unblock+0x3c>
 473:	83 c4 10             	add    esp,0x10
    //关闭中断
    enum task_status old_status = intr_disable();  
 476:	e8 fc ff ff ff       	call   477 <thread_unblock+0x44>
 47b:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    ASSERT(elem_find(&thread_ready_list, &pthread->general_tag) == FALSE);
 47e:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 481:	83 c0 30             	add    eax,0x30
 484:	83 ec 08             	sub    esp,0x8
 487:	50                   	push   eax
 488:	68 00 00 00 00       	push   0x0
 48d:	e8 fc ff ff ff       	call   48e <thread_unblock+0x5b>
 492:	83 c4 10             	add    esp,0x10
 495:	85 c0                	test   eax,eax
 497:	74 1c                	je     4b5 <thread_unblock+0x82>
 499:	68 38 02 00 00       	push   0x238
 49e:	68 b8 02 00 00       	push   0x2b8
 4a3:	68 a0 00 00 00       	push   0xa0
 4a8:	68 3d 00 00 00       	push   0x3d
 4ad:	e8 fc ff ff ff       	call   4ae <thread_unblock+0x7b>
 4b2:	83 c4 10             	add    esp,0x10
    list_push(&thread_ready_list, &pthread->general_tag);
 4b5:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 4b8:	83 c0 30             	add    eax,0x30
 4bb:	83 ec 08             	sub    esp,0x8
 4be:	50                   	push   eax
 4bf:	68 00 00 00 00       	push   0x0
 4c4:	e8 fc ff ff ff       	call   4c5 <thread_unblock+0x92>
 4c9:	83 c4 10             	add    esp,0x10
    pthread->status = TASK_READY;
 4cc:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 4cf:	c7 40 04 01 00 00 00 	mov    DWORD PTR [eax+0x4],0x1
    //还原调用环境的中断设置
    intr_set_status(old_status);  
 4d6:	83 ec 0c             	sub    esp,0xc
 4d9:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 4dc:	e8 fc ff ff ff       	call   4dd <thread_unblock+0xaa>
 4e1:	83 c4 10             	add    esp,0x10
 4e4:	90                   	nop
 4e5:	c9                   	leave  
 4e6:	c3                   	ret    
