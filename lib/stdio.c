#include "stdio.h"

#define va_list char*
//va_start:使ap指向参数v的地址
#define va_start(ap, v) ap = (va_list)&v
//va_arg：使ap指向下一个参数，下一个参数类型是t，返回其参数值
#define va_arg(ap, t) *((t*)(ap += 4))
//va_end: 使ap=NULL
#define va_end(ap) ap=NULL

/* 将整型转换为字符（integer to ascii） */
static void itoa(uint32_t value, char **buf_ptr_addr, uint8_t base)
{
    //取商取余
    uint32_t Q = value / base;
    uint32_t R = value % base;
    //递归调用
    if(Q) {
        itoa(Q, buf_ptr_addr, base);
    }
    //将余数转换为字符
    if(R >= 0 && R <= 9) {
        *((*buf_ptr_addr)++) = R + '0';
    } else if(R >= 10 && R <= 15) {
        *((*buf_ptr_addr)++) = R - 10 + 'A';
    } else {
        PANIC("R <= 15 && R >= 0");
    }
}

/* 将参数ap按照格式format输出到字符串str，并返回str的长度 */
static uint32_t vsprintf(char *str, const char *format, va_list ap)
{
    int arg_int, arg_uint;
    char *arg_str;
    while(*format) {
        if(*format != '%') {
            *str++ = *format++;
        } else {
            ++format;           //跳过'%'
            switch(*format) {
                case 'x':
                    arg_uint= va_arg(ap, uint32_t);
                    itoa(arg_uint, &str, 16);
                    ++format;
                    break;
                case 'd':
                    arg_int = va_arg(ap, int);
                    if(arg_int < 0) {
                        arg_int = 0 - arg_int;
                        *str++ = '-';
                    }
                    itoa(arg_int, &str, 10);
                    ++format;
                    break;
                case 's':
                    arg_str = va_arg(ap, char *);
                    strcpy(str, arg_str);
                    str += strlen(arg_str);
                    ++format;
                    break;
                case 'c':
                    *str++ = va_arg(ap, char);
                    ++format;
                    break;
                default:
                    PANIC("% of format must be one of x,d,s,c");
                    break;
            }
        }
    }

    return strlen(str);
}

/* printf */
uint32_t printf(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    char buf[1024] = {0};
    vsprintf(buf, format, ap);
    va_end(ap);
    return write(buf);
}

/* 同printf不同的地方就是字符串不是写到终端，而是写到buf中 */
uint32_t sprintf(char *buf, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    uint32_t retval = vsprintf(buf, format, ap);
    va_end(ap);
    return retval;
}

/* 与printf的区别是不使用write系统调用 */
uint32_t printk(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    char buf[1024] = {0};
    uint32_t len = vsprintf(buf, format, ap);
    va_end(ap);
    console_put_str(buf);
    return len;
}