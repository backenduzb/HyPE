#!/usr/bin/env python3
import json
import os
import subprocess
import sys

DESKTOP_ENTRY = os.path.expanduser("~/.local/share/applications/00-arch-launcher.desktop")

def get_launcher_info():
    name = "Arch"
    icon = "distributor-logo-arch"
    exec_cmd = "sh -c '$HOME/.config/rofi/scripts/toggle.sh full'"
    if os.path.exists(DESKTOP_ENTRY):
        try:
            with open(DESKTOP_ENTRY, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("Name="):
                        name = line.split("=", 1)[1].strip()
                    elif line.startswith("Icon="):
                        icon = line.split("=", 1)[1].strip()
                    elif line.startswith("Exec="):
                        exec_cmd = line.split("=", 1)[1].strip()
        except Exception:
            pass
    return name, icon, exec_cmd

def resolve_icon(cls):
    if not cls:
        return "application-x-executable"
    if "telegram" in cls.lower():
        return "telegram"

    search_dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications",
    ]
    for d in search_dirs:
        for fname in [f"{cls}.desktop", f"{cls.lower()}.desktop"]:
            fpath = os.path.join(d, fname)
            if os.path.exists(fpath):
                try:
                    with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                        for line in f:
                            if line.startswith("Icon="):
                                icon_val = line.split("=", 1)[1].strip()
                                if icon_val:
                                    return icon_val
                except Exception:
                    pass
    return cls

def get_clients():
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], timeout=1)
        clients = json.loads(out)
    except Exception:
        clients = []

    valid = []
    for c in clients:
        title = c.get("title", "")
        cls = c.get("class", "")
        addr = c.get("address", "")
        if not title and not cls:
            continue
        valid.append({
            "title": title or cls,
            "class": cls,
            "address": addr,
            "icon": resolve_icon(cls)
        })
    return valid

def print_list():
    _, launcher_icon, _ = get_launcher_info()
    sys.stdout.write(f"Arch\0icon\x1f{launcher_icon}\n")

    for c in get_clients():
        sys.stdout.write(f"{c['title']}\0icon\x1f{c['icon']}\n")
    sys.stdout.flush()

def select_item(index_str):
    try:
        idx = int(index_str.strip())
    except ValueError:
        return

    if idx == 0:
        _, _, exec_cmd = get_launcher_info()
        subprocess.Popen(exec_cmd, shell=True, start_new_session=True)
    else:
        clients = get_clients()
        client_idx = idx - 1
        if 0 <= client_idx < len(clients):
            addr = clients[client_idx]["address"]
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{addr}"])

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == "--count":
            print(len(get_clients()) + 1)
        elif arg == "--list":
            print_list()
        elif arg == "--select" and len(sys.argv) > 2:
            select_item(sys.argv[2])
    else:
        print_list()
