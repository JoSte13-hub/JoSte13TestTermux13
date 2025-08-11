#!/bin/bash

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

USER_FILE=~/user/user.py
COMMANDS_LIST=~/commands/commands_list.txt
BASHRC=~/.bashrc

# Lege commands_list.txt mit Standardbefehlen an
cat > "$COMMANDS_LIST" << EOF
help - zeigt diese Hilfe - help.py
cnc - create new command - cnc.py
cun - change user name - cun.py
cup - change password - cup.py
ssal - save system as link - ssal.py
EOF

# start.py erstellen
cat > ~/start.py << 'EOF'
import os
import time
import zipfile
import urllib.request

USER_FILE = os.path.expanduser("~/user/user.py")
COMMANDS_LIST = os.path.expanduser("~/commands/commands_list.txt")
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
    # Alte PS1-Einträge aus .bashrc entfernen
    lines = []
    if os.path.exists(BASHRC_PATH):
        with open(BASHRC_PATH, "r") as f:
            for line in f:
                if "PS1=" not in line and "Custom prompt for JoSte13" not in line:
                    lines.append(line)
    lines.append("\n# Custom prompt for JoSte13 system\n")
    lines.append(prompt)
    with open(BASHRC_PATH, "w") as f:
        f.writelines(lines)
    # Aliase updaten
    update_command_aliases()
    # source ~/.bashrc (in Subshell, evtl. nicht sofort sichtbar)
    os.system("source ~/.bashrc")

def update_command_aliases():
    bashrc_path = BASHRC_PATH
    # Alte Aliase zwischen Markern entfernen
    lines = []
    in_block = False
    if os.path.exists(bashrc_path):
        with open(bashrc_path, "r") as f:
            for line in f:
                if line.strip() == "# COMMAND ALIASES START":
                    in_block = True
                    continue
                if line.strip() == "# COMMAND ALIASES END":
                    in_block = False
                    continue
                if not in_block:
                    lines.append(line)
    lines.append("# COMMAND ALIASES START\n")
    if os.path.exists(COMMANDS_LIST):
        with open(COMMANDS_LIST, "r") as f:
            for line in f:
                if line.strip():
                    parts = line.strip().split(" - ")
                    if len(parts) == 3:
                        name, _, file_name = parts
                        cmd_path = os.path.expanduser(f"~/commands/{file_name}")
                        lines.append(f"alias {name}='python3 {cmd_path}'\n")
    lines.append("# COMMAND ALIASES END\n")
    with open(bashrc_path, "w") as f:
        f.writelines(lines)

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

# cnc.py - erstellt nur Zuordnung, keine Datei!
cat > ~/commands/cnc.py << 'EOF'
import os
commands_list_file = os.path.expanduser("~/commands/commands_list.txt")

name = input("Name: ")
desc = input("Description: ")
file_name = input("File Name (existierende Datei in commands/, z.B. befehl.py): ")

# Prüfen ob Datei existiert
cmd_path = os.path.expanduser(f"~/commands/{file_name}")
if not os.path.exists(cmd_path):
    print("[!] Datei existiert nicht! Bitte erstelle sie im commands-Ordner.")
    exit()

# Prüfen, ob Befehl schon existiert
exists = False
with open(commands_list_file, "r") as f:
    for line in f:
        if line.startswith(name + " -"):
            exists = True
            break

if exists:
    print("[!] Befehl existiert bereits!")
    exit()

with open(commands_list_file, "a") as f:
    f.write(f"{name} - {desc} - {file_name}\n")

print(f"[+] Command '{name}' hinzugefügt!")
EOF

# cun.py (Benutzername ändern)
cat > ~/commands/cun.py << 'EOF'
import os
USER_FILE = os.path.expanduser("~/user/user.py")
commands_list_file = os.path.expanduser("~/commands/commands_list.txt")
BASHRC_PATH = os.path.expanduser("~/.bashrc")

new_name = input("new user name: ")

# Benutzername ändern
lines = []
with open(USER_FILE, "r") as f:
    for line in f:
        if line.startswith("USERNAME"):
            lines.append(f"USERNAME = '{new_name}'\n")
        else:
            lines.append(line)
with open(USER_FILE, "w") as f:
    f.writelines(lines)

# Prompt & Aliase neu setzen
lines = []
in_block = False
if os.path.exists(BASHRC_PATH):
    with open(BASHRC_PATH, "r") as f:
        for line in f:
            if "PS1=" not in line and "COMMAND ALIASES" not in line and "Custom prompt for JoSte13" not in line:
                lines.append(line)

prompt = f"PS1='\\[\\e[32m\\]┌──(\\[\\e[34m\\]{new_name}@JoSte13\\[\\e[32m\\])─[\\[\\e[37m\\]\\w\\[\\e[32m\\]]\\n\\[\\e[32m\\]└─\\[\\e[34m\\]$\\[\\e[0m\\] '\n"

lines.append("\n# Custom prompt for JoSte13 system\n")
lines.append(prompt)

lines.append("# COMMAND ALIASES START\n")
with open(commands_list_file, "r") as f:
    for line in f:
        if line.strip():
            parts = line.strip().split(" - ")
            if len(parts) == 3:
                name, _, file_name = parts
                cmd_path = os.path.expanduser(f"~/commands/{file_name}")
                lines.append(f"alias {name}='python3 {cmd_path}'\n")
lines.append("# COMMAND ALIASES END\n")

with open(BASHRC_PATH, "w") as f:
    f.writelines(lines)

print("[*] Benutzername geändert. Bitte neu starten!")
EOF

# cup.py (Passwort ändern)
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

# ssal.py (System als ZIP speichern)
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

# Prompt setzen wenn User schon existiert
if [ -f "$USER_FILE" ]; then
  USERNAME=$(grep USERNAME "$USER_FILE" | cut -d"'" -f2)
  if [ ! -z "$USERNAME" ]; then
    # Alte PS1 und Aliase aus .bashrc entfernen
    grep -v -e "PS1=" -e "COMMAND ALIASES START" -e "COMMAND ALIASES END" -e "Custom prompt for JoSte13" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
    echo "PS1='\\[\\e[32m\\]┌──(\\[\\e[34m\\]${USERNAME}@JoSte13\\[\\e[32m\\])─[\\[\\e[37m\\]\\w\\[\\e[32m\\]]\\n\\[\\e[32m\\]└─\\[\\e[34m\\]\\$\\[\\e[0m\\] '" >> ~/.bashrc
    echo "# COMMAND ALIASES START" >> ~/.bashrc
    for f in ~/commands/*.py; do
      cmdname=$(basename "$f" .py)
      echo "alias $cmdname='python3 $f'" >> ~/.bashrc
    done
    echo "# COMMAND ALIASES END" >> ~/.bashrc
  fi
fi

echo -e "${GREEN}[*] Installation abgeschlossen. Starte System...${RESET}"

# Selbst löschen
rm -- "$0"

# start.py starten
python3 ~/start.py
