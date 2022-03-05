#include "stdint.h"
#include "print.h"
#include "debug.h"
#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"
#include "console.h"

void k_thread_a(void *arg);
void k_thread_b(void *arg);

int main(void)
{
	put_str("i am kernel\n");
	init_all();
	//新建线程
	thread_start("k_thread_a", 31, k_thread_a, "argA ");
	thread_start("k_thread_b", 31, k_thread_b, "argB ");
	uint32_t len = list_len(&thread_ready_list);
	console_put_int(len);
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
		//console_put_str("Main ");
		put_str("Main ");
	}
	return 0;
}


void k_thread_a(void *arg)
{
	while(1){
		//console_put_str("A ");
		put_str("A ");
	}
}

void k_thread_b(void *arg)
{
	while(1) {
		//console_put_str("B ");
		put_str("B ");
	}
}