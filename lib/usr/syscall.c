#include "syscall.h"


/* 无参数的系统调用 */
#define _syscall0(NUMBER) ({                \
    int retval;                             \
    asm volatile (                          \
        "int $0x80"                         \
        :"=a"(retval)                       \
        :"a"(NUMBER)                        \
        :"memory"                           \
    );                                      \
    retval;                                 \
})

/* 支持一个参数的系统调用 */
#define _syscall1(NUMBER, ARG1) ({          \
    int retval;                             \
    asm volatile (                          \
        "int $0x80"                         \
        :"=a"(retval)                       \
        :"a"(NUMBER), "b"(ARG1)             \
        :"memory"                           \
    );                                      \
    retval;                                 \
})

/* 支持2个参数的系统调用 */
#define _syscall2(NUMBER, ARG1, ARG2) ({          \
    int retval;                             \
    asm volatile (                          \
        "int $0x80"                         \
        :"=a"(retval)                       \
        :"a"(NUMBER), "b"(ARG1), "c"(ARG2)            \
        :"memory"                           \
    );                                      \
    retval;                                 \
})

/* 支持3个参数的系统调用 */
#define _syscall3(NUMBER, ARG1, ARG2, ARG3) ({          \
    int retval;                             \
    asm volatile (                          \
        "int $0x80"                         \
        :"=a"(retval)                       \
        :"a"(NUMBER), "b"(ARG1), "c"(ARG2), "d"(ARG3)             \
        :"memory"                           \
    );                                      \
    retval;                                 \
})

/* 返回当前任务的pid */
uint32_t getpid(void)
{
    return _syscall0(SYS_GETPID);
}

/* */
uint32_t write(int32_t fd, const void *buf, uint32_t count)
{
    return _syscall3(SYS_WRITE, fd, buf, count);
}