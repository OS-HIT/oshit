
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
SRC_FILES := $(shell find $(SRC_DIR) -type f -name '*.rs')
LIB_FILES := $(shell find oshit_usrlib -type f -name '*.rs')

ifeq ($(OS), )
sdfiles: | $(SD_MNT) $(SD_BINS)
else
sdfiles: $(SD_BINS)
endif

# user: fs.img
user: fs.img

fs.img: $(BINS) $(ALL_FILES)
	mkdir $(MOUNT)
	export MOUNT=$(MOUNT) \
	&& export BIN_DIR=$(BIN_DIR) \
	&& sudo -E ./make_fs_img

$(BIN_DIR)/%: $(SRC_DIR)/% $(BIN_DIR)
	cp user_linker.ld $</src/user_linker.ld
	cd $< && cargo build --bin $* --release
	cp $</target/riscv64gc-unknown-none-elf/release/$* $@
	rm $</src/user_linker.ld

$(SD_MNT)/%: $(BIN_DIR)/%
	cp $^ $@

$(BIN_DIR):
	mkdir $(BIN_DIR)

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

clean: clean_usr
	make -C oshit_kernel clean
	cd oshit_usrlib && cargo clean
	rm -rf user_bins
	rm -f fs.img
	rm -rf $(MOUNT)

clean_usr: $(SRC_DIR)/*
	for file in $^; do \
		cargo clean --manifest-path $${file}/Cargo.toml; \
		rm -f $${file}/src/user_linker.ld; \
	done

.PHONY:
	run user clean user programs sdfiles clean_usr