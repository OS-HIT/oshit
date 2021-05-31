
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

# comp or homemade
COMP_MODE := COMP
BIN_DIR	:= user_bins
# TODO: make this different under COMP and HOMEMADE
PROC0_DIR := user_programs/proc0
SHELL_DIR := user_programs/shell

ifeq ($(COMP_MODE), HOMEMADE)
SRC_DIR	:= user_programs
SRCS	:= $(wildcard $(SRC_DIR)/*)
BINS	:= $(foreach SRC,$(SRCS), $(BIN_DIR)/$(notdir $(SRC)))
SD_BINS	:= $(foreach SRC,$(SRCS), $(SD_MNT)/$(notdir $(SRC)))
FS_BINS	:= $(foreach SRC,$(SRCS), $(MOUNT)/$(notdir $(SRC)))
SRC_FILES := $(shell find $(SRC_DIR) -type f -name '*.rs')
LIB_FILES := $(shell find oshit_usrlib -type f -name '*.rs')
ALL_FILES := $(SRC_FILES) $(LIB_FILES)
else
COMP_USER_DIR := testsuits-for-oskernel/riscv-syscalls-testing/user
SRC_DIR := $(COMP_USER_DIR)/src/oscomp
COMP_BIN_DIR :=  $(COMP_USER_DIR)/build/riscv64
SRC_FILES := $(shell find $(SRC_DIR) -type f -name '*.c')
RES_DIR := testsuits-for-oskernel/riscv-syscalls-testing/res
K210_TOOL := kendryte-toolchain/bin
K210_TOOL_ZIP := $(RES_DIR)/kendryte-toolchain-ubuntu-amd64-8.2.0-20190409.tar.xz
endif

ifeq ($(OS), )
sdfiles: | $(SD_MNT) $(SD_BINS)
else
sdfiles: $(SD_BINS)
endif

# user: fs.img
user: fs.img
ifeq ($(COMP_MODE), HOMEMADE)
fs.img: $(BINS) $(ALL_FILES)
	mkdir $(MOUNT)
	export MOUNT=$(MOUNT) \
	&& export BIN_DIR=$(BIN_DIR) \
	&& sudo -E ./make_fs_img
else
fs.img: $(SRC_FILES) $(K210_TOOL) $(BIN_DIR) $(eval SHELL:=/bin/bash)
	export PATH=$$PWD/$(K210_TOOL):$$PATH &&\
	cd $(COMP_USER_DIR) &&\
	bash build-oscomp.sh
	cp -r $(COMP_BIN_DIR)/* $(BIN_DIR)/

	cp user_linker.ld $(PROC0_DIR)/src/user_linker.ld
	cd $(PROC0_DIR) && cargo build --bin proc0 --release
	cp $(PROC0_DIR)/target/riscv64imac-unknown-none-elf/release/proc0 $(BIN_DIR)
	rm $(PROC0_DIR)/src/user_linker.ld

	cp user_linker.ld $(SHELL_DIR)/src/user_linker.ld
	cd $(SHELL_DIR) && cargo build --bin shell --release
	cp $(SHELL_DIR)/target/riscv64imac-unknown-none-elf/release/shell $(BIN_DIR)
	rm $(SHELL_DIR)/src/user_linker.ld

	mkdir $(MOUNT)
	export MOUNT=$(MOUNT) \
	&& export BIN_DIR=$(BIN_DIR) \
	&& sudo -E ./make_fs_img
endif

$(K210_TOOL): $(K210_TOOL_ZIP)
	tar -xf $(K210_TOOL_ZIP)\

$(BIN_DIR)/%: $(SRC_DIR)/% $(BIN_DIR)
	cp user_linker.ld $</src/user_linker.ld
	cd $< && cargo build --bin $* --release
	cp $</target/riscv64imac-unknown-none-elf/release/$* $@
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
	rm -rf kendryte-toolchain

clean_usr: user_programs/*
	for file in $^; do \
		cargo clean --manifest-path $${file}/Cargo.toml; \
		rm -f $${file}/src/user_linker.ld; \
	done
	rm -rf testsuits-for-oskernel/riscv-syscalls-testing/user/build

.PHONY:
	run user clean user programs sdfiles clean_usr