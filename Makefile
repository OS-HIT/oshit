OS 						:= $(shell grep -i Microsoft /proc/version)
WSL_DRIVE 				:= f
MOUNT 					:= fs_mount_point
KERNEL_BIN 				= oshit_kernel/kernel.bin
K210_BIN				= k210.bin
FS_IMG					= oshit_rootfs/fs.img
BOARD					?= qemu
BOOTLOADER 				:= bootloader/rustsbi-$(BOARD).bin
K210_BOOTLOADER_SIZE 	:= 131072
LOG_LVL					= info

# KERNEL ENTRY
ifeq ($(BOARD), qemu)
	KERNEL_ENTRY_PA := 0x80200000
else ifeq ($(BOARD), k210)
	KERNEL_ENTRY_PA := 0x80020000
endif

ifeq ($(OS),)
	PY := python3
	SD_MNT := /dev/sdb
	K210-SERIALPORT	:= /dev/ttyUSB0
else
	PY := python.exe
	SD_MNT := /mnt/$(WSL_DRIVE)
	K210-SERIALPORT	:= COM3
endif

$(K210_TOOL): $(K210_TOOL_ZIP)
	tar -xf $(K210_TOOL_ZIP)\

$(BIN_DIR)/%: $(SRC_DIR)/% $(BIN_DIR)
	cp user_linker.ld $</src/user_linker.ld
	cd $< && cargo build --bin $* --release
	cp $</target/riscv64imac-unknown-none-elf/release/$* $@
	rm $</src/user_linker.ld

$(BIN_DIR):
	mkdir $(BIN_DIR)

$(SD_MNT):
	@echo "Folder $(SD_MNT) does not exist, trying to mount sd card. \n\033[0;31mIf you saw this and you are not in WSL, \033[30;101mABORT NOW SOMETHING IS WRONG\033[0;31m.\033[0m"
	@for i in 5 4 3 2 1; do \
		echo "\033[37;101m"$$i"\033[0m; \
		sleep 1; \
	done
	@mkdir -p $(SD_MNT)
	@chmod 777 $(SD_MNT)
	@mount -t drvfs $(WSL_DRIVE): $(SD_MNT)
	@rm -rf $(SD_MNT)/*

sd: $(FS_IMG)

$(KERNEL_BIN): 
	make -C oshit_kernel all

$(FS_IMG):
	make -C oshit_rootfs all

$(K210_BIN): $(KERNEL_BIN) $(BOOTLOADER)
	cp $(BOOTLOADER) $(BOOTLOADER).copy
	dd if=$(KERNEL_BIN) of=$(BOOTLOADER).copy bs=$(K210_BOOTLOADER_SIZE) seek=1
	mv $(BOOTLOADER).copy $(K210_BIN)

ifeq ($(BOARD),qemu)
run: $(KERNEL_BIN) $(FS_IMG) $(BOOTLOADER)
	qemu-system-riscv64 \
		-machine virt \
		-nographic \
		-bios $(BOOTLOADER)\
		-device loader,file=$(KERNEL_BIN),addr=$(KERNEL_ENTRY_PA) \
		-drive file=$(FS_IMG),if=none,format=raw,id=x0 \
		-device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0
else
run: $(K210_BIN)
ifeq ($(OS),)
	@sudo chmod 777 $(K210-SERIALPORT)
endif
	@$(PY) $(K210-BURNER) -p $(K210-SERIALPORT) -b 1500000 $(K210_BIN)
	@$(PY) -m serial.tools.miniterm --eol LF --dtr 0 --rts 0 --filter direct $(K210-SERIALPORT) 115200
endif

debug: $(KERNEL_BIN) $(FS_IMG) $(BOOTLOADER)
	@qemu-system-riscv64 \
			-s -S \
			-machine virt \
			-nographic \
			-bios $(BOOTLOADER)\
			-device loader,file=$(KERNEL_BIN),addr=$(KERNEL_ENTRY_PA)\
			-drive file=$(FS_IMG),if=none,format=raw,id=x0 \
			-device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

clean: clean_usr
	make -C oshit_kernel clean
	make -C oshit_rootfs clean
	cd oshit_usrlib && cargo clean

.PHONY: run user clean clean_usr sd $(KERNEL_BIN) $(FS_IMG)

ifeq ($(BOARD), qemu)
FW_JUMP_ADDR := 0x80200000
else ifeq ($(BOARD), k210)
FW_JUMP_ADDR := 0x80040000
endif

_opensbi:
	export CROSS_COMPILE=riscv64-unknown-elf- &&\
	export PLATFORM_RISCV_XLEN=64 &&\
	cd opensbi && make PLATFORM=kendryte/k210 FW_JUMP=y FW_JUMP_ADDR=$(FW_JUMP_ADDR)
	cp opensbi/build/platform/kendryte/k210/firmware/fw_jump.bin bootloader/opensbi-$(BOARD).bin