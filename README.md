<div align="center">

# **_glut_**

<p align="center"><i>A warm, keyboard-first Hyprland desktop on CachyOS. One command from a fresh install to this exact machine.</i></p>

<p align="center">
  <a href="https://cachyos.org"><img src="https://img.shields.io/badge/Base-CachyOS-black?style=for-the-badge&labelColor=111111&logo=archlinux&logoColor=white" alt="Base: CachyOS"/></a>
  <a href="https://hyprland.org"><img src="https://img.shields.io/badge/Hyprland-0.57-black?style=for-the-badge&labelColor=111111&logo=hyprland&logoColor=white" alt="Hyprland 0.57"/></a>
  <a href="https://github.com/duxlabs-dev/dux-shell"><img src="https://img.shields.io/badge/Shell-DankMaterialShell-black?style=for-the-badge&labelColor=111111" alt="Shell: DankMaterialShell"/></a>
  <img src="https://img.shields.io/badge/Themes-136-black?style=for-the-badge&labelColor=111111" alt="136 themes"/>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-black?style=for-the-badge&labelColor=111111" alt="License: MIT"/></a>
</p>

</div>

<table>
  <tr>
    <td><img width="100%" alt="glut: feuerhirsch theme" src=".github/assets/feuerhirsch.jpg" /></td>
    <td><img width="100%" alt="glut: terminal with neovim and fastfetch" src=".github/assets/terminal.jpg" /></td>
  </tr>
  <tr>
    <td><img width="100%" alt="glut: grosse-welle theme" src=".github/assets/grosse-welle.jpg" /></td>
    <td><img width="100%" alt="glut: synthwave84 theme" src=".github/assets/synthwave84.jpg" /></td>
  </tr>
  <tr>
    <td><img width="100%" alt="glut: sakura theme" src=".github/assets/sakura.jpg" /></td>
    <td><img width="100%" alt="glut: osaka-jade theme" src=".github/assets/osaka-jade.jpg" /></td>
  </tr>
</table>

## What this is

*Glut* is German for embers. It is my daily desktop, published the way it actually runs, not a cleaned-up showcase.

- **Exact, not approximate.** The repo is a mirror of the live machine. Every night a timer copies the real configs and the real package list back into this repo and pushes them. What you clone is what I'm running today.
- **One command.** `install.sh` takes a fresh CachyOS install to this desktop: packages, configs, shell plugins, 136 themes, login screen, services, tools.
- **Hardware-agnostic.** GPU drivers and microcode are not copied from my machine. CachyOS' `chwd` picks the right ones for yours.
- **Wallpaper is the theme.** Pick a wallpaper and the whole desktop follows it: shell, window borders, terminal, prompt, editor.
- **Offline where it counts.** Speech-to-text runs locally on the GPU, nothing leaves the machine.

## Install

On a fresh [CachyOS](https://cachyos.org) install (or Arch with the CachyOS repos), as your normal user:

```sh
sudo pacman -S --needed git github-cli
git clone https://github.com/FL4REE/glut ~/glut
~/glut/install.sh
```

Reboot, pick Hyprland on the login screen, done. Re-running `install.sh` is safe; anything it would replace is moved to `~/.glut-backup-<date>/` first.

| Option | Effect |
| :--- | :--- |
| `GLUT_SKIP_WALLPAPERS=1` | Skip the wallpaper pack (~500 MB). Themes still work, without images. |
| `GLUT_SKIP_WHISPER=1` | Skip the speech-to-text model (~550 MB). |
| `GLUT_SKIP_SDDM=1` | Keep your current login screen. |
| `GLUT_PRIVATE_REPO=you/your-private` | Also clone and run your own private overlay (see below). |

<details>
<summary><b>What <code>install.sh</code> does, step by step</b></summary>

| Stage | What happens |
| :--- | :--- |
| 1. Packages | Full `pacman -Syu`, builds `paru` from source (CachyOS' libalpm breaks `paru-bin`), installs [`pacman.txt`](packages/pacman.txt), [`aur.txt`](packages/aur.txt), [`flatpak.txt`](packages/flatpak.txt), then `chwd -a` for drivers. |
| 2. Configs | Symlinks `config/*` into `~/.config`, so a `git pull` updates the desktop in place. Rewrites absolute paths for your username. |
| 3. Shell plugins | Links the plugins in [`projects/`](projects), clones the third-party ones at pinned commits. |
| 4. Themes | Installs `themectl`, the 136 palettes in [`themes/`](themes) and the wallpaper pack from the [releases](https://github.com/FL4REE/glut/releases), then applies the current theme. |
| 5. Login screen | SDDM with [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme) and the animated [Gargantua](https://github.com/FL4REE/sddm-gargantua) variant. |
| 6. Services | DMS, calendar daemon, session target, the nightly sync timer (owner only). |
| 7. Speech-to-text | Downloads the Whisper `large-v3-turbo` model. |
| 8. Private overlay | Clones and runs a private repo if your `gh` login can see it. |

</details>

## Keybinds

Keyboard first. `SUPER + SHIFT + /` shows every bind on screen.

| Keys | Action |
| :--- | :--- |
| `SUPER + Space` | Launcher (type `~` to search themes) |
| `SUPER + Return` | Terminal (Ghostty) |
| `SUPER + ALT + D` | Dictate: speak, press again, the text is typed into the focused window |
| `SUPER + ALT + T` | Pick a theme |
| `SUPER + ALT + N` | Next theme |
| `SUPER + ALT + W` | Wallpaper carousel |
| `SUPER + V` | Clipboard history |
| `SUPER + Tab` | Overview of all workspaces |
| `SUPER + N` | Notifications |
| `SUPER + X` | Power menu |
| `SUPER + ALT + L` | Lock |
| `SUPER + C` | Close window |
| `SUPER + F` / `SUPER + SHIFT + F` | Maximize / fullscreen |
| `SUPER + SHIFT + T` | Toggle floating |
| `SUPER + H J K L` or arrows | Move focus (`+ SHIFT` moves the window) |
| `SUPER + 1…9` | Workspace (`+ SHIFT` sends the window there) |

## Custom tooling

Small tools written for this desktop. They all live in [`bin/`](bin) and are linked into `~/.local/bin`. Their messages are in German.

| Tool | What it does |
| :--- | :--- |
| [`themectl`](https://github.com/FL4REE/theme-switcher) | The theme engine. Turns a wallpaper into a full palette and applies it in one go: shell and window borders (via matugen), wallpaper, Starship, Neovim, icon theme. Imports themes from aether, iTerm2 and Omarchy. Comes with a theme gallery and a launcher plugin. |
| [`diktat`](bin/diktat) | Offline speech-to-text on a hotkey. Records with PipeWire, transcribes with whisper.cpp on the GPU, copies the text and types it into the focused window. |
| [`app`](bin/app) | `app yt`, `app gh`, `app dc`: short names for websites (opened as their own windows, no tabs) and programs. Fuzzy picker without arguments, Fish completion. Edit [`config/app/apps.conf`](config/app/apps.conf). |
| [`livewallpaper`](bin/livewallpaper) | Animated Wallpaper Engine backgrounds via `linux-wallpaperengine`, with a picker. |
| [`confsync`](bin/confsync) | Mirrors the live configs into this repo ([`manifest.txt`](config/manifest.txt)). Refuses to commit anything that looks like an API key or token. |
| [`pkgsync`](bin/pkgsync) | Keeps the package lists in step with what is really installed. New packages are appended, nothing is ever removed silently, drivers are filtered out via [`ignore.txt`](packages/ignore.txt). |

### Shell plugins

| Plugin | What it does |
| :--- | :--- |
| [DesktopContextMenu](projects/DesktopContextMenu) | Windows-style right-click menu on the desktop: apps, updates, power, screenshot. |
| [FussballTicker](projects/FussballTicker) | Live scores in the bar and goal notifications for Hansa Rostock, BVB, the Bundesliga and Germany (needs a free api-football key). |
| [MediaFlyouts](projects/MediaFlyouts) | FluentFlyout-style pop-ups for music and lock keys, visible over fullscreen apps. |
| [RunCat](projects/RunCat) | The running cat: CPU load as animation speed. |
| ThemeSwitcher / ThemeGallery | From [theme-switcher](https://github.com/FL4REE/theme-switcher): themes in the launcher and a visual gallery. |

## Stack

| Layer | Choice |
| :--- | :--- |
| Distro | CachyOS (Arch, x86-64-v3 optimized) |
| Compositor | Hyprland 0.57 with the new Lua config |
| Shell / bar / launcher | DankMaterialShell (Quickshell), via [dux-shell](https://github.com/duxlabs-dev/dux-shell) |
| Login | SDDM + sddm-astronaut-theme, Gargantua variant |
| Terminal | Ghostty |
| Shell | Fish + Starship |
| Editor | Neovim (AstroNvim) |
| Colors | themectl + matugen |
| Audio | PipeWire |
| Speech-to-text | whisper.cpp (CUDA) |

## How the sync works

```
 live desktop ──(nightly timer)──▶ confsync ──▶ config/, themes/, projects/
                                   pkgsync  ──▶ packages/*.txt
                                      │
                         secret check, commit, pull --rebase, push
                                      ▼
                                github.com/FL4REE/glut
                                      │
                      git clone && ./install.sh  (any new machine)
```

On the machine I work on, configs are real folders and get copied in. On every machine set up with `install.sh`, they are symlinks into the clone, so edits land in the repo directly.

## Private overlay

Things that only make sense for me (editor and AI tool settings, my notes vault) live in a separate private repository. `install.sh` runs it at the end if the logged-in `gh` user can see it, and skips it silently otherwise. To use the same mechanism for your own private bits, point `GLUT_PRIVATE_REPO` at a repo with an `install.sh`.

## Layout

```
glut/
├── install.sh        one-shot installer
├── bin/              custom tools (linked into ~/.local/bin)
├── config/           ~/.config mirror + manifest/exclude for confsync
├── home/             files that live directly in ~
├── packages/         pacman, AUR and Flatpak lists, ignore patterns
├── projects/         own shell plugins
├── themes/           136 palettes (wallpapers come from the releases)
└── systemd/          user units: session target, sync timer, calendar
```

## Credits

- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) / [dux-shell](https://github.com/duxlabs-dev/dux-shell): the shell everything sits in.
- [wallpaperCarousel](https://github.com/motor-dev/wallpaperCarousel) (MIT) and [dms-claudecode](https://github.com/titeya/dms-claudecode) (MIT): shell plugins, installed from upstream.
- [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme) (GPL-3.0): the login screen base.
- [runcat-text](https://github.com/bzglve/runcat-text) (BSD-2-Clause): the cat font in RunCat, [license](projects/RunCat/LICENSE-runcat.ttf).
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp), [aether](https://github.com/bjarneo/aether), [matugen](https://github.com/InioX/matugen), [AstroNvim](https://github.com/AstroNvim/AstroNvim).
- Inspired by [osyx](https://github.com/rccyx/osyx).
- Wallpapers belong to their respective artists.

## License

[MIT](./LICENSE), except for third-party files, which keep their own licenses.
