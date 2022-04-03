#ifndef _KERNEL_DEVICE_CONSOLE_H
#define _KERNEL_DEVICE_CONSOLE_H

#include "global.h"

void console_init(void);
void console_put_str(char *str);
void console_put_char(uint8_t char_asci);
void console_put_int(uint32_t num);


#endif