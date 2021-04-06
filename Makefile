user:
	python build_usr.py

run: user
	make -C oshit_kernel run

debug: user
	make -C oshit_kernel debug

.PHONY:
	run user