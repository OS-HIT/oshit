#![no_std]
#![no_main]
#![feature(asm)]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::{
    sys_time,
    TMS
};

#[no_mangle]
fn main() -> i32 {
    for _i in 0..10 {
        let mut t: TMS = TMS{
            tms_utime   : 0,
            tms_stime   : 0,
            tms_cutime  : 0,
            tms_cstime  : 0,
        };
        println!("\rCurrent tick: {:>20}; S Time: {:>20}; U Time: {:>20};", sys_time(&mut t), t.tms_stime, t.tms_utime);
    }

    0
}