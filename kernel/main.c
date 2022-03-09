#include "stdint.h"
#include "print.h"
#include "debug.h"
#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"
#include "console.h"

void u_prog_a(void);
void u_prog_b(void);
int main(void)
{
	put_str("i am kernel\n");
	init_all();

	process_create(u_prog_a, "u_prog_a");
	process_create(u_prog_b, "u_prog_b");
	uint32_t len = list_len(&thread_ready_list);
	console_put_int(len);
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
		//console_put_str("Main ");
		//put_str("Main ");
	}
	return 0;
}

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