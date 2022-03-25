#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"
#include "stdio.h"

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
	thread_start("k_a", 32, k_a, "thread_a");
	thread_start("k_b", 32, k_b, "thread_b");
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
		//console_put_str("Main ");
		//put_str("Main ");
	}
	return 0;
}

void k_a(void *args)
{
	while(1);
}
void k_b(void *args)
{
	while(1);
}