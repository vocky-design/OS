nasm -f elf32 -l ../lib/kernel/print.lst -o ../lib/kernel/print.o  ../lib/kernel/print.S
gcc -m32 -c -I ../lib/kernel/  -o main.o main.c
ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel.bin main.o ../lib/kernel/print.o 
dd if=kernel.bin of=../bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc
