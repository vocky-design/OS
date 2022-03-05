
./build/memory.o:     file format elf32-i386


Disassembly of section .text:

00000000 <mem_pool_init>:
};
struct paddr_pool kernel_pool, user_pool;
struct vaddr_pool kernel_vaddr_pool;

static void mem_pool_init(uint32_t all_mem)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 38             	sub    esp,0x38
    put_str("   mem_pool_init start\n");         
   6:	83 ec 0c             	sub    esp,0xc
   9:	68 00 00 00 00       	push   0x0
   e:	e8 fc ff ff ff       	call   f <mem_pool_init+0xf>
  13:	83 c4 10             	add    esp,0x10
    //页目录表和页表占用的物理地址，其实地址0x100000,包括1个目录表，0和768页目录项指向同一页表，769-1022目录项指向254个页表。
    uint32_t used_mem = 256 * PG_SIZE + 0x100000;     //加上低端1MB内存。
  16:	c7 45 f4 00 00 20 00 	mov    DWORD PTR [ebp-0xc],0x200000
    uint32_t free_mem = all_mem - used_mem;
  1d:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  20:	2b 45 f4             	sub    eax,DWORD PTR [ebp-0xc]
  23:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    uint32_t free_pages = free_mem / PG_SIZE;           //理论上，完全可以整除
  26:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  29:	c1 e8 0c             	shr    eax,0xc
  2c:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    uint32_t kernel_free_pages = free_pages / 2;
  2f:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  32:	d1 e8                	shr    eax,1
  34:	89 45 e8             	mov    DWORD PTR [ebp-0x18],eax
    uint32_t user_free_pages = free_pages - kernel_free_pages;
  37:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
  3a:	2b 45 e8             	sub    eax,DWORD PTR [ebp-0x18]
  3d:	89 45 e4             	mov    DWORD PTR [ebp-0x1c],eax
    //为简化位图操作，余数不处理，坏处是这样做会丢内存；好处是不用做内存的越界检查，因为位图表示的内存少于实际物理内存。
    uint32_t kbm_length = kernel_free_pages / 8;
  40:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
  43:	c1 e8 03             	shr    eax,0x3
  46:	89 45 e0             	mov    DWORD PTR [ebp-0x20],eax
    uint32_t ubm_length = user_free_pages / 8;
  49:	8b 45 e4             	mov    eax,DWORD PTR [ebp-0x1c]
  4c:	c1 e8 03             	shr    eax,0x3
  4f:	89 45 dc             	mov    DWORD PTR [ebp-0x24],eax
    //从0开始，物理起始地址
    uint32_t kp_start = used_mem;
  52:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  55:	89 45 d8             	mov    DWORD PTR [ebp-0x28],eax
    uint32_t up_start = used_mem + kernel_free_pages * PG_SIZE;
  58:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
  5b:	c1 e0 0c             	shl    eax,0xc
  5e:	89 c2                	mov    edx,eax
  60:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  63:	01 d0                	add    eax,edx
  65:	89 45 d4             	mov    DWORD PTR [ebp-0x2c],eax
    //以页为基本单位  4KB
    kernel_pool.pool_size = kernel_free_pages * PG_SIZE;
  68:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
  6b:	c1 e0 0c             	shl    eax,0xc
  6e:	a3 28 00 00 00       	mov    ds:0x28,eax
    user_pool.pool_size = user_free_pages * PG_SIZE;
  73:	8b 45 e4             	mov    eax,DWORD PTR [ebp-0x1c]
  76:	c1 e0 0c             	shl    eax,0xc
  79:	a3 28 00 00 00       	mov    ds:0x28,eax

    kernel_pool.paddr_start = kp_start;
  7e:	8b 45 d8             	mov    eax,DWORD PTR [ebp-0x28]
  81:	a3 24 00 00 00       	mov    ds:0x24,eax
    user_pool.paddr_start = up_start;
  86:	8b 45 d4             	mov    eax,DWORD PTR [ebp-0x2c]
  89:	a3 24 00 00 00       	mov    ds:0x24,eax

    kernel_pool.pool_bitmap.bytes = (uint8_t*)MEM_BITMAP_BASE;
  8e:	c7 05 20 00 00 00 00 	mov    DWORD PTR ds:0x20,0xc009a000
  95:	a0 09 c0 
    kernel_pool.pool_bitmap.btmp_bytes_len = kbm_length;
  98:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
  9b:	a3 1c 00 00 00       	mov    ds:0x1c,eax

    user_pool.pool_bitmap.bytes = (uint8_t*)(MEM_BITMAP_BASE + kbm_length);
  a0:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
  a3:	2d 00 60 f6 3f       	sub    eax,0x3ff66000
  a8:	a3 20 00 00 00       	mov    ds:0x20,eax
    user_pool.pool_bitmap.btmp_bytes_len = ubm_length;
  ad:	8b 45 dc             	mov    eax,DWORD PTR [ebp-0x24]
  b0:	a3 1c 00 00 00       	mov    ds:0x1c,eax
    
    bitmap_init(&kernel_pool.pool_bitmap);
  b5:	83 ec 0c             	sub    esp,0xc
  b8:	68 1c 00 00 00       	push   0x1c
  bd:	e8 fc ff ff ff       	call   be <mem_pool_init+0xbe>
  c2:	83 c4 10             	add    esp,0x10
    bitmap_init(&user_pool.pool_bitmap);
  c5:	83 ec 0c             	sub    esp,0xc
  c8:	68 1c 00 00 00       	push   0x1c
  cd:	e8 fc ff ff ff       	call   ce <mem_pool_init+0xce>
  d2:	83 c4 10             	add    esp,0x10
    lock_init(&kernel_pool.lock);
  d5:	83 ec 0c             	sub    esp,0xc
  d8:	68 00 00 00 00       	push   0x0
  dd:	e8 fc ff ff ff       	call   de <mem_pool_init+0xde>
  e2:	83 c4 10             	add    esp,0x10
    lock_init(&user_pool.lock);
  e5:	83 ec 0c             	sub    esp,0xc
  e8:	68 00 00 00 00       	push   0x0
  ed:	e8 fc ff ff ff       	call   ee <mem_pool_init+0xee>
  f2:	83 c4 10             	add    esp,0x10
    //输出内存池信息
    put_str("   kernel_pool_bitmap_start:");
  f5:	83 ec 0c             	sub    esp,0xc
  f8:	68 18 00 00 00       	push   0x18
  fd:	e8 fc ff ff ff       	call   fe <mem_pool_init+0xfe>
 102:	83 c4 10             	add    esp,0x10
    put_int((uint32_t)kernel_pool.pool_bitmap.bytes);
 105:	a1 20 00 00 00       	mov    eax,ds:0x20
 10a:	83 ec 0c             	sub    esp,0xc
 10d:	50                   	push   eax
 10e:	e8 fc ff ff ff       	call   10f <mem_pool_init+0x10f>
 113:	83 c4 10             	add    esp,0x10
    put_str("   kernel_pool_paddr_start:");
 116:	83 ec 0c             	sub    esp,0xc
 119:	68 35 00 00 00       	push   0x35
 11e:	e8 fc ff ff ff       	call   11f <mem_pool_init+0x11f>
 123:	83 c4 10             	add    esp,0x10
    put_int((uint32_t)kernel_pool.paddr_start);
 126:	a1 24 00 00 00       	mov    eax,ds:0x24
 12b:	83 ec 0c             	sub    esp,0xc
 12e:	50                   	push   eax
 12f:	e8 fc ff ff ff       	call   130 <mem_pool_init+0x130>
 134:	83 c4 10             	add    esp,0x10
    put_char('\n');
 137:	83 ec 0c             	sub    esp,0xc
 13a:	6a 0a                	push   0xa
 13c:	e8 fc ff ff ff       	call   13d <mem_pool_init+0x13d>
 141:	83 c4 10             	add    esp,0x10
    put_str("   user_pool_bitmap_start:");
 144:	83 ec 0c             	sub    esp,0xc
 147:	68 51 00 00 00       	push   0x51
 14c:	e8 fc ff ff ff       	call   14d <mem_pool_init+0x14d>
 151:	83 c4 10             	add    esp,0x10
    put_int((uint32_t)user_pool.pool_bitmap.bytes);
 154:	a1 20 00 00 00       	mov    eax,ds:0x20
 159:	83 ec 0c             	sub    esp,0xc
 15c:	50                   	push   eax
 15d:	e8 fc ff ff ff       	call   15e <mem_pool_init+0x15e>
 162:	83 c4 10             	add    esp,0x10
    put_str("   user_pool_paddr_start:");
 165:	83 ec 0c             	sub    esp,0xc
 168:	68 6c 00 00 00       	push   0x6c
 16d:	e8 fc ff ff ff       	call   16e <mem_pool_init+0x16e>
 172:	83 c4 10             	add    esp,0x10
    put_int((uint32_t)user_pool.paddr_start);
 175:	a1 24 00 00 00       	mov    eax,ds:0x24
 17a:	83 ec 0c             	sub    esp,0xc
 17d:	50                   	push   eax
 17e:	e8 fc ff ff ff       	call   17f <mem_pool_init+0x17f>
 183:	83 c4 10             	add    esp,0x10
    put_char('\n');   
 186:	83 ec 0c             	sub    esp,0xc
 189:	6a 0a                	push   0xa
 18b:	e8 fc ff ff ff       	call   18c <mem_pool_init+0x18c>
 190:	83 c4 10             	add    esp,0x10

    kernel_vaddr_pool.vaddr_start = K_HEAP_START;
 193:	c7 05 08 00 00 00 00 	mov    DWORD PTR ds:0x8,0xc0100000
 19a:	00 10 c0 
    kernel_vaddr_pool.pool_bitmap.bytes = (uint8_t *)(MEM_BITMAP_BASE + kbm_length + ubm_length);
 19d:	8b 55 e0             	mov    edx,DWORD PTR [ebp-0x20]
 1a0:	8b 45 dc             	mov    eax,DWORD PTR [ebp-0x24]
 1a3:	01 d0                	add    eax,edx
 1a5:	2d 00 60 f6 3f       	sub    eax,0x3ff66000
 1aa:	a3 04 00 00 00       	mov    ds:0x4,eax
    kernel_vaddr_pool.pool_bitmap.btmp_bytes_len = kbm_length;
 1af:	8b 45 e0             	mov    eax,DWORD PTR [ebp-0x20]
 1b2:	a3 00 00 00 00       	mov    ds:0x0,eax
    bitmap_init(&kernel_vaddr_pool.pool_bitmap);
 1b7:	83 ec 0c             	sub    esp,0xc
 1ba:	68 00 00 00 00       	push   0x0
 1bf:	e8 fc ff ff ff       	call   1c0 <mem_pool_init+0x1c0>
 1c4:	83 c4 10             	add    esp,0x10

    put_str("   mem_pool_init done\n");
 1c7:	83 ec 0c             	sub    esp,0xc
 1ca:	68 86 00 00 00       	push   0x86
 1cf:	e8 fc ff ff ff       	call   1d0 <mem_pool_init+0x1d0>
 1d4:	83 c4 10             	add    esp,0x10
}
 1d7:	90                   	nop
 1d8:	c9                   	leave  
 1d9:	c3                   	ret    

000001da <mem_init>:

void mem_init(void) 
{
 1da:	55                   	push   ebp
 1db:	89 e5                	mov    ebp,esp
 1dd:	83 ec 18             	sub    esp,0x18
    put_str("mem_init start\n");
 1e0:	83 ec 0c             	sub    esp,0xc
 1e3:	68 9d 00 00 00       	push   0x9d
 1e8:	e8 fc ff ff ff       	call   1e9 <mem_init+0xf>
 1ed:	83 c4 10             	add    esp,0x10
    uint32_t mem_bytes_total = (*(uint32_t *)0xb00);
 1f0:	b8 00 0b 00 00       	mov    eax,0xb00
 1f5:	8b 00                	mov    eax,DWORD PTR [eax]
 1f7:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    mem_pool_init(mem_bytes_total);
 1fa:	83 ec 0c             	sub    esp,0xc
 1fd:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 200:	e8 fb fd ff ff       	call   0 <mem_pool_init>
 205:	83 c4 10             	add    esp,0x10
    put_str("mem_init done\n");
 208:	83 ec 0c             	sub    esp,0xc
 20b:	68 ad 00 00 00       	push   0xad
 210:	e8 fc ff ff ff       	call   211 <mem_init+0x37>
 215:	83 c4 10             	add    esp,0x10
}
 218:	90                   	nop
 219:	c9                   	leave  
 21a:	c3                   	ret    

0000021b <vaddr_get>:
        //用户虚拟空间，后面写。
    }
    return (void *)vaddr_start;
}*/
static void *vaddr_get(enum pool_flag pf, uint32_t pg_cnt)
{
 21b:	55                   	push   ebp
 21c:	89 e5                	mov    ebp,esp
 21e:	83 ec 18             	sub    esp,0x18
    int vaddr_start = 0, bit_idx_start = -1;
 221:	c7 45 f4 00 00 00 00 	mov    DWORD PTR [ebp-0xc],0x0
 228:	c7 45 ec ff ff ff ff 	mov    DWORD PTR [ebp-0x14],0xffffffff
    uint32_t cnt = 0;
 22f:	c7 45 f0 00 00 00 00 	mov    DWORD PTR [ebp-0x10],0x0
    if(pf == PF_KERNEL) {
 236:	83 7d 08 01          	cmp    DWORD PTR [ebp+0x8],0x1
 23a:	75 64                	jne    2a0 <vaddr_get+0x85>
        bit_idx_start = bitmap_scan(&kernel_vaddr_pool.pool_bitmap, pg_cnt);
 23c:	83 ec 08             	sub    esp,0x8
 23f:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 242:	68 00 00 00 00       	push   0x0
 247:	e8 fc ff ff ff       	call   248 <vaddr_get+0x2d>
 24c:	83 c4 10             	add    esp,0x10
 24f:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
        if(bit_idx_start == -1) {
 252:	83 7d ec ff          	cmp    DWORD PTR [ebp-0x14],0xffffffff
 256:	75 2b                	jne    283 <vaddr_get+0x68>
            return NULL;
 258:	b8 00 00 00 00       	mov    eax,0x0
 25d:	e9 cd 00 00 00       	jmp    32f <vaddr_get+0x114>
        }
        while(cnt < pg_cnt) {
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
 262:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 265:	8d 50 01             	lea    edx,[eax+0x1]
 268:	89 55 f0             	mov    DWORD PTR [ebp-0x10],edx
 26b:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
 26e:	01 d0                	add    eax,edx
 270:	83 ec 04             	sub    esp,0x4
 273:	6a 01                	push   0x1
 275:	50                   	push   eax
 276:	68 00 00 00 00       	push   0x0
 27b:	e8 fc ff ff ff       	call   27c <vaddr_get+0x61>
 280:	83 c4 10             	add    esp,0x10
    if(pf == PF_KERNEL) {
        bit_idx_start = bitmap_scan(&kernel_vaddr_pool.pool_bitmap, pg_cnt);
        if(bit_idx_start == -1) {
            return NULL;
        }
        while(cnt < pg_cnt) {
 283:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 286:	3b 45 0c             	cmp    eax,DWORD PTR [ebp+0xc]
 289:	72 d7                	jb     262 <vaddr_get+0x47>
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
        }
        vaddr_start = kernel_vaddr_pool.vaddr_start + bit_idx_start * PG_SIZE;
 28b:	a1 08 00 00 00       	mov    eax,ds:0x8
 290:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
 293:	c1 e2 0c             	shl    edx,0xc
 296:	01 d0                	add    eax,edx
 298:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
 29b:	e9 8c 00 00 00       	jmp    32c <vaddr_get+0x111>
    } else {
        struct task_struct *cur_thread = running_thread();
 2a0:	e8 fc ff ff ff       	call   2a1 <vaddr_get+0x86>
 2a5:	89 45 e8             	mov    DWORD PTR [ebp-0x18],eax
        bit_idx_start = bitmap_scan(&cur_thread->userprog_vaddr_pool.pool_bitmap, pg_cnt);
 2a8:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 2ab:	83 c0 24             	add    eax,0x24
 2ae:	83 ec 08             	sub    esp,0x8
 2b1:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 2b4:	50                   	push   eax
 2b5:	e8 fc ff ff ff       	call   2b6 <vaddr_get+0x9b>
 2ba:	83 c4 10             	add    esp,0x10
 2bd:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
        if(bit_idx_start == -1) {
 2c0:	83 7d ec ff          	cmp    DWORD PTR [ebp-0x14],0xffffffff
 2c4:	75 2a                	jne    2f0 <vaddr_get+0xd5>
            return NULL;
 2c6:	b8 00 00 00 00       	mov    eax,0x0
 2cb:	eb 62                	jmp    32f <vaddr_get+0x114>
        }
        while(cnt < pg_cnt) {
            bitmap_set(&cur_thread->userprog_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
 2cd:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 2d0:	8d 50 01             	lea    edx,[eax+0x1]
 2d3:	89 55 f0             	mov    DWORD PTR [ebp-0x10],edx
 2d6:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
 2d9:	01 c2                	add    edx,eax
 2db:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 2de:	83 c0 24             	add    eax,0x24
 2e1:	83 ec 04             	sub    esp,0x4
 2e4:	6a 01                	push   0x1
 2e6:	52                   	push   edx
 2e7:	50                   	push   eax
 2e8:	e8 fc ff ff ff       	call   2e9 <vaddr_get+0xce>
 2ed:	83 c4 10             	add    esp,0x10
        struct task_struct *cur_thread = running_thread();
        bit_idx_start = bitmap_scan(&cur_thread->userprog_vaddr_pool.pool_bitmap, pg_cnt);
        if(bit_idx_start == -1) {
            return NULL;
        }
        while(cnt < pg_cnt) {
 2f0:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 2f3:	3b 45 0c             	cmp    eax,DWORD PTR [ebp+0xc]
 2f6:	72 d5                	jb     2cd <vaddr_get+0xb2>
            bitmap_set(&cur_thread->userprog_vaddr_pool.pool_bitmap, bit_idx_start+cnt++, 1);
        }
        vaddr_start = cur_thread->userprog_vaddr_pool.vaddr_start + bit_idx_start * PG_SIZE;        
 2f8:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 2fb:	8b 40 2c             	mov    eax,DWORD PTR [eax+0x2c]
 2fe:	8b 55 ec             	mov    edx,DWORD PTR [ebp-0x14]
 301:	c1 e2 0c             	shl    edx,0xc
 304:	01 d0                	add    eax,edx
 306:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
        //(0xc0000000-PG_SZIE)作为用户3级栈已经在start_process被分配
        ASSERT((uint32_t)vaddr_start < (0xc0000000-PG_SIZE));
 309:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 30c:	3d ff ef ff bf       	cmp    eax,0xbfffefff
 311:	76 19                	jbe    32c <vaddr_get+0x111>
 313:	68 bc 00 00 00       	push   0xbc
 318:	68 18 02 00 00       	push   0x218
 31d:	6a 7e                	push   0x7e
 31f:	68 e9 00 00 00       	push   0xe9
 324:	e8 fc ff ff ff       	call   325 <vaddr_get+0x10a>
 329:	83 c4 10             	add    esp,0x10
    }
    return (void *)vaddr_start;
 32c:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 32f:	c9                   	leave  
 330:	c3                   	ret    

00000331 <paddr_get>:

/* 在m_pool指向的物理内存池中分配1个物理页,成功返回物理起始地址 */
static void *paddr_get(struct paddr_pool *m_pool)
{
 331:	55                   	push   ebp
 332:	89 e5                	mov    ebp,esp
 334:	83 ec 18             	sub    esp,0x18
    int32_t bit_idx = bitmap_scan(&m_pool->pool_bitmap, 1);
 337:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 33a:	83 c0 1c             	add    eax,0x1c
 33d:	83 ec 08             	sub    esp,0x8
 340:	6a 01                	push   0x1
 342:	50                   	push   eax
 343:	e8 fc ff ff ff       	call   344 <paddr_get+0x13>
 348:	83 c4 10             	add    esp,0x10
 34b:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    if(bit_idx == -1) {
 34e:	83 7d f4 ff          	cmp    DWORD PTR [ebp-0xc],0xffffffff
 352:	75 07                	jne    35b <paddr_get+0x2a>
        return NULL;
 354:	b8 00 00 00 00       	mov    eax,0x0
 359:	eb 2c                	jmp    387 <paddr_get+0x56>
    }
    bitmap_set(&m_pool->pool_bitmap, bit_idx, 1);
 35b:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 35e:	8b 55 08             	mov    edx,DWORD PTR [ebp+0x8]
 361:	83 c2 1c             	add    edx,0x1c
 364:	83 ec 04             	sub    esp,0x4
 367:	6a 01                	push   0x1
 369:	50                   	push   eax
 36a:	52                   	push   edx
 36b:	e8 fc ff ff ff       	call   36c <paddr_get+0x3b>
 370:	83 c4 10             	add    esp,0x10
    uint32_t paddr_start = m_pool->paddr_start + bit_idx * PG_SIZE;
 373:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 376:	8b 40 24             	mov    eax,DWORD PTR [eax+0x24]
 379:	8b 55 f4             	mov    edx,DWORD PTR [ebp-0xc]
 37c:	c1 e2 0c             	shl    edx,0xc
 37f:	01 d0                	add    eax,edx
 381:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    return (void *)paddr_start;
 384:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
}
 387:	c9                   	leave  
 388:	c3                   	ret    

00000389 <pde_ptr>:
{
    uint32_t *pte = (uint32_t *)(0xffc00000 + ((0xffc00000 & vaddr) >> 10) + ((0x003ff000 & vaddr) >> 10));
    return pte;
}*/
uint32_t *pde_ptr(uint32_t vaddr)
{
 389:	55                   	push   ebp
 38a:	89 e5                	mov    ebp,esp
 38c:	83 ec 10             	sub    esp,0x10
    uint32_t *pde = (uint32_t *)(0xfffff000 + PDE_IDX(vaddr)*4);
 38f:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 392:	c1 e8 16             	shr    eax,0x16
 395:	05 00 fc ff 3f       	add    eax,0x3ffffc00
 39a:	c1 e0 02             	shl    eax,0x2
 39d:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
    return pde;
 3a0:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
}
 3a3:	c9                   	leave  
 3a4:	c3                   	ret    

000003a5 <pte_ptr>:
uint32_t *pte_ptr(uint32_t vaddr)
{
 3a5:	55                   	push   ebp
 3a6:	89 e5                	mov    ebp,esp
 3a8:	83 ec 10             	sub    esp,0x10
    uint32_t *pte = (uint32_t *)(0xffc00000 + ((vaddr & 0xffc00000) >> 10) + PTE_IDX(vaddr) * 4);
 3ab:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 3ae:	25 00 00 c0 ff       	and    eax,0xffc00000
 3b3:	c1 e8 0a             	shr    eax,0xa
 3b6:	89 c2                	mov    edx,eax
 3b8:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 3bb:	25 00 f0 3f 00       	and    eax,0x3ff000
 3c0:	c1 e8 0c             	shr    eax,0xc
 3c3:	c1 e0 02             	shl    eax,0x2
 3c6:	01 d0                	add    eax,edx
 3c8:	2d 00 00 40 00       	sub    eax,0x400000
 3cd:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
    return pte;
 3d0:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
}
 3d3:	c9                   	leave  
 3d4:	c3                   	ret    

000003d5 <page_table_add>:

/* 页表中添加虚拟地址_vaddr与物理地址_paddr的映射 */
static void page_table_add(void *_vaddr, void *_paddr)
{
 3d5:	55                   	push   ebp
 3d6:	89 e5                	mov    ebp,esp
 3d8:	83 ec 28             	sub    esp,0x28
    uint32_t vaddr = (uint32_t)(uint32_t *)_vaddr;
 3db:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 3de:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    uint32_t paddr = (uint32_t)(uint32_t *)_paddr;
 3e1:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 3e4:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax

    uint32_t *pde = pde_ptr(vaddr);
 3e7:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 3ea:	e8 fc ff ff ff       	call   3eb <page_table_add+0x16>
 3ef:	83 c4 04             	add    esp,0x4
 3f2:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    uint32_t *pte = pte_ptr(vaddr); 
 3f5:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 3f8:	e8 fc ff ff ff       	call   3f9 <page_table_add+0x24>
 3fd:	83 c4 04             	add    esp,0x4
 400:	89 45 e8             	mov    DWORD PTR [ebp-0x18],eax

    if(*pde & 0x1) {
 403:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 406:	8b 00                	mov    eax,DWORD PTR [eax]
 408:	83 e0 01             	and    eax,0x1
 40b:	85 c0                	test   eax,eax
 40d:	74 64                	je     473 <page_table_add+0x9e>
        ASSERT(!(*pte & 0x1));  //pte不存在
 40f:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 412:	8b 00                	mov    eax,DWORD PTR [eax]
 414:	83 e0 01             	and    eax,0x1
 417:	85 c0                	test   eax,eax
 419:	74 1c                	je     437 <page_table_add+0x62>
 41b:	68 f9 00 00 00       	push   0xf9
 420:	68 24 02 00 00       	push   0x224
 425:	68 b0 00 00 00       	push   0xb0
 42a:	68 e9 00 00 00       	push   0xe9
 42f:	e8 fc ff ff ff       	call   430 <page_table_add+0x5b>
 434:	83 c4 10             	add    esp,0x10
        if(!(*pte & 0x1)) {     
 437:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 43a:	8b 00                	mov    eax,DWORD PTR [eax]
 43c:	83 e0 01             	and    eax,0x1
 43f:	85 c0                	test   eax,eax
 441:	75 12                	jne    455 <page_table_add+0x80>
            *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
 443:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 446:	83 c8 07             	or     eax,0x7
 449:	89 c2                	mov    edx,eax
 44b:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 44e:	89 10                	mov    DWORD PTR [eax],edx
        *pde = pte_paddr | PG_US_U | PG_RW_W | PG_P_1;
        memset((void *)((uint32_t)pte & 0xfffff000), 0, PG_SIZE);               //清空页表，要用虚拟地址访问刚申请的页表        
        ASSERT(!(*pte & 0x1));  
        *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
    }
}
 450:	e9 8e 00 00 00       	jmp    4e3 <page_table_add+0x10e>
    if(*pde & 0x1) {
        ASSERT(!(*pte & 0x1));  //pte不存在
        if(!(*pte & 0x1)) {     
            *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
        } else {
            PANIC("pte repeat");  
 455:	68 07 01 00 00       	push   0x107
 45a:	68 24 02 00 00       	push   0x224
 45f:	68 b4 00 00 00       	push   0xb4
 464:	68 e9 00 00 00       	push   0xe9
 469:	e8 fc ff ff ff       	call   46a <page_table_add+0x95>
 46e:	83 c4 10             	add    esp,0x10
        *pde = pte_paddr | PG_US_U | PG_RW_W | PG_P_1;
        memset((void *)((uint32_t)pte & 0xfffff000), 0, PG_SIZE);               //清空页表，要用虚拟地址访问刚申请的页表        
        ASSERT(!(*pte & 0x1));  
        *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
    }
}
 471:	eb 70                	jmp    4e3 <page_table_add+0x10e>
            *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
        } else {
            PANIC("pte repeat");  
        }
    } else {
        uint32_t pte_paddr = (uint32_t)(uint32_t *)paddr_get(&kernel_pool);       //为页表申请空间
 473:	83 ec 0c             	sub    esp,0xc
 476:	68 00 00 00 00       	push   0x0
 47b:	e8 b1 fe ff ff       	call   331 <paddr_get>
 480:	83 c4 10             	add    esp,0x10
 483:	89 45 e4             	mov    DWORD PTR [ebp-0x1c],eax
        *pde = pte_paddr | PG_US_U | PG_RW_W | PG_P_1;
 486:	8b 45 e4             	mov    eax,DWORD PTR [ebp-0x1c]
 489:	83 c8 07             	or     eax,0x7
 48c:	89 c2                	mov    edx,eax
 48e:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 491:	89 10                	mov    DWORD PTR [eax],edx
        memset((void *)((uint32_t)pte & 0xfffff000), 0, PG_SIZE);               //清空页表，要用虚拟地址访问刚申请的页表        
 493:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 496:	25 00 f0 ff ff       	and    eax,0xfffff000
 49b:	83 ec 04             	sub    esp,0x4
 49e:	68 00 10 00 00       	push   0x1000
 4a3:	6a 00                	push   0x0
 4a5:	50                   	push   eax
 4a6:	e8 fc ff ff ff       	call   4a7 <page_table_add+0xd2>
 4ab:	83 c4 10             	add    esp,0x10
        ASSERT(!(*pte & 0x1));  
 4ae:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 4b1:	8b 00                	mov    eax,DWORD PTR [eax]
 4b3:	83 e0 01             	and    eax,0x1
 4b6:	85 c0                	test   eax,eax
 4b8:	74 1c                	je     4d6 <page_table_add+0x101>
 4ba:	68 f9 00 00 00       	push   0xf9
 4bf:	68 24 02 00 00       	push   0x224
 4c4:	68 ba 00 00 00       	push   0xba
 4c9:	68 e9 00 00 00       	push   0xe9
 4ce:	e8 fc ff ff ff       	call   4cf <page_table_add+0xfa>
 4d3:	83 c4 10             	add    esp,0x10
        *pte = paddr | PG_US_U | PG_RW_W | PG_P_1;
 4d6:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 4d9:	83 c8 07             	or     eax,0x7
 4dc:	89 c2                	mov    edx,eax
 4de:	8b 45 e8             	mov    eax,DWORD PTR [ebp-0x18]
 4e1:	89 10                	mov    DWORD PTR [eax],edx
    }
}
 4e3:	90                   	nop
 4e4:	c9                   	leave  
 4e5:	c3                   	ret    

000004e6 <malloc_page>:

/* 分配cnt个页空间，成功则返回起始虚拟地址，失败返回NULL */
static void *malloc_page(enum pool_flag pf, uint32_t pg_cnt)
{
 4e6:	55                   	push   ebp
 4e7:	89 e5                	mov    ebp,esp
 4e9:	83 ec 28             	sub    esp,0x28
    ASSERT(pg_cnt >0 && pg_cnt < 3840);      //15MB*1024*1024/4096=3840页
 4ec:	83 7d 0c 00          	cmp    DWORD PTR [ebp+0xc],0x0
 4f0:	74 09                	je     4fb <malloc_page+0x15>
 4f2:	81 7d 0c ff 0e 00 00 	cmp    DWORD PTR [ebp+0xc],0xeff
 4f9:	76 1c                	jbe    517 <malloc_page+0x31>
 4fb:	68 12 01 00 00       	push   0x112
 500:	68 34 02 00 00       	push   0x234
 505:	68 c2 00 00 00       	push   0xc2
 50a:	68 e9 00 00 00       	push   0xe9
 50f:	e8 fc ff ff ff       	call   510 <malloc_page+0x2a>
 514:	83 c4 10             	add    esp,0x10
    //三步：
    //1.通过vaddr_get在虚拟内存池申请虚拟地址。
    //2.通过paddr_get在物理内存池申请物理页。
    //3.通过page_table_add进行地址映射。
    void *vaddr_start = vaddr_get(pf, pg_cnt);
 517:	83 ec 08             	sub    esp,0x8
 51a:	ff 75 0c             	push   DWORD PTR [ebp+0xc]
 51d:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 520:	e8 f6 fc ff ff       	call   21b <vaddr_get>
 525:	83 c4 10             	add    esp,0x10
 528:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
    if(vaddr_start == NULL) {
 52b:	83 7d ec 00          	cmp    DWORD PTR [ebp-0x14],0x0
 52f:	75 07                	jne    538 <malloc_page+0x52>
        return NULL;
 531:	b8 00 00 00 00       	mov    eax,0x0
 536:	eb 6e                	jmp    5a6 <malloc_page+0xc0>
    }

    uint32_t vaddr = (uint32_t)vaddr_start, cnt = pg_cnt;
 538:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 53b:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
 53e:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 541:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    struct paddr_pool *mem_pool = pf & PF_KERNEL ? &kernel_pool : &user_pool;
 544:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 547:	83 e0 01             	and    eax,0x1
 54a:	85 c0                	test   eax,eax
 54c:	74 07                	je     555 <malloc_page+0x6f>
 54e:	b8 00 00 00 00       	mov    eax,0x0
 553:	eb 05                	jmp    55a <malloc_page+0x74>
 555:	b8 00 00 00 00       	mov    eax,0x0
 55a:	89 45 e8             	mov    DWORD PTR [ebp-0x18],eax

    while(cnt--) {
 55d:	eb 37                	jmp    596 <malloc_page+0xb0>
        void *paddr_start = paddr_get(mem_pool);
 55f:	83 ec 0c             	sub    esp,0xc
 562:	ff 75 e8             	push   DWORD PTR [ebp-0x18]
 565:	e8 c7 fd ff ff       	call   331 <paddr_get>
 56a:	83 c4 10             	add    esp,0x10
 56d:	89 45 e4             	mov    DWORD PTR [ebp-0x1c],eax
        if(paddr_start == NULL) {
 570:	83 7d e4 00          	cmp    DWORD PTR [ebp-0x1c],0x0
 574:	75 07                	jne    57d <malloc_page+0x97>
            return NULL;
 576:	b8 00 00 00 00       	mov    eax,0x0
 57b:	eb 29                	jmp    5a6 <malloc_page+0xc0>
        }
        page_table_add((void *)vaddr, paddr_start);
 57d:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 580:	83 ec 08             	sub    esp,0x8
 583:	ff 75 e4             	push   DWORD PTR [ebp-0x1c]
 586:	50                   	push   eax
 587:	e8 49 fe ff ff       	call   3d5 <page_table_add>
 58c:	83 c4 10             	add    esp,0x10
        vaddr += PG_SIZE;
 58f:	81 45 f4 00 10 00 00 	add    DWORD PTR [ebp-0xc],0x1000
    }

    uint32_t vaddr = (uint32_t)vaddr_start, cnt = pg_cnt;
    struct paddr_pool *mem_pool = pf & PF_KERNEL ? &kernel_pool : &user_pool;

    while(cnt--) {
 596:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 599:	8d 50 ff             	lea    edx,[eax-0x1]
 59c:	89 55 f0             	mov    DWORD PTR [ebp-0x10],edx
 59f:	85 c0                	test   eax,eax
 5a1:	75 bc                	jne    55f <malloc_page+0x79>
        }
        page_table_add((void *)vaddr, paddr_start);
        vaddr += PG_SIZE;
    }  

    return vaddr_start;
 5a3:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
}
 5a6:	c9                   	leave  
 5a7:	c3                   	ret    

000005a8 <get_kernel_pages>:

/* 从内核物理内存池申请一页内存，并清空 */
/* 成功则返回虚拟地址，失败返回NULL */
void *get_kernel_pages(uint32_t pg_cnt)
{
 5a8:	55                   	push   ebp
 5a9:	89 e5                	mov    ebp,esp
 5ab:	83 ec 18             	sub    esp,0x18
    lock_acquire(&kernel_pool.lock);
 5ae:	83 ec 0c             	sub    esp,0xc
 5b1:	68 00 00 00 00       	push   0x0
 5b6:	e8 fc ff ff ff       	call   5b7 <get_kernel_pages+0xf>
 5bb:	83 c4 10             	add    esp,0x10
    void *vaddr = malloc_page(PF_KERNEL, pg_cnt);
 5be:	83 ec 08             	sub    esp,0x8
 5c1:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 5c4:	6a 01                	push   0x1
 5c6:	e8 1b ff ff ff       	call   4e6 <malloc_page>
 5cb:	83 c4 10             	add    esp,0x10
 5ce:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    //清空内容
    if(vaddr != NULL) {
 5d1:	83 7d f4 00          	cmp    DWORD PTR [ebp-0xc],0x0
 5d5:	74 17                	je     5ee <get_kernel_pages+0x46>
        memset(vaddr, 0 , pg_cnt*PG_SIZE);
 5d7:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 5da:	c1 e0 0c             	shl    eax,0xc
 5dd:	83 ec 04             	sub    esp,0x4
 5e0:	50                   	push   eax
 5e1:	6a 00                	push   0x0
 5e3:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 5e6:	e8 fc ff ff ff       	call   5e7 <get_kernel_pages+0x3f>
 5eb:	83 c4 10             	add    esp,0x10
    }
    
    lock_release(&kernel_pool.lock);
 5ee:	83 ec 0c             	sub    esp,0xc
 5f1:	68 00 00 00 00       	push   0x0
 5f6:	e8 fc ff ff ff       	call   5f7 <get_kernel_pages+0x4f>
 5fb:	83 c4 10             	add    esp,0x10
    return vaddr;
 5fe:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 601:	c9                   	leave  
 602:	c3                   	ret    

00000603 <get_user_pages>:
/* 从用户物理内存池申请一页内存，并清空 */
/* 成功则返回虚拟地址，失败返回NULL */
void *get_user_pages(uint32_t pg_cnt)
{
 603:	55                   	push   ebp
 604:	89 e5                	mov    ebp,esp
 606:	83 ec 18             	sub    esp,0x18
    lock_acquire(&user_pool.lock);
 609:	83 ec 0c             	sub    esp,0xc
 60c:	68 00 00 00 00       	push   0x0
 611:	e8 fc ff ff ff       	call   612 <get_user_pages+0xf>
 616:	83 c4 10             	add    esp,0x10
    void *vaddr = malloc_page(PF_USER, pg_cnt);
 619:	83 ec 08             	sub    esp,0x8
 61c:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 61f:	6a 02                	push   0x2
 621:	e8 c0 fe ff ff       	call   4e6 <malloc_page>
 626:	83 c4 10             	add    esp,0x10
 629:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    /*
    if(vaddr != NULL) {
        memset(vaddr, 0 , pg_cnt*PG_SIZE);
    }
    */
    lock_release(&user_pool.lock);
 62c:	83 ec 0c             	sub    esp,0xc
 62f:	68 00 00 00 00       	push   0x0
 634:	e8 fc ff ff ff       	call   635 <get_user_pages+0x32>
 639:	83 c4 10             	add    esp,0x10
    return vaddr;
 63c:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 63f:	c9                   	leave  
 640:	c3                   	ret    

00000641 <get_a_page>:
/* 将vaddr与pf池中的物理地址关联，只支持一页空间分配 */
void *get_a_page(enum pool_flag pf, uint32_t vaddr)
{
 641:	55                   	push   ebp
 642:	89 e5                	mov    ebp,esp
 644:	83 ec 18             	sub    esp,0x18
    ASSERT((vaddr & 0x00000fff) == 0);
 647:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 64a:	25 ff 0f 00 00       	and    eax,0xfff
 64f:	85 c0                	test   eax,eax
 651:	74 1c                	je     66f <get_a_page+0x2e>
 653:	68 2d 01 00 00       	push   0x12d
 658:	68 40 02 00 00       	push   0x240
 65d:	68 fa 00 00 00       	push   0xfa
 662:	68 e9 00 00 00       	push   0xe9
 667:	e8 fc ff ff ff       	call   668 <get_a_page+0x27>
 66c:	83 c4 10             	add    esp,0x10
    struct paddr_pool *mem_pool = pf & PF_KERNEL ? &kernel_pool: &user_pool;
 66f:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 672:	83 e0 01             	and    eax,0x1
 675:	85 c0                	test   eax,eax
 677:	74 07                	je     680 <get_a_page+0x3f>
 679:	b8 00 00 00 00       	mov    eax,0x0
 67e:	eb 05                	jmp    685 <get_a_page+0x44>
 680:	b8 00 00 00 00       	mov    eax,0x0
 685:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    lock_acquire(&mem_pool->lock);
 688:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 68b:	83 ec 0c             	sub    esp,0xc
 68e:	50                   	push   eax
 68f:	e8 fc ff ff ff       	call   690 <get_a_page+0x4f>
 694:	83 c4 10             	add    esp,0x10
    //先将虚拟地址的位图置1
    struct task_struct *cur = running_thread();
 697:	e8 fc ff ff ff       	call   698 <get_a_page+0x57>
 69c:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    int32_t bit_idx = -1;
 69f:	c7 45 ec ff ff ff ff 	mov    DWORD PTR [ebp-0x14],0xffffffff
    if(cur->pgdir != NULL && pf == PF_USER) {               //当前是用户进程
 6a6:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 6a9:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 6ac:	85 c0                	test   eax,eax
 6ae:	0f 84 97 00 00 00    	je     74b <get_a_page+0x10a>
 6b4:	83 7d 08 02          	cmp    DWORD PTR [ebp+0x8],0x2
 6b8:	0f 85 8d 00 00 00    	jne    74b <get_a_page+0x10a>
        bit_idx = (vaddr - cur->userprog_vaddr_pool.vaddr_start) / PG_SIZE;
 6be:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 6c1:	8b 40 2c             	mov    eax,DWORD PTR [eax+0x2c]
 6c4:	8b 55 0c             	mov    edx,DWORD PTR [ebp+0xc]
 6c7:	29 c2                	sub    edx,eax
 6c9:	89 d0                	mov    eax,edx
 6cb:	c1 e8 0c             	shr    eax,0xc
 6ce:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
        ASSERT(bit_idx > 0);
 6d1:	83 7d ec 00          	cmp    DWORD PTR [ebp-0x14],0x0
 6d5:	7f 1c                	jg     6f3 <get_a_page+0xb2>
 6d7:	68 47 01 00 00       	push   0x147
 6dc:	68 40 02 00 00       	push   0x240
 6e1:	68 02 01 00 00       	push   0x102
 6e6:	68 e9 00 00 00       	push   0xe9
 6eb:	e8 fc ff ff ff       	call   6ec <get_a_page+0xab>
 6f0:	83 c4 10             	add    esp,0x10
        if(!bitmap_bit_test(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx)) {           //此位没有占用
 6f3:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 6f6:	8b 55 f0             	mov    edx,DWORD PTR [ebp-0x10]
 6f9:	83 c2 24             	add    edx,0x24
 6fc:	83 ec 08             	sub    esp,0x8
 6ff:	50                   	push   eax
 700:	52                   	push   edx
 701:	e8 fc ff ff ff       	call   702 <get_a_page+0xc1>
 706:	83 c4 10             	add    esp,0x10
 709:	85 c0                	test   eax,eax
 70b:	75 1d                	jne    72a <get_a_page+0xe9>
            bitmap_set(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx, 1);
 70d:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 710:	8b 55 f0             	mov    edx,DWORD PTR [ebp-0x10]
 713:	83 c2 24             	add    edx,0x24
 716:	83 ec 04             	sub    esp,0x4
 719:	6a 01                	push   0x1
 71b:	50                   	push   eax
 71c:	52                   	push   edx
 71d:	e8 fc ff ff ff       	call   71e <get_a_page+0xdd>
 722:	83 c4 10             	add    esp,0x10
    struct task_struct *cur = running_thread();
    int32_t bit_idx = -1;
    if(cur->pgdir != NULL && pf == PF_USER) {               //当前是用户进程
        bit_idx = (vaddr - cur->userprog_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        if(!bitmap_bit_test(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx)) {           //此位没有占用
 725:	e9 d7 00 00 00       	jmp    801 <get_a_page+0x1c0>
            bitmap_set(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx, 1);
        } else {
            PANIC("get_a_page: This bit is occupied on the bitmap");
 72a:	68 54 01 00 00       	push   0x154
 72f:	68 40 02 00 00       	push   0x240
 734:	68 06 01 00 00       	push   0x106
 739:	68 e9 00 00 00       	push   0xe9
 73e:	e8 fc ff ff ff       	call   73f <get_a_page+0xfe>
 743:	83 c4 10             	add    esp,0x10
    struct task_struct *cur = running_thread();
    int32_t bit_idx = -1;
    if(cur->pgdir != NULL && pf == PF_USER) {               //当前是用户进程
        bit_idx = (vaddr - cur->userprog_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        if(!bitmap_bit_test(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx)) {           //此位没有占用
 746:	e9 b6 00 00 00       	jmp    801 <get_a_page+0x1c0>
            bitmap_set(&cur->userprog_vaddr_pool.pool_bitmap, bit_idx, 1);
        } else {
            PANIC("get_a_page: This bit is occupied on the bitmap");
        }
    } else if(cur->pgdir == NULL && pf == PF_KERNEL) {      //当前是内核线程
 74b:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 74e:	8b 40 20             	mov    eax,DWORD PTR [eax+0x20]
 751:	85 c0                	test   eax,eax
 753:	0f 85 8c 00 00 00    	jne    7e5 <get_a_page+0x1a4>
 759:	83 7d 08 01          	cmp    DWORD PTR [ebp+0x8],0x1
 75d:	0f 85 82 00 00 00    	jne    7e5 <get_a_page+0x1a4>
        bit_idx = (vaddr - kernel_vaddr_pool.vaddr_start) / PG_SIZE;
 763:	a1 08 00 00 00       	mov    eax,ds:0x8
 768:	8b 55 0c             	mov    edx,DWORD PTR [ebp+0xc]
 76b:	29 c2                	sub    edx,eax
 76d:	89 d0                	mov    eax,edx
 76f:	c1 e8 0c             	shr    eax,0xc
 772:	89 45 ec             	mov    DWORD PTR [ebp-0x14],eax
        ASSERT(bit_idx > 0);
 775:	83 7d ec 00          	cmp    DWORD PTR [ebp-0x14],0x0
 779:	7f 1c                	jg     797 <get_a_page+0x156>
 77b:	68 47 01 00 00       	push   0x147
 780:	68 40 02 00 00       	push   0x240
 785:	68 0a 01 00 00       	push   0x10a
 78a:	68 e9 00 00 00       	push   0xe9
 78f:	e8 fc ff ff ff       	call   790 <get_a_page+0x14f>
 794:	83 c4 10             	add    esp,0x10
        if(!bitmap_bit_test(&kernel_vaddr_pool.pool_bitmap, bit_idx)) {
 797:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 79a:	83 ec 08             	sub    esp,0x8
 79d:	50                   	push   eax
 79e:	68 00 00 00 00       	push   0x0
 7a3:	e8 fc ff ff ff       	call   7a4 <get_a_page+0x163>
 7a8:	83 c4 10             	add    esp,0x10
 7ab:	85 c0                	test   eax,eax
 7ad:	75 18                	jne    7c7 <get_a_page+0x186>
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx, 1);
 7af:	8b 45 ec             	mov    eax,DWORD PTR [ebp-0x14]
 7b2:	83 ec 04             	sub    esp,0x4
 7b5:	6a 01                	push   0x1
 7b7:	50                   	push   eax
 7b8:	68 00 00 00 00       	push   0x0
 7bd:	e8 fc ff ff ff       	call   7be <get_a_page+0x17d>
 7c2:	83 c4 10             	add    esp,0x10
            PANIC("get_a_page: This bit is occupied on the bitmap");
        }
    } else if(cur->pgdir == NULL && pf == PF_KERNEL) {      //当前是内核线程
        bit_idx = (vaddr - kernel_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        if(!bitmap_bit_test(&kernel_vaddr_pool.pool_bitmap, bit_idx)) {
 7c5:	eb 3a                	jmp    801 <get_a_page+0x1c0>
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx, 1);
        } else {
            PANIC("get a page: This bit is occupied on the bitmap");
 7c7:	68 84 01 00 00       	push   0x184
 7cc:	68 40 02 00 00       	push   0x240
 7d1:	68 0e 01 00 00       	push   0x10e
 7d6:	68 e9 00 00 00       	push   0xe9
 7db:	e8 fc ff ff ff       	call   7dc <get_a_page+0x19b>
 7e0:	83 c4 10             	add    esp,0x10
            PANIC("get_a_page: This bit is occupied on the bitmap");
        }
    } else if(cur->pgdir == NULL && pf == PF_KERNEL) {      //当前是内核线程
        bit_idx = (vaddr - kernel_vaddr_pool.vaddr_start) / PG_SIZE;
        ASSERT(bit_idx > 0);
        if(!bitmap_bit_test(&kernel_vaddr_pool.pool_bitmap, bit_idx)) {
 7e3:	eb 1c                	jmp    801 <get_a_page+0x1c0>
            bitmap_set(&kernel_vaddr_pool.pool_bitmap, bit_idx, 1);
        } else {
            PANIC("get a page: This bit is occupied on the bitmap");
        }
    } else {
        PANIC("get_a_page: not allow 'kernel alloc userspace' or 'user alloc kernelspace'");
 7e5:	68 b4 01 00 00       	push   0x1b4
 7ea:	68 40 02 00 00       	push   0x240
 7ef:	68 11 01 00 00       	push   0x111
 7f4:	68 e9 00 00 00       	push   0xe9
 7f9:	e8 fc ff ff ff       	call   7fa <get_a_page+0x1b9>
 7fe:	83 c4 10             	add    esp,0x10
    }
    //做好虚拟地址与物理地址的映射
    void *alloced_phyaddr = paddr_get(mem_pool);
 801:	83 ec 0c             	sub    esp,0xc
 804:	ff 75 f4             	push   DWORD PTR [ebp-0xc]
 807:	e8 25 fb ff ff       	call   331 <paddr_get>
 80c:	83 c4 10             	add    esp,0x10
 80f:	89 45 e8             	mov    DWORD PTR [ebp-0x18],eax
    ASSERT(alloced_phyaddr != NULL);
 812:	83 7d e8 00          	cmp    DWORD PTR [ebp-0x18],0x0
 816:	75 1c                	jne    834 <get_a_page+0x1f3>
 818:	68 ff 01 00 00       	push   0x1ff
 81d:	68 40 02 00 00       	push   0x240
 822:	68 15 01 00 00       	push   0x115
 827:	68 e9 00 00 00       	push   0xe9
 82c:	e8 fc ff ff ff       	call   82d <get_a_page+0x1ec>
 831:	83 c4 10             	add    esp,0x10
    if(alloced_phyaddr == NULL) {
 834:	83 7d e8 00          	cmp    DWORD PTR [ebp-0x18],0x0
 838:	75 07                	jne    841 <get_a_page+0x200>
        return NULL;
 83a:	b8 00 00 00 00       	mov    eax,0x0
 83f:	eb 24                	jmp    865 <get_a_page+0x224>
    }
    page_table_add((void *)vaddr, alloced_phyaddr);
 841:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 844:	83 ec 08             	sub    esp,0x8
 847:	ff 75 e8             	push   DWORD PTR [ebp-0x18]
 84a:	50                   	push   eax
 84b:	e8 85 fb ff ff       	call   3d5 <page_table_add>
 850:	83 c4 10             	add    esp,0x10
    //
    lock_release(&mem_pool->lock);
 853:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 856:	83 ec 0c             	sub    esp,0xc
 859:	50                   	push   eax
 85a:	e8 fc ff ff ff       	call   85b <get_a_page+0x21a>
 85f:	83 c4 10             	add    esp,0x10
    return (void *)vaddr;
 862:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
}
 865:	c9                   	leave  
 866:	c3                   	ret    

00000867 <addr_v2p>:

/* 计算虚拟地址映射到的物理地址 */
uint32_t addr_v2p(uint32_t vaddr)
{
 867:	55                   	push   ebp
 868:	89 e5                	mov    ebp,esp
 86a:	83 ec 10             	sub    esp,0x10
    uint32_t *pte = pte_ptr(vaddr);
 86d:	ff 75 08             	push   DWORD PTR [ebp+0x8]
 870:	e8 fc ff ff ff       	call   871 <addr_v2p+0xa>
 875:	83 c4 04             	add    esp,0x4
 878:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
    return (*pte & 0xfffff000) + (vaddr & 0x00000fff);
 87b:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
 87e:	8b 00                	mov    eax,DWORD PTR [eax]
 880:	25 00 f0 ff ff       	and    eax,0xfffff000
 885:	89 c2                	mov    edx,eax
 887:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 88a:	25 ff 0f 00 00       	and    eax,0xfff
 88f:	01 d0                	add    eax,edx
}
 891:	c9                   	leave  
 892:	c3                   	ret    
