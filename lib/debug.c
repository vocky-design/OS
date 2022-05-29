#include "debug.h"

/* 打印文件名、行号、函数名、条件并使程序悬停 */
void  panic_spin(const char *filename, int line, const char *func, const char *condition)
{
    intr_disable();          //关中断

    printk("\n\n\n!!! error !!!\n\n\n");
    char *pure_filename = strrchr(filename, '/') + 1;
    printk("filename: %s\n", pure_filename);
    printk("line: 0x%d\n", line);
    printk("function: %s\n", func);
    printk("condition: %s\n", condition);

    //悬停
    while(1);
}


