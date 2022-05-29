#include "init.h"
#include "stdio.h"
#include "file.h"


/***********任务调度系统测试****************/
int main(void)
{
	put_str("i am kernel\n");
	init_all();
	intr_enable();	
	
}

// /***********内存管理系统测试****************/
// int main(void)
// {
// 	put_str("i am kernel\n");
// 	init_all();
// 	intr_enable();	

// 	void *addr1 = sys_malloc(1);
// 	void *addr2 = sys_malloc(15);
// 	void *addr3 = sys_malloc(16);
// 	printk("malloc addr: 0x%x, 0x%x, 0x%x", addr1, addr2, addr3);
// 	sys_free(addr1);
// 	sys_free(addr2);
// 	sys_free(addr3);
	
// }

// /***********文件系统测试****************/
// int main(void)
// {
// 	put_str("i am kernel\n");
// 	init_all();
// 	intr_enable();	

// 	int32_t fd = sys_open("/file1", O_CREAT | O_RDWR);
// 	printk("fd: %d\n", fd);	

// 	char buf[12] = "hello world";
// 	sys_write(fd, buf, 12);

// 	struct stat state;
// 	sys_stat("/file1", &state);
// 	printk("st_ino = %d\n", state.st_ino);
// 	printk("st_size = %d\n", state.st_size);
// 	printk("st_ftype = %d\n", state.st_ftype);

// 	if(sys_close(fd)) {
// 		printk("/file1 close failed\n");
// 		return -1;
// 	}
// 	printk("/file1 close success\n");

// 	if(sys_unlink("/file1")) {
// 		printk("file1 delete failed\n");
// 	}
// 	printk("file1 delete success\n");
// }

