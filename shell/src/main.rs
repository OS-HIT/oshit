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
    sys_read,
    sys_write,
    FD_STDIN,
    FD_STDOUT,
};

#[no_mangle]
fn main() -> i32 {
    println!("[shell] Start.");
    loop {
        print!(">> ");
        let mut buf = [0u8;200];
        let mut i = 0;
        loop {
            let mut c = [0u8; 2];
            sys_read(FD_STDIN, c.as_ptr(), 1);
            print!("{}", c[0] as char);
            if c[0] == 13 {
                println!("");
                for ch in buf.iter() {
                    print!("{}", *ch as char);
                }
                println!("");
                break;
            } else {
                buf[i] = c[0];
                i += 1;
            }
        }
        let pid = sys_fork();
        if pid == 0 {
            sys_exec(buf.as_ptr());
        } else {
            let mut exit_code: i32 = 0;
            loop {
                if sys_waitpid(pid, &mut exit_code) > 0 {
                    println!("Finished with code {}.", exit_code);
                    break;
                }
            }
        }
    }
    0
}