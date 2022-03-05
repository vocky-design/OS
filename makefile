AS = nasm
CC = gcc
LD = ld
BUILD_DIR = ./build
BOCHS_DIR = ./bochs
ENTRY_POINT = 0xc0001500
LIB = -I lib/ -I lib/kernel/ -I kernel/ -I kernel/thread/ -I kernel/device/ -I kernel/userprog/
ASFLAGS = -f elf32
CFLAGS  = -g -m32 $(LIB) -fno-builtin -fno-stack-protector -Wall -Wstrict-prototypes -Wmissing-prototypes -c
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o \
	$(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o $(BUILD_DIR)/bitmap.o \
	$(BUILD_DIR)/memory.o $(BUILD_DIR)/thread.o $(BUILD_DIR)/list.o $(BUILD_DIR)/switch.o $(BUILD_DIR)/sync.o   \
	$(BUILD_DIR)/console.o $(BUILD_DIR)/keyboard.o $(BUILD_DIR)/ioqueue.o $(BUILD_DIR)/tss.o $(BUILD_DIR)/process.o \
	

####################### C编译 #######################################
##KERNEL##
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/stdint.h lib/kernel/print.h lib/debug.h kernel/init.h  kernel/interrupt.h  kernel/device/console.h kernel/memory.h kernel/thread/thread.h kernel/device/console.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h kernel/interrupt.h kernel/timer.h kernel/memory.h \
kernel/thread/thread.h kernel/device/console.h kernel/device/keyboard.h kernel/userprog/tss.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h lib/kernel/print.h lib/kernel/stdint.h kernel/global.h lib/kernel/io.h 
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/timer.o: kernel/timer.c kernel/timer.h lib/kernel/io.h lib/kernel/print.h lib/debug.h kernel/thread/thread.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/memory.o: kernel/memory.c kernel/memory.h lib/debug.h lib/kernel/print.h lib/kernel/stdint.h lib/kernel/bitmap.h lib/string.h kernel/thread/sync.h kernel/thread/thread.h
	$(CC) $(CFLAGS) -o $@ $<

##KERNEL/THREAD##
$(BUILD_DIR)/thread.o: kernel/thread/thread.c kernel/thread/thread.h lib/kernel/stdint.h lib/string.h kernel/memory.h kernel/interrupt.h lib/kernel/list.h lib/debug.h lib/kernel/list.h lib/kernel/print.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/sync.o: kernel/thread/sync.c kernel/thread/sync.h lib/kernel/stdint.h lib/kernel/list.h lib/debug.h kernel/interrupt.h kernel/thread/thread.h
	$(CC) $(CFLAGS) -o $@ $<
##KERNEL/DEVICE##
$(BUILD_DIR)/console.o: kernel/device/console.c	kernel/device/console.h lib/kernel/stdint.h lib/kernel/print.h kernel/thread/sync.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/keyboard.o: kernel/device/keyboard.c kernel/device/keyboard.h lib/kernel/stdint.h lib/kernel/print.h lib/kernel/io.h kernel/interrupt.h kernel/device/ioqueue.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/ioqueue.o: kernel/device/ioqueue.c	kernel/device/ioqueue.h	lib/kernel/stdint.h kernel/thread/thread.h kernel/thread/sync.h lib/debug.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<
##KERNEL/USERPROG##
$(BUILD_DIR)/tss.o:	kernel/userprog/tss.c kernel/userprog/tss.h lib/kernel/stdint.h lib/kernel/print.h lib/debug.h lib/string.h kernel/thread/thread.h kernel/global.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/process.o: kernel/userprog/process.c kernel/userprog/process.h kernel/global.h lib/kernel/stdint.h kernel/device/console.h lib/debug.h lib/string.h \
kernel/memory.h kernel/thread/thread.h kernel/userprog/tss.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<
##LIB##
$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c lib/kernel/bitmap.h lib/kernel/stdint.h lib/string.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/list.o: lib/kernel/list.c lib/kernel/list.h kernel/interrupt.h lib/kernel/stdint.h
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/string.o: lib/string.c lib/string.h lib/kernel/stdint.h lib/debug.h 
	$(CC) $(CFLAGS) -o $@ $<
$(BUILD_DIR)/debug.o: lib/debug.c lib/debug.h lib/kernel/print.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

####################### NASM编译 #######################################
$(BUILD_DIR)/kernel.o: kernel/kernel.S 
	$(AS) $(ASFLAGS) -o $@ $<
$(BUILD_DIR)/print.o: lib/kernel/print.S 
	$(AS) $(ASFLAGS) -o $@ $<
$(BUILD_DIR)/switch.o: kernel/thread/switch.S 
	$(AS) $(ASFLAGS) -o $@ $<

####################### 链接所有文件 #######################################
$(BUILD_DIR)/kernel.bin: $(OBJS)	
	$(LD) $(LDFLAGS) -o $@ $^

.PHONY:	mk_dir hd clean all test
test:
	objdump -S -m i386 -M intel $(BUILD_DIR)/process.o   >$(BUILD_DIR)/process.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/memory.o    >$(BUILD_DIR)/memory.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/interrupt.o >$(BUILD_DIR)/interrupt.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/thread.o    >$(BUILD_DIR)/thread.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/tss.o    	 >$(BUILD_DIR)/tss.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/process.o   >$(BUILD_DIR)/process.asm
	objdump -S -m i386 -M intel $(BUILD_DIR)/string.o   >$(BUILD_DIR)/string.asm

mk_dir:
	if [ ! -d $(BUILD_DIR) ];then mkdir $(BUILD_DIR);fi

build: $(BUILD_DIR)/kernel.bin

hd:
	dd if=$(BUILD_DIR)/kernel.bin of=$(BOCHS_DIR)/hd60M.img bs=512 count=200 seek=9 conv=notrunc

all: mk_dir build hd test

clean:
	cd $(BUILD_DIR) && rm -f ./*