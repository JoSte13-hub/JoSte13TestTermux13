#!/bin/bash

GREEN="\e[32m"
RESET="\e[0m"

clear_title() {
  clear
  width=$(tput cols 2>/dev/null || echo 80)
  title="     _      ____  _       _ _____
    | | ___/ ___|| |_ ___/ |___ /
 _  | |/ _ \___ \| __/ _ \ | |_ \\
| |_| | (_) |__) | ||  __/ |___) |
 \___/ \___/____/ \__\___|_|____/"
  while IFS= read -r line; do
    printf "%*s%s\n" $(((width + ${#line}) / 2)) "" "$line"
  done <<< "$title"
  echo
}

echo -e "${GREEN}[*] Starting installation...${RESET}"

pkg update -y && pkg upgrade -y
pkg install -y python python2 python3 apache2 wget curl zip unzip

mkdir -p ~/commands
mkdir -p ~/downloads
mkdir -p ~/user

USER_FILE=~/user/user.py
COMMANDS_LIST=~/commands/commands_list.txt

cat > "$COMMANDS_LIST" << EOF
help - show this help - help.py
cnc - create new command - cnc.py
cun - change user name - cun.py
cup - change password - cup.py
ssal - save system as backup zip - ssal.py
EOF

cat > ~/start.py << 'EOF'
import os
import sys
import time
import subprocess
import getpass
import shutil
import zipfile

try:
    import readline
except ImportError:
    pass

import atexit

histfile = os.path.expanduser("~/.jo_ste13_history")
try:
    readline.read_history_file(histfile)
except FileNotFoundError:
    pass

atexit.register(readline.write_history_file, histfile)

USER_FILE = os.path.expanduser("~/user/user.py")
COMMANDS_DIR = os.path.expanduser("~/commands")
COMMANDS_LIST_FILE = os.path.expanduser("~/commands/commands_list.txt")
DOWNLOADS_DIR = os.path.expanduser("~/downloads")
HOME_DIR = os.path.expanduser("~")

def clear():
    os.system("clear")

def load_user():
    if not os.path.exists(USER_FILE):
        return None, None
    user = {}
    with open(USER_FILE, "r") as f:
        exec(f.read(), user)
    return user.get("USERNAME"), user.get("PASSWORD")

def save_user(username, password):
    with open(USER_FILE, "w") as f:
        f.write(f"USERNAME = '{username}'\nPASSWORD = '{password}'\n")

def load_commands():
    commands = {}
    if not os.path.exists(COMMANDS_LIST_FILE):
        return commands
    with open(COMMANDS_LIST_FILE, "r") as f:
        for line in f:
            line=line.strip()
            if not line:
                continue
            parts = line.split(" - ")
            if len(parts) != 3:
                continue
            name, desc, filename = parts
            commands[name] = {"desc": desc, "file": os.path.join(COMMANDS_DIR, filename)}
    return commands

def run_command(cmd_name, commands):
    if cmd_name not in commands:
        print(f"Unknown command: {cmd_name}")
        return
    path = commands[cmd_name]["file"]
    if not os.path.exists(path):
        print(f"Command file not found: {path}")
        return
    try:
        with open(path, "r") as f:
            code = f.read()
        exec(code, globals())
    except Exception as e:
        print(f"Error executing {cmd_name}: {e}")

def create_account():
    clear()
    print_title()
    username = input("Enter username: ")
    password = getpass.getpass("Enter password: ")
    save_user(username, password)
    clear()
    print("[*] Account created!")
    time.sleep(1)
    clear()
    return username

def load_from_zip():
    clear()
    print_title()
    print("Available ZIP files in your home directory:")
    files = [f for f in os.listdir(HOME_DIR) if f.endswith(".zip")]
    if not files:
        print("No ZIP files found.")
        time.sleep(2)
        return None
    for i, file in enumerate(files, 1):
        print(f"{i}. {file}")
    choice = input("Enter the number of the ZIP to load: ")
    try:
        index = int(choice) - 1
        if index < 0 or index >= len(files):
            print("Invalid selection.")
            time.sleep(2)
            return None
    except:
        print("Invalid input.")
        time.sleep(2)
        return None
    zip_path = os.path.join(HOME_DIR, files[index])

    temp_dir = os.path.expanduser("~/temp_restore")
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
    except Exception as e:
        print(f"Error extracting ZIP: {e}")
        time.sleep(2)
        return None

    user_py_path = os.path.join(temp_dir, "user/user.py")
    if not os.path.exists(user_py_path):
        print("No user.py found inside ZIP!")
        shutil.rmtree(temp_dir)
        time.sleep(2)
        return None

    user_data = {}
    with open(user_py_path, "r") as f:
        exec(f.read(), user_data)
    original_password = user_data.get("PASSWORD", "")
    original_username = user_data.get("USERNAME", "")

    pw_attempt = getpass.getpass("Enter password to decrypt: ")
    if pw_attempt != original_password:
        print("Wrong password! Cleaning temp files...")
        shutil.rmtree(temp_dir)
        time.sleep(2)
        return None

    def copytree(src, dst):
        for item in os.listdir(src):
            s = os.path.join(src, item)
            d = os.path.join(dst, item)
            if os.path.isdir(s):
                if not os.path.exists(d):
                    os.makedirs(d)
                copytree(s, d)
            else:
                shutil.copy2(s, d)

    copytree(temp_dir, HOME_DIR)
    shutil.rmtree(temp_dir)
    print(f"System loaded from ZIP '{files[index]}'. Welcome {original_username}!")
    time.sleep(2)
    return original_username

def main_menu():
    while True:
        clear()
        print_title()
        print("1. Create new account")
        print("2. Load from ZIP backup")
        choice = input("\nChoose (1 or 2): ")
        if choice == "1":
            user = create_account()
            return user
        elif choice == "2":
            user = load_from_zip()
            if user:
                return user
            else:
                print("Loading failed. Try again.")
                time.sleep(2)
        else:
            print("Invalid input!")
            time.sleep(1)

def print_help(commands):
    print("Available commands:")
    for name, data in commands.items():
        print(f"{name} - {data['desc']}")

def format_path(path):
    home = HOME_DIR
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        rel = path[len(home) + 1:]
        parts = rel.split("/")
        if len(parts) < 3:
            return "~/" + "/".join(parts)
        else:
            return "/".join(parts[-3:])
    else:
        parts = path.strip("/").split("/")
        if len(parts) > 3:
            parts = parts[-3:]
        return "/".join(parts)

def print_title():
    title = """
     _      ____  _       _ _____
    | | ___/ ___|| |_ ___/ |___ /
 _  | |/ _ \___ \| __/ _ \ | |_ \\
| |_| | (_) |__) | ||  __/ |___) |
 \___/ \___/____/ \__\___|_|____/
"""
    print("\033[92m" + title + "\033[0m")

def interactive_shell(username, commands):
    while True:
        try:
            cwd_display = format_path(os.getcwd())
            inp = input(f"\033[32m┌──(\033[34m{username}@JoSte13\033[32m)─[\033[37m{cwd_display}\033[32m]\n└─\033[34m$ \033[0m").strip()
            if inp == "":
                continue
            if inp == "exit":
                print("Bye!")
                break
            elif inp == "help":
                print_help(commands)
            elif inp.startswith("cd "):
                try:
                    path = inp[3:].strip()
                    if path == "":
                        path = HOME_DIR
                    os.chdir(os.path.expanduser(path))
                except FileNotFoundError:
                    print(f"Directory not found: {path}")
                except Exception as e:
                    print(f"Error on cd: {e}")
            elif inp in commands:
                run_command(inp, commands)
                # Nach cnc Befehl Befehle neu laden, damit neuer Befehl erkannt wird
                if inp == "cnc":
                    commands = load_commands()
                # Nach cun Befehl den Benutzernamen neu laden
                elif inp == "cun":
                    new_username, _ = load_user()
                    if new_username:
                        username = new_username
            else:
                try:
                    subprocess.run(inp, shell=True)
                except Exception as e:
                    print(f"Error executing shell command: {e}")
        except KeyboardInterrupt:
            print("\nUse 'exit' to quit.")
        except Exception as e:
            print(f"Error: {e}")

def main():
    username, password = load_user()
    if username is None:
        username = main_menu()
    commands = load_commands()
    clear()
    print(f"Welcome, {username}!")
    interactive_shell(username, commands)

if __name__ == "__main__":
    main()
EOF

# help.py
cat > ~/commands/help.py << 'EOF'
commands_list_file = os.path.expanduser("~/commands/commands_list.txt")
with open(commands_list_file, "r") as f:
    for line in f:
        line=line.strip()
        if not line:
            continue
        name, desc, _ = line.split(" - ")
        print(f"{name} - {desc}")
EOF

# cnc.py
cat > ~/commands/cnc.py << 'EOF'
import os
commands_list_file = os.path.expanduser("~/commands/commands_list.txt")

name = input("Name: ")
desc = input("Description: ")
file_name = input("File Name (existing file in commands/, e.g. command.py): ")

cmd_path = os.path.expanduser(f"~/commands/{file_name}")
if not os.path.exists(cmd_path):
    print("[!] File does not exist! Please create it in the commands folder first.")
    exit()

exists = False
with open(commands_list_file, "r") as f:
    for line in f:
        if line.startswith(name + " -"):
            exists = True
            break

if exists:
    print("[!] Command already exists!")
    exit()

with open(commands_list_file, "a") as f:
    f.write(f"{name} - {desc} - {file_name}\n")

print(f"[+] Command '{name}' added!")
EOF

# cun.py
cat > ~/commands/cun.py << 'EOF'
import os
USER_FILE = os.path.expanduser("~/user/user.py")

new_name = input("New user name: ")

lines = []
with open(USER_FILE, "r") as f:
    for line in f:
        if line.startswith("USERNAME"):
            lines.append(f"USERNAME = '{new_name}'\n")
        else:
            lines.append(line)
with open(USER_FILE, "w") as f:
    f.writelines(lines)

print("[*] Username changed!")
EOF

# cup.py
cat > ~/commands/cup.py << 'EOF'
import os
USER_FILE = os.path.expanduser("~/user/user.py")

new_pw = input("New password: ")
lines = []
with open(USER_FILE, "r") as f:
    for line in f:
        if line.startswith("PASSWORD"):
            lines.append(f"PASSWORD = '{new_pw}'\n")
        else:
            lines.append(line)
with open(USER_FILE, "w") as f:
    f.writelines(lines)
print("[*] Password changed!")
EOF

# ssal.py
cat > ~/commands/ssal.py << 'EOF'
import os
import zipfile

USER_FILE = os.path.expanduser("~/user/user.py")
with open(USER_FILE, "r") as f:
    exec(f.read())

zip_name = f"user-{USERNAME}-joste13.zip"
zip_path = os.path.expanduser(f"~/downloads/{zip_name}")

home = os.path.expanduser("~")
downloads_dir = os.path.expanduser("~/downloads")

with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for foldername, subfolders, filenames in os.walk(home):
        for filename in filenames:
            if foldername.startswith(downloads_dir) and filename == zip_name:
                continue
            zipf.write(os.path.join(foldername, filename), os.path.relpath(os.path.join(foldername, filename), home))

print(f"Backup saved: {zip_path}")
EOF

echo -e "${GREEN}[*] Installation completed.${RESET}"

rm -- "$0"

python3 ~/start.py
