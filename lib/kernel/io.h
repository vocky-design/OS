#ifndef   _LIB_IO_H
#define   _LIB_IO_H
#include "stdint.h"
/* 向端口port写入一个字节 */
static inline void outb(uint16_t port, uint8_t data)
{
    asm volatile ("outb %b0,%w1"::"a"(data),"d"(port));
}
/* 将addr处起始的word_cnt个字写入端口port */
static inline void outsw(uint16_t port, const void *addr, uint32_t word_cnt)
{
    asm volatile ("cld; rep outsw":"+S"(addr),"+c"(word_cnt):"d"(port));
}
/* 从端口port读取一个字节 */
static inline uint8_t inb(uint16_t port)
{
    uint8_t data;
    asm volatile ("inb %w1,%b0":"=a"(data):"d"(port));
    return data;
}
/* 从端口读取word_cnt个字写入起始addr处*/
static inline void insw(uint16_t port, const void *addr, uint32_t word_cnt)
{
    asm volatile ("cld; rep insw":"+D"(addr),"+c"(word_cnt):"d"(port):"memory");
}
#endif