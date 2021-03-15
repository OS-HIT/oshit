#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::sys_yield;

const HEIGHT: usize = 5;

#[no_mangle]
fn main() -> i32 {
    for i in 0..HEIGHT {
        print!("测试B，重复输出另一个字符串。");
        println!(" [{}/{}]", i + 1, HEIGHT);
        sys_yield();
    }
    println!("Test write_a OK!");
    0
}