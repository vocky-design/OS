#!/bin/bash
nasm -I include/ -o mbr.bin -l mbr.lst mbr.S
nasm -I include/ -o loader.bin -l loader.lst loader.S
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=../hd60M.img bs=512 count=4 seek=2 conv=notrunc
