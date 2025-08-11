#!/bin/bash

# Farben
GREEN="\e[32m"
BLUE="\e[34m"
WHITE="\e[37m"
RESET="\e[0m"

echo -e "${GREEN}[*] Starte Installation...${RESET}"

# Pakete installieren
pkg update -y && pkg upgrade -y
pkg install -y python python2 python3 apache2 wget curl zip unzip

# Ordnerstruktur erstellen
mkdir -p ~/commands
mkdir -p ~/downloads
mkdir -p ~/user

# user.py Pfad
USER_FILE=~/user/user.py

# start.py schreiben
cat > ~/start.py << 'EOF'
import os
import time
import zipfile
import urllib.request

USER_FILE = os.path.expanduser("~/user/user.py")
COMMANDS_DIR = os.path.expanduser("~/commands")
DOWNLOADS_DIR = os.path.expanduser("~/downloads")
BASHRC_PATH = os.path.expanduser("~/.bashrc")

def clear():
    os.system("clear")

def write_user(username, password):
    with open(USER_FILE, "w") as f:
        f.write(f"USERNAME = '{username}'\nPASSWORD = '{password}'\n")

def load_user():
    if not os.path.exists(USER_FILE):
        return None, None
    user = {}
    with open(USER_FILE, "r") as f:
        exec(f.read(), user)
    return user.get("USERNAME"), user.get("PASSWORD")

def set_prompt(username):
    prompt = f"PS1='\\[\\e[32m\\]┌──(\\[\\e[34m\\]{username}@JoSte13\\[\\e[32m\\])─[\\[\\e[37m\\]\\w\\[\\e[32m\\]]\\n\\[\\e[32m\\]└─\\[\\e[34m\\]$\\[\\e[0m\\] '\n"
    # Lade ~/.bashrc neu, entferne alte PS1 Einträge davor
    if os.path.exists(BASHRC_PATH):
        lines = []
        with open(BASHRC_PATH, "r") as f:
            for line in f:
                if "PS1=" not in line:
                    lines.append(line)
        lines.append("# Custom prompt for JoSte13 system\n")
        lines.append(prompt)
        with open(BASHRC_PATH, "w") as f:
            f.writelines(lines)
    else:
        with open(BASHRC_PATH, "w") as f:
            f.write(prompt)

def create_account():
    clear()
    username = input("Name: ")
    password = input("Password: ")
    write_user(username, password)
    set_prompt(username)
    clear()
    print("[*] Account erstellt!")

def load_from_link():
    clear()
    link = input("Link: ")
    zip_path = os.path.join(DOWNLOADS_DIR, "system.zip")
    try:
        urllib.request.urlretrieve(link, zip_path)
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(os.path.expanduser("~"))
        print("[*] System geladen!")
    except Exception as e:
        print(f"Fehler beim Laden: {e}")
    time.sleep(1)
    clear()

def main_menu():
    while True:
        clear()
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
file_name = input("file name (ohne .py): ")
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
# Prompt aktualisieren
bashrc = os.path.expanduser("~/.bashrc")
lines = []
with open(bashrc, "r") as f:
    for line in f:
        if "PS1=" not in line:
            lines.append(line)
prompt = f"PS1='\\[\\e[32m\\]┌──(\\[\\e[34m\\]{new_name}@JoSte13\\[\\e[32m\\])─[\\[\\e[37m\\]\\w\\[\\e[32m\\]]\\n\\[\\e[32m\\]└─\\[\\e[34m\\]$\\[\\e[0m\\] '\n"
lines.append("# Custom prompt for JoSte13 system\n")
lines.append(prompt)
with open(bashrc, "w") as f:
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

# Prompt für aktuellen User setzen, falls vorhanden
if [ -f "$USER_FILE" ]; then
  USERNAME=$(grep USERNAME "$USER_FILE" | cut -d"'" -f2)
  if [ ! -z "$USERNAME" ]; then
    # Alte PS1 aus .bashrc entfernen
    grep -v "PS1=" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
    echo "PS1='\\[\\e[32m\\]┌──(\\[\\e[34m\\]${USERNAME}@JoSte13\\[\\e[32m\\])─[\\[\\e[37m\\]\\w\\[\\e[32m\\]]\\n\\[\\e[32m\\]└─\\[\\e[34m\\]\\$\\[\\e[0m\\] '" >> ~/.bashrc
  fi
fi

echo -e "${GREEN}[*] Installation abgeschlossen. Starte System...${RESET}"

# Installations-Skript löschen
rm -- "$0"

# start.py ausführen
python3 ~/start.py
