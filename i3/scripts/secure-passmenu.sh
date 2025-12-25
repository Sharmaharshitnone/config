#!/bin/bash

# 1. Temporarily disable clipmenud monitoring
clipctl disable

# 2. Run the passmenu utility
# The output (the selected password) will be placed in the clipboard by passmenu,
# but clipmenud will not record it in the history file because it is disabled.
passmenu

# 3. Re-enable clipmenud monitoring
# The 'passmenu' command clears the clipboard after a short timeout,
# but re-enabling clipmenud ensures it starts capturing other copies again.
clipctl enable
