user:
	python build_usr.py

run: user
	make -C oshit_kernel run

debug: user
	make -C oshit_kernel debug

clean:
	make -C oshit_kernel clean

.PHONY:
	run user clean