#ifndef _LIB_STDIO_H
#define _LIB_STDIO_H

#include "global.h"
#include "usr/syscall.h"
#include "console.h"

uint32_t printf(const char *format, ...);
uint32_t sprintf(char *buf, const char *format, ...);
uint32_t printk(const char *format, ...);
#endif