#ifndef _LIB_KERNEL_LIST_H
#define _LIB_KERNEL_LIST_H

#include "stdint.h"

#define offset(struct_type, member)   (uint32_t)(&((struct_type *)0)->member)   
#define elem2entry(struct_type, member_name, member_ptr)    (struct_type *)((uint32_t)member_ptr - offset(struct_type, member_name))

/* 链表节点 */
struct list_elem {
    struct list_elem *prev;
    struct list_elem *next;
};
/* 链表初始结构 */
struct list {
    struct list_elem head;
    struct list_elem tail;
};

typedef bool traversal_func(struct list_elem *elem, int arg);


void list_init(struct list *list);
bool list_empty(struct list *list);
uint32_t list_len(struct list *list);
void list_push(struct list *list, struct list_elem *elem);
void list_append(struct list *list, struct list_elem *elem);
struct list_elem *list_pop(struct list *list);
bool elem_find(struct list *list, struct list_elem *obj_elem);
struct list_elem *list_traversal(struct list *list, traversal_func func, int arg);


#endif