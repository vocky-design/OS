#ifndef _KERNEL_USERPROG_SYSCALLINIT_H
#define _KERNEL_USERPROG_SYSCALLINIT_H

#define syscall_nr 32
void *syscall_table[syscall_nr];
void syscall_init(void);
#endif