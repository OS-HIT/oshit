import os

base_address = 0x80400000
step = 0x20000
linker = 'user_linker.ld'

app_id = 0
apps = os.listdir('.')
apps.sort()
lines_before = []
with open(linker, 'r') as f:
    for line in f.readlines():
        lines_before.append(line)

usr_bin_dir = "user_bins"

if not os.path.exists(usr_bin_dir):
    os.mkdir(usr_bin_dir)
else:
    filelist = [ f for f in os.listdir(usr_bin_dir) ]
    for f in filelist:
        os.remove(os.path.join(usr_bin_dir, f))

app_list = ["proc0", "uname_test", "systime_test", "hello_world", "shell"]

for app in apps:
    if app not in app_list:
        continue 
    lines = lines_before
    # for line in lines_before:
        # line_altered = line.replace(hex(base_address), hex(base_address+step*app_id))
        # lines.append(line_altered)
    with open(app + "/src/" + linker, 'w+') as f:
        f.writelines(lines)
    os.chdir(app)
    print("building...")
    os.system('cargo build --bin %s --release' % app)
    print("copying...")
    os.system("cp target/riscv64gc-unknown-none-elf/release/%s ../user_bins/%s" % (app, app))
    # os.system("rust-objcopy --binary-architecture=riscv64 target/riscv64gc-unknown-none-elf/release/%s --strip-all -O binary ../user_bins/%s.bin" % (app, app))
    os.chdir("..")
    print('[build.py] application %s processed' %(app))
    app_id = app_id + 1
