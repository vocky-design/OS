#include "stdint.h"
#include "print.h"
#include "debug.h"
#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "thread.h"
#include "console.h"

#define DEBUG

#ifdef DEBUG
#include "list.h"
struct list_test
{
	uint8_t ch1;
	uint8_t ch2;
};

#endif

//void k_thread_a(void *arg);
//void k_thread_b(void *arg);

int main(void)
{
	#ifdef DEBUG
	//对list.h的测试
	struct list list;
	struct list_elem elem1, elem2, elem3;
	list_init(&list);
	ASSERT(list_empty(&list) == TRUE);
	list_push(&list, &elem1);
	list_append(&list, &elem2);
	list_append(&list, &elem3);
	list_pop(&list);
	ASSERT(list_len(&list) == 2);
	ASSERT(elem_find(&list, &elem2) == TRUE);
	ASSERT(elem_find(&list, &elem3) == TRUE);
	ASSERT(list.head.next == &elem2);
	ASSERT(list.head.next->next == &elem3);
	ASSERT(list.head.next->next->next == &list.tail);

	struct list_test list2;
	list2.ch1 = '1'; list2.ch2 = '2';
	uint8_t *pch = &list2.ch2;
	struct list_test *plist = elem2entry(struct list_test, ch2, pch);
	ASSERT(plist->ch1 == '1'); ASSERT(plist->ch2 == '2');
	#endif

	put_str("i am kernel\n");
	init_all();
	//新建线程
	//thread_start("k_thread_a", 31, k_thread_a, "argA ");
	//thread_start("k_thread_b", 8, k_thread_b, "argB ");
	intr_enable();						//确保中断打开，调度器开始工作
	while(1); //{
		//console_put_str("Main ");
	//}
	return 0;
}

/*
void k_thread_a(void *arg)
{
	char *parg = arg;
	while(1) {
		console_put_str(parg);
	}
}

void k_thread_b(void *arg)
{
	char *parg = arg;
	while(1) {
		console_put_str(parg);
	}
}
*/