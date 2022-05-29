#include "string.h"
#include "stdint.h"
#include "debug.h"

/*************************************操作内存部分************************************/
void memset(void *dst_, uint8_t value, uint32_t size)
{
    ASSERT(dst_ != NULL);
    uint8_t *dst = (uint8_t *)dst_;
    while(size--) {
        *dst++ = value;
    }
}
void memcpy(void *dst_, const void *src_, uint32_t size)
{
    ASSERT(dst_ != NULL && src_ != NULL);
    uint8_t *dst = (uint8_t*)dst_;
    const uint8_t *src = (uint8_t*)src_;
    while (size--) {
        *dst++ = *src++;
    }
}
//*a>*b返回1，*a<*b返回-1，*a==*b返回0
int8_t memcmp(const void *a_, const void *b_, uint32_t size)
{
    ASSERT(a_ != NULL && b_ != NULL);
    const uint8_t *a = (uint8_t*)a_;
    const uint8_t *b = (uint8_t*)b_;
    while(size--) {
        if(*a != *b) {
            return *a>*b ? 1:-1; 
        }
        a++;
        b++;
    }
    return 0;
}

/*************************************操作字符串部分***************************************/
char *strcpy(char *dst, const char *src)
{
    ASSERT(dst != NULL && src != NULL);
    char *p = dst;
    while((*dst++ = *src++));
    return p;
}
uint32_t strlen(const char *str)
{
    ASSERT(str != NULL);
    const char *p = str;
    while(*str++);
    return str-p;
}
/* a < b : -1
   a > b :  1
   a = b :  0
 */
int8_t strcmp(const char *a, const char *b)
{
    ASSERT(a != NULL && b != NULL);
    while(*a != 0 && *a == *b) {//*a != 0条件是为了避免两个字符串相同时的越界问题
        a++;
        b++;
    }
    return *a<*b ? -1:*a>*b ;
}

/* 从头检索，返回字符位置指针 */
char *strchr(const char *str, const char ch)
{
    ASSERT(str != NULL);
    while(*str) {
        if(*str == ch) {
            return (char *)str;
        }
        ++str;
    }
    return NULL;
}

/* 将字符串src_拼接到dst_后，返回拼接后的串地址 */
char *strcat(char *dst_, const char *src_)
{
    ASSERT(dst_ != NULL && src_ != NULL);

    char *str = dst_;
    while(*str++);
    //要覆盖掉\0
    --str;
    while((*str++ = *src_++));
    return dst_;
}

/* 从后往前查找字符串str中首次出现字符ch的地址 */
char *strrchr(const char *str, const uint8_t ch)
{
    ASSERT(str != NULL);
    const char *last_char = NULL;
    /* 从头到尾遍历一次，若存在ch字符，last_char总是该字符最后一次出现在串中的地址(不是下标，是地址) */
    while(*str != 0) {
        if(*str == ch) {
            last_char = str;
        }
        ++str;
    }
    return (char *)last_char;
}