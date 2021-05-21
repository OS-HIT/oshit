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
};

#[no_mangle]
fn main() -> i32 {
    println!("[proc0] Started.");
    if sys_fork() == 0 {
        sys_exec(b"/shell\0".as_ptr(), &[0 as *const u8], &[0 as *const u8]);
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