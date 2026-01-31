# Dotfiles Configuration

Personal Linux configuration files for i3wm, Sway, and associated tools.

## Structure

```
├── i3/                      # i3 window manager configuration
│   ├── config              # Main i3 config
│   ├── config.d/           # Modular config includes
│   └── scripts/            # Helper scripts
├── i3status-rust/          # Status bar configuration
│   ├── config.toml         # Main status bar config
│   ├── README.md           # Complete documentation
│   └── IMPROVEMENTS.md     # Improvement recommendations
├── sway/                   # Sway (Wayland) configuration
├── nvim/                   # Neovim configuration
├── kitty/                  # Terminal emulator
├── zsh/                    # Zsh shell configuration
├── tmux/                   # Tmux configuration
├── picom/                  # Compositor configuration
├── dunst/                  # Notification daemon
└── ...                     # Other configs
```

## Highlights

### i3status-rust
Feature-rich status bar with:
- Gruvbox theming with transparent backgrounds
- Scratchpad integration via tmux
- Signal-based updates for performance
- 20+ functional blocks

See [i3status-rust/README.md](i3status-rust/README.md) for complete documentation.

### Key Features
- **Window Manager**: i3 (X11) and Sway (Wayland)
- **Status Bar**: i3status-rust with Material Nerd Font icons
- **Terminal**: Kitty with JetBrainsMono Nerd Font
- **Editor**: Neovim with custom configuration
- **Shell**: Zsh with custom prompt
- **Notifications**: Dunst
- **Compositor**: Picom (X11)

## Dependencies

Install required packages (Arch Linux):
```bash
# Core
sudo pacman -S i3-wm i3status-rust kitty neovim zsh tmux

# Status bar dependencies
sudo pacman -S pulseaudio brightnessctl lm_sensors

# Optional (for full functionality)
sudo pacman -S timewarrior taskwarrior vit calcurse btop htop \
               pavucontrol redshift auto-cpufreq tlp picom dunst
```

## Installation

```bash
# Clone to config directory
git clone https://github.com/Sharmaharshitnone/config ~/.config

# Or symlink individual configs
ln -s ~/path/to/config/i3 ~/.config/i3
ln -s ~/path/to/config/i3status-rust ~/.config/i3status-rust
```

## License

Personal configuration files - use at your own risk.
