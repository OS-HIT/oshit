
OS := $(shell grep -iq Microsoft /proc/version)
DRIVE := f
MOUNT := fs_mount_point

ifeq ($(OS),)
	PY := python.exe
	SD_MNT := /mnt/$(DRIVE)
	K210-SERIALPORT	:= COM3
else
	PY := python3
	SD_MNT := /dev/sdb
	K210-SERIALPORT	:= /dev/ttyUSB0
endif

SRC_DIR	:= user_programs
BIN_DIR	:= user_bins
SRCS	:= $(wildcard $(SRC_DIR)/*)
BINS	:= $(foreach SRC,$(SRCS), $(BIN_DIR)/$(notdir $(SRC)))
SD_BINS	:= $(foreach SRC,$(SRCS), $(SD_MNT)/$(notdir $(SRC)))
FS_BINS	:= $(foreach SRC,$(SRCS), $(MOUNT)/$(notdir $(SRC)))

ifeq ($(OS), )
sdfiles: | $(SD_MNT) $(SD_BINS)
else
sdfiles: $(SD_BINS)
endif

user: fs.img

fs.img: fs_img

fs_img: $(FS_BINS)
	umount $(MOUNT)
	rm -rf fs_mount_point

fs_img_inner: $(BINS) $(MOUNT)
	dd if=/dev/zero of=fs.img bs=1024 count=1048576
	mkfs.vfat fs.img
	mount -o loop fs.img $(MOUNT)

$(MOUNT)/%: $(BIN_DIR)/% fs_img_inner
	cp $< $@

$(MOUNT):
	mkdir $(MOUNT)

$(BIN_DIR)/%: $(SRC_DIR)/%
	cd $^ && cargo build --bin $* --release
	cp $^/target/riscv64gc-unknown-none-elf/release/$* $@

$(SD_MNT)/%: $(BIN_DIR)/%
	cp $^ $@

$(SD_MNT):
	echo "Folder $(SD_MNT) does not exist, trying to mount sd card. \033[0;31mIf you saw this and you are not in WSL, \033[0;91mABORT NOW SOMETHING IS WRONG\033[0;31m. I don't want to break your system.\033[0m"
	mkdir -p $(SD_MNT)
	chmod 777 $(SD_MNT)
	mount -t drvfs $(DRIVE): $(SD_MNT)
	rm -rf $(SD_MNT)/*

run: user
	make -C oshit_kernel run PY=$(PY) K210-SERIALPORT=$(K210-SERIALPORT)

debug: user
	make -C oshit_kernel debug

clean:
	make -C oshit_kernel clean
	rm user_bins/*
	rm fs_img
	rm -rf $(MOUNT)

.PHONY:
	run user clean user programs sdfiles fs_img fs_img_inner