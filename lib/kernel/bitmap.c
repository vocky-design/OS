#include "bitmap.h"

void bitmap_init(struct bitmap *btmp)
{
    //清空位图占用空间
    memset(btmp->bytes, 0, btmp->btmp_bytes_len);
}
/* 判断bit_idx位是否为1，该位有1则返回1，否则返回0 */
bool bitmap_bit_test(struct bitmap *btmp, uint32_t bit_idx)
{
    uint32_t byte_idx = bit_idx / 8;
    uint8_t  byte_odd = bit_idx % 8;
    return btmp->bytes[byte_idx] & (1 << byte_odd) ;
}
/* 在位图中申请连续cnt个位，成功，则返回其起始位下标，失败返回-1 */
uint32_t bitmap_scan(struct bitmap *btmp, uint32_t cnt)
{
    uint32_t byte_idx = 0;
    while(0xff == btmp->bytes[byte_idx] && byte_idx < btmp->btmp_bytes_len) {
        ++byte_idx;
    }
    if(byte_idx == btmp->btmp_bytes_len) {
        return -1;
    }
    ASSERT(byte_idx < btmp->btmp_bytes_len);


    //若在位图数组范围内的某字节内找到了空闲位，在该字节内逐位比对，找到空闲位的索引。
    uint8_t i = 0;
    while(btmp->bytes[byte_idx] & (1<<i)) {
        ++i;
    }
    uint32_t bit_idx_start = byte_idx * 8 + i;
    if(cnt == 1) {
        return (uint32_t)bit_idx_start;
    }
    uint32_t bit_left = btmp->btmp_bytes_len * 8 - bit_idx_start;
    uint32_t next_bit_idx = bit_idx_start + 1;
    uint32_t count = 1;
    bit_idx_start = -1;
    while(bit_left--) {
        if(!bitmap_bit_test(btmp, next_bit_idx)) {     //该位是0，可以申请
            ++count;
        } else {
            count = 0;
        }
        if(count == cnt) {
            bit_idx_start = next_bit_idx - cnt + 1;
            break;
        }
        ++next_bit_idx;
    }
    return (uint32_t)bit_idx_start;
}
/* 将位图btmp的bit_idx位设置为value */
void bitmap_set(struct bitmap *btmp, uint32_t bit_idx, bool value)
{
    ASSERT(value == 0 || value == 1);
    uint32_t byte_idx = bit_idx / 8;
    uint8_t  byte_odd = bit_idx % 8;
    if(value) {
        btmp->bytes[byte_idx] |= (1<<byte_odd);
    } else {
        btmp->bytes[byte_idx] &= ~(1<<byte_odd);
    }
}