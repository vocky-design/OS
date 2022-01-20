#!/bin/bash
#clean
rm -f build/*

#lib/
nasm -f elf32 -l build/print.lst -o build/print.o  lib/kernel/print.S
#boot/
nasm -I boot/include/ -o build/mbr.bin      -l build/mbr.lst        boot/mbr.S
nasm -I boot/include/ -o build/loader.bin   -l build/loader.lst     boot/loader.S
#kernel/
nasm -f elf32 -l build/kernel.lst -o build/kernel.o kernel/kernel.S
gcc -m32  -fno-builtin -fno-stack-protector -c -I lib/kernel/ -o build/interrupt.o kernel/interrupt.c
gcc -m32  -fno-builtin -fno-stack-protector -c -I lib/kernel/ -o build/init.o      kernel/init.c
gcc -m32  -fno-builtin -fno-stack-protector -c -I lib/kernel/ -o build/main.o      kernel/main.c
ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel.bin \
build/main.o build/init.o build/interrupt.o build/kernel.o build/print.o
#加载
dd if=build/mbr.bin    of=bochs/hd60M.img bs=512 count=1 conv=notrunc
dd if=build/loader.bin of=bochs/hd60M.img bs=512 count=4   seek=2 conv=notrunc
dd if=build/kernel.bin of=bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc

#gcc -m32 -fno-builtin