#!/usr/bin/env python3
import i3ipc
import os
import sys
import re

# Application name mappings for cleaner display names
# Gruvbox colors:
# Red: #fb4934, Green: #b8bb26, Yellow: #fabd2f, Blue: #83a598, Purple: #d3869b, Aqua: #8ec07c, Orange: #fe8019, Gray: #928374

APP_NAME_MAP = {
#     # Browsers
    "firefox": "<span size='x-large'> </span>",
    "google-chrome": "<span size='x-large'> </span>",

    # Terminals
    "alacritty": "<span size='x-large'> </span>",
    "kitty": "<span size='x-large'> </span>",
    "st": "<span size='x-large'> </span>",

    # Editors
    "code": "<span size='x-large'>󰨞 </span>",
    "antigravity": "<span size='x-large'> </span>",
    "code-oss": "<span size='x-large'>󰨞 </span>",
    "nvim": "<span size='x-large'> </span>",
    "vim": "<span size='x-large'> </span>",
    "neovide": "<span size='x-large'> </span>",
    "emacs": "<span size='x-large'> </span>",

    # Development
    "jetbrains-idea": "<span size='x-large'> </span>",
    "jetbrains-clion": "<span size='x-large'> </span>",
    "jetbrains-pycharm": "<span size='x-large'> </span>",
    "jetbrains-webstorm": "<span size='x-large'>󰛦 </span>",
    "jetbrains-rider": "<span size='x-large'>󰆧 </span>",
    "jetbrains-goland": "<span size='x-large'> </span>",
    "jetbrains-datagrip": "<span size='x-large'> </span>",
    "jetbrains-rubymine": "<span size='x-large'> </span>",
    "jetbrains-phpstorm": "<span size='x-large'> </span>",
    "postman": "<span size='x-large'>󰛮 </span>",
    "docker": "<span size='x-large'> </span>",
    "virt-manager": "<span size='x-large'>󰢔 </span>",
    "gnome-boxes": "<span size='x-large'>󰢔 </span>",
    "virtualbox": "<span size='x-large'>󰢔 </span>",

    # Communication
    "telegramdesktop": "<span size='x-large'> </span>",
    "telegram": "<span size='x-large'> </span>",
    "evolution": "<span size='x-large'>󰇰 </span>",

    # Media
    "pavucontrol": "<span size='x-large'>󰕾 </span>",
    "vlc": "<span size='x-large'>󰕼 </span>",
    "mpv": "<span size='x-large'> </span>",
    "obs": "<span size='x-large'>󰑋 </span>",
    "obs-studio": "<span size='x-large'>󰑋 </span>",
    "gimp": "<span size='x-large'> </span>",
    "inkscape": "<span size='x-large'> </span>",
    "steam": "<span size='x-large'> </span>",

    # System & Utilities
    "thunar": "<span size='x-large'> </span>",
    "yazi": "<span size='x-large'> </span>",
    "htop": "<span size='x-large'>󰓅 </span>",
    "btop": "<span size='x-large'>󰓅 </span>",
    "gparted": "<span size='x-large'>󰋊 </span>",
    "clock": "<span size='x-large'> </span>",
    "peaclock": "<span size='x-large'> </span>",
    "calc": "<span size='x-large'> </span>",
    "calculator": "<span size='x-large'> </span>",
    "galculator": "<span size='x-large'> </span>",
    "zathura": "<span size='x-large'> </span>",

    # Custom / Other
    "scratchpad": "<span size='x-large'>󰘳 </span>",
    "main-tmux": "<span size='x-large'> </span>",
    "gemini": "<span size='x-large'>󰚩 </span>",
    "gemini-sc": "<span size='x-large'>󰚩 </span>",
    "task": "<span size='x-large'> </span>",
    "tasks": "<span size='x-large'> </span>",
    "todo": "<span size='x-large'> </span>",
}

def short_class(con):
    """Return a short, lowercase token for a connection's window class/instance.
    Falls back to an empty string when not present.
    """
    cls = (
        getattr(con, "window_class", None)
        or getattr(con, "window_instance", None)
        or ""
    )
    if isinstance(cls, str) and cls:
        token = cls.split()[-1]
        return token.lower()
    return ""

def workspace_label(ws):
    """Build a readable workspace label from the workspace node.
    Strategy:
    - Collect leaf windows on the workspace and pick the first as primary.
    - Match an icon by exact lowercased class/name or by substring.
    - If ws.num == -1 (named workspace), try to extract a leading number from ws.name.
    - Preserve existing non-empty names when the workspace is empty.
    """
    apps = []
    for leaf in ws.leaves():
        cls = short_class(leaf)
        if cls:
            apps.append(cls)
        elif leaf.name:
            apps.append(leaf.name)

    if apps:
        primary = apps[0]
        primary_l = primary.lower() if isinstance(primary, str) else ""

        # Get clean app name from mapping or use original
        clean_name = APP_NAME_MAP.get(primary_l, primary)

        # workspace number: ws.num may be -1 for named workspaces
        if ws.num != -1:
            ws_num = ws.num
        else:
            m = re.match(r"^(\d+)", (ws.name or ""))
            ws_num = int(m.group(1)) if m else None

        if ws_num is not None:
            label = f"{ws_num}: {clean_name}"
        else:
            label = f"{clean_name}"
    else:
        # no application windows on this workspace: preserve the existing name if set
        if ws.name:
            label = ws.name
        else:
            label = str(ws.num)

    return label

def update_names(i3):
    tree = i3.get_tree()
    for ws in tree.workspaces():
        try:
            new_name = workspace_label(ws)
        except Exception as exc:
            print("workspace_label error:", exc, file=sys.stderr)
            continue

        # Only rename when necessary
        if ws.name != new_name:
            try:
                # Escape double quotes
                cur = (ws.name or "").replace('"', '\\"')
                new = new_name.replace('"', '\\"')
                if cur:
                    cmd = f'rename workspace "{cur}" to "{new}"'
                else:
                    # fallback to number-based rename
                    cmd = f'rename workspace number {ws.num} to "{new}"'
                i3.command(cmd)
                print(
                    f"renamed workspace: '{ws.name}' -> '{new_name}'", file=sys.stderr
                )
            except Exception as e:
                print("rename error:", e, file=sys.stderr)

def on_event(i3, e):
    update_names(i3)

def main():
    i3 = i3ipc.Connection()
    # initial pass
    update_names(i3)
    # subscribe to common events
    i3.on("window::new", on_event)
    i3.on("window::close", on_event)
    i3.on("window::focus", on_event)
    i3.on("workspace::focus", on_event)
    i3.on("window::move", on_event)
    try:
        i3.main()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
