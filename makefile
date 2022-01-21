AS = nasm
CC = gcc
LD = ld
BUILD_DIR = ./build
BOCHS_DIR = ./bochs
ENTRY_POINT = 0xc0001500
LIB = -I lib/kernel/ -I kernel/ -I lib/
ASFLAGS = -f elf32
CFLAGS  = -m32 $(LIB) -fno-builtin -fno-stack-protector -Wall -Wstrict-prototypes -Wmissing-prototypes -c
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o \
	$(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o $(BUILD_DIR)/bitmap.o

####################### C编译 #######################################
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h kernel/debug.h kernel/init.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h kernel/interrupt.h kernel/timer.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h lib/kernel/print.h lib/kernel/stdint.h kernel/global.h lib/kernel/io.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/timer.o: kernel/timer.c kernel/timer.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h lib/kernel/print.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/string.o: lib/string.c lib/string.h lib/kernel/stdint.h kernel/debug.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c lib/kernel/bitmap.h lib/kernel/stdint.h lib/string.h
	$(CC) $(CFLAGS) -o $@ $<
####################### NASM编译 #######################################
$(BUILD_DIR)/kernel.o: kernel/kernel.S 
	$(AS) $(ASFLAGS) -o $@ $<
$(BUILD_DIR)/print.o: lib/kernel/print.S 
	$(AS) $(ASFLAGS) -o $@ $<

####################### 链接所有文件 #######################################
$(BUILD_DIR)/kernel.bin: $(OBJS)	
	$(LD) $(LDFLAGS) -o $@ $^

.PHONY:	mk_dir hd clean all
mk_dir:
	if [ ! -d $(BUILD_DIR) ];then mkdir $(BUILD_DIR);fi

build: $(BUILD_DIR)/kernel.bin

hd:
	dd if=$(BUILD_DIR)/kernel.bin of=$(BOCHS_DIR)/hd60M.img bs=512 count=200 seek=9 conv=notrunc

all: mk_dir build hd

clean:
	cd $(BUILD_DIR) && rm -f ./*