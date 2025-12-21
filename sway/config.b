set $mod Mod4
font pango:JetBrainsMono Nerd Font 8

# Xresources via pywal still works with Sway set_from_resource $background i3wm.background #000000 set_from_resource $foreground i3wm.foreground #ffffff
# # ... (all your other set_from_resource lines are fine) ...
# set_from_resource $color15 i3wm.color15 #ffffff


# SWAY: Output configuration. '*' applies to all monitors.
# Replace the ~/.config/i3/scripts/bg.sh script with this.
exec ~/.config/sway/scripts/bg.sh

# SWAY: Input device configuration. Replaces xinput and setxkbmap.
# Find your device identifiers by running `swaymsg -t get_inputs`
input type:touchpad {
    dwt enabled
    tap enabled
    # natural_scroll enabled
  #     middle_emulation enabled
}
input type:keyboard {
    xkb_layout us
      xkb_options caps:escape
      xkb_options altwin:menu_win
}

# SWAY: Hide cursor after a period of inactivity. Replaces unclutter.
seat seat0 hide_cursor 5000

# --- Autostart Applications ---
# SWAY: Use `exec_always` for things that need to restart with Sway.
# SWAY: `dex` can be problematic. It's often better to launch daemons directly.

# Daemons that work fine in Wayland
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
# exec --no-startup-id dunst
# SWAY: clipmenud is X11. Replace with a Wayland clipboard manager.
# exec --no-startup-id wl-paste --watch clipman store

# Polkit agent and scripts should still work
exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 # Adjust path if needed
# exec_always --no-startup-id ~/.config/i3/scripts/workspace-names.py &
exec_always --no-startup-id ~/.config/i3/scripts/alternating_layouts.py

# SWAY: Screen locker. Replace xss-lock and i3lock with swayidle and swaylock.
exec swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f'


workspace_auto_back_and_forth yes
# SWAY: title_window_icon is not a valid Sway command. Remove it.
# for_window [all] title_window_icon on

# --- Keybindings ---

# SWAY: Screen recording. Replace X11-based scripts with wf-recorder.
bindsym $mod+Shift+Print exec --no-startup-id wf-recorder -g "$(slurp)" -f ~/Videos/recording-$(date +'%Y-%m-%d_%H-%M-%S').mp4
# Include other config files (this part is identical)
include ~/.config/sway/config.d/*.conf

# SWAY: Clipboard menu. Replace clipmenu with a wofi/bemenu based solution.
bindsym $mod+c exec clipman pick -t wofi

bindsym $mod+Shift+s exec --no-startup-id systemctl poweroff

gaps inner 10
gaps outer 0
bindsym $mod+Shift+plus gaps inner all plus 5
bindsym $mod+Shift+minus gaps inner all minus 5

floating_modifier $mod
tiling_drag titlebar

# tiling_drag modifier titlebar
bindsym $mod+Return exec alacritty
# (All your other alacritty/tmux/custom script binds are likely fine)
bindsym $mod+Control+Return exec alacritty -e tmux attach
bindsym $mod+Shift+Return exec /home/kali/.local/bin/open-term-same-dir

# kill focused window
bindsym $mod+Shift+q kill

# SWAY: Program launcher. Replace dmenu with wofi or bemenu.
bindsym $mod+d exec --no-startup-id wofi --show drun
# SWAY: Passmenu. You will need a wofi-compatible version.
bindsym $mod+x exec --no-startup-id pass-wofi

# (ALL of your focus, move, layout, floating, workspace, and resize bindings are 100% compatible and need NO changes)
# change focus
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right
# ... etc ...

# switch to workspace
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
# ... etc ...

# reload the configuration file
bindsym $mod+Shift+c reload
# restart sway inplace
bindsym $mod+Shift+r restart
# exit sway
bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

mode "resize" {
        bindsym h resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym j resize shrink height 10 px or 10 ppt
        bindsym l resize grow width 10 px or 10 ppt
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"
bindsym $mod+m bar mode toggle

# --- Bar Configuration ---
# SWAY: This is the modern way to define a bar in Sway.
# The user was asking about i3status-rs, so we'll use that.
bar {
    # The command to get status updates.
    status_command i3status-rs ~/.config/i3status-rust/config.toml

    position top
    font pango:JetBrainsMono Nerd Font 11
    # You can add more swaybar specific settings here if needed
    
    colors {
        background #000000CC
        # statusline $foreground
        # separator $color8
        # target             border      bg          text
        # focused_workspace    $color4     $color0     $foreground
        # active_workspace     $color8     $background $foreground
        # inactive_workspace   $background $background $color8
        # urgent_workspace     $color1     $color1     $foreground
    }
}


# Window border colors (these are 100% compatible)
# class                 border      backgr.     text        indicator   child_border
# client.focused          $color4     $color4     $foreground $color5     $color4
# client.focused_inactive $color8     $background $foreground $color8     $color8
# client.unfocused        $background $background $color8     $background $background
# client.urgent           $color1     $color1     $foreground $color1     $color1
# client.placeholder      $background $background $foreground $background $background
# client.background       $background

# --- END OF FILE sway/config ---
