# rmpc Configuration Documentation

> **rmpc** — a Rust-based MPD client for the terminal (TUI).
> Config location: `~/.config/rmpc/`
> Format: **RON** (Rusty Object Notation) — Rust-native config format.

---

## Directory Structure

```
rmpc/
├── config.ron            # ← ACTIVE config (the one rmpc loads)
├── config.debug.ron      # Developer/debug config (points to /tmp/mpd_socket)
├── default_config.ron    # Upstream default config — reference only, do NOT edit
├── default_theme.ron     # Upstream default theme — reference only
├── smol.ron              # Alternate compact/debug config variant
├── themes/
│   └── dark.ron          # ← ACTIVE theme (pure-dark monochrome, transparent)
└── scripts/
    ├── autolrc           # Auto-fetch lyrics for currently playing song
    ├── notify            # Send desktop notification on song change (via on_song_change)
    ├── onresize          # Hook for terminal resize events
    ├── printenv          # Dump rmpc environment variables (debug helper)
    └── ytsearch          # Search current song on YouTube (bound to `Y` key)
```

---

## File Reference

### `config.ron` — Main Configuration

This is the file rmpc reads on startup. Hot-reloadable (`enable_config_hot_reload: true`).

| Section | Purpose |
|---------|---------|
| **Connection** (`address`) | Unix socket path to MPD (`~/.local/share/mpd/socket`) |
| **Paths** (`cache_dir`, `lyrics_dir`) | Cache for album art thumbnails; directory for `.lrc` lyric files |
| **Playback** (`volume_step`, `scrolloff`) | Volume increment per keypress; lines kept visible above/below cursor |
| **Performance** (`max_fps`, `status_update_interval_ms`) | UI refresh cap; MPD status poll interval |
| **Behavior** (`wrap_navigation`, `enable_mouse`) | Cursor wraps at list edges; mouse clicks enabled |
| **Theme** (`theme: "dark"`) | Loads `themes/dark.ron` — name maps to filename without `.ron` |
| **Hooks** (`on_song_change`) | Shell commands run when song changes (here: `scripts/notify`) |
| **Album Art** (`album_art`) | Method `Auto` tries embedded art → folder art → MPD readpicture |
| **Keybinds** | Three scopes: `global` (everywhere), `navigation` (lists), `queue` (queue pane) |
| **Search** | Case-insensitive substring matching across artist/album/title tags |
| **Tabs** | Defines what panes appear in each tab and their layout splits |

#### Tabs Layout

| Tab (Key) | Content |
|-----------|---------|
| Queue (`1`) | Left 30%: Lyrics + AlbumArt stacked · Right 70%: Queue list |
| Directories (`2`) | Full-pane file browser |
| Artists (`3`) | Full-pane artist list |
| Album Artists (`4`) | Full-pane album artist list |
| Albums (`5`) | Full-pane album browser |
| Playlists (`6`) | Full-pane playlist browser |
| Search (`7`) | Full-pane search interface |
| **Art (`8`)** | **Top 60%: AlbumArt · Bottom 40%: Lyrics** — immersive view |
| Testing (`9`) | Dev layout with nested splits (Queue + Dirs + Albums + Artists) |

#### Keybind Quick Reference

| Key | Action | Scope |
|-----|--------|-------|
| `q` | Quit | Global |
| `p` | Toggle pause | Global |
| `>` / `<` | Next/prev track | Global |
| `.` / `,` | Volume up/down | Global |
| `f` / `b` | Seek forward/back | Global |
| `z` / `x` / `c` | Repeat/Random/Single toggle | Global |
| `1`–`8` | Switch to tab | Global |
| `Tab` / `S-Tab` | Next/prev tab | Global |
| `j` / `k` | Down/Up | Navigation |
| `h` / `l` | Left/Right (folders) | Navigation |
| `g` / `G` | Top/Bottom | Navigation |
| `C-u` / `C-d` | Half-page up/down | Navigation |
| `a` / `A` | Add / Add all | Navigation |
| `/` | Search | Navigation |
| `Space` | Select | Navigation |
| `Enter` | Confirm / Play (queue) | Navigation/Queue |
| `d` / `D` | Delete / Delete all | Queue |
| `Y` | YouTube search (external) | Global |
| `P` | Open in MusicBrainz Picard | Global |

---

### `themes/dark.ron` — Pure Dark Theme

Design philosophy: **monochrome + transparent background**.
No catppuccin/tokyo-night/nord candy colors. Only grays and white.

| Element | Color | Hex |
|---------|-------|-----|
| Primary text | Soft white | `#d4d4d4` |
| Secondary text | Medium gray | `#999999` |
| Dim / borders | Dark gray | `#444444` |
| Active tab / current item | Black-on-white | `#000000` on `#d4d4d4` |
| Highlight | Pure white bold | `#ffffff` |
| Progress bar track | Very dark | `#333333` |
| Progress bar elapsed | Soft white | `#d4d4d4` |

**Layout order** (top to bottom, no gaps):
1. **Header** — 1 row: `▶ 1:29/4:13  Artist · Title  [states]  Vol`
2. **Tabs** — 1 row: tab bar
3. **TabContent** — fills remaining space
4. **ProgressBar** — 1 row at bottom

This eliminates the gap you see between header and tab bar in multi-row layouts.

---

### `default_config.ron` — Upstream Defaults

Reference copy of rmpc's built-in defaults. Compare against this when troubleshooting.
**Do not edit** — your overrides go in `config.ron`.

### `default_theme.ron` — Upstream Default Theme

Reference copy of the default theme shipped with rmpc. Shows all available styling
options with their default values.
**Do not edit** — your theme goes in `themes/`.

### `config.debug.ron` — Debug Configuration

Points to `/tmp/mpd_socket` (separate MPD instance for testing).
Enables extra scripts like `printenv`. Use with `rmpc --config config.debug.ron`.

### `smol.ron` — Compact Variant

An alternate config with a more compact layout and different split ratios.
References the catppuccin-macchiato theme (now deleted — update if you want to use this).

---

## Scripts

### `scripts/notify`
Triggered by `on_song_change`. Sends a desktop notification (likely via `notify-send`)
with the current song's title/artist. Integrates with dunst notification daemon.

### `scripts/ytsearch`
Bound to `Y` key. Opens a YouTube search for the currently selected song.
Uses rmpc's `$SELECTED_SONGS` environment variable.

### `scripts/autolrc`
Auto-fetches lyrics for the currently playing song. Downloads `.lrc` files
to `lyrics_dir`. Used in `config.debug.ron`.

### `scripts/printenv`
Debug helper. Dumps all rmpc-injected environment variables to `/tmp/rmpc/env`.
Useful for understanding what data rmpc exposes to external commands.

### `scripts/onresize`
Hook for terminal resize events. Can be bound via `on_resize` in config.
Useful for dynamic layouts or re-rendering album art.

---

## RON Format Notes

The `#![enable(...)]` directives at the top of each `.ron` file are RON preprocessor flags:

| Directive | Effect |
|-----------|--------|
| `implicit_some` | Write `"foo"` instead of `Some("foo")` for Option fields |
| `unwrap_newtypes` | Newtype structs can be written as their inner value |
| `unwrap_variant_newtypes` | Enum variants with single fields skip the wrapper |

### Size values in pane splits

| Format | Meaning | Example |
|--------|---------|---------|
| `"30%"` | Percentage of parent | 30% of containing pane |
| `"100%"` | Fill remaining space | After all fixed/% siblings |
| `"3"` | Fixed terminal rows/cols | Exactly 3 rows |
| `"0.4r"` | Ratio of remaining space | 40% of what's left after fixed |

### Pane types

`Queue`, `Directories`, `Artists`, `AlbumArtists`, `Albums`, `Playlists`,
`Search`, `AlbumArt`, `Lyrics`, `Header`, `Tabs`, `TabContent`, `ProgressBar`
