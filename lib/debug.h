#ifndef _KERNEL_DEBUG_H
#define _KERNEL_DEBUG_H
#include "print.h"
#include "interrupt.h"
#include "stdio.h"

#define NODEBUG

void panic_spin(const char *filename, int line, const char *func, const char *condition);
#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)

/* ASSERT断言 */
#ifdef NODEBUG
    #define ASSERT(CONDITION) ((void)0)
#else
    #define ASSERT(CONDITION)   \
        if(CONDITION) { }       \
        else {                  \
            PANIC(#CONDITION);  \
        }
#endif

/* PRINTK_DEBUG做运行监控 */
#ifdef NODEBUG
    #define PRINTK_DEBUG(...) ((void)0)
#else
    #define PRINTK_DEBUG(...)  \
    do{                                 \
        char *pure_filename = strrchr(__FILE__, '/') + 1;   \
        printk("%s %d %s-> ", pure_filename, __LINE__, __func__);   \
        printk(__VA_ARGS__);                        \
    }while(0)
#endif


#endif