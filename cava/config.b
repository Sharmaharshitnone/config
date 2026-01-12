## CAVA Configuration
## Location: ~/.config/cava/config
## Elite Audio Visualizer Setup for Arch Linux + Kitty Terminal

[general]
# Performance: Match your monitor's refresh rate for buttery-smooth animation
framerate = 144

# Bars: 0 = Auto-detect terminal width (recommended)
bars = 0

# Bar dimensions for high-res look
bar_width = 2
bar_spacing = 1

# Sensitivity: Auto-adjust volume levels to prevent clipping
sensitivity = 100
autosens = 1

# Lower/Higher Cutoff: Removes inaudible frequencies for cleaner visualization
lower_cutoff_freq = 20
higher_cutoff_freq = 20000


[input]
# Audio Source: PipeWire (modern Linux standard)
# Alternatives: pulse, alsa, fifo, sndio
method = pipewire

# Auto-detect the active audio stream
source = auto


[output]
# Rendering Method
# - noncurses: Fastest, best for transparent terminals
# - ncurses: More stable, better color support
# - raw: For piping to other programs
method = noncurses

# Visual Style
# - stereo: Split left/right channels (mirrored)
# - mono: Single centered visualization
channels = stereo

# If mono, how to combine channels
mono_option = average

# Reverse bars (bottom to top instead of top to bottom)
reverse = 0

# ASCII Output (only for method = raw)
ascii_max_range = 1000

# Raw output settings (only for method = raw)
raw_target = /dev/stdout
data_format = binary
bit_format = 16bit
bar_delimiter = 59
frame_delimiter = 10


[color]
# Enable gradient coloring (0 = single color, 1 = gradient)
gradient = 1

# === CYBERPUNK NEON GRADIENT ===
# Electric Blue -> Purple -> Hot Pink -> Red
# This gradient creates an aggressive, high-energy look
gradient_color_1 = '#00ffff'  # Cyan (Low frequencies)
gradient_color_2 = '#00ccff'
gradient_color_3 = '#0099ff'
gradient_color_4 = '#6666ff'
gradient_color_5 = '#9933ff'
gradient_color_6 = '#cc00ff'
gradient_color_7 = '#ff00cc'
gradient_color_8 = '#ff0066'  # Hot Pink (High frequencies)

# If gradient = 0, this is the single color used
# foreground = '#ff00ff'

# Background color (only for ncurses method)
# Set to 'default' for transparent terminals
background = default


[smoothing]
# Monstercat Smoothing: Makes bars fall slower (rhythmic/musical look)
# 0 = Off, 1 = On
monstercat = 1

# Waves: Experimental smoothing (can cause flickering)
waves = 0

# Noise Reduction: Higher = smoother, Lower = snappier
# Range: 0-100 (Default: 77)
# - 90+: Very liquid/smooth (good for ambient music)
# - 65-75: Balanced (recommended)
# - 40-60: Aggressive/responsive (good for EDM/metal)
noise_reduction = 65

# Integral: Smooths out sudden changes (deprecated, use noise_reduction)
# integral = 77

# Gravity: How fast bars fall (only if monstercat = 0)
# Higher = slower fall
# gravity = 100

# Ignore: Prevents bars from reacting to quiet sounds below this threshold
# ignore = 0


[eq]
# Equalizer: Boost or cut specific frequency bands
# 1 = Bass, 2-4 = Low-Mid, 5-7 = Mid-High, 8-10 = Treble
# Range: 0-20 (1 = No change)
1 = 1.2   # Slight bass boost
2 = 1
3 = 1
4 = 1
5 = 1
6 = 1
7 = 1
8 = 1
9 = 1
10 = 1.1  # Slight treble boost


## ============================================
## ALTERNATIVE COLOR SCHEMES (Commented Out)
## Uncomment one to switch themes
## ============================================

# --- DRACULA (Vibrant Neon) ---
# gradient_color_1 = '#8BE9FD'
# gradient_color_2 = '#9AEDFE'
# gradient_color_3 = '#CAA9FA'
# gradient_color_4 = '#BD93F9'
# gradient_color_5 = '#FF92D0'
# gradient_color_6 = '#FF79C6'
# gradient_color_7 = '#FF6E67'
# gradient_color_8 = '#FF5555'

# --- CATPPUCCIN MOCHA (Pastel Soft) ---
# gradient_color_1 = '#94e2d5'
# gradient_color_2 = '#89dceb'
# gradient_color_3 = '#74c7ec'
# gradient_color_4 = '#89b4fa'
# gradient_color_5 = '#cba6f7'
# gradient_color_6 = '#f5c2e7'
# gradient_color_7 = '#eba0ac'
# gradient_color_8 = '#f38ba8'

# --- GRUVBOX (Warm Retro) ---
# gradient_color_1 = '#b8bb26'
# gradient_color_2 = '#fabd2f'
# gradient_color_3 = '#fe8019'
# gradient_color_4 = '#fb4934'
# gradient_color_5 = '#d3869b'
# gradient_color_6 = '#b16286'
# gradient_color_7 = '#8f3f71'
# gradient_color_8 = '#cc241d'

# --- MATRIX (Classic Green) ---
gradient_color_1 = '#003300'
gradient_color_2 = '#00ff00'
gradient_color_3 = "#00df00"
gradient_color_4 = '#00ff00'
gradient_color_5 = "#083108"
gradient_color_6 = '#00ff00'
gradient_color_7 = "#98d198"
gradient_color_8 = "#d9fcd9"

# --- FIRE (Ember to Flame) ---
# gradient_color_1 = '#ff4500'
# gradient_color_2 = '#ff6600'
# gradient_color_3 = '#ff8800'
# gradient_color_4 = '#ffaa00'
# gradient_color_5 = '#ffcc00'
# gradient_color_6 = '#ffee00'
# gradient_color_7 = '#ffff00'
# gradient_color_8 = '#ffffff'


## ============================================
## PRO TIPS
## ============================================
# 1. Run in transparent terminal (Kitty/Alacritty) with blur for best aesthetics
# 2. Float the cava window in i3/sway for a widget-like appearance
# 3. Use "cava -p /path/to/custom/config" to test different configs
# 4. Combine with "cmatrix" or "pipes.sh" in a tiled layout for cyberpunk vibes
# 5. If using PulseAudio instead of PipeWire, change method to 'pulse'
