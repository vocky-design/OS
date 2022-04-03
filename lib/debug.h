#ifndef _KERNEL_DEBUG_H
#define _KERNEL_DEBUG_H
#include "print.h"
#include "interrupt.h"
#include "stdio.h"

#define NDEBUG

void panic_spin(const char *filename, int line, const char *func, const char *condition);
#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)

#ifdef NDEBUG
    #define ASSERT(CONDITION) ((void)0)
    #define PRINTK_DEBUG(...) ((void)0)
#else
    #define ASSERT(CONDITION)   \
        if(CONDITION) { }       \
        else {                  \
            PANIC(#CONDITION);  \
        }

    #define PRINTK_DEBUG(...)  \
    do{                                 \
        printk("%s %d %s    ", __FILE__, __LINE__, __func__);   \
        printk(__VA_ARGS__);                        \
    }while(0)
#endif


#endif