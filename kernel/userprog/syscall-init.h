<<<<<<< HEAD

=======
#ifndef _KERNEL_USERPROG_SYSCALL-INIT_H
#define _KERNEL_USERPROG_SYSCALL-INIT_H
>>>>>>> 003db3805aa82043c5678e1d069b07c57d39020e

#define syscall_nr 32
void *syscall_table[syscall_nr];
void syscall_init(void);
#endif