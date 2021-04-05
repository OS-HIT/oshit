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

if not os.path.exists("user_bins"):
    os.mkdir("user_bins")

for app in apps:
    if app[:4] != "usr_":
        continue 
    lines = lines_before
    # for line in lines_before:
        # line_altered = line.replace(hex(base_address), hex(base_address+step*app_id))
        # lines.append(line_altered)
    with open(app + "/src/" + linker, 'w+') as f:
        f.writelines(lines)
    os.chdir(app)
    os.system('cargo build --bin %s --release' % app)
    os.system("cp target/riscv64gc-unknown-none-elf/release/%s ../user_bins/%s" % (app, app))
    # os.system("rust-objcopy --binary-architecture=riscv64 target/riscv64gc-unknown-none-elf/release/%s --strip-all -O binary ../user_bins/%s.bin" % (app, app))
    os.chdir("..")
    print('[build.py] application %s start with address %s' %(app, hex(base_address+step*app_id)))
    app_id = app_id + 1
