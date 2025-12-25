#!/usr/bin/env python3
# Auto-rename i3 workspaces to include a primary app name (text only).
# Requires: pip3 install --user i3ipc

import i3ipc
import sys
import re

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
        # Just return the class name lowercased, minimal processing
        return cls.lower()
    return ""

def workspace_label(ws):
    """Build a readable workspace label from the workspace node.
    Strategy:
    - Collect leaf windows on the workspace and pick the first as primary.
    - Use the raw window class name as the label.
    - If ws.num == -1 (named workspace), try to extract a leading number.
    """
    apps = []
    for leaf in ws.leaves():
        cls = short_class(leaf)
        if cls:
            apps.append(cls)
        elif leaf.name:
            apps.append(leaf.name)

    if apps:
        # Use the first app's name found
        primary_name = apps[0]

        # workspace number: ws.num may be -1 for named workspaces
        if ws.num != -1:
            ws_num = ws.num
        else:
            m = re.match(r"^(\d+)", (ws.name or ""))
            ws_num = int(m.group(1)) if m else None

        if ws_num is not None:
            label = f"{ws_num}: {primary_name}"
        else:
            label = f"{primary_name}"
    else:
        # no application windows: preserve number or existing name if it's just a number
        # If the workspace is empty, we usually want "1" not "1: "
        if ws.num != -1:
             label = str(ws.num)
        else:
             # Try to keep the number part if it exists
             m = re.match(r"^(\d+)", (ws.name or ""))
             label = m.group(1) if m else ws.name

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
