#!/bin/bash

# Farben
GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}[*] Starte Installation...${RESET}"

# Pakete installieren
pkg update -y && pkg upgrade -y
pkg install -y python python2 python3 apache2 wget curl zip unzip

# Ordnerstruktur
mkdir -p ~/commands
mkdir -p ~/downloads
mkdir -p ~/user

# start.py erstellen
cat > ~/start.py << 'EOF'
import os
import time
import zipfile
import urllib.request

USER_FILE = os.path.expanduser("~/user/user.py")
COMMANDS_DIR = os.path.expanduser("~/commands")
DOWNLOADS_DIR = os.path.expanduser("~/downloads")

def set_prompt(username):
    bashrc_path = os.path.expanduser("~/.bashrc")
    prompt = f"PS1='┌──({username}@JoSte13)─[\\w]\\n└─$ '\n"
    with open(bashrc_path, "a") as f:
        f.write("\n# Custom Prompt\n" + prompt)

def create_account():
    os.system("clear")
    print("_      ____  _       _ _____")
    username = input("Name: ")
    password = input("Password: ")
    with open(USER_FILE, "w") as f:
        f.write(f"USERNAME = '{username}'\nPASSWORD = '{password}'\n")
    set_prompt(username)
    print("[*] Account erstellt!")
    time.sleep(1)

def load_from_link():
    os.system("clear")
    print("_      ____  _       _ _____")
    link = input("Link: ")
    zip_path = os.path.join(DOWNLOADS_DIR, "system.zip")
    urllib.request.urlretrieve(link, zip_path)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(os.path.expanduser("~"))
    print("[*] System geladen!")
    time.sleep(1)

def main_menu():
    while True:
        os.system("clear")
        print("_      ____  _       _ _____")
        print("1. new account")
        print("2. from link")
        choice = input("\nchoose from: ")
        if choice == "1":
            create_account()
            break
        elif choice == "2":
            load_from_link()
            break
        else:
            print("Ungültige Eingabe!")
            time.sleep(1)

if __name__ == "__main__":
    main_menu()
EOF

# Standardbefehle erstellen
cat > ~/commands/help.py << 'EOF'
import os
print("help - zeigt diese Hilfe")
print("cnc - create new command")
print("cun - change user name")
print("cup - change password")
print("ssal - save system as link")
EOF

cat > ~/commands/cnc.py << 'EOF'
import os
name = input("name: ")
desc = input("description: ")
file_name = input("file name: ")
cmd_path = os.path.expanduser(f"~/commands/{file_name}.py")
with open(cmd_path, "w") as f:
    f.write("print('Custom Command ausgeführt')\n")
print(f"[+] Command {name} erstellt!")
EOF

cat > ~/commands/cun.py << 'EOF'
import os
USER_FILE = os.path.expanduser("~/user/user.py")
new_name = input("new user name: ")
lines = []
with open(USER_FILE, "r") as f:
    for line in f:
        if line.startswith("USERNAME"):
            lines.append(f"USERNAME = '{new_name}'\n")
        else:
            lines.append(line)
with open(USER_FILE, "w") as f:
    f.writelines(lines)
print("[*] Benutzername geändert. Bitte neu starten!")
EOF

cat > ~/commands/cup.py << 'EOF'
import os
USER_FILE = os.path.expanduser("~/user/user.py")
new_pw = input("new password: ")
lines = []
with open(USER_FILE, "r") as f:
    for line in f:
        if line.startswith("PASSWORD"):
            lines.append(f"PASSWORD = '{new_pw}'\n")
        else:
            lines.append(line)
with open(USER_FILE, "w") as f:
    f.writelines(lines)
print("[*] Passwort geändert!")
EOF

cat > ~/commands/ssal.py << 'EOF'
import os
import zipfile
import getpass

USER_FILE = os.path.expanduser("~/user/user.py")
with open(USER_FILE, "r") as f:
    exec(f.read())

password_check = getpass.getpass("Passwort: ")
if password_check != PASSWORD:
    print("Falsches Passwort!")
    exit()

zip_path = os.path.expanduser("~/system_backup.zip")
with zipfile.ZipFile(zip_path, 'w') as zipf:
    for foldername, subfolders, filenames in os.walk(os.path.expanduser("~")):
        for filename in filenames:
            file_path = os.path.join(foldername, filename)
            zipf.write(file_path, os.path.relpath(file_path, os.path.expanduser("~")))
print(f"Backup gespeichert unter: {zip_path}")
EOF

echo -e "${GREEN}[*] Installation abgeschlossen. Starte System...${RESET}"
sleep 1
python3 ~/start.py
