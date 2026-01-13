#!/usr/bin/env bash
# Setup Recovery Script - Install explicitly installed packages
# Separated into PACMAN (official repos) and YAY (AUR) packages

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_info "System Recovery Mode - Installing Arch Linux packages"
log_info "Syncing package database..."
sudo pacman -Sy --noconfirm &>/dev/null || log_warn "Pacman sync failed"

# PACMAN PACKAGES (Official Repositories) - 111 packages
log_info "Installing official packages via pacman (111 packages)..."
sudo pacman -S --needed --noconfirm \
  7zip act adw-gtk-theme alsa-utils android-tools android-udev \
  base base-devel bat bc bemenu bemenu-wayland blueman bluez bluez-utils \
  boost brightnessctl btop calcurse ccache cliphist cloudflared dkms dmenu \
  dmidecode docker docker-buildx docker-compose dunst efibootmgr eza fd \
  firefox flatpak foliate fzf gammastep gdb gimp git github-cli glow go \
  gparted grim gvfs gvfs-mtp hyperfine i2c-tools i3-wm i3lock i3status-rust \
  imagemagick intel-media-driver intel-ucode iwd jdk-openjdk jq kdenlive kitty \
  lazydocker lazygit lib32-gamemode lib32-nvidia-utils lib32-vulkan-icd-loader \
  libva-nvidia-driver linux linux-firmware linux-headers lldb luarocks ly lynx \
  maim mako man-db mat2 materia-gtk-theme mediainfo mold mpc mpd mpd-mpris mpv \
  neovim network-manager-applet networkmanager noto-fonts \
  noto-fonts-cjk noto-fonts-emoji noto-fonts-extra nsxiv nvidia-open-dkms nvidia-prime nvtop \
  obs-studio opendoas openrgb pacman-contrib pandoc-cli papirus-icon-theme \
  parallel pass pavucontrol picard picom clipmenu pipewire pipewire-alsa \
  pipewire-pulse polkit-gnome python-i3ipc python-pipx python-setuptools qt6ct \
  ranger rclone redshift reflector ripgrep rmpc rnote rtkit rust sbctl sheldon \
  slurp smartmontools speech-dispatcher stow sway swaybg task \
  telegram-desktop thermald thunar timew tmux ttf-dejavu ttf-jetbrains-mono-nerd \
  ttf-liberation ttf-nerd-fonts-symbols-mono tumbler udiskie ufw unclutter \
  usbutils valgrind virtualbox virtualbox-host-modules-arch vit vlc vulkan-intel \
  waybar wget wireless_tools xclip xdg-utils xdotool xorg-xev xorg-xinit \
  xorg-xinput xorg-xrandr xorg-xwininfo xss-lock xwallpaper yazi yt-dlp \
  zathura zathura-cb zathura-pdf-poppler zeal zig zoxide zram-generator zsh

if [[ $? -eq 0 ]]; then
    log_info "✓ Pacman packages installed successfully"
else
    log_warn "Some pacman packages may have failed"
fi

# YAY PACKAGES (AUR Only) - 15 packages
log_info "Installing AUR packages via yay (15 packages)..."
yay -S --needed --noconfirm \
  activitywatch-bin antigravity-bin auto-cpufreq bibata-cursor-theme-bin \
  cargo-lambda-bin cloudflare-warp-bin envycontrol fnm \
  google-chrome jetbrains-toolbox piper-tts tdl-bin \
  ufw-docker visual-studio-code-bin nordic-theme peaclock simple-mtpfs 

if [[ $? -eq 0 ]]; then
    log_info "✓ AUR packages installed successfully"
else
    log_warn "Some AUR packages may have failed"
fi

log_info "✓ Installation complete!"
log_info "Total packages installed: $(pacman -Q | wc -l)"
log_info "Future updates: pacman -Syu && yay -Syu"
