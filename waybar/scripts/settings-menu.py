#!/usr/bin/env python3
import os
import pwd
import random
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
THEME_DIR = PROJECT_DIR / "themes" / "macos"
SETTINGS_XML = SCRIPT_DIR.parent / "menu" / "settings.xml"

ICONS = {
    "Wallpaper": "preferences-desktop-wallpaper",
    "Select Wallpaper": "document-open",
    "Next Wallpaper": "go-next",
    "Previous Wallpaper": "go-previous",
    "Random Wallpaper": "media-playlist-shuffle",
    "Animations": "preferences-desktop-screensaver",
    "Enabled": "media-playback-start",
    "Disabled": "media-playback-pause",
    "Theme": "preferences-desktop-theme",
    "macOS Dark": "weather-clear-night",
    "macOS Light": "weather-clear",
}


def config_dir():
    return Path(
        os.environ.get("HYCON_DIR")
        or os.environ.get("XDG_CONFIG_HOME")
        or (Path.home() / ".config")
    )


def resolve_dirs():
    global PROJECT_DIR, THEME_DIR
    env_dir = os.environ.get("HYCON_DIR")
    if env_dir and (Path(env_dir) / "themes" / "macos").is_dir():
        PROJECT_DIR = Path(env_dir)
        THEME_DIR = PROJECT_DIR / "themes" / "macos"


def rofi_theme():
    config = config_dir()
    theme = os.environ.get("HYCON_THEME", "macos")
    if theme:
        candidate = config / "themes" / theme / "rofi" / "menu.rasi"
        if candidate.exists():
            return candidate
    for candidate in (
        THEME_DIR / "rofi" / "menu.rasi",
        config / "rofi" / "menu.rasi",
        config / "rofi" / "full.rasi",
    ):
        if candidate.exists():
            return candidate
    return None


def get_label(element):
    for attribute in element.findall("attribute"):
        if attribute.get("name") == "label":
            return attribute.text or ""
    return ""


def get_action(element):
    for attribute in element.findall("attribute"):
        if attribute.get("name") == "action":
            return attribute.text or ""
    return ""


def notify(title, body):
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", title, body], check=False)


def rofi_pick(labels, prompt):
    lines = []
    for text in labels:
        icon = ICONS.get(text)
        if icon:
            lines.append(f"{text}\0icon\x1f{icon}")
        else:
            lines.append(text)

    command = ["rofi", "-dmenu", "-show-icons", "-i", "-format", "i", "-p", prompt]
    theme = rofi_theme()
    if theme:
        command += ["-config", str(theme)]
    command += [
        "-theme-str",
        "inputbar { children: [prompt]; } entry { enabled: false; }",
    ]

    try:
        process = subprocess.run(
            command,
            input="\n".join(lines) + "\n",
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        return None

    if process.returncode != 0:
        return None

    try:
        return int(process.stdout.strip())
    except ValueError:
        return None


def real_home():
    try:
        return Path(pwd.getpwuid(os.getuid()).pw_dir)
    except Exception:
        return Path.home()


def wallpaper_paths():
    home_dir = real_home() / "Wallpapers"
    directories = [home_dir]
    if not home_dir.is_dir():
        directories.append(PROJECT_DIR / "assets" / "wallpapers")
    extensions = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp"}
    result = []
    seen = set()

    for directory in directories:
        if not directory.is_dir():
            continue
        for path in sorted(directory.iterdir(), key=lambda item: item.name.casefold()):
            if path.suffix.lower() in extensions and path not in seen:
                result.append(path)
                seen.add(path)

    return result


def pick_wallpaper(paths):
    lines = [f"{path.name}\0icon\x1f{path}" for path in paths]
    command = [
        "rofi",
        "-dmenu",
        "-show-icons",
        "-i",
        "-format",
        "i",
        "-p",
        "Wallpaper",
    ]
    theme = THEME_DIR / "rofi" / "wallpaper.rasi"
    if not theme.exists():
        theme = config_dir() / "rofi" / "wallpaper.rasi"
    if theme.exists():
        command += ["-config", str(theme)]
    command += [
        "-theme-str",
        "inputbar { children: [prompt]; } entry { enabled: false; }",
    ]

    try:
        process = subprocess.run(
            command,
            input="\n".join(lines) + "\n",
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        return None

    if process.returncode != 0:
        return None

    try:
        return int(process.stdout.strip())
    except ValueError:
        return None


def update_banner(path):
    try:
        link = THEME_DIR / "rofi" / "wallpaper.jpg"
        link.parent.mkdir(parents=True, exist_ok=True)
        link.unlink(missing_ok=True)
        link.symlink_to(Path(path).resolve())
        banner = THEME_DIR / "rofi" / "banner.rasi"
        banner.write_text(
            f'banner {{\n    background-image: url("{link}", height);\n}}\n'
        )
    except Exception:
        pass


def wallpaper_state():
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return Path(runtime) / f"hycon-wallpaper-{os.getuid()}"


def read_wallpaper_index(total):
    if total < 1:
        return 0
    try:
        index = int(wallpaper_state().read_text().strip())
    except Exception:
        return 0
    return index % total


def write_wallpaper_index(index):
    try:
        wallpaper_state().write_text(f"{index}\n")
    except Exception:
        pass


def set_wallpaper(path, index=None):
    for command in (["awww", "img", str(path)], ["swww", "img", str(path)]):
        if shutil.which(command[0]):
            subprocess.run(command, check=False)
            update_banner(path)
            if index is not None:
                write_wallpaper_index(index)
            return True
    return False


def wallpaper_action(action):
    paths = wallpaper_paths()
    if not paths:
        notify("Wallpaper", "No wallpaper found")
        return

    index = read_wallpaper_index(len(paths))

    if action == "menu.select-wallpaper":
        selected = pick_wallpaper(paths)
        if selected is not None and 0 <= selected < len(paths):
            set_wallpaper(paths[selected], selected)
    elif action == "menu.next-wallpaper":
        index = (index + 1) % len(paths)
        set_wallpaper(paths[index], index)
    elif action == "menu.prev-wallpaper":
        index = (index - 1) % len(paths)
        set_wallpaper(paths[index], index)
    elif action == "menu.rand-wallpaper":
        index = random.randrange(len(paths))
        set_wallpaper(paths[index], index)


def execute(action, label):
    if action.startswith("theme.set-"):
        name = action.split("-", 1)[1]
        switch = THEME_DIR / "switch.sh"
        if switch.exists():
            subprocess.run([str(switch), name], check=False)
            notify("Theme", f"macOS {name.capitalize()} applied")
        return

    if action == "animations.enable":
        subprocess.run(
            ["hyprctl", "keyword", "animations:enabled", "true"], check=False
        )
        notify("Animations", "Enabled")
        return

    if action == "animations.disable":
        subprocess.run(
            ["hyprctl", "keyword", "animations:enabled", "false"], check=False
        )
        notify("Animations", "Disabled")
        return

    if action.startswith("menu."):
        wallpaper_action(action)
        return

    notify(label or "Menu", f"Unknown action: {action}")


def menu_items(element):
    result = []
    for child in element:
        if child.tag == "submenu":
            result.append(("submenu", get_label(child), child))
        elif child.tag == "item":
            result.append(("item", get_label(child), get_action(child)))
    return result


def run_menu(element, prompt, allow_back=False):
    items = menu_items(element)
    entries = []

    if allow_back:
        entries.append(("back", "← Back", None))

    entries.extend(items)

    selected = rofi_pick([entry[1] for entry in entries], prompt)
    if selected is None or selected < 0 or selected >= len(entries):
        return

    kind, label, value = entries[selected]

    if kind == "back":
        return

    if kind == "submenu":
        run_menu(value, label, True)
        return

    execute(value, label)


def main():
    resolve_dirs()

    if not SETTINGS_XML.exists():
        fallback = config_dir() / "waybar" / "menu" / "settings.xml"
        if fallback.exists():
            xml_path = fallback
        else:
            notify("Settings", "settings.xml not found")
            return 1
    else:
        xml_path = SETTINGS_XML

    try:
        root = ET.parse(xml_path).getroot()
    except ET.ParseError as error:
        notify("Settings", f"XML error: {error}")
        return 1

    menu = root.find("menu")
    if menu is None:
        notify("Settings", "menu node not found")
        return 1

    run_menu(menu, "Settings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
