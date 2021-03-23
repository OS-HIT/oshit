user:
	python build_usr.py

run: user
	make -C oshit_kernel run

.PHONY:
	run user