AS = nasm
CC = gcc
LD = ld
BUILD_DIR = ./build
BOCHS_DIR = ./bochs
ENTRY_POINT = 0xc0001500
LIB = -I lib/ -I lib/kernel/ -I lib/usr/ -I kernel/ -I kernel/thread/ -I kernel/device/ -I kernel/userprog/
ASFLAGS = -f elf32
CFLAGS  = -g -m32 $(LIB) -fno-builtin -fno-stack-protector -Wall -Wstrict-prototypes -Wmissing-prototypes -c
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o \
	$(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o $(BUILD_DIR)/bitmap.o \
	$(BUILD_DIR)/memory.o $(BUILD_DIR)/thread.o $(BUILD_DIR)/list.o $(BUILD_DIR)/switch.o $(BUILD_DIR)/sync.o   \
	$(BUILD_DIR)/console.o $(BUILD_DIR)/keyboard.o $(BUILD_DIR)/ioqueue.o $(BUILD_DIR)/tss.o $(BUILD_DIR)/process.o \
 	$(BUILD_DIR)/syscall-init.o $(BUILD_DIR)/syscall.o

####################### C编译 #######################################
##KERNEL##
$(BUILD_DIR)/main.o: kernel/main.c kernel/global.h kernel/init.h kernel/interrupt.h  \
kernel/memory.h kernel/thread/thread.h kernel/userprog/process.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/init.o: kernel/init.c lib/kernel/print.h kernel/interrupt.h kernel/timer.h kernel/memory.h \
kernel/thread/thread.h kernel/device/console.h kernel/device/keyboard.h kernel/userprog/tss.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/global.h lib/kernel/io.h 
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/timer.o: kernel/timer.c lib/kernel/io.h kernel/thread/thread.h \
kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/memory.o: kernel/memory.c kernel/global.h kernel/thread/sync.h \
kernel/thread/thread.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

##KERNEL/THREAD##
$(BUILD_DIR)/thread.o: kernel/thread/thread.c kernel/global.h \
kernel/memory.h kernel/interrupt.h kernel/userprog/process.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/sync.o: kernel/thread/sync.c kernel/global.h kernel/thread/thread.h \
kernel/interrupt.h 
	$(CC) $(CFLAGS) -o $@ $<

##KERNEL/DEVICE##
$(BUILD_DIR)/console.o: kernel/device/console.c	kernel/global.h \
kernel/thread/sync.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/keyboard.o: kernel/device/keyboard.c kernel/global.h \
lib/kernel/io.h kernel/interrupt.h kernel/device/ioqueue.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/ioqueue.o: kernel/device/ioqueue.c	kernel/global.h \
kernel/thread/thread.h kernel/thread/sync.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

##KERNEL/USERPROG##
$(BUILD_DIR)/tss.o:	kernel/userprog/tss.c kernel/global.h \
kernel/thread/thread.h 
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/process.o: kernel/userprog/process.c kernel/global.h \
kernel/memory.h kernel/thread/thread.h kernel/userprog/tss.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/syscall-init.o: kernel/userprog/syscall-init.c kernel/global.h kernel/thread/thread.h \
lib/usr/syscall.h
	$(CC) $(CFLAGS) -o $@ $<

##LIB##
$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c kernel/global.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/list.o: lib/kernel/list.c kernel/interrupt.h lib/kernel/stdint.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/string.o: lib/string.c lib/kernel/stdint.h lib/debug.h 
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/debug.o: lib/debug.c lib/kernel/print.h kernel/interrupt.h
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/syscall.o: lib/usr/syscall.c lib/kernel/stdint.h
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

.PHONY:	mk_dir hd clean all 

mk_dir:
	if [ ! -d $(BUILD_DIR) ];then mkdir $(BUILD_DIR);fi

build: $(BUILD_DIR)/kernel.bin

hd:
	dd if=$(BUILD_DIR)/kernel.bin of=$(BOCHS_DIR)/hd60M.img bs=512 count=200 seek=9 conv=notrunc

all: mk_dir build hd 

clean:
	cd $(BUILD_DIR) && rm -f ./*