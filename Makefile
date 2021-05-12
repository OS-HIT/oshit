
OS := $(shell grep -iq Microsoft /proc/version)
DRIVE := f

ifeq ($(OS),)
	PY := python3.exe
	SD_MNT := /mnt/$(DRIVE)
else
	PY := python3
	SD_MNT := /dev/sdb
endif

SRC_DIR	:= user_programs
BIN_DIR	:= user_bins
SRCS	:= $(wildcard $(SRC_DIR)/*)
BINS	:= $(foreach SRC,$(SRCS), $(BIN_DIR)/$(notdir $(SRC)))
SD_BINS	:= $(foreach SRC,$(SRCS), $(SD_MNT)/$(notdir $(SRC)))

ifeq ($(OS), )
user: | $(SD_MNT) $(SD_BINS)
else
user: $(SD_BINS)
endif

$(BIN_DIR)/%: $(SRC_DIR)/%
	cd $^ && cargo build --bin $* --release
	cp $^/target/riscv64gc-unknown-none-elf/release/$* $@

$(SD_MNT)/%: $(BIN_DIR)/%
	cp $^ $@

$(SD_MNT):
	@echo "Folder $(SD_MNT) does not exist, trying to mount sd card. \033[0;31mIf you saw this and you are not in WSL, \033[0;91mABORT NOW SOMETHING IS WRONG\033[0;31m. I don't want to break your system.\033[0m"
	@mkdir -p $(SD_MNT)
	@mount -t drvfs $(DRIVE): $(SD_MNT)
	@rm -rf 'System Volume Information/'

run: user
	make -C oshit_kernel run

debug: user
	make -C oshit_kernel debug

clean:
	make -C oshit_kernel clean
	rm user_bins/*

.PHONY:
	run user clean user programs