typedef int int32_t;
typedef unsigned int uint32_t;
typedef long long int int64_t;
typedef unsigned long long int uint64_t;

const uint64_t SYSCALL_GETCWD        = 17;
const uint64_t SYSCALL_DUP           = 23;
const uint64_t SYSCALL_DUP3          = 24;
const uint64_t SYSCALL_MKDIRAT       = 34;
const uint64_t SYSCALL_UNLINKAT      = 35;
const uint64_t SYSCALL_LINKAT        = 37;
const uint64_t SYSCALL_UMOUNT2       = 39;
const uint64_t SYSCALL_MOUNT         = 40;
const uint64_t SYSCALL_CHDIR         = 49;
const uint64_t SYSCALL_OPENAT        = 56;
const uint64_t SYSCALL_OPEN          = 56;
const uint64_t SYSCALL_CLOSE         = 57;
const uint64_t SYSCALL_PIPE          = 59;
const uint64_t SYSCALL_PIPE2         = 59;
const uint64_t SYSCALL_GETDENTS64    = 61;
const uint64_t SYSCALL_READ          = 63;
const uint64_t SYSCALL_WRITE         = 64;
const uint64_t SYSCALL_FSTAT         = 80;
const uint64_t SYSCALL_EXIT          = 93;
const uint64_t SYSCALL_NANOSLEEP     = 101;
const uint64_t SYSCALL_SCHED_YIELD   = 124;
const uint64_t SYSCALL_TIMES         = 153;
const uint64_t SYSCALL_UNAME         = 160;
const uint64_t SYSCALL_GETTIMEOFDAY  = 169;
const uint64_t SYSCALL_GETPID        = 172;
const uint64_t SYSCALL_GETPPID       = 173;
const uint64_t SYSCALL_BRK           = 214;
const uint64_t SYSCALL_MUNMAP        = 215;
const uint64_t SYSCALL_FORK          = 220;
const uint64_t SYSCALL_EXEC          = 221;
const uint64_t SYSCALL_MMAP          = 222;
const uint64_t SYSCALL_WAITPID       = 260;
const uint64_t SYSCALL_SIGRETURN     = 139;
const uint64_t SYSCALL_SIGACTION     = 134;
const uint64_t SYSCALL_SIGPROCMASK   = 135;
const uint64_t SYSCALL_KILL          = 129;

static inline uint64_t syscall(uint64_t which, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    // cannot assign register directly, use register variable instead. Not a reliable solution, consider switching to pure asm.
	register uint64_t a0 asm ("a0") = (uint64_t)(arg0);
	register uint64_t a1 asm ("a1") = (uint64_t)(arg1);
	register uint64_t a2 asm ("a2") = (uint64_t)(arg2);
	register uint64_t a7 asm ("a7") = (uint64_t)(which);
	asm volatile ("ecall"
		: "+r" (a0)
		: "r" (a1), "r" (a2), "r" (a7)
		: "memory");
	return a0;
}

uint64_t fork() {
	return syscall(SYSCALL_FORK, 0, 0, 0);
}

uint64_t waitpid(uint64_t pid, uint64_t* exit_code_ptr) {
	return syscall(SYSCALL_WAITPID, pid, (uint64_t)exit_code_ptr, 0);
}

uint64_t yield() {
	return syscall(SYSCALL_SCHED_YIELD, 0, 0, 0);
}

void exec(const char* path, char* argv[], const char* envp[]) {
	syscall(SYSCALL_EXEC, (uint64_t)path, (uint64_t)argv, (uint64_t)envp);
}

int strlen(char* str) {
	char* iter = str;
	while (*(iter++));
	return iter - str - 1;
}

int find(char* str, char c) {
	char* iter = str;
	while (*iter && *iter != c) {iter++;};
	return iter - str;
}

void memcpy(char* src, char* dst, uint64_t len) {
	while (len --> 0) {
		*(dst++) = *(src++);
	}
}

void puts(char* str) {
	syscall(SYSCALL_WRITE, 1, (uint64_t)str, strlen(str));
}

char* commands[] = {
	// "busybox|mkdir|-p|/var/tmp",
	// "lmbench_all|lmdd|label=\"File /var/tmp/XXX write bandwidth:\"|of=/var/tmp/XXX|move=1m|fsync=1|print=3",
	"busybox|echo|START|bw_file_rd_io_only",
	// "lmbench_all|bw_file_rd|-P|1|512k|io_only|/var/tmp/XXX",
	// "busybox|echo|END|bw_file_rd|io_only|$?",
	// "busybox|echo|START|bw_file_rd_open2close",
	// "lmbench_all|bw_file_rd|-P|1|512k|open2close|/var/tmp/XXX",
	// "busybox|echo|END|bw_file_rd|open2close|$?",
	// "busybox|echo|START|lat_ctx",
	// "lmbench_all|lat_ctx|-P|1|-s|32|2|4|8|16|24|32",
	// "busybox|echo|END|lat_ctx|$?",
	// "busybox|echo|START|lat_proc_fork",
	// "lmbench_all|lat_proc|-P|1|fork",
	// "busybox|echo|END|lat_proc_fork|$?",
	// "busybox|echo|START|lat_proc_exec",
	// "lmbench_all|lat_proc|-P|1|exec",
	// "busybox|echo|END|lat_proc_exec|$?",
	// "busybox|echo|START|bw_pipe",
	// "lmbench_all|bw_pipe|-P|1",
	// "busybox|echo|END|bw_pipe|$?",
	// "busybox|echo|START|lat_pipe",
	// "lmbench_all|lat_pipe|-P|1",
	// "busybox|echo|END|lat_pipe|$?",
	// "busybox|echo|START|lat_pagefault",
	// "lmbench_all|lat_pagefault|-P|1|/var/tmp/XXX",
	// "busybox|echo|END|lat_pagefault|$?",
	// "busybox|echo|START|lat_mmap",
	// "lmbench_all|lat_mmap|-P|1|512k|/var/tmp/XXX",
	// "busybox|echo|END|lat_mmap|$?",
	0
};

const char* envp[] = {
	"PWD=/busybox",
	"LOGNAME=root",
	"_=busybox",
	"MOTD_SHOWN=pam",
	"LINES=67",
	"HOME=/",
	"LANG=zh_CN.UTF-8",
	"COLUMNS=138",
	"TERM=xterm-256color",
	"USER=root",
	"SHLVL=1",
	"PATH=/",
	"OLDPWD=/",
	0
};

char* argv[100] = {0};

void _start() {
	puts("[proc0] Started.\n");

	
	for(int i = 0; commands[i]; i++) {
		puts("[proc0] running program.\n");
		for (int j = 0; j < 100; j++) {
			argv[j] = 0;
		}
		char* cmd = commands[i];
		char name[100] = {0};
		int nxt_space = find(cmd, '|');
		memcpy(cmd, name, nxt_space);
		int j = 0;
		argv[j++] = name;
		char* argv_iter = cmd;
		while(nxt_space != strlen(argv_iter)) {
			argv_iter[nxt_space] = '\0';
			argv_iter = &(argv_iter[nxt_space + 1]);
			argv[j++] = argv_iter;
			nxt_space = find(argv_iter, '|');
		}
		if (fork() == 0) {
			// puts("[proc0] Fake exec.\n");
			exec(name, argv, envp);
		} else {
			uint64_t exit_code = 0;
			while (waitpid(-1, &exit_code) < 0) {
				yield();
			}
		}
	}
	
	puts("[proc0] All fin.\n");

	uint64_t exit_code = 0;
	while (1) {
		while (waitpid(-1, &exit_code) < 0) {
			yield();
		}
	}

	// if (fork() == 0) {
	// } else {
	// 	while (1) {
	// 		uint64_t exit_code = 0;
	// 		if (waitpid(-1, &exit_code) < 0) {
	// 			yield();
	// 		}
	// 	}
	// }
}