#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
EMOJI_DATA = Path("/usr/share/rofi-emoji/all_emojis.txt")


def config_home():
    return Path(
        os.environ.get("HYCON_DIR")
        or os.environ.get("XDG_CONFIG_HOME")
        or (Path.home() / ".config")
    )


def theme_name():
    return os.environ.get("HYCON_THEME", "macos")


def theme_dir():
    name = theme_name()
    candidates = [
        config_home() / "themes" / name,
        SCRIPT_DIR.parent.parent / "themes" / name,
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return candidate
    return None


def theme_file(filename):
    directory = theme_dir()
    candidates = []
    if directory:
        candidates.append(directory / "rofi" / filename)
    candidates.extend(
        [
            config_home() / "rofi" / filename,
            SCRIPT_DIR.parent / filename,
        ]
    )
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def picker_theme():
    return theme_file("picker.rasi") or theme_file("menu.rasi")


def emoji_theme():
    return theme_file("emoji.rasi") or picker_theme()


def notify(title, body):
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", title, body], check=False)


def copy_to_clipboard(text):
    commands = [
        ["wl-copy"],
        ["xclip", "-selection", "clipboard"],
        ["xsel", "--clipboard", "--input"],
    ]
    for command in commands:
        if not shutil.which(command[0]):
            continue
        try:
            result = subprocess.run(command, input=text, text=True, check=False)
        except OSError:
            continue
        if result.returncode == 0:
            return True
    return False


def run_rofi(lines, prompt, theme_str, theme=None):
    command = [
        "rofi",
        "-dmenu",
        "-i",
        "-no-custom",
        "-format",
        "s",
        "-p",
        prompt,
    ]
    theme = theme or picker_theme()
    if theme:
        command += ["-config", str(theme)]
    if theme_str:
        command += ["-theme-str", theme_str]
    try:
        result = subprocess.run(
            command,
            input="\n".join(lines) + "\n",
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        notify("Picker", "rofi not found")
        return None
    if result.returncode != 0:
        return None
    return result.stdout.rstrip("\n")


def finish(selection):
    if not selection:
        return 0
    glyph = selection.split(maxsplit=1)[0]
    if copy_to_clipboard(glyph):
        notify("Copied", glyph)
    else:
        notify("Clipboard", "wl-copy, xclip or xsel not found")
    return 0


def icons():
    data = SCRIPT_DIR / "nerd-icons.tsv"
    if not data.is_file():
        notify("Icons", "nerd-icons.tsv not found")
        return 1
    lines = []
    with data.open(encoding="utf-8") as handle:
        for raw in handle:
            raw = raw.rstrip("\n")
            if not raw:
                continue
            glyph, _, label = raw.partition("\t")
            if glyph and label:
                lines.append(f"{glyph}  {label}")
    if not lines:
        notify("Icons", "No icons available")
        return 1
    selection = run_rofi(
        lines,
        "Nerd Font Icons",
        'listview { lines: 14; } element-text { font: "JetBrainsMono Nerd Font 12"; }',
    )
    return finish(selection)


def emoji():
    lines = []
    if EMOJI_DATA.is_file():
        with EMOJI_DATA.open(encoding="utf-8") as handle:
            for raw in handle:
                parts = raw.rstrip("\n").split("\t")
                if len(parts) < 4:
                    continue
                character = parts[0]
                name = parts[3]
                keywords = parts[4] if len(parts) > 4 else ""
                if not character or not name:
                    continue
                if keywords:
                    lines.append(f"{character}  {name}  {keywords}")
                else:
                    lines.append(f"{character}  {name}")

    if lines:
        selection = run_rofi(
            lines,
            "Emoji",
            "",
            emoji_theme(),
        )
        return finish(selection)

    command = ["rofi", "-show", "emoji", "-modi", "emoji"]
    theme = emoji_theme()
    if theme:
        command += ["-config", str(theme)]
    try:
        subprocess.run(command, check=False)
    except FileNotFoundError:
        notify("Emoji", "rofi-emoji not available")
        return 1
    return 0


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "icons"
    if mode == "emoji":
        return emoji()
    if mode == "icons":
        return icons()
    print(f"Usage: {Path(sys.argv[0]).name} <icons|emoji>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
