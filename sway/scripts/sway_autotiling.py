#!/usr/bin/env python3
"""
Sway Autotiling - Native Wayland automatic split direction
Optimized for performance: minimal allocations, direct IPC usage
"""

import sys
from i3ipc import Connection, Event


def find_parent(tree, window_id):
    """Find parent container (non-recursive for performance)"""
    stack = [(tree, None)]
    
    while stack:
        node, parent = stack.pop()
        if node.id == window_id:
            return parent
        
        # Reverse to maintain DFS order
        for child in reversed(node.nodes):
            stack.append((child, node))
    
    return None


def on_window_focus(conn, event):
    """
    Set split direction based on window aspect ratio.
    Ignores tabbed/stacked containers to preserve manual layouts.
    """
    focused = event.container
    parent = find_parent(conn.get_tree(), focused.id)
    
    # Skip if no parent or manual layout
    if not parent or parent.layout in ('tabbed', 'stacked'):
        return
    
    # Determine optimal split based on aspect ratio
    # Tall windows → split horizontal (stack vertically)
    # Wide windows → split vertical (tile horizontally)
    is_tall = focused.rect.height > focused.rect.width
    
    if is_tall and parent.orientation == 'horizontal':
        conn.command('split v')
    elif not is_tall and parent.orientation == 'vertical':
        conn.command('split h')


def main():
    """Initialize Sway IPC listener"""
    if len(sys.argv) > 1 and sys.argv[1] in ('-h', '--help'):
        print(f"Usage: {sys.argv[0]}")
        print("Automatically sets split direction in Sway based on window dimensions.")
        print("Add to Sway config: exec /path/to/sway_autotiling.py")
        return 0
    
    try:
        conn = Connection()
        conn.on(Event.WINDOW_FOCUS, on_window_focus)
        
        # Non-blocking event loop
        conn.main()
    except KeyboardInterrupt:
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
