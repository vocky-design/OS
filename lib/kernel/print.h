#ifndef _LIB_KERNEL_PRINT_H
#define _LIB_KERNEL_PRINT_H
#include "stdint.h"
void put_char(const uint8_t char_asci);
void put_str(const char *message);
void put_int(const uint32_t num);
#endif