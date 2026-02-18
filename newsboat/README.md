# Newsboat — RSS Feed Reader Configuration

Terminal RSS/Atom reader. Fork of Newsbeuter. Runs inside tmux scratchpad via `$mod+o → r`.

## Quick Start

```bash
# Launch standalone
newsboat

# Launch via i3 (scratchpad)
# Press: $mod+o then r

# Reload all feeds
Shift+R

# First-time setup (after cloning dotfiles)
cd ~/work/config && ./setup-recovery/restore-dotfiles.sh
# This creates: ~/.config/newsboat → ~/work/config/newsboat
```

## Keybindings

### Navigation (Vim-style)

| Key | Action | Context |
|-----|--------|---------|
| `j` / `k` | Move down / up | Feed list, Article list, URL view |
| `l` / `Enter` | Open selected | Feed list, Article list |
| `h` / `q` | Go back / Quit dialog | All |
| `gg` | Jump to top | Feed list, Article list |
| `G` | Jump to bottom | Feed list, Article list |
| `g` | Jump to top | Article view |
| `J` / `K` | Next / Previous feed | Article list |
| `n` / `p` | Next / Previous unread | Feed list, Article list |
| `Shift+Q` | Hard quit (no confirm) | All |

### Operations

| Key | Action | Context |
|-----|--------|---------|
| `Shift+R` | Reload ALL feeds | Feed list |
| `r` | Reload current feed | Feed list |
| `o` | Open in Firefox | Article view |
| `Shift+O` | Open in browser + mark read | Article list |
| `Ctrl+B` | Bookmark article | Article list, Article view |
| `E` | Enqueue podcast | Article view |
| `s` | Save article to file | Article view |
| `/` | Search articles | Feed list, Article list |
| `t` / `T` | Select tag / Clear tag | Feed list |
| `Shift+F` | Set filter | Feed list, Article list |
| `Ctrl+F` | Clear filter | Feed list, Article list |
| `F` | Select predefined filter | Feed list, Article list |
| `U` | Toggle read feeds | Feed list |
| `D` | Delete article | Article list |
| `Shift+N` | Toggle read status | Article list |
| `Ctrl+E` | Edit flags | Article list |
| `Shift+A` | Mark feed read | Feed list |
| `Shift+C` | Mark ALL feeds read | Feed list |
| `?` | Help | All |
| `:` | Command line | All |
| `V` | Open dialogs list | All |

### Macros (press `,` then key)

| Macro | Action | Use Case |
|-------|--------|----------|
| `,v` | Play in mpv (audio only) | Listen to talks/podcasts while coding |
| `,V` | Play in mpv (with video) | Full focus video watching |
| `,y` | Copy URL to clipboard | Share link, open elsewhere |
| `,o` | Open in w3m (terminal) | Read without leaving terminal |
| `,d` | Download with yt-dlp | Save videos/podcasts locally |

## Feed Management

### Adding a Feed

Edit `~/.config/newsboat/urls` (or press `Shift+E` inside newsboat):

```
https://example.com/feed.xml tag1 tag2 "~Custom Display Name"
```

### Tagging Convention

| Tag | Category |
|-----|----------|
| `linux` | Arch Linux, kernel, distro news |
| `programming` | C++, Rust, Zig, systems programming |
| `security` | CVEs, exploit research, threat intel |
| `tech` | Industry news, aggregators (HN, Lobsters) |
| `selfhost` | Self-hosting, Docker, homelab |
| `foss` | Open source projects, community |
| `ml` | Machine learning, AI research |
| `growth` | Self-improvement, mental models, strategy |

### Query Feeds

Query feeds are virtual feeds that aggregate articles matching a filter. They appear at the top of the feed list:

- **ALL UNREAD** — every unread article across all feeds
- **TODAY** — articles published in the last 24 hours
- **THIS WEEK** — articles from the last 7 days
- **Security / Programming / Linux / ML** — category aggregations

To add a custom query feed in `urls`:

```
"query:My Custom Feed:tags # \"mytag\" and unread = \"yes\""
```

### Hiding Feeds

Prefix a tag with `!` to hide the feed from the main list (only visible through query feeds):

```
https://example.com/feed.xml !hidden-tag
"query:Aggregated:tags # \"hidden-tag\""
```

## Predefined Filters

Press `F` to select from these saved filters:

| Filter | Expression |
|--------|------------|
| Unread articles | `unread = "yes"` |
| Last 24 hours | `age between 0:1` |
| Last 7 days | `age between 0:7` |
| Security feeds | `tags # "security"` |
| Programming feeds | `tags # "programming"` |
| Linux feeds | `tags # "linux"` |

## Podcast Workflow

1. Find a feed with enclosures (podcast episodes)
2. Press `E` to enqueue the episode
3. Run `podboat` in a separate terminal to manage downloads
4. Inside podboat: `D` to download, `P` to play, `A` to auto-download all

```bash
# Launch podboat
podboat

# Podcasts download to:
~/Podcasts/<feed-name>/
```

## Bookmarks

Press `Ctrl+B` on any article to bookmark it. Bookmarks are saved to:

```
~/.local/share/newsboat/bookmarks.txt
```

Format: `timestamp → title → URL → feed → description` (tab-separated)

```bash
# View bookmarks
cat ~/.local/share/newsboat/bookmarks.txt | column -t -s $'\t'

# Search bookmarks
rg "keyword" ~/.local/share/newsboat/bookmarks.txt
```

## Notifications

New articles trigger a dunst notification via the `scripts/notify` script:

- **App name:** Newsboat
- **Icon:** `applications-rss+xml`
- **Urgency:** low
- **Replace ID:** 91919 (stacks/replaces previous notifications)

## Integration Points

| System | Integration |
|--------|-------------|
| **i3** | `$mod+o → r` opens newsboat in tmux scratchpad |
| **dunst** | New article notifications on feed reload |
| **mpv** | `,v` audio / `,V` video macro |
| **xclip** | `,y` copy URL to clipboard |
| **yt-dlp** | `,d` download media |
| **Firefox** | Default browser for `o` / `Shift+O` |
| **podboat** | Podcast download manager |

## File Locations

| File | Purpose |
|------|---------|
| `~/.config/newsboat/config` | Main configuration |
| `~/.config/newsboat/urls` | Feed subscriptions |
| `~/.config/newsboat/scripts/notify` | Dunst notification script |
| `~/.config/newsboat/scripts/bookmark` | Bookmark-to-file plugin |
| `~/.local/share/newsboat/cache.db` | Article cache (SQLite) |
| `~/.local/share/newsboat/bookmarks.txt` | Saved bookmarks |
| `~/.local/share/newsboat/history.search` | Search history |
| `~/.local/share/newsboat/history.cmdline` | Command history |
| `~/.local/share/newsboat/queue` | Podboat download queue |

## Symlink Setup

This config is managed via the dotfiles repo at `~/work/config/`. The restore script creates:

```
~/.config/newsboat → ~/work/config/newsboat  (symlink)
```

To set up manually:

```bash
ln -sfn ~/work/config/newsboat ~/.config/newsboat
```

## Curated Feed Philosophy

The feed list is intentionally **lean (~25 feeds)**. Every feed was selected for:

1. **Signal-to-noise ratio** — No clickbait sources, no high-volume aggregators that bury signal
2. **Primary sources** — Official project blogs over third-party coverage
3. **Actionable content** — Prioritize feeds that teach or inform over feeds that merely entertain
4. **Diversity** — Balanced across technical depth (Krebs, LWN) and strategic thinking (Farnam Street, Naval)

### Feed Categories Explained

**Linux/Arch** — You run Arch. These are the feeds that matter for your system:
- *Arch Linux News* — mandatory for Arch users, manual intervention notices
- *LWN.net* — deepest Linux/kernel journalism
- *Phoronix* — hardware benchmarks, driver updates, kernel performance

**Programming** — Aligned with your C++/Rust/CP training path:
- *Rust Blog + TWiR* — language evolution and ecosystem digest
- *ISO C++ News* — standard proposals relevant to CP optimization
- *Andrew Kelley* — Zig creator, systems programming philosophy

**Cybersecurity** — Your Kali setup suggests active security interest:
- *Krebs* — investigative security journalism, breach analysis
- *The Hacker News* — CVE coverage, tool releases
- *PortSwigger Daily Swig* — web security research
- *Schneier* — cryptography, policy, threat modeling

**Tech** — Community-curated tech pulse:
- *Lobste.rs* — invite-only, low-noise HN alternative
- *HN Best* — algorithmically filtered top HN stories only
- *Ars Technica* — long-form tech journalism

**Machine Learning** — Research-quality ML content:
- *Lil'Log (Lilian Weng)* — OpenAI researcher, exceptional survey posts
- *colah's blog* — visual explanations of neural network concepts
- *The AI Edge* — practical ML engineering digest

**Self-Improvement** — Becoming the top 1%:
- *James Clear* — habit systems, compounding improvement
- *Farnam Street* — mental models, decision-making frameworks
- *Paul Graham* — essays on ambition, startups, thinking clearly
- *Naval Ravikant* — wealth creation, leverage, specific knowledge

## Troubleshooting

```bash
# Newsboat won't start — check for lock file
rm ~/.local/share/newsboat/cache.db.lock

# Validate config without launching
newsboat -C ~/.config/newsboat/config -u ~/.config/newsboat/urls -x print-unread

# Check feed errors
newsboat -l 3 -d ~/.config/newsboat/debug.log

# Export feeds to OPML (for backup/migration)
newsboat -e > ~/feeds.opml

# Import feeds from OPML
newsboat -i feeds.opml
```
