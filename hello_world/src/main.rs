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
fn main() -> i32 {
    println!("Hello world!");

    0
}