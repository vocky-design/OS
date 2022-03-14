#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"


//void u_prog_a(void);
//void u_prog_b(void);
void k_a(void *args);
void k_b(void *args);
int main(void)
{
	put_str("i am kernel\n");
	init_all();

	//process_create(u_prog_a, "u_prog_a");
	//process_create(u_prog_b, "u_prog_b");
	thread_start("k_a", 32, k_a, NULL);
	thread_start("k_b", 32, k_b, NULL);
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
		//console_put_str("Main ");
		//put_str("Main ");
	}
	return 0;
}

void k_a(void *args)
{
	console_put_str("thread_a start\n");
	int max = 100;
	while(max--) {
		void *addr1 = sys_malloc(1024);
		void *addr2 = sys_malloc(1024);
		sys_free(addr1);
		sys_free(addr2);
	}
	console_put_str("thread_a end\n");
	while(1);
}
void k_b(void *args)
{
	console_put_str("thread_b start\n");
	int max = 100;
	while(max--) {
		void *addr1 = sys_malloc(2048);
		void *addr2 = sys_malloc(2048);
		sys_free(addr1);
		sys_free(addr2);
	}
	console_put_str("thread_b end\n");
	while(1);
}