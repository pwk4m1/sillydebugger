target=bin/cachevm.bin
reset=src/reset.asm


all: clean build

clean:
	rm -fr $(target)

build:
	nasm -fbin -o $(target) $(reset)

qemu:
	qemu-system-x86_64 -bios bin/cachevm.bin -serial stdio

qemu-int:
	qemu-system-x86_64 -bios bin/cachevm.bin -d int 2>&1 | tee /tmp/int_runlog.txt

qemu-log:
	qemu-system-x86_64 -bios bin/cachevm.bin -d in_asm 2>&1 | tee /tmp/runlog.txt

qemu-gdb:
	qemu-system-x86_64 -bios bin/cachevm.bin -S -gdb tcp::1234  

