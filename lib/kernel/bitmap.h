#ifndef  _LIB_KERNEL_BITMAP_H
#define  _LIB_KERNEL_BITMAP_H

#include "stdint.h"

/* 位图数据结构的定义 */
struct bitmap {
    uint32_t btmp_bytes_len;
    uint8_t *bits;
};

void bitmap_init(struct bitmap *btmp);
bool bitmap_scan_test(struct bitmap *btmp, uint32_t bit_idx);
int32_t bitmap_scan(struct bitmap *btmp, uint32_t cnt);
void bitmap_set(struct bitmap *btmp, uint32_t bit_idx, int8_t value);
#endif