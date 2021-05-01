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
    sys_read
};

#[no_mangle]
fn main() -> i32 {
    println!("[shell] Start.");
    loop {
        
    }
    0
}