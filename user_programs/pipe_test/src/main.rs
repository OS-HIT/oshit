#![no_std]
#![no_main]

#[macro_use]
extern crate oshit_usrlib;

use oshit_usrlib::{
    sys_pipe,
    sys_fork,
    sys_close,
    read,
    wait,
    sys_write
};

static STR: &str = "Hello, world!";

#[no_mangle]
fn main() -> i32 { 
    println!("Running: pipe_test.");
    let mut pipe_fd = [0usize; 2];
    println!("Createing pipe.");
    sys_pipe(&mut pipe_fd);
    // read end
    // assert_eq!(pipe_fd[0], 3);
    // write end
    // assert_eq!(pipe_fd[1], 4);
    println!("Created pipe, fd = 3 & 4.");
    if sys_fork() == 0 {
        println!("Forked, hello from child.");
        // child process, read from parent
        // close write_end
        sys_close(pipe_fd[1]);
        println!("child write end closed.");
        let mut buffer = [0u8; 32];
        println!("child trying to read...");
        let len_read = read(pipe_fd[0], &mut buffer) as usize;
        println!("child read success.");
        // close read_end
        sys_close(pipe_fd[0]);
        assert_eq!(core::str::from_utf8(&buffer[..len_read]).unwrap(), STR);
        println!("Read OK, child process exited!");
    } else {
        println!("Forked, hello from parent.");
        // parent process, write to child
        // close read end
        println!("parent read end closed.");
        sys_close(pipe_fd[0]);
        println!("parent trying to write...");
        sys_write(pipe_fd[1], STR.as_bytes());
        // assert_eq!(sys_write(pipe_fd[1], STR.as_bytes()), STR.len() as isize);
        println!("parent write complete.");
        // close write end
        sys_close(pipe_fd[1]);
        let mut child_exit_code: i32 = 0;
        wait(&mut child_exit_code);
        assert_eq!(child_exit_code, 0);
        println!("pipetest passed!");
    }
    0
}