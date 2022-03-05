#include "list.h"
#include "interrupt.h"

/* 初始化双向链表list */
void list_init(struct list *list)
{
    list->head.prev = NULL;
    list->tail.next = NULL;
    list->head.next = &list->tail;
    list->tail.prev = &list->head;
}

/* 把链表元素elem插入到元素before之前 */
static void list_insert_before(struct list_elem *before, struct list_elem *elem)
{
    enum intr_status old_status =  intr_disable();             //关闭中断

    before->prev->next = elem;
    elem->prev = before->prev;
    elem->next = before;
    before->prev = elem;

    intr_set_status(old_status);                                //恢复中断
}

/* 添加链表元素到链表队首，类似于栈push操作 */
void list_push(struct list *list, struct list_elem *elem)
{
    list_insert_before(list->head.next, elem);
}

/* 添加链表元素到链表队尾，类似于队列的先进先出操作 */
void list_append(struct list *list, struct list_elem *elem)
{
    list_insert_before(&list->tail, elem);
}

/* 使元素elem脱离链表 */
static void list_remove(struct list_elem *elem)
{
    enum intr_status old_status =  intr_disable();             //关闭中断

    elem->prev->next = elem->next;
    elem->next->prev = elem->prev;

    //缺少free步骤

    intr_set_status(old_status);                                //恢复中断
}

/* 将链表第一个元素弹出并返回，类似于栈pop操作  */
struct list_elem *list_pop(struct list *list)
{
    struct list_elem *elem = list->head.next;
    list_remove(elem);
    return elem;
}

/* 判断链表是否为空 */
bool list_empty(struct list *list)
{
    return (list->head.next == &list->tail ? TRUE:FALSE);
}

/* 返回链表长度 */
uint32_t list_len(struct list *list)
{
    struct list_elem *elem = list->head.next;
    uint32_t len = 0;
    while(elem != &list->tail) {
        ++len;
        elem = elem->next;
    }
    return len;
}

/* 从链表中查找元素obj_elem，成功时返回TRUE，失败返回FALSE */
bool elem_find(struct list *list, struct list_elem *obj_elem)
{
    struct list_elem *elem = list->head.next;
    while(elem != obj_elem && elem != &list->tail) {
        elem = elem->next;
    }
    if(elem == &list->tail) {          //说明没有找到
        return FALSE;
    }
    return TRUE;
}

/*  */
struct list_elem *list_traversal(struct list *list, traversal_func func, int arg)
{
    struct list_elem *elem = list->head.next;
    if(list_empty(list) == TRUE) {
        return NULL;
    }

    while(elem != &list->tail) {
        if(func(elem, arg) == TRUE) {
            return elem;
        }
        elem = elem->next;
    }

    return NULL;
}