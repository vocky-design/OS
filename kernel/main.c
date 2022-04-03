#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "process.h"
#include "stdio.h"



int main(void)
{
	put_str("i am kernel\n");

	init_all();

	//process_create(u_prog_a, "u_prog_a");
	//process_create(u_prog_b, "u_prog_b");
	intr_enable();						//确保中断打开，任务调度器开始工作
	while(1) {
	}
	return 0;
}

