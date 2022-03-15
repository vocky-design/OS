#ifndef _LIB_USR_SYSCALL_H
#define _LIB_USR_SYSCALL_H

enum SYSCALL_NR {
    SYS_GETPID
};

uint32_t getpid(void);
#endif