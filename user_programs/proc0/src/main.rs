// user/src/bin/initproc.rs

#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::{
    sys_fork,
    sys_waitpid,
    sys_exec,
    sys_yield,
    sys_getpid,
    sys_exit
};

const programs : &'static [&'static [u8]] = &[
    // b"/shell\0", 
    b"/brk\0", 
    b"/chdir\0",
    b"/clone\0",
    b"/close\0",
    b"/dup\0",
    b"/dup2\0",
    b"/execve\0",
    b"/exit\0",
    b"/fork\0",
    b"/fstat\0",
    b"/getcwd\0",
    b"/getdents\0",
    b"/getpid\0",
    b"/getppid\0",
    b"/gettimeofday\0",
    b"/mkdir_\0",
    b"/mmap\0",
    b"/mount\0",
    b"/munmap\0",
    b"/open\0",
    b"/openat\0",
    b"/pipe\0",
    b"/read\0",
    b"/sleep\0",
    b"/times\0",
    b"/umount\0",
    b"/uname\0",
    b"/unlink\0",
    b"/wait\0",
    b"/waitpid\0",
    b"/write\0",
    b"/yield\0"
];

#[no_mangle]
fn main() -> i32 {
    println!("[proc0] Started.");
    if sys_fork() == 0 {
        for prog in programs {
            println!("This is {}, Now execute: {}", sys_getpid(), core::str::from_utf8(prog).unwrap());
            let child = sys_fork();
            if child == 0 {
                if sys_exec(prog.as_ptr(), &[0 as *const u8], &[0 as *const u8]) == -1 {
                    println!("Exec failed. dying.");
                    sys_exit(-1);
                }
            } else {
                let mut exit_code: i32 = 0;
                sys_waitpid(child, &mut exit_code);
                println!("Finished {}", core::str::from_utf8(prog).unwrap());
            }
        }
    } else {
        loop {
            let mut exit_code: i32 = 0;
            let pid = sys_waitpid(-1, &mut exit_code);
            if pid == -1 || pid == -2{
                sys_yield();
                continue;
            } 
            println!(
                "[proc0] Released a zombie process, pid={}, exit_code={}",
                pid,
                exit_code,
            );
        }
    }
    0
}