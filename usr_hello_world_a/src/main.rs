#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::sys_yield;

const HEIGHT: usize = 20;

#[no_mangle]
fn main() -> i32 {
    for i in 0..HEIGHT {
        print!("测试A，重复输出一个一定长度的字符串。");
        println!(" [{}/{}]", i + 1, HEIGHT);
        // sys_yield();
    }
    println!("Test write_a OK!");
    0
}