#!/bin/bash

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}[*] Starte Installation...${RESET}"

# Update und Pakete installieren
pkg update -y && pkg upgrade -y
pkg install -y python python2 python3 apache2 wget curl zip unzip

# Ordnerstruktur anlegen
mkdir -p ~/commands
mkdir -p ~/downloads
mkdir -p ~/user

USER_FILE=~/user/user.py
COMMANDS_LIST=~/commands/commands_list.txt

# commands_list.txt mit Standardbefehlen erstellen
cat > "$COMMANDS_LIST" << EOF
help - zeigt diese Hilfe - help.py
cnc - create new command - cnc.py
cun - change user name - cun.py
cup - change password - cup.py
ssal - save system as link - ssal.py
EOF

# start.py mit interaktiver Python-Shell und klarer Ausgabe vor Eingabe
cat > ~/start.py << 'EOF'
import os
import sys
import time

USER_FILE = os.path.expanduser("~/user/user.py")
COMMANDS_DIR = os.path.expanduser("~/commands")
COMMANDS_LIST_FILE = os.path.expanduser("~/commands/commands_list.txt")
DOWNLOADS_DIR = os.path.expanduser("~/downloads")

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
        print(f"Unbekannter Befehl: {cmd_name}")
        return
    path = commands[cmd_name]["file"]
    if not os.path.exists(path):
        print(f"Datei für Befehl nicht gefunden: {path}")
        return
    try:
        with open(path, "r") as f:
            code = f.read()
        exec(code, globals())
    except Exception as e:
        print(f"Fehler beim Ausführen von {cmd_name}: {e}")

def create_account():
    clear()
    username = input("Name: ")
    password = input("Password: ")
    save_user(username, password)
    clear()
    print("[*] Account erstellt!")
    time.sleep(1)
    clear()
    return username

def load_from_link():
    import urllib.request
    import zipfile
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
            user = create_account()
            return user
        elif choice == "2":
            load_from_link()
            user, _ = load_user()
            return user
        else:
            print("Ungültige Eingabe!")
            time.sleep(1)

def print_help(commands):
    print("Verfügbare Befehle:")
    for name, data in commands.items():
        print(f"{name} - {data['desc']}")

def interactive_shell(username, commands):
    while True:
        try:
            inp = input(f"\033[32m┌──(\033[34m{username}@JoSte13\033[32m)─[\033[37m~\033[32m]\n└─\033[34m$ \033[0m").strip()
            if inp == "":
                continue
            if inp == "exit":
                print("Bye!")
                break
            elif inp == "help":
                print_help(commands)
            else:
                run_command(inp, commands)
        except KeyboardInterrupt:
            print("\nNutze 'exit' zum Beenden.")
        except Exception as e:
            print(f"Fehler: {e}")

def main():
    username, password = load_user()
    if username is None:
        username = main_menu()
    commands = load_commands()
    clear()
    print(f"Willkommen, {username}!")
    interactive_shell(username, commands)

if __name__ == "__main__":
    main()
EOF

# help.py (zeigt alle Befehle)
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

# cnc.py (neuen Befehl hinzufügen)
cat > ~/commands/cnc.py << 'EOF'
import os
commands_list_file = os.path.expanduser("~/commands/commands_list.txt")

name = input("Name: ")
desc = input("Description: ")
file_name = input("File Name (existierende Datei in commands/, z.B. befehl.py): ")

cmd_path = os.path.expanduser(f"~/commands/{file_name}")
if not os.path.exists(cmd_path):
    print("[!] Datei existiert nicht! Bitte erstelle sie im commands-Ordner.")
    exit()

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

echo -e "${GREEN}[*] Installation abgeschlossen.${RESET}"

# Lösche die install.sh selbst
rm -- "$0"

# Starte automatisch das System
python3 ~/start.py
