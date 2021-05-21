#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::{
    sys_uname,
    UTSName
};
use core::slice::from_raw_parts;

#[no_mangle]
fn main(argc: usize, argv: &[&str], envp: &[&str]) -> i32 {
    println!("Hello world!");
    for (idx, arg) in argv.iter().enumerate() {
        println!("Args[{}]: {}", idx, arg);
    }
    for (idx, arg) in envp.iter().enumerate() {
        println!("Envs[{}]: {}", idx, arg);
    }
    0
}