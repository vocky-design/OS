#ifndef  _LIB_KERNEL_BITMAP_H
#define  _LIB_KERNEL_BITMAP_H
#include "global.h"

/* 位图数据结构的定义 */
struct bitmap {
    uint32_t btmp_bytes_len;        //以字节为单位
    uint8_t *bytes;
};

void bitmap_init(struct bitmap *btmp);
bool bitmap_bit_test(struct bitmap *btmp, uint32_t bit_idx);
int32_t bitmap_scan(struct bitmap *btmp, uint32_t cnt);
void bitmap_set(struct bitmap *btmp, uint32_t bit_idx, bool value);
#endif