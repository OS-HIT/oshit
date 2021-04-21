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
    let sysname    : *const u8 = [0u8;100].as_mut_ptr();
    let nodename   : *const u8 = [0u8;100].as_mut_ptr();
    let release    : *const u8 = [0u8;100].as_mut_ptr();
    let version    : *const u8 = [0u8;100].as_mut_ptr();
    let machine    : *const u8 = [0u8;100].as_mut_ptr();
    let domainname : *const u8 = [0u8;100].as_mut_ptr();

    let mut uts: UTSName = UTSName {
        sysname   ,
        nodename  ,
        release   ,
        version   ,
        machine   ,
        domainname,
    };

    sys_uname(&mut uts);

    unsafe {
        println!("sysname   : {}", core::str::from_utf8(from_raw_parts(sysname   , 100)).unwrap());
        println!("nodename  : {}", core::str::from_utf8(from_raw_parts(nodename  , 100)).unwrap());
        println!("release   : {}", core::str::from_utf8(from_raw_parts(release   , 100)).unwrap());
        println!("version   : {}", core::str::from_utf8(from_raw_parts(version   , 100)).unwrap());
        println!("machine   : {}", core::str::from_utf8(from_raw_parts(machine   , 100)).unwrap());
        println!("domainname: {}", core::str::from_utf8(from_raw_parts(domainname, 100)).unwrap());
    }

    0
}