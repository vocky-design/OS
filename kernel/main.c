#include "stdint.h"
#include "print.h"
#include "debug.h"
#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"
#include "console.h"

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
	thread_start("k_a", 32, k_b, NULL);
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
		//console_put_str("Main ");
		//put_str("Main ");
	}
	return 0;
}
void k_a(void *args)
{
	void *addr = sys_malloc(33);
	console_put_str("I am thread_a, sys_malloc(33), addr is 0x");
	console_put_int((uint32_t)addr);
	console_put_char('\n');
	while(1);
}
void k_b(void *args)
{
	void *addr = sys_malloc(63);
	console_put_str("I am thread_a, sys_malloc(63), addr is 0x");
	console_put_int((uint32_t)addr);
	console_put_char('\n');
	while(1);
}

/*
void u_prog_a(void)
{
	while(1) {
		put_str("uprog_A");
		//console_put_str("uprog_A");
	}
}
void u_prog_b(void)
{
	while(1) {
		put_str("uprog_B");
		//console_put_str("uprog_B");
	}
}
*/