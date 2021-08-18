typedef int int32_t;
typedef unsigned int uint32_t;
typedef long long int int64_t;
typedef unsigned long long int uint64_t;

const int SYSCALL_GETCWD        = 17;
const int SYSCALL_DUP           = 23;
const int SYSCALL_DUP3          = 24;
const int SYSCALL_MKDIRAT       = 34;
const int SYSCALL_UNLINKAT      = 35;
const int SYSCALL_LINKAT        = 37;
const int SYSCALL_UMOUNT2       = 39;
const int SYSCALL_MOUNT         = 40;
const int SYSCALL_CHDIR         = 49;
const int SYSCALL_OPENAT        = 56;
const int SYSCALL_OPEN          = 56;
const int SYSCALL_CLOSE         = 57;
const int SYSCALL_PIPE          = 59;
const int SYSCALL_PIPE2         = 59;
const int SYSCALL_GETDENTS64    = 61;
const int SYSCALL_READ          = 63;
const int SYSCALL_WRITE         = 64;
const int SYSCALL_FSTAT         = 80;
const int SYSCALL_EXIT          = 93;
const int SYSCALL_NANOSLEEP     = 101;
const int SYSCALL_SCHED_YIELD   = 124;
const int SYSCALL_TIMES         = 153;
const int SYSCALL_UNAME         = 160;
const int SYSCALL_GETTIMEOFDAY  = 169;
const int SYSCALL_GETPID        = 172;
const int SYSCALL_GETPPID       = 173;
const int SYSCALL_BRK           = 214;
const int SYSCALL_MUNMAP        = 215;
const int SYSCALL_FORK          = 220;
const int SYSCALL_EXEC          = 221;
const int SYSCALL_MMAP          = 222;
const int SYSCALL_WAITPID       = 260;
const int SYSCALL_SIGRETURN     = 139;
const int SYSCALL_SIGACTION     = 134;
const int SYSCALL_SIGPROCMASK   = 135;
const int SYSCALL_KILL          = 129;


const int SIGHUP     =  1; 
const int SIGINT     =  2; 
const int SIGQUIT    =  3; 
const int SIGILL     =  4; 
const int SIGTRAP    =  5; 
const int SIGABRT    =  6; 
const int SIGBUS     =  7; 
const int SIGFPE     =  8; 
const int SIGKILL    =  9; 
const int SIGUSR1    = 10; 
const int SIGSEGV    = 11; 
const int SIGUSR2    = 12; 
const int SIGPIPE    = 13; 
const int SIGALRM    = 14; 
const int SIGTERM    = 15; 
const int SIGSTKFLT  = 16; 
const int SIGCHLD    = 17; 
const int SIGCONT    = 18; 
const int SIGSTOP    = 19; 
const int SIGTSTP    = 20; 
const int SIGTTIN    = 21; 
const int SIGTTOU    = 22; 
const int SIGURG     = 23; 
const int SIGXCPU    = 24; 
const int SIGXFSZ    = 25; 
const int SIGVTALRM  = 26; 
const int SIGPROF    = 27; 
const int SIGWINCH   = 28; 
const int SIGIO      = 29; 
const int SIGPWR     = 30; 
const int SIGSYS     = 31; 
const int SIGRTMIN	 = 34;
const int SIGRTMAX	 = 64;

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

// char* commands[] = {
// 	"busybox echo latency measurements",
// 	"lmbench_all lat_syscall -P 1 null",
// 	"lmbench_all lat_syscall -P 1 read",
// 	"lmbench_all lat_syscall -P 1 write",
// 	"busybox mkdir -p /var/tmp",
// 	"busybox touch /var/tmp/lmbench",
// 	"lmbench_all lat_syscall -P 1 stat /var/tmp/lmbench",
// 	"lmbench_all lat_syscall -P 1 fstat /var/tmp/lmbench",
// 	"lmbench_all lat_syscall -P 1 open /var/tmp/lmbench",
// 	"lmbench_all lat_select -n 100 -P 1 file",
// 	"lmbench_all lat_sig -P 1 install",
// 	"lmbench_all lat_sig -P 1 catch",
// 	"lmbench_all lat_sig -P 1 prot lat_sig",
// 	"lmbench_all lat_pipe -P 1",
// 	"lmbench_all lat_proc -P 1 fork",
// 	"lmbench_all lat_proc -P 1 exec",
// 	"busybox cp hello /tmp",
// 	"lmbench_all lat_proc -P 1 shell",
// 	"lmbench_all lmdd label=\"File /var/tmp/XXX write bandwidth:\" of=/var/tmp/XXX move=645m fsync=1 print=3",
// 	"lmbench_all lat_pagefault -P 1 /var/tmp/XXX",
// 	"lmbench_all lat_mmap -P 1 512k /var/tmp/XXX",
// 	"busybox echo file system latency",
// 	"lmbench_all lat_fs /var/tmp",
// 	"busybox echo Bandwidth measurements",
// 	"lmbench_all bw_pipe -P 1",
// 	"lmbench_all bw_file_rd -P 1 512k io_only /var/tmp/XXX",
// 	"lmbench_all bw_file_rd -P 1 512k open2close /var/tmp/XXX",
// 	"lmbench_all bw_mmap_rd -P 1 512k mmap_only /var/tmp/XXX",
// 	"lmbench_all bw_mmap_rd -P 1 512k open2close /var/tmp/XXX",
// 	"busybox echo context switch overhead",
// 	"lmbench_all lat_ctx -P 1 -s 32 2 4 8 16 24 32 64 96",
// 	0
// };

// const char* envp[] = {
// 	"PWD=/busybox",
// 	"LOGNAME=root",
// 	"_=busybox",
// 	"MOTD_SHOWN=pam",
// 	"LINES=67",
// 	"HOME=/",
// 	"LANG=zh_CN.UTF-8",
// 	"COLUMNS=138",
// 	"TERM=xterm-256color",
// 	"USER=root",
// 	"SHLVL=1",
// 	"PATH=/",
// 	"OLDPWD=/",
// 	0
// };

typedef struct t_sigaction {
	void (*sa_handler)(int);
	unsigned long sigset_t;
	int sa_flags;
} sigaction;

uint64_t set_alarm(void (*alarm_fp)(int)) {
	sigaction sa = {
		alarm_fp,
		0,
		1
	};
	return syscall(SYSCALL_SIGACTION, SIGALRM, &sa, 0);
}

void sigreturn() {
	syscall(SYSCALL_SIGRETURN, 0, 0, 0);
}

void alarm(int input) {
	puts("Alarm triggered!!!\n");
	sigreturn();
}

uint64_t kill(int signal) {
	return syscall(SYSCALL_KILL, 0, signal, 0);
}

uint64_t exit(int code) {
	return syscall(SYSCALL_EXIT, code, 0, 0);
}

char* argv[100] = {0};

void _start() {
	puts("[proc0] Started.\n");

	if (fork() == 0) {
		if (!set_alarm(alarm)) {
			puts("set good\n");
			while(1);
		}
		exit(-1);
	} else {
		while (1) {
			kill(SIGALRM);
			uint64_t exit_code = 0;
			if (waitpid(-1, &exit_code) < 0) {
				yield();
			}
		}
	}
}