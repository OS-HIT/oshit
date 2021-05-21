// user/src/bin/initproc.rs

#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use core::slice::from_raw_parts;

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
        let mut argc = [[0u8; 20]; 20];
        let mut i = 0;
        'inner: loop {
            let mut c = [0u8; 2];
            sys_read(FD_STDIN, c.as_ptr(), 1);
            match c[0] {
                13 => {
                    println!("");
                    break 'inner;
                },
                27 => {
                    sys_read(FD_STDIN, c.as_ptr(), 1);
                    if c[0] != b'[' {
                        continue 'inner;
                    } else {
                        sys_read(FD_STDIN, c.as_ptr(), 1);
                        match c[0] {
                            b'D' => {
                                print!("\x1b[1D");
                                i -= 1;
                            }
                            b'C' => {
                                print!("\x1b[1C");
                                i += 1;
                            }
                            _ => continue 'inner,
                        }
                    }
                },
                127 => {
                    buf[i-1..200].rotate_left(1);
                    buf[199] = 0;
                    i -= 1;
                    print!("\x1b[1D\x1b[0K");
                    for ch in buf[i..].iter() {
                        print!("{}", *ch as char);
                        if *ch == 0u8 {break;}
                    }
                    print!("\x1b[{}G", i + 4);
                },
                other => {
                    buf[i..199].rotate_right(1);
                    buf[i] = other;
                    print!("\x1b[0K");
                    for ch in buf[i..].iter() {
                        print!("{}", *ch as char);
                        if *ch == 0u8 {break;}
                    }
                    print!("\x1b[{}G", i + 5);
                    i += 1;
                }
            }
        }
        let mut s = core::str::from_utf8(&buf).unwrap();
        let mut name = [0u8;200];
        let mut args = [0 as *const u8; 20];
        if let Some(pos) = s.find(' ') {
            name[..pos].copy_from_slice(s[..pos].as_bytes());
            let mut i = 0;
            loop {
                if let Some(n_pos) = s.find(' ') {
                    argc[i][..n_pos].copy_from_slice(&s[..n_pos].as_bytes());
                    argc[i][n_pos] = b'\0';
                    s = &s[n_pos + 1..];
                    args[i] = argc[i].as_ptr() as *const u8;
                    i += 1;
                } else {
                    break;
                }
            }
            argc[i][..s.find('\0').unwrap()].copy_from_slice(&s[..s.find('\0').unwrap()].as_bytes());
            argc[i][s.find('\0').unwrap()] = b'\0';
            args[i] = argc[i].as_ptr() as *const u8;
        } else {
            name[..s.as_bytes().len()].copy_from_slice(s.as_bytes());
        }
        
        let pid = sys_fork();
        if pid == 0 {
            sys_exec(name.as_ptr(), &args, &[0 as *const u8]);
        } else {
            let mut exit_code: i32 = 0;
            loop {
                if sys_waitpid(pid, &mut exit_code) > 0 {
                    println!("Process finished with code {}.", exit_code);
                    break;
                }
            }
        }
    }
    0
}