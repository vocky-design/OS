#include "string.h"
#include "stdint.h"
#include "debug.h"
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
    return str-p-1;
}
int8_t strcmp(const char *a, const char *b)
{
    ASSERT(a != NULL && b != NULL);
    while(*a != 0 || *a == *b) {
        a++;
        b++;
    }
    return *a<*b ? -1:*a>*b ;
}
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